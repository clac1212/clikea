-- CLIKEA : catalogue en gammes et articles, difficulté Elo, recette du 10 du jour (docs/PRODUITS.md).

-- Gamme = la réponse (BILLY). Porte la difficulté et les statistiques.
create table public.clikea_families (
  name text primary key check (char_length(name) between 1 and 40),
  slug text not null unique,
  iconic boolean not null default false,
  active boolean not null default true,
  playable boolean not null default true,
  visual_family text not null default 'divers',
  llm_reason text,
  ratings_total integer not null default 0,
  top_seller boolean not null default false,
  seed_difficulty real not null,
  difficulty real not null,
  n_first integer not null default 0,
  spellings text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Article = ce qu'on montre (photo, type dans 5 langues). Un article principal par gamme.
create table public.clikea_articles (
  item_no text primary key,
  family text not null references public.clikea_families(name) on update cascade,
  is_main boolean not null default false,
  type_fr text not null, type_en text not null, type_de text not null, type_es text not null, type_it text not null,
  price numeric,
  image_url text not null,
  image_id text not null,
  image_path text not null,
  category text,
  pip_url text,
  is_new boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index clikea_articles_one_main on public.clikea_articles (family) where is_main;

-- Niveau de chaque appareil et premières rencontres appareil × gamme (seule la première compte pour la difficulté).
create table public.clikea_players (
  device_id text primary key,
  theta real not null default 0,
  n integer not null default 0
);
create table public.clikea_exposures (
  device_id text not null,
  family text not null,
  primary key (device_id, family)
);
create table public.clikea_meta (key text primary key, value text not null);

alter table public.clikea_families enable row level security;
alter table public.clikea_articles enable row level security;
alter table public.clikea_players enable row level security;
alter table public.clikea_exposures enable row level security;
alter table public.clikea_meta enable row level security;
revoke all on public.clikea_families, public.clikea_articles, public.clikea_players, public.clikea_exposures, public.clikea_meta from anon, authenticated;

-- Grille du jour : rôle et format de chaque place.
-- slots = [{"f": nom, "role": culte|rappel|revenant|inedit, "diff": facile|moyen|dur|piege, "fmt": photo|ortho}, ...]
alter table public.clikea_daily_grid add column slots jsonb;
update public.clikea_daily_grid g set slots = (
  select jsonb_agg(jsonb_build_object('f', x, 'role', null, 'diff', null, 'fmt', 'photo') order by i)
  from unnest(g.products) with ordinality u(x, i));
alter table public.clikea_daily_grid alter column slots set not null;
alter table public.clikea_daily_grid add constraint clikea_daily_grid_slots_10 check (jsonb_array_length(slots) = 10);

-- Réponses : format et rôle de la question.
alter table public.clikea_answers add column format text not null default 'photo' check (format in ('photo', 'ortho'));
alter table public.clikea_answers add column role text check (role in ('culte', 'rappel', 'revenant', 'inedit'));
grant insert (format, role) on public.clikea_answers to anon, authenticated;

-- Difficulté : modèle Elo pour QCM (Pelánek). Hasard : Duo 1/2, Carré 1/4, Cash 0.
create function public.clikea_update_difficulty()
returns integer language plpgsql security definer set search_path = public as $$
declare
  a record; last_id bigint; th real; np integer; d real; nf integer; c real; p real; r real; cnt integer := 0;
begin
  select value::bigint into last_id from public.clikea_meta where key = 'elo_last_answer_id';
  last_id := coalesce(last_id, 0);
  for a in select * from public.clikea_answers where id > last_id order by id loop
    last_id := a.id;
    continue when a.format = 'ortho';  -- l'orthographe mesure autre chose que la reconnaissance du produit
    select difficulty, n_first into d, nf from public.clikea_families where name = a.product;
    continue when not found;
    insert into public.clikea_exposures (device_id, family) values (a.device_id, a.product) on conflict do nothing;
    continue when not found;  -- déjà rencontré : la réponse mesure la mémoire, pas la difficulté
    select theta, n into th, np from public.clikea_players where device_id = a.device_id;
    if not found then
      th := 0; np := 0;
      insert into public.clikea_players (device_id) values (a.device_id);
    end if;
    c := case a.mode when 'duo' then 0.5 when 'carre' then 0.25 else 0 end;
    p := c + (1 - c) / (1 + exp(-(th - d)));
    r := case when a.correct then 1 else 0 end;
    update public.clikea_players set theta = th + (1.0 / (1 + 0.05 * np)) * (r - p), n = np + 1 where device_id = a.device_id;
    update public.clikea_families set difficulty = greatest(-4, least(4, d - (1.0 / (1 + 0.05 * nf)) * (r - p))), n_first = nf + 1
      where name = a.product;
    cnt := cnt + 1;
  end loop;
  insert into public.clikea_meta (key, value) values ('elo_last_answer_id', last_id::text)
    on conflict (key) do update set value = excluded.value;
  return cnt;
end $$;
revoke execute on function public.clikea_update_difficulty() from public, anon, authenticated;

-- Choix d'une gamme pour une place : fraîcheur, difficulté, plafonds.
create function public.clikea_pick(p_day date, p_fresh text, p_diff text, p_exclude text[], t30 real, t70 real, t90 real, p_ortho boolean)
returns text language sql volatile security definer set search_path = public as $$
  with h as (
    select x as name, max(g.day) as last, count(*) as shows
    from public.clikea_daily_grid g, unnest(g.products) x where g.day < p_day group by x
  ), c as (
    select f.name, f.iconic, h.last, coalesce(h.shows, 0) as shows,
      case when f.difficulty <= t30 then 'facile' when f.difficulty <= t70 then 'moyen'
           when f.difficulty <= t90 then 'dur' else 'piege' end as bucket
    from public.clikea_families f left join h on h.name = f.name
    where f.active and f.playable and f.name <> all (p_exclude)
      and (not p_ortho or cardinality(f.spellings) >= 3)
  )
  select name from c
  where (p_diff is null or p_fresh = 'culte' or bucket = p_diff)
    and case p_fresh
      when 'culte' then iconic and (last is null or last <= p_day - 10)
      when 'rappel' then not iconic and shows = 1 and last between p_day - 7 and p_day - 3
      when 'revenant' then not iconic and last <= p_day - 21 and shows < 10
      when 'inedit' then not iconic and last is null
      else (last is null or last <= p_day - 7) and shows < 10
    end
  order by random() limit 1;
$$;
revoke execute on function public.clikea_pick(date, text, text, text[], real, real, real, boolean) from public, anon, authenticated;

-- Recette : 3 inédits, 1 rappel, 4 revenants, 2 cultes ; une question d'orthographe certains jours.
create or replace function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  d date; n integer := 0; t30 real; t70 real; t90 real;
  s record; tries text[]; k integer; fresh text; pick text; picked text[]; slots jsonb; ortho_pos integer; is_ortho boolean;
begin
  select percentile_cont(0.3) within group (order by difficulty), percentile_cont(0.7) within group (order by difficulty),
         percentile_cont(0.9) within group (order by difficulty)
    into t30, t70, t90 from public.clikea_families where active and playable and not iconic;
  for d in select g::date from generate_series(today, today + p_ahead, interval '1 day') g loop
    continue when exists (select 1 from public.clikea_daily_grid where day = d);
    picked := '{}'; slots := '[]'::jsonb;
    ortho_pos := case when random() < 0.6 then (array[1, 10, 1, 10, 6])[1 + floor(random() * 5)::int] else 0 end;
    for s in select * from (values
        (1, 'culte', 'facile'), (2, 'revenant', 'facile'), (3, 'rappel', 'moyen'), (4, 'revenant', 'moyen'),
        (5, 'inedit', 'moyen'), (6, 'revenant', 'moyen'), (7, 'inedit', 'dur'), (8, 'revenant', 'dur'),
        (9, 'inedit', 'piege'), (10, 'culte', 'facile')) v(pos, fresh, diff) order by pos loop
      -- Repli quand une catégorie est vide (démarrage, inédits épuisés) : fraîcheur voisine, puis toute difficulté.
      tries := case s.fresh
        when 'culte' then array['culte', 'revenant', 'inedit']
        when 'rappel' then array['rappel', 'revenant', 'inedit']
        when 'revenant' then array['revenant', 'inedit', 'libre']
        else array['inedit', 'revenant', 'libre'] end;
      pick := null; is_ortho := s.pos = ortho_pos;
      <<search>>
      for k in 1 .. array_length(tries, 1) loop
        fresh := tries[k];
        pick := public.clikea_pick(d, fresh, s.diff, picked, t30, t70, t90, is_ortho);
        exit search when pick is not null;
        pick := public.clikea_pick(d, fresh, null, picked, t30, t70, t90, is_ortho);
        exit search when pick is not null;
      end loop;
      if pick is null and is_ortho then
        is_ortho := false;
        pick := public.clikea_pick(d, s.fresh, null, picked, t30, t70, t90, false);
        fresh := s.fresh;
      end if;
      if pick is null then raise exception 'tirage impossible pour le % (place %)', d, s.pos; end if;
      picked := picked || pick;
      slots := slots || jsonb_build_object('f', pick, 'role', case when fresh = 'libre' then 'revenant' else fresh end,
                                           'diff', s.diff, 'fmt', case when is_ortho then 'ortho' else 'photo' end);
    end loop;
    insert into public.clikea_daily_grid (day, products, slots) values (d, picked, slots);
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.clikea_plan_days(integer) from public, anon, authenticated;

-- Statistiques par gamme.
drop view if exists public.clikea_product_stats;
create view public.clikea_product_stats with (security_invoker = true) as
select f.name, f.iconic, f.visual_family, f.seed_difficulty, round(f.difficulty::numeric, 2) as difficulty, f.n_first,
  count(a.id) as answers,
  round(100.0 * avg(a.correct::int), 1) as pct_correct,
  round(100.0 * avg(a.correct::int) filter (where a.mode = 'duo'), 1) as pct_duo,
  round(100.0 * avg(a.correct::int) filter (where a.mode = 'carre'), 1) as pct_carre,
  round(100.0 * avg(a.correct::int) filter (where a.mode = 'cash'), 1) as pct_cash,
  count(*) filter (where a.timed_out) as timeouts,
  (select count(*) from public.clikea_daily_grid g where f.name = any (g.products) and g.day <= (now() at time zone 'Europe/Paris')::date) as days_shown
from public.clikea_families f
left join public.clikea_answers a on a.product = f.name
group by f.name;
revoke all on public.clikea_product_stats from anon, authenticated;

-- Chaque nuit : difficulté d'abord (22 h 00 UTC), tirage ensuite (22 h 05 UTC, tâche existante).
select cron.schedule('clikea-difficulty', '0 22 * * *', $$select public.clikea_update_difficulty()$$);
