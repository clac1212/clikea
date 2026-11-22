-- Calibrage nocturne : Elo, recalage des produits jamais joués, nouveau tirage des grilles futures.
create or replace function public.clikea_nightly()
returns jsonb language plpgsql security definer set search_path = public as $$
declare elo integer; drift_icon real; drift_other real; moved integer; replanned integer;
begin
  elo := public.clikea_update_difficulty();
  -- Écart moyen entre difficulté mesurée et difficulté de départ, sur les gammes assez jouées (au moins 5 gammes).
  select case when count(*) >= 5 then avg(difficulty - seed_difficulty) end into drift_icon
    from public.clikea_families where iconic and n_first >= 3;
  select case when count(*) >= 5 then avg(difficulty - seed_difficulty) end into drift_other
    from public.clikea_families where not iconic and n_first >= 3;
  update public.clikea_families
    set difficulty = greatest(-4, least(4, seed_difficulty + coalesce(case when iconic then drift_icon else drift_other end, 0)))
    where n_first = 0;
  get diagnostics moved = row_count;
  -- La grille du jour et les grilles manuelles ne bougent pas ; les grilles futures (invisibles) sont refaites.
  delete from public.clikea_daily_grid where day > (now() at time zone 'Europe/Paris')::date and source = 'auto';
  replanned := public.clikea_plan_days(7);
  return jsonb_build_object('elo', elo, 'drift_iconic', drift_icon, 'drift_other', drift_other, 'unseen_recaled', moved, 'planned', replanned,
                            'ref_theta', public.clikea_ref_theta());
end $$;
revoke execute on function public.clikea_nightly() from public, anon, authenticated;

select cron.unschedule('clikea-difficulty');
select cron.unschedule('clikea-plan-days');
select cron.schedule('clikea-nightly', '0 22 * * *', $$select public.clikea_nightly()$$);
