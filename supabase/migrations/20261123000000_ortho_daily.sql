-- 10 du jour : une question d'orthographe chaque jour ; statistiques orthographe.
create or replace function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  th real := public.clikea_ref_theta();
  b1 real; b2 real; b3 real; b4 real; mn integer;
  d date; n integer := 0; s record; k integer; pick text; fresh text; picked text[]; slots jsonb;
  ortho_pos integer; is_ortho boolean; lo real; hi real; widen real;
begin
  select value into b1 from public.clikea_settings where key = 'daily_b1';
  select value into b2 from public.clikea_settings where key = 'daily_b2';
  select value into b3 from public.clikea_settings where key = 'daily_b3';
  select value into b4 from public.clikea_settings where key = 'daily_b4';
  select value::integer into mn from public.clikea_settings where key = 'calibrated_min';
  for d in select g::date from generate_series(today, today + p_ahead, interval '1 day') g loop
    continue when exists (select 1 from public.clikea_daily_grid where day = d);
    picked := '{}'; slots := '[]'::jsonb;
    -- Une question d'orthographe par jour, sur une place sûre (culte en ouverture ou clôture le plus souvent).
    ortho_pos := (array[1, 10, 1, 10, 2])[1 + floor(random() * 5)::int];
    for s in select * from (values
        (1, 'culte', 'facile'), (2, 'revenant', 'facile'), (3, 'rappel', 'moyen'), (4, 'inedit', 'moyen'),
        (5, 'revenant', 'moyen'), (6, 'inedit', 'moyen'), (7, 'revenant', 'dur'), (8, 'inedit', 'dur'),
        (9, 'inedit', 'piege'), (10, 'culte', 'facile')) v(pos, fresh, diff) order by pos loop
      lo := case s.diff when 'facile' then b1 when 'moyen' then b2 when 'dur' then b3 else 0.26 end;
      hi := case s.diff when 'facile' then 1.01 when 'moyen' then b1 when 'dur' then b2 else b4 end;
      is_ortho := s.pos = ortho_pos;
      pick := null; fresh := s.fresh;
      -- Replis : même bande sans préférence de fraîcheur, puis bande élargie, puis tout produit non plafonné.
      -- D'abord un produit déjà mesuré par les joueurs, avec la fraîcheur voulue.
      pick := public.clikea_pick(d, s.fresh, lo, hi, picked, th, is_ortho, false, mn);
      fresh := s.fresh;
      if pick is null then
      <<search>>
      for k in 1 .. 5 loop
        widen := case k when 3 then 0.10 when 4 then 0.25 else 0 end;
        fresh := case when k = 1 then s.fresh when k = 5 then 'libre' else 'libre' end;
        pick := public.clikea_pick(d, fresh, case when k = 5 then 0 else lo - widen end, case when k = 5 then 2 else hi + widen end, picked, th, is_ortho,
                                   k >= 4 and s.diff in ('facile', 'moyen'));
        exit search when pick is not null;
      end loop;
      end if;
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

-- Statistiques par gamme : réussite en photo et en orthographe séparées.
drop view if exists public.clikea_product_stats;
create view public.clikea_product_stats with (security_invoker = true) as
select f.name, f.iconic, f.visual_family, f.seed_difficulty, round(f.difficulty::numeric, 2) as difficulty, f.n_first,
  count(a.id) filter (where a.format = 'photo') as answers,
  round(100.0 * avg(a.correct::int) filter (where a.format = 'photo'), 1) as pct_correct,
  round(100.0 * avg(a.correct::int) filter (where a.format = 'photo' and a.mode = 'duo'), 1) as pct_duo,
  round(100.0 * avg(a.correct::int) filter (where a.format = 'photo' and a.mode = 'carre'), 1) as pct_carre,
  round(100.0 * avg(a.correct::int) filter (where a.format = 'photo' and a.mode = 'cash'), 1) as pct_cash,
  count(a.id) filter (where a.format = 'ortho') as ortho_answers,
  round(100.0 * avg(a.correct::int) filter (where a.format = 'ortho'), 1) as pct_ortho,
  count(*) filter (where a.timed_out) as timeouts,
  (select count(*) from public.clikea_daily_grid g where f.name = any (g.products) and g.day <= (now() at time zone 'Europe/Paris')::date) as days_shown
from public.clikea_families f
left join public.clikea_answers a on a.product = f.name and a.source <> 'calib'
group by f.name;
revoke all on public.clikea_product_stats from anon, authenticated;
