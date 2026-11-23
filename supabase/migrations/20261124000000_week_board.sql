-- CLIKEA : classement du 10 du jour, du jour ou de la semaine, avec la série de chaque joueur.
-- La semaine va du lundi au dimanche (jours de Paris) et additionne les scores de chaque appareil.
-- device_id reste invisible : le cumul se fait côté base, le public ne reçoit que nom, score, jours et série.
create or replace function public.clikea_daily_board(p_day date, p_period text default 'day')
returns table (name text, score integer, days integer, streak integer, first_at timestamptz)
language sql stable security definer set search_path = public as $$
  with lim as (
    select case when p_period = 'week' then date_trunc('week', p_day)::date else p_day end as d0,
           p_day as d1
  ),
  played as (
    select device_id, day from public.clikea_daily_scores where day <= p_day
  ),
  isl as (
    select device_id, day, day - (row_number() over (partition by device_id order by day))::int as grp
    from played
  ),
  runs as (
    select device_id, max(day) as last_day, count(*)::int as len from isl group by device_id, grp
  ),
  streaks as (
    select device_id, len as streak from runs where last_day >= p_day - 1
  ),
  agg as (
    select s.device_id,
           (array_agg(s.name order by s.day desc) filter (where s.name is not null))[1] as name,
           sum(s.score)::int as score, count(*)::int as days, min(s.created_at) as first_at
    from public.clikea_daily_scores s, lim
    where s.day between lim.d0 and lim.d1
    group by s.device_id
  )
  select a.name, a.score, a.days, coalesce(st.streak, 0), a.first_at
  from agg a left join streaks st using (device_id)
  where a.name is not null
  order by a.score desc, a.first_at asc
  limit 20;
$$;
revoke execute on function public.clikea_daily_board(date, text) from public;
grant execute on function public.clikea_daily_board(date, text) to anon, authenticated;

-- Place de l'appareil dans le cumul de la semaine (tous joueurs, nommés ou non).
create or replace function public.clikea_week_rank(p_day date, p_device text)
returns table (rank integer, total integer, score integer, days integer)
language sql stable security definer set search_path = public as $$
  with w as (
    select device_id, sum(score)::int as score, count(*)::int as days
    from public.clikea_daily_scores
    where day between date_trunc('week', p_day)::date and p_day
    group by device_id
  ), me as (select * from w where device_id = p_device)
  select (select count(*)::int from w where w.score > me.score) + 1,
         (select count(*)::int from w), me.score, me.days
  from me;
$$;
revoke execute on function public.clikea_week_rank(date, text) from public;
grant execute on function public.clikea_week_rank(date, text) to anon, authenticated;
