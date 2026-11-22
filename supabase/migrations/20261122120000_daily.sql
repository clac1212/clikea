-- CLIKEA : le 10 du jour, son classement, et l'historique des réponses par produit.

-- Sécurité : TRUNCATE et TRIGGER contournent la RLS. Le public n'en a jamais besoin.
revoke truncate, trigger, references on public.clikea_scores from anon, authenticated;

-- Catalogue : miroir de PRODUCTS dans index.html. Le palier sert au tirage du jour.
create table public.clikea_products (
  name text primary key check (char_length(name) between 1 and 40),
  tier text not null check (tier in ('easy','medium','hard')),
  type_fr text not null,
  image text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.clikea_products enable row level security;
revoke all on public.clikea_products from anon, authenticated;

insert into public.clikea_products (name, tier, type_fr, image) values
  ('BILLY', 'easy', 'Bibliothèque', 'img/billy.webp'),
  ('KALLAX', 'easy', 'Étagère', 'img/kallax.webp'),
  ('MALM', 'easy', 'Coiffeuse', 'img/malm.webp'),
  ('POÄNG', 'easy', 'Fauteuil', 'img/poang.webp'),
  ('LACK', 'easy', 'Table basse', 'img/lack.webp'),
  ('HEMNES', 'easy', 'Lit banquette 2 places (structure)', 'img/hemnes.webp'),
  ('PAX', 'easy', 'Armoire-penderie', 'img/pax.webp'),
  ('ALEX', 'easy', 'Caisson à tiroirs', 'img/alex.webp'),
  ('MICKE', 'easy', 'Bureau', 'img/micke.webp'),
  ('TROFAST', 'easy', 'Combinaison structure + bacs', 'img/trofast.webp'),
  ('MAMMUT', 'easy', 'Table enfant', 'img/mammut.webp'),
  ('ANTILOP', 'easy', 'Structure chaise haute+tablette', 'img/antilop.webp'),
  ('DUKTIG', 'medium', 'Lit poupée+linge de lit', 'img/duktig.webp'),
  ('BLÅHAJ', 'easy', 'Peluche', 'img/blahaj.webp'),
  ('RÅSKOG', 'easy', 'Desserte', 'img/raskog.webp'),
  ('BEKVÄM', 'medium', 'Étagère à épices', 'img/bekvam.webp'),
  ('MARIUS', 'medium', 'Tabouret', 'img/marius.webp'),
  ('INGOLF', 'medium', 'Chaise junior', 'img/ingolf.webp'),
  ('NORDVIKEN', 'hard', 'Chaise de bar', 'img/nordviken.webp'),
  ('STRANDMON', 'easy', 'Fauteuil à oreilles', 'img/strandmon.webp'),
  ('EKTORP', 'easy', 'Canapé 3 places', 'img/ektorp.webp'),
  ('SÖDERHAMN', 'easy', 'Module 3 places', 'img/soderhamn.webp'),
  ('VIMLE', 'easy', 'Canapé 3 places', 'img/vimle.webp'),
  ('KIVIK', 'easy', 'Canapé 2 places', 'img/kivik.webp'),
  ('FJÄLLBO', 'medium', 'Banc TV', 'img/fjallbo.webp'),
  ('VITTSJÖ', 'medium', 'Étagère', 'img/vittsjo.webp'),
  ('KNOXHULT', 'medium', 'Élément bas avec portes et tiroir', 'img/knoxhult.webp'),
  ('SUNDVIK', 'medium', 'Lit bébé', 'img/sundvik.webp'),
  ('SMÅSTAD', 'medium', 'Banc avec rangement jouets', 'img/smastad.webp'),
  ('KURA', 'medium', 'Lit réversible', 'img/kura.webp'),
  ('MULIG', 'medium', 'Portant', 'img/mulig.webp'),
  ('SKUBB', 'medium', 'Rangement, 6 pièces', 'img/skubb.webp'),
  ('ORDNING', 'hard', 'Égouttoir à couverts', 'img/ordning.webp'),
  ('FÖRNUFTIG', 'medium', 'Purificateur d''air', 'img/fornuftig.webp'),
  ('TRÅDFRI', 'medium', 'Transformateur électrique connecté', 'img/tradfri.webp'),
  ('KLIPPAN', 'easy', 'Canapé 2 places', 'img/klippan.webp'),
  ('GOSIG GOLDEN', 'medium', 'Peluche', 'img/gosig-golden.webp'),
  ('FABLER', 'hard', 'Couverts, 3 pièces', 'img/fabler.webp'),
  ('STOCKHOLM', 'medium', 'Table basse', 'img/stockholm.webp'),
  ('HAUGA', 'medium', 'Armoire 2 portes', 'img/hauga.webp'),
  ('GULLIVER', 'medium', 'Lit bébé', 'img/gulliver.webp'),
  ('SONGESAND', 'hard', 'Commode 3 tiroirs', 'img/songesand.webp'),
  ('BRIMNES', 'medium', 'Armoire 3 portes', 'img/brimnes.webp'),
  ('HAVSTA', 'medium', 'Armoire avec plinthe', 'img/havsta.webp'),
  ('IDANÄS', 'hard', 'Élément haut portes vitrées, 1 tir', 'img/idanas.webp'),
  ('RISATORP', 'medium', 'Panier', 'img/risatorp.webp'),
  ('KVISTBRO', 'medium', 'Table de rangement', 'img/kvistbro.webp'),
  ('VATTENKRASSE', 'hard', 'Ensemble de vases à bouture', 'img/vattenkrasse.webp'),
  ('FEJKA', 'medium', 'Plante artificielle', 'img/fejka.webp'),
  ('LISABO', 'medium', 'Table', 'img/lisabo.webp'),
  ('DAGOTTO', 'medium', 'Repose-pieds', 'img/dagotto.webp'),
  ('TERTIAL', 'medium', 'Lampe de bureau', 'img/tertial.webp'),
  ('NÄVLINGE', 'hard', 'Spot à pince à LED', 'img/navlinge.webp'),
  ('KORKEN', 'hard', 'Bocal avec couvercle', 'img/korken.webp'),
  ('VARDAGEN', 'hard', 'Faitout avec couvercle', 'img/vardagen.webp'),
  ('FJÄLLBERGET', 'hard', 'Chaise conférence', 'img/fjallberget.webp'),
  ('PÅHL', 'medium', 'Bureau', 'img/pahl.webp'),
  ('TROMMA', 'hard', 'Horloge murale', 'img/tromma.webp'),
  ('BONDHOLMEN', 'hard', 'Table, extérieur', 'img/bondholmen.webp'),
  ('FÖRHÖJA', 'hard', 'Desserte', 'img/forhoja.webp'),
  ('LÄCKÖ', 'hard', 'Étagère', 'img/lacko.webp'),
  ('TÄRNÖ', 'hard', 'Table+2 chaises, extérieur', 'img/tarno.webp'),
  ('BÄSTIS', 'hard', 'Brosse adhésive', 'img/bastis.webp'),
  ('KALAS', 'medium', 'Assiette', 'img/kalas.webp'),
  ('PLUFSIG', 'hard', 'Tapis de gymnastique pliant', 'img/plufsig.webp'),
  ('MÅLA', 'hard', 'Chevalet', 'img/mala.webp'),
  ('SUNNERSTA', 'hard', 'Récipient', 'img/sunnersta.webp'),
  ('UPPDATERA', 'hard', 'Boîte', 'img/uppdatera.webp'),
  ('SAMLA', 'medium', 'Boîte avec couvercle', 'img/samla.webp'),
  ('DRÖNA', 'hard', 'Rangement tissu', 'img/drona.webp'),
  ('LOTE', 'hard', 'Commode 3 tiroirs', 'img/lote.webp'),
  ('GUNDE', 'hard', 'Chaise pliante', 'img/gunde.webp'),
  ('SVALKA', 'hard', 'Verre à vin', 'img/svalka.webp'),
  ('PEPPRIG', 'hard', 'Kit de nettoyage', 'img/pepprig.webp'),
  ('EKENÄSET', 'hard', 'Fauteuil', 'img/ekenaset.webp'),
  ('PÄRUP', 'hard', 'Housse canapé 2 pl', 'img/parup.webp'),
  ('FRIHETEN', 'hard', 'Canapé convertible angle+rangement', 'img/friheten.webp'),
  ('JÄTTEBO', 'hard', 'Module 1,5 place avec rangement', 'img/jattebo.webp'),
  ('NORDLI', 'hard', 'Commode modulable 2 tir', 'img/nordli.webp'),
  ('SNIGLAR', 'hard', 'Lit bébé', 'img/sniglar.webp'),
  ('FLISAT', 'hard', 'Rangement mural', 'img/flisat.webp'),
  ('KUGGIS', 'hard', 'Boîte de rangement avec couvercle', 'img/kuggis.webp'),
  ('DIRIGERA', 'hard', 'Passerelle pour produits connectés', 'img/dirigera.webp'),
  ('RANARP', 'hard', 'Suspension', 'img/ranarp.webp'),
  ('HEKTAR', 'hard', 'Lampadaire avec 3 spots', 'img/hektar.webp'),
  ('FORSÅ', 'hard', 'Lampe de bureau', 'img/forsa.webp'),
  ('KONCIS', 'hard', 'Plat à four avec grille', 'img/koncis.webp'),
  ('STOENSE', 'hard', 'Tapis, poils ras', 'img/stoense.webp'),
  ('TIPHEDE', 'hard', 'Tapis tissé à plat', 'img/tiphede.webp'),
  ('VOXNAN', 'hard', 'Étagère douche', 'img/voxnan.webp'),
  ('BROGRUND', 'hard', 'Poubelle ouverture à pression', 'img/brogrund.webp'),
  ('SUNDSÖ', 'hard', 'Rangement', 'img/sundso.webp'),
  ('LOMMARP', 'hard', 'Rangement', 'img/lommarp.webp'),
  ('SOTENÄS', 'hard', 'Fauteuil', 'img/sotenas.webp'),
  ('ÅRSTID', 'hard', 'Lampe de table', 'img/arstid.webp'),
  ('LUNNOM', 'hard', 'Ampoule LED E27 470 lumen', 'img/lunnom.webp'),
  ('SKAFTET', 'hard', 'Pied lampadaire, arceau noir', 'img/skaftet.webp'),
  ('NYMÅNE', 'hard', 'Applique/liseuse, inst fixe', 'img/nymane.webp'),
  ('VARMBLIXT', 'hard', 'Lampe de table/applique LED', 'img/varmblixt.webp'),
  ('LÅNESPELARE', 'hard', 'Support pour écran', 'img/lanespelare.webp'),
  ('MATCHSPEL', 'hard', 'Chaise gaming', 'img/matchspel.webp'),
  ('HUVUDSPELARE', 'hard', 'Chaise gaming', 'img/huvudspelare.webp'),
  ('MARKUS', 'hard', 'Chaise de bureau', 'img/markus.webp'),
  ('JÄRVFJÄLLET', 'hard', 'Chaise de bureau av accoudoirs', 'img/jarvfjallet.webp'),
  ('NORDKISA', 'hard', 'Armoire ouverte av porte couliss', 'img/nordkisa.webp'),
  ('HAMNÖN', 'hard', 'Hamac', 'img/hamnon.webp'),
  ('KOLBJÖRN', 'hard', 'Élément rangement int/extérieur', 'img/kolbjorn.webp'),
  ('HYLLIS', 'hard', 'Étagère', 'img/hyllis.webp'),
  ('OMAR', 'hard', 'Étagère', 'img/omar.webp');

-- Grille du jour : 10 noms, 3 faciles puis 4 moyens puis 3 durs.
-- source = 'manual' pour une grille choisie à la main ; le tirage auto ne la touche pas.
create table public.clikea_daily_grid (
  day date primary key,
  products text[] not null check (cardinality(products) = 10),
  source text not null default 'auto' check (source in ('auto','manual')),
  created_at timestamptz not null default now()
);
alter table public.clikea_daily_grid enable row level security;
revoke all on public.clikea_daily_grid from anon, authenticated;
grant select on public.clikea_daily_grid to anon, authenticated;
-- Les grilles futures restent invisibles.
create policy clikea_grid_read on public.clikea_daily_grid for select to anon, authenticated
  using (day <= (now() at time zone 'Europe/Paris')::date);

-- Scores du jour : une ligne par appareil et par jour.
-- results : une lettre par produit, o = juste, k = raté, t = temps écoulé.
create table public.clikea_daily_scores (
  id uuid primary key default gen_random_uuid(),
  day date not null references public.clikea_daily_grid(day),
  device_id text not null check (char_length(device_id) between 6 and 64),
  name text check (name is null or char_length(btrim(name)) between 1 and 20),
  score integer not null check (score between 0 and 50),
  correct integer not null check (correct between 0 and 10),
  results text not null check (results ~ '^[okt]{10}$'),
  lang text not null check (lang in ('fr','en','es','de','it')),
  duration_s integer check (duration_s between 0 and 7200),
  created_at timestamptz not null default now(),
  unique (day, device_id),
  check (correct = char_length(results) - char_length(replace(results, 'o', '')))
);
alter table public.clikea_daily_scores enable row level security;
revoke all on public.clikea_daily_scores from anon, authenticated;
-- device_id n'est jamais lisible : il sert de preuve pour ajouter son nom après coup.
grant select (day, name, score, correct, results, created_at) on public.clikea_daily_scores to anon, authenticated;
grant insert (day, device_id, name, score, correct, results, lang, duration_s) on public.clikea_daily_scores to anon, authenticated;
create policy clikea_daily_read on public.clikea_daily_scores for select to anon, authenticated using (true);
create policy clikea_daily_insert on public.clikea_daily_scores for insert to anon, authenticated
  with check (day = (now() at time zone 'Europe/Paris')::date);

-- Ajout du nom après la partie, seulement par l'appareil qui a joué et une seule fois.
create function public.clikea_daily_set_name(p_day date, p_device text, p_name text)
returns boolean language sql security definer set search_path = public as $$
  with u as (
    update public.clikea_daily_scores set name = btrim(p_name)
    where day = p_day and device_id = p_device and name is null
      and char_length(btrim(p_name)) between 1 and 20
    returning 1
  ) select exists (select 1 from u);
$$;
revoke execute on function public.clikea_daily_set_name(date, text, text) from public;
grant execute on function public.clikea_daily_set_name(date, text, text) to anon, authenticated;

-- Chaque réponse, pour les statistiques par produit. Écriture seule pour le public.
create table public.clikea_answers (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  device_id text not null check (char_length(device_id) between 6 and 64),
  source text not null check (source in ('daily','replay','free')),
  day date,
  difficulty text check (difficulty in ('easy','hard')),
  position integer not null check (position between 1 and 20),
  product text not null check (char_length(product) between 1 and 40),
  mode text not null check (mode in ('duo','carre','cash')),
  correct boolean not null,
  timed_out boolean not null,
  ms integer check (ms between 0 and 600000),
  lang text not null check (lang in ('fr','en','es','de','it')),
  check ((source = 'free') = (day is null)),
  check ((source = 'free') = (difficulty is not null))
);
create index clikea_answers_product_idx on public.clikea_answers (product);
alter table public.clikea_answers enable row level security;
revoke all on public.clikea_answers from anon, authenticated;
grant insert (device_id, source, day, difficulty, position, product, mode, correct, timed_out, ms, lang) on public.clikea_answers to anon, authenticated;
create policy clikea_answers_insert on public.clikea_answers for insert to anon, authenticated with check (true);

-- Statistiques par produit (lecture réservée au tableau de bord Supabase).
create view public.clikea_product_stats with (security_invoker = true) as
select p.name, p.tier,
  count(a.id) as answers,
  round(100.0 * avg(a.correct::int), 1) as pct_correct,
  count(*) filter (where a.mode = 'duo') as duo,
  count(*) filter (where a.mode = 'carre') as carre,
  count(*) filter (where a.mode = 'cash') as cash,
  round(100.0 * avg(a.correct::int) filter (where a.mode = 'cash'), 1) as pct_cash,
  count(*) filter (where a.timed_out) as timeouts,
  (select count(*) from public.clikea_daily_grid g where p.name = any (g.products) and g.day <= (now() at time zone 'Europe/Paris')::date) as days_played
from public.clikea_products p
left join public.clikea_answers a on a.product = p.name
group by p.name, p.tier;
revoke all on public.clikea_product_stats from anon, authenticated;

-- Tirage : remplit les jours manquants jusqu'à J+p_ahead.
-- Un produit ne revient pas avant que son palier ait tourné (taille du palier / tirages par jour).
create function public.clikea_plan_days(p_ahead integer default 14)
returns integer language plpgsql security definer set search_path = public as $$
declare
  today date := (now() at time zone 'Europe/Paris')::date;
  d date; picks text[]; t record; n integer := 0; win integer;
begin
  for d in select g::date from generate_series(today, today + p_ahead, interval '1 day') g loop
    continue when exists (select 1 from public.clikea_daily_grid where day = d);
    picks := '{}';
    for t in select * from (values ('easy', 3, 1), ('medium', 4, 2), ('hard', 3, 3)) v(tier, k, ord) order by ord loop
      select greatest(0, count(*)::int / t.k - 1) into win from public.clikea_products where tier = t.tier and active;
      picks := picks || array(
        select p.name from public.clikea_products p
        where p.tier = t.tier and p.active
          and p.name <> all (coalesce((select array_agg(x) from public.clikea_daily_grid g, unnest(g.products) x
                                       where g.day < d and g.day >= d - win), '{}'))
        order by random() limit t.k);
    end loop;
    if cardinality(picks) <> 10 then raise exception 'tirage incomplet pour %', d; end if;
    insert into public.clikea_daily_grid (day, products) values (d, picks);
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.clikea_plan_days(integer) from public, anon, authenticated;

select public.clikea_plan_days(14);

create extension if not exists pg_cron;
select cron.schedule('clikea-plan-days', '5 22 * * *', $$select public.clikea_plan_days(14)$$);
