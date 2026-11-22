-- Niveau de référence du 10 du jour : ajusté pour que la réussite prédite sur les réponses réelles
-- (photo, 30 derniers jours) égale la réussite observée. Plus robuste que la moyenne des niveaux Elo au démarrage.
create or replace function public.clikea_ref_theta()
returns real language plpgsql stable security definer set search_path = public as $$
declare lo real := -5; hi real := 5; mid real; obs real; pred real; i integer;
begin
  select avg(a.correct::int) into obs from public.clikea_answers a join public.clikea_families f on f.name = a.product
    where a.format = 'photo' and a.source <> 'calib' and a.created_at > now() - interval '30 days';
  if obs is null then return 0; end if;  -- aucune réponse : échelle des difficultés de départ
  for i in 1 .. 25 loop
    mid := (lo + hi) / 2;
    select avg(c + (1 - c) / (1 + exp(-(mid - f.difficulty)))) into pred
      from (select a.product, case a.mode when 'duo' then 0.5 when 'carre' then 0.25 else 0 end as c
            from public.clikea_answers a where a.format = 'photo' and a.source <> 'calib' and a.created_at > now() - interval '30 days') x
      join public.clikea_families f on f.name = x.product;
    if pred < obs then lo := mid; else hi := mid; end if;
  end loop;
  return (lo + hi) / 2;
end $$;
revoke execute on function public.clikea_ref_theta() from public, anon, authenticated;

-- Choix d'une gamme : p_top = parmi les 5 plus faciles de la bande (repli des places sûres), sinon au hasard.
drop function if exists public.clikea_pick(date, text, real, real, text[], real, boolean);
create function public.clikea_pick(p_day date, p_fresh text, p_lo real, p_hi real, p_exclude text[], p_theta real, p_ortho boolean, p_top boolean default false)
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
  ), ok as (
    select name, p from c
    where p >= p_lo and p < p_hi
      and case p_fresh
        when 'culte' then iconic and (last is null or last <= p_day - 10)
        when 'rappel' then not iconic and shows = 1 and last between p_day - 7 and p_day - 3
        when 'revenant' then not iconic and last <= p_day - 21 and shows < 10
        when 'inedit' then not iconic and last is null
        else (last is null or last <= p_day - case when iconic then 10 else 7 end) and shows < 10
      end
    order by case when p_top then -p else 0 end, random()
    limit case when p_top then 5 else 1 end
  )
  select name from ok order by random() limit 1;
$$;
revoke execute on function public.clikea_pick(date, text, real, real, text[], real, boolean, boolean) from public, anon, authenticated;

-- Tirage v3 avec niveau de référence et repli vers les plus faciles pour les places sûres.
create or replace function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  th real := public.clikea_ref_theta();
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
        pick := public.clikea_pick(d, fresh, case when k = 5 then 0 else lo - widen end, case when k = 5 then 2 else hi + widen end, picked, th, is_ortho,
                                   k >= 4 and s.diff in ('facile', 'moyen'));
        exit search when pick is not null;
      end loop;
      if pick is null and is_ortho then
        is_ortho := false;
        pick := public.clikea_pick(d, 'libre', 0, 2, picked, th, false, s.diff in ('facile', 'moyen'));
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
