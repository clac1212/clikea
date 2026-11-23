-- CLIKEA : la place d'un appareil suit la même règle que la liste du classement :
-- joueurs nommés + l'appareil lui-même, tri par score décroissant puis par première partie.
create or replace function public.clikea_daily_rank(p_day date, p_period text default 'day', p_device text default null)
returns table (rank integer, total integer, score integer)
language sql stable security definer set search_path = public as $$
  with lim as (
    select case p_period when 'week' then date_trunc('week', p_day)::date
                         when 'month' then date_trunc('month', p_day)::date
                         else p_day end as d0, p_day as d1
  ),
  agg as (
    select s.device_id, bool_or(s.name is not null) as named,
           sum(s.score)::int as score, min(s.created_at) as first_at
    from public.clikea_daily_scores s, lim
    where s.day between lim.d0 and lim.d1
    group by s.device_id
  ),
  me as (select * from agg where device_id = p_device),
  others as (select a.* from agg a where a.named and a.device_id is distinct from p_device)
  select (select count(*)::int from others o where o.score > me.score or (o.score = me.score and o.first_at < me.first_at)) + 1,
         (select count(*)::int from others) + 1,
         me.score
  from me;
$$;
revoke execute on function public.clikea_daily_rank(date, text, text) from public;
grant execute on function public.clikea_daily_rank(date, text, text) to anon, authenticated;
notify pgrst, 'reload schema';
