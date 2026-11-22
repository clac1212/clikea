-- CLIKEA : le réseau de produits et les retours (docs/CALIBRATION.md, section « Réseau et retours »).

alter table public.clikea_families add column pool text not null default 'out' check (pool in ('core', 'seen', 'out'));

insert into public.clikea_settings (key, value, note) values
  ('pool_seen_size', 200, 'Réseau : nombre de « déjà vus » (meilleures ventes hors cœur)'),
  ('pool_drop_success', 0.35, 'Réseau : un produit du réseau vu au moins 3 jours dans le 10 du jour et retrouvé moins souvent que ça au retour en sort'),
  ('pool_promote_success', 0.6, 'Réseau : un inédit retrouvé au moins aussi souvent (10 réponses minimum) entre dans les « déjà vus »')
on conflict (key) do nothing;

-- Réseau : cœur = cultes + produits connus au calibrage + inédits qui ont bien marché ;
-- « déjà vus » = meilleures ventes les plus notées ; on retire ce que personne ne retrouve même au retour.
create or replace function public.clikea_refresh_pool()
returns jsonb language plpgsql security definer set search_path = public as $$
declare seen_size integer; drop_s real; promote_s real; c integer; s integer;
begin
  select value::integer into seen_size from public.clikea_settings where key = 'pool_seen_size';
  select value into drop_s from public.clikea_settings where key = 'pool_drop_success';
  select value into promote_s from public.clikea_settings where key = 'pool_promote_success';
  update public.clikea_families f set pool = case
      when f.iconic or coalesce((select sum(correct::int) from public.clikea_answers a
                                  where a.source = 'calib' and a.product = f.name), 0) >= 1 then 'core'
      when (select count(*) >= 10 and avg(correct::int) >= promote_s from public.clikea_answers a
            where a.source <> 'calib' and a.format = 'photo' and a.product = f.name) then 'core'
      else 'out' end
  where f.active and f.playable;
  update public.clikea_families set pool = 'out' where not (active and playable);
  -- Sortie : produit vu au moins 3 jours dans le 10 du jour et toujours peu retrouvé (hors cultes).
  update public.clikea_families f set pool = 'out'
  where pool = 'core' and not iconic
    and (select count(*) from public.clikea_daily_grid g where f.name = any (g.products)) >= 3
    and (select avg(correct::int) from public.clikea_answers a where a.product = f.name and a.source = 'daily' and a.format = 'photo') < drop_s;
  -- « Déjà vus » : meilleures ventes les plus notées, hors cœur.
  update public.clikea_families f set pool = 'seen'
  where f.name in (
    select name from public.clikea_families
    where active and playable and pool = 'out'
    order by top_seller desc, ratings_total desc limit seen_size);
  select count(*) filter (where pool = 'core'), count(*) filter (where pool = 'seen') into c, s from public.clikea_families;
  return jsonb_build_object('core', c, 'seen', s);
end $$;
revoke execute on function public.clikea_refresh_pool() from public, anon, authenticated;

-- Taux de réussite d'un produit dans le 10 du jour (photo), pour faire revenir d'abord les plus ratés.
create or replace function public.clikea_daily_success(p_name text)
returns real language sql stable security definer set search_path = public as $$
  select coalesce(avg(correct::int), 0.5)::real from public.clikea_answers
  where product = p_name and source = 'daily' and format = 'photo';
$$;
revoke execute on function public.clikea_daily_success(text) from public, anon, authenticated;

-- Choix d'un produit pour une place du 10 du jour v4.
create or replace function public.clikea_pick4(p_day date, p_kind text, p_exclude text[], p_theta real, p_ortho boolean)
returns text language sql volatile security definer set search_path = public as $$
  with h as (
    select x as name, max(g.day) as last, count(*) as shows
    from public.clikea_daily_grid g, unnest(g.products) x where g.day < p_day group by x
  ), c as (
    select f.name, f.iconic, f.pool, f.n_first, h.last, coalesce(h.shows, 0) as shows,
      0.25 + 0.75 / (1 + exp(-(p_theta - f.difficulty))) as p
    from public.clikea_families f left join h on h.name = f.name
    where f.active and f.playable and f.name <> all (p_exclude)
      -- jamais deux jours de suite ; un culte au plus une fois par semaine
      and (h.last is null or h.last <= p_day - case when f.iconic then 7 else 2 end)
      and (not p_ortho or (cardinality(f.spellings) >= 3 and (f.iconic or coalesce(h.shows, 0) >= 1 or f.n_first >= 8)))
  ), ok as (
    select name, case p_kind
        when 'sur' then -p                                         -- les plus sûrs
        when 'rappel' then public.clikea_daily_success(name)       -- les plus ratés d'abord
        when 'revenant' then public.clikea_daily_success(name)
        else 0 end as prio
    from c
    where case p_kind
      when 'sur' then pool = 'core' and p >= 0.8
      when 'culte' then iconic and p >= 0.75
      when 'rappel' then pool <> 'out' and last between p_day - 10 and p_day - 2
      when 'revenant' then pool <> 'out' and last <= p_day - 21
      when 'nouveau' then pool <> 'out' and last is null
      when 'piege' then last is null and p between 0.27 and 0.45
      when 'reseau' then pool <> 'out'
      else true end
    order by prio, random()
    limit case when p_kind in ('rappel', 'revenant', 'sur') then 3 else 1 end
  )
  select name from ok order by random() limit 1;
$$;
revoke execute on function public.clikea_pick4(date, text, text[], real, boolean) from public, anon, authenticated;

-- 10 du jour v4 : 3 sûrs, 3 rappels, 2 revenants, 1 nouveau, 1 piège.
-- Alternance des questions : au plus 2 « comment ça s'écrit ? » par jour, sur des produits qui reviennent.
create or replace function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  th real := public.clikea_ref_theta();
  d date; n integer := 0; s record; k integer; pick text; picked text[]; slots jsonb; tries text[]; kind text; is_ortho boolean;
  ortho_a integer; ortho_b integer;
begin
  for d in select g::date from generate_series(today, today + p_ahead, interval '1 day') g loop
    continue when exists (select 1 from public.clikea_daily_grid where day = d);
    picked := '{}'; slots := '[]'::jsonb;
    -- une question d'orthographe sur un rappel ou un revenant, parfois une seconde sur le culte de clôture
    ortho_a := (array[5, 6, 6])[1 + floor(random() * 3)::int];
    ortho_b := case when random() < 0.4 then 10 else 0 end;
    for s in select * from (values
        (1, 'culte', 'culte', 'facile'), (2, 'sur', 'culte', 'facile'), (3, 'rappel', 'rappel', 'moyen'),
        (4, 'rappel', 'rappel', 'moyen'), (5, 'rappel', 'rappel', 'moyen'), (6, 'revenant', 'revenant', 'moyen'),
        (7, 'revenant', 'revenant', 'dur'), (8, 'nouveau', 'inedit', 'moyen'), (9, 'piege', 'inedit', 'piege'),
        (10, 'culte', 'culte', 'facile')) v(pos, kind, role, diff) order by pos loop
      is_ortho := s.pos in (ortho_a, ortho_b);
      -- Replis : une catégorie vide (démarrage, peu d'historique) cède la place à la suivante.
      tries := case s.kind
        when 'culte' then array['culte', 'sur', 'reseau']
        when 'sur' then array['sur', 'culte', 'reseau']
        when 'rappel' then array['rappel', 'nouveau', 'reseau']
        when 'revenant' then array['revenant', 'rappel', 'nouveau', 'reseau']
        when 'nouveau' then array['nouveau', 'reseau']
        else array['piege', 'nouveau', 'libre'] end;
      pick := null;
      for k in 1 .. array_length(tries, 1) loop
        kind := tries[k];
        pick := public.clikea_pick4(d, kind, picked, th, is_ortho);
        exit when pick is not null;
      end loop;
      if pick is null and is_ortho then
        is_ortho := false;
        for k in 1 .. array_length(tries, 1) loop
          kind := tries[k];
          pick := public.clikea_pick4(d, kind, picked, th, false);
          exit when pick is not null;
        end loop;
      end if;
      if pick is null then raise exception 'tirage impossible pour le % (place %)', d, s.pos; end if;
      picked := picked || pick;
      slots := slots || jsonb_build_object('f', pick,
        'role', case kind when 'rappel' then 'rappel' when 'revenant' then 'revenant' when 'nouveau' then 'inedit' when 'piege' then 'inedit'
                          else (select case when iconic then 'culte' else 'revenant' end from public.clikea_families where name = pick) end,
        'diff', s.diff, 'fmt', case when is_ortho then 'ortho' else 'photo' end);
    end loop;
    insert into public.clikea_daily_grid (day, products, slots) values (d, picked, slots);
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.clikea_plan_days(integer) from public, anon, authenticated;

-- Chaque nuit : réseau rafraîchi avant le tirage.
create or replace function public.clikea_nightly()
returns jsonb language plpgsql security definer set search_path = public as $$
declare elo integer; drift_icon real; drift_other real; moved integer; replanned integer; ref real; pool jsonb;
begin
  elo := public.clikea_update_difficulty();
  select case when count(*) >= 5 then avg(difficulty - seed_difficulty) end into drift_icon
    from public.clikea_families where iconic and n_first >= 3;
  select case when count(*) >= 5 then avg(difficulty - seed_difficulty) end into drift_other
    from public.clikea_families where not iconic and n_first >= 3;
  update public.clikea_families
    set difficulty = greatest(-4, least(4, seed_difficulty + coalesce(case when iconic then drift_icon else drift_other end, 0)))
    where n_first = 0;
  get diagnostics moved = row_count;
  ref := public.clikea_ref_theta();
  update public.clikea_settings set value = ref where key = 'ref_theta';
  pool := public.clikea_refresh_pool();
  delete from public.clikea_daily_grid where day > (now() at time zone 'Europe/Paris')::date and source = 'auto';
  replanned := public.clikea_plan_days(7);
  return jsonb_build_object('elo', elo, 'drift_iconic', drift_icon, 'drift_other', drift_other, 'unseen_recaled', moved,
                            'planned', replanned, 'ref_theta', ref, 'pool', pool);
end $$;
revoke execute on function public.clikea_nightly() from public, anon, authenticated;

-- Difficultés publiques : on y joint le réseau (1 = cœur, 2 = déjà vu, 0 = hors réseau).
create or replace function public.clikea_difficulties()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_object_agg(name, jsonb_build_array(round(difficulty::numeric, 2), n_first,
           case pool when 'core' then 1 when 'seen' then 2 else 0 end))
  from public.clikea_families where active and playable;
$$;

-- La preuve que l'apprentissage invisible marche : réussite selon le rang de la rencontre (1re, 2e, 3e…).
create view public.clikea_return_stats with (security_invoker = true) as
with r as (
  select a.*, row_number() over (partition by device_id, product order by id) as meet
  from public.clikea_answers a where a.source in ('daily', 'free', 'replay')
)
select least(meet, 5) as rencontre, format, count(*) as answers, round(100.0 * avg(correct::int), 1) as pct_correct
from r group by 1, 2 order by 2, 1;
revoke all on public.clikea_return_stats from anon, authenticated;
