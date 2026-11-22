-- Difficultés en un seul bloc JSON {nom: [difficulté, premières rencontres]} : l'API limite à 1 000 lignes par réponse.
drop function if exists public.clikea_difficulties();
create function public.clikea_difficulties()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_object_agg(name, jsonb_build_array(round(difficulty::numeric, 2), n_first))
  from public.clikea_families where active and playable;
$$;
revoke execute on function public.clikea_difficulties() from public;
grant execute on function public.clikea_difficulties() to anon, authenticated;
