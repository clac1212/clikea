-- CLIKEA : calibrage par les joueurs (docs/CALIBRATION.md).

-- Réglages modifiables sans republier le jeu. Lecture publique (le jeu les charge au démarrage).
create table public.clikea_settings (
  key text primary key,
  value real not null,
  note text not null
);
alter table public.clikea_settings enable row level security;
revoke all on public.clikea_settings from anon, authenticated;
grant select on public.clikea_settings to anon, authenticated;
create policy clikea_settings_read on public.clikea_settings for select to anon, authenticated using (true);
insert into public.clikea_settings (key, value, note) values
  ('free_conf_min', 0.85, 'Partie libre : chance de trouver (en Carré) au-dessus de laquelle un produit est « confiance »'),
  ('free_zone_min', 0.50, 'Partie libre : bas de la zone de jeu ; en dessous = défi'),
  ('free_share_conf', 0.25, 'Partie libre : part de produits « confiance »'),
  ('free_share_defi', 0.15, 'Partie libre : part de défis (le reste = zone)'),
  ('free_explore', 0.10, 'Partie libre : part de produits encore peu mesurés'),
  ('free_session_step', 0.15, 'Partie libre : hausse de niveau par partie enchaînée dans les 2 h'),
  ('free_repeat_days', 3, 'Partie libre : jours avant qu''un produit déjà vu puisse revenir'),
  ('calibrated_min', 8, 'Réponses de première rencontre à partir desquelles un produit est « mesuré »'),
  ('daily_b1', 0.85, '10 du jour : places 1, 2, 10 au-dessus de ce seuil (chance en Carré, joueur moyen)'),
  ('daily_b2', 0.60, '10 du jour : places 3 à 6 entre b2 et b1'),
  ('daily_b3', 0.45, '10 du jour : places 7 et 8 entre b3 et b2'),
  ('daily_b4', 0.30, '10 du jour : piège (place 9) entre 0,26 et b4'),
  ('daily_target_score', 28, '10 du jour : score moyen visé sur 50 (suivi, pas appliqué automatiquement)');

-- Difficultés mesurées, lisibles par le jeu (la table des gammes reste privée).
create function public.clikea_difficulties()
returns table (n text, d real, c integer) language sql stable security definer set search_path = public as $$
  select name, round(difficulty::numeric, 2)::real, n_first from public.clikea_families where active and playable;
$$;
revoke execute on function public.clikea_difficulties() from public;
grant execute on function public.clikea_difficulties() to anon, authenticated;

-- Réponses du mode calibrage (« je connais / je ne connais pas »), séparées du jeu.
alter table public.clikea_answers drop constraint clikea_answers_source_check;
alter table public.clikea_answers add constraint clikea_answers_source_check check (source in ('daily', 'replay', 'free', 'calib'));
alter table public.clikea_answers drop constraint clikea_answers_check;
alter table public.clikea_answers add constraint clikea_answers_check check ((source in ('free', 'calib')) = (day is null));

-- Produits signalés « à retirer » pendant le calibrage.
create table public.clikea_flags (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  device_id text not null check (char_length(device_id) between 6 and 64),
  product text not null check (char_length(product) between 1 and 40),
  reason text not null check (reason in ('niche', 'photo', 'type'))
);
alter table public.clikea_flags enable row level security;
revoke all on public.clikea_flags from anon, authenticated;
grant insert (device_id, product, reason) on public.clikea_flags to anon, authenticated;
create policy clikea_flags_insert on public.clikea_flags for insert to anon, authenticated with check (true);

-- Niveau moyen des joueurs (appareils avec au moins 20 premières rencontres), 0 tant qu'il n'y en a pas.
create function public.clikea_mean_theta()
returns real language sql stable security definer set search_path = public as $$
  select coalesce((select avg(theta)::real from public.clikea_players where n >= 20), 0::real);
$$;
revoke execute on function public.clikea_mean_theta() from public, anon, authenticated;

-- Choix d'une gamme : fraîcheur, bande de chance de réussite (Carré, joueur moyen), plafonds.
drop function if exists public.clikea_pick(date, text, text, text[], real, real, real, boolean);
create function public.clikea_pick(p_day date, p_fresh text, p_lo real, p_hi real, p_exclude text[], p_theta real, p_ortho boolean)
returns text language sql volatile security definer set search_path = public as $$
  with h as (
    select x as name, max(g.day) as last, count(*) as shows
    from public.clikea_daily_grid g, unnest(g.products) x where g.day < p_day group by x
  ), c as (
    select f.name, f.iconic, h.last, coalesce(h.shows, 0) as shows,
      0.25 + 0.75 / (1 + exp(-(p_theta - f.difficulty))) as p
    from public.clikea_families f left join h on h.name = f.name
    where f.active and f.playable and f.name <> all (p_exclude)
      and (not p_ortho or cardinality(f.spellings) >= 3)
  )
  select name from c
  where p >= p_lo and p < p_hi
    and case p_fresh
      when 'culte' then iconic and (last is null or last <= p_day - 10)
      when 'rappel' then not iconic and shows = 1 and last between p_day - 7 and p_day - 3
      when 'revenant' then not iconic and last <= p_day - 21 and shows < 10
      when 'inedit' then not iconic and last is null
      else (last is null or last <= p_day - case when iconic then 10 else 7 end) and shows < 10
    end
  order by random() limit 1;
$$;
revoke execute on function public.clikea_pick(date, text, real, real, text[], real, boolean) from public, anon, authenticated;

-- 10 du jour v3 : 3 produits sûrs, 4 dans la zone, 2 plus durs, 1 piège ; fraîcheur en préférence, plafonds conservés.
create or replace function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  th real := public.clikea_mean_theta();
  b1 real; b2 real; b3 real; b4 real;
  d date; n integer := 0; s record; k integer; pick text; fresh text; picked text[]; slots jsonb;
  ortho_pos integer; is_ortho boolean; lo real; hi real; widen real;
begin
  select value into b1 from public.clikea_settings where key = 'daily_b1';
  select value into b2 from public.clikea_settings where key = 'daily_b2';
  select value into b3 from public.clikea_settings where key = 'daily_b3';
  select value into b4 from public.clikea_settings where key = 'daily_b4';
  for d in select g::date from generate_series(today, today + p_ahead, interval '1 day') g loop
    continue when exists (select 1 from public.clikea_daily_grid where day = d);
    picked := '{}'; slots := '[]'::jsonb;
    ortho_pos := case when random() < 0.6 then (array[1, 10, 1, 10, 2])[1 + floor(random() * 5)::int] else 0 end;
    for s in select * from (values
        (1, 'culte', 'facile'), (2, 'revenant', 'facile'), (3, 'rappel', 'moyen'), (4, 'inedit', 'moyen'),
        (5, 'revenant', 'moyen'), (6, 'inedit', 'moyen'), (7, 'revenant', 'dur'), (8, 'inedit', 'dur'),
        (9, 'inedit', 'piege'), (10, 'culte', 'facile')) v(pos, fresh, diff) order by pos loop
      lo := case s.diff when 'facile' then b1 when 'moyen' then b2 when 'dur' then b3 else 0.26 end;
      hi := case s.diff when 'facile' then 1.01 when 'moyen' then b1 when 'dur' then b2 else b4 end;
      is_ortho := s.pos = ortho_pos;
      pick := null; fresh := s.fresh;
      -- Replis : même bande sans préférence de fraîcheur, puis bande élargie, puis tout produit non plafonné.
      <<search>>
      for k in 1 .. 5 loop
        widen := case k when 3 then 0.10 when 4 then 0.25 else 0 end;
        fresh := case when k = 1 then s.fresh when k = 5 then 'libre' else 'libre' end;
        pick := public.clikea_pick(d, fresh, case when k = 5 then 0 else lo - widen end, case when k = 5 then 2 else hi + widen end, picked, th, is_ortho);
        exit search when pick is not null;
      end loop;
      if pick is null and is_ortho then
        is_ortho := false;
        pick := public.clikea_pick(d, 'libre', 0, 2, picked, th, false);
      end if;
      if pick is null then raise exception 'tirage impossible pour le % (place %)', d, s.pos; end if;
      picked := picked || pick;
      slots := slots || jsonb_build_object('f', pick,
        'role', case when fresh = 'libre' then (select case when iconic then 'culte' else 'revenant' end from public.clikea_families where name = pick) else fresh end,
        'diff', s.diff, 'fmt', case when is_ortho then 'ortho' else 'photo' end);
    end loop;
    insert into public.clikea_daily_grid (day, products, slots) values (d, picked, slots);
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.clikea_plan_days(integer) from public, anon, authenticated;

-- Suivi : répartition des scores du 10 du jour.
create view public.clikea_daily_stats with (security_invoker = true) as
select day, count(*) as players, round(avg(score), 1) as avg_score,
  percentile_cont(0.25) within group (order by score) as p25,
  percentile_cont(0.5) within group (order by score) as median,
  percentile_cont(0.75) within group (order by score) as p75,
  min(score) as min, max(score) as max
from public.clikea_daily_scores group by day;
revoke all on public.clikea_daily_stats from anon, authenticated;
