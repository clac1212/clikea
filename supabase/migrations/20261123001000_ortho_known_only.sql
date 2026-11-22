-- Orthographe réservée aux produits connus.
create or replace function public.clikea_pick(p_day date, p_fresh text, p_lo real, p_hi real, p_exclude text[], p_theta real, p_ortho boolean, p_top boolean default false, p_min_n integer default 0)
returns text language sql volatile security definer set search_path = public as $$
  with h as (
    select x as name, max(g.day) as last, count(*) as shows
    from public.clikea_daily_grid g, unnest(g.products) x where g.day < p_day group by x
  ), c as (
    select f.name, f.iconic, f.n_first, h.last, coalesce(h.shows, 0) as shows,
      0.25 + 0.75 / (1 + exp(-(p_theta - f.difficulty))) as p
    from public.clikea_families f left join h on h.name = f.name
    where f.active and f.playable and f.name <> all (p_exclude)
      -- Orthographe : seulement des produits que les joueurs connaissent (cultes ou mesurés).
      and (not p_ortho or (cardinality(f.spellings) >= 3 and (f.iconic or f.n_first >= 8)))
      and f.n_first >= p_min_n
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
revoke execute on function public.clikea_pick(date, text, real, real, text[], real, boolean, boolean, integer) from public, anon, authenticated;

