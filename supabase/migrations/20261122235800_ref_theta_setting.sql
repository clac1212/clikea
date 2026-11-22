-- Le niveau de référence est publié dans les réglages : un nouveau joueur démarre au niveau moyen réel.
insert into public.clikea_settings (key, value, note) values
  ('ref_theta', public.clikea_ref_theta(), 'Niveau de référence (mis à jour chaque nuit) : point de départ d''un nouveau joueur')
  on conflict (key) do update set value = excluded.value;
create or replace function public.clikea_nightly()
returns jsonb language plpgsql security definer set search_path = public as $$
declare elo integer; drift_icon real; drift_other real; moved integer; replanned integer; ref real;
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
  delete from public.clikea_daily_grid where day > (now() at time zone 'Europe/Paris')::date and source = 'auto';
  replanned := public.clikea_plan_days(7);
  return jsonb_build_object('elo', elo, 'drift_iconic', drift_icon, 'drift_other', drift_other, 'unseen_recaled', moved,
                            'planned', replanned, 'ref_theta', ref);
end $$;
revoke execute on function public.clikea_nightly() from public, anon, authenticated;
