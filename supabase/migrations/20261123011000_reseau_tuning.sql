-- Réseau : « déjà vus » limités aux objets qu'on repère chez soi ou en magasin ;
-- retours à intervalles croissants ; orthographe réservée aux produits connus.
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
  update public.clikea_families f set pool = 'out'
  where pool = 'core' and not iconic
    and (select count(*) from public.clikea_daily_grid g where f.name = any (g.products)) >= 3
    and (select avg(correct::int) from public.clikea_answers a where a.product = f.name and a.source = 'daily' and a.format = 'photo') < drop_s;
  update public.clikea_families f set pool = 'seen'
  where f.name in (
    select name from public.clikea_families
    where active and playable and pool = 'out'
      and visual_family in ('canapé', 'fauteuil', 'chaise', 'tabouret et banc', 'table', 'bureau', 'lit',
        'armoire et penderie', 'commode et caisson', 'buffet et meuble tv', 'étagère et bibliothèque', 'rangement mural',
        'boîte et panier', 'luminaire de plafond', 'lampe à poser', 'lampadaire', 'miroir', 'jouet et peluche', 'enfant et bébé')
    order by top_seller desc, ratings_total desc limit seen_size);
  select count(*) filter (where pool = 'core'), count(*) filter (where pool = 'seen') into c, s from public.clikea_families;
  return jsonb_build_object('core', c, 'seen', s);
end $$;
revoke execute on function public.clikea_refresh_pool() from public, anon, authenticated;

create or replace function public.clikea_pick4(p_day date, p_kind text, p_exclude text[], p_theta real, p_ortho boolean)
returns text language sql volatile security definer set search_path = public as $$
  with h as (
    select x as name, max(g.day) as last, count(*) as shows
    from public.clikea_daily_grid g, unnest(g.products) x where g.day < p_day group by x
  ), c as (
    select f.name, f.iconic, f.pool, f.n_first, h.last, coalesce(h.shows, 0) as shows,
      0.25 + 0.75 / (1 + exp(-(p_theta - f.difficulty))) as p,
      -- intervalle minimal avant le prochain passage : il s'allonge à chaque passage
      case coalesce(h.shows, 0) when 0 then 0 when 1 then 2 when 2 then 7 when 3 then 21 else 45 end as gap
    from public.clikea_families f left join h on h.name = f.name
    where f.active and f.playable and f.name <> all (p_exclude)
      and (not p_ortho or (cardinality(f.spellings) >= 3 and (f.iconic or f.pool = 'core' or coalesce(h.shows, 0) >= 2)))
  ), ok as (
    select name, case p_kind
        when 'sur' then -p
        when 'rappel' then public.clikea_daily_success(name)
        when 'revenant' then public.clikea_daily_success(name)
        else 0 end as prio
    from c
    where (last is null or last <= p_day - greatest(gap, case when iconic then 7 else 2 end))
      and case p_kind
        when 'sur' then pool = 'core' and p >= 0.8
        when 'culte' then iconic and p >= 0.75
        when 'rappel' then pool <> 'out' and shows = 1 and last >= p_day - 5
        when 'revenant' then pool <> 'out' and shows >= 2
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
