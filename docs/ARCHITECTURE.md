# Architecture

CLIKEA est une **page unique** : `index.html` contient le balisage, les styles, le code du jeu, les 109 produits, les traductions et le générateur de ticket. Il n'y a ni framework, ni étape de build, ni dépendance à installer. Deux fichiers JSON à la racine sont des archives de données, pas des ressources chargées.

## Vue d'ensemble

```
Navigateur
  └── index.html (GitHub Pages / clikeagame.com)
        ├── état de partie en mémoire (state)
        ├── localStorage : langue, identifiant d'appareil, record personnel
        ├── POST  eu.i.posthog.com/capture      → analytics
        └── REST  Supabase clikea_scores        → classement (lecture + insertion)
```

Aucun serveur applicatif : GitHub Pages sert un fichier statique, Supabase et PostHog sont appelés directement depuis le navigateur avec des clés publiques.

## Structure du fichier

| Zone | Contenu |
|---|---|
| `<head>` | Titre, description, favicon SVG en `data:` (logo CLIKEA), variables CSS. |
| CSS | Thème bleu IKEA / jaune, quatre écrans, ticket, feuille de partage, media queries. |
| Écrans | `#intro`, `#game`, `#end`, `#board`, plus `#shareSheet` en surcouche. Un seul est visible (`show(id)`). |
| Données | `PRODUCTS` (109 objets), `DECOR` (5 produits décoratifs de l'accueil), `EASY_NAMES` (49 noms cultes), `FACTS` (faits vérifiés), `I18N` (5 langues). |
| Moteur | `startGame`, `chooseMode`, `resolve`, `next`, `endGame`. |
| Classement | `submitScore`, `loadRank`, `loadBoard`, `renderBoard`. |
| Ticket | `printTicket` (DOM), `drawTrophy` (canvas 1080 × 1350), `shareTrophy`, `shareTo`. |
| Logo | `LOGO` (tracés SVG des lettres), `drawLogo` (rendu canvas du ticket). |
| Contrôles | Bloc `?selftest=1` en fin de fichier. |

## Modèle de données produit

```js
{ n: "BILLY", t: { fr: "Bibliothèque", en: "Bookcase", es: "Librería", de: "Bücherregal", it: "Libreria" },
  p: 59.99,
  i: "img/billy.webp" }
```

- `n` : nom IKEA, unique. Sert d'identifiant et de réponse.
- `t` : type de meuble par langue. Le code tolère une chaîne simple (`typeOf`).
- `p` : prix indicatif en euros, catalogue français.
- `i` : chemin local de la photo WebP 640 × 640, dans `img/`. Les URL d'origine restent dans `produits.json`.

## Déroulement d'une partie

1. **Accueil** : choix du niveau (`easy` par défaut / `hard`), pseudo (obligatoire pour démarrer, 20 caractères max), bouton « Jouer ». Le classement du niveau est chargé en arrière-plan.
2. **Tirage** : `poolIndexes(difficulty)` construit le vivier — les 49 noms de `EASY_NAMES` en facile, tous les autres en difficile — puis `shuffle(...).slice(0, 20)`. Les deux viviers sont disjoints et couvrent les 109 produits.
3. **Question** : photo du produit, « Quel est ce meuble ? », choix du mode.
   - **Duo** : 2 propositions, dont la bonne ; les leurres sont tirés parmi les 108 autres produits.
   - **Carré** : 4 propositions.
   - **Cash** : champ texte, pas de chrono.
   - Duo et Carré lancent un compte à rebours de 10 s (`QUESTION_MS`), à 100 ms de granularité. À zéro : question perdue, `resolve(false, null)`.
4. **Résolution** : verrouillage (`state.locked`), calcul des points (`MODES[mode].pts`), mise à jour de la série, photo entourée en vert ou rouge, fiche produit, événement `clikea_question_answered`.
5. **Cash — comparaison tolérante** (`matchName`) : normalisation (minuscules, accents et ponctuation retirés), égalité stricte, ou distance de Levenshtein ≤ 1 pour les noms de 6 caractères et plus, ou égalité avec le premier mot du nom s'il fait au moins 4 caractères (« GOSIG » accepté pour « GOSIG GOLDEN »).
6. **Fin** : après la 20e réponse, écran de fin, calcul du pourcentage de joueurs battus (position dans le classement), tampon et message selon le score, animation du ticket, événement `clikea_game_finished`, puis `submitScore()`.

## Barème et états

- `GAME_SIZE = 20`, `MAX_PTS = 20 × 5 = 100`.
- Points : Duo 1, Carré 3, Cash 5. Le mode est choisi **par question**, pas pour la partie entière.
- Un score de 0 n'est pas envoyé (`submitScore` sort tôt).
- `state.submitted` empêche un double envoi ; `state.rank` vient du comptage des scores supérieurs.
- `state.results` garde un marqueur par question (`ok`, `ko`, `to` pour temps écoulé) : il alimente la grille du partage texte.
- Si le pseudo est vide, la partie se lance quand même ; le score n'est pas envoyé et un champ apparaît à la fin pour l'ajouter (`submitEndName`).

## Persistance locale (`localStorage`)

| Clé | Usage |
|---|---|
| `clikea-lang` | Langue choisie (sinon langue du navigateur, sinon `fr`). |
| `clikea-did` | Identifiant d'appareil aléatoire pour PostHog (`distinct_id`), pas d'identification personnelle. |
| `clikea-best:<pseudo normalisé>` | Record personnel affiché sur le ticket (partie libre). |
| `clikea-daily` | 10 du jour, par date de Paris : progression (`i`, `pts`, `results`, `pending`), `done`, `secs`, `player`, `sent`. Sert à reprendre une partie, bloquer le rejeu, calculer la série. Sous `?selftest`, la clé devient `clikea-daily-selftest`. |

Tous les accès sont dans des `try/catch` : la navigation privée iOS peut lever une exception.

## Internationalisation

`I18N` contient cinq paquets (`fr`, `en`, `es`, `de`, `it`) avec les mêmes clés. `t(key, vars)` lit la clé dans la langue courante, retombe sur le français, et remplace les `{placeholders}`. `applyLang` met à jour les textes du DOM, la description meta et le `<select id="lang">`. Le contenu produit (types) est localisé dans `PRODUCTS`.

Le français est la langue de référence : une clé manquante dans une autre langue s'affiche en français plutôt que de casser l'écran.

## Le 10 du jour

- **Porte principale** de l'accueil (`#dailyBtn`). La partie libre est repliée sous `#freeToggle`.
- **Jour** : date de Paris (`parisDay()`), changement à minuit heure de Paris. Numéro de grille `#N` = jours depuis `DAILY_EPOCH` (`2026-11-22` = #1).
- **Grille** : lue dans `clikea_daily_grid` pour le jour (`fetchGrid`). 10 produits, toujours dans l'ordre 3 faciles, 4 moyens, 3 durs. Chaque produit se joue en Duo, Carré ou Cash, barème identique à la partie libre : **score sur 50** (`DAILY_MAX`).
- **Une partie par appareil et par jour.** La progression est sauvegardée après chaque réponse. Un produit affiché puis abandonné (page fermée) compte en temps écoulé à la reprise : recharger la page ne permet pas de revoir un produit.
- **Série** : jours joués d'affilée (`dayStreak`), calculée sur l'appareil. Elle ne casse pas tant que le jour n'est pas fini.
- **Score** : envoyé dans `clikea_daily_scores` à la fin, avec ou sans nom. Le nom ajouté après coup passe par la fonction `clikea_daily_set_name` (une seule fois, par l'appareil qui a joué).
- **Défi** : le lien partagé porte `jour=AAAA-MM-JJ&defi=<score>&par=<nom>`. Le même jour, l'ami joue la même grille et compte pour sa série. Un autre jour, il rejoue la grille passée en mode `replay` : hors classement, hors série.
- **Partage texte** : `CLIKEA du jour #N · 34/50`, deux lignes de cinq cases, `🔥 N jours d'affilée`, lien.

## Base Supabase

Projet `vubopkycvzzqufpqxpbg`. Schéma versionné dans `supabase/migrations/`, annulation dans `supabase/rollback_20261122_daily.sql`.

| Objet | Public (clé publiable) | Rôle |
|---|---|---|
| `clikea_scores` | lecture, insertion | classement de la partie libre |
| `clikea_products` | aucun accès | catalogue miroir de `PRODUCTS`, avec le palier du tirage (`easy` = 20 premiers noms cultes, `medium` = 29 autres cultes, `hard` = 60 autres) et `active` |
| `clikea_daily_grid` | lecture jusqu'à aujourd'hui | une ligne par jour, 10 noms ; `source = 'manual'` pour une grille choisie à la main |
| `clikea_daily_scores` | lecture sans `device_id`, insertion le jour même | une ligne par appareil et par jour (`unique(day, device_id)`), `results` = une lettre par produit (`o`, `k`, `t`) |
| `clikea_answers` | insertion seule | chaque réponse (partie libre, du jour, rejouée) : produit, mode, juste, temps écoulé, durée |
| `clikea_product_stats` | aucun accès | vue : réponses, % de bonnes réponses, % en Cash, temps écoulés, jours tirés, par produit |

- **Tirage automatique** : `clikea_plan_days(14)` remplit les jours manquants jusqu'à J+14. Tâche `pg_cron` `clikea-plan-days` chaque soir à 22 h 05 UTC. Un produit ne revient pas avant que son palier ait tourné (taille du palier ÷ tirages par jour).
- **Choisir une grille à la main** : `update clikea_daily_grid set products = array[...10 noms...], source = 'manual' where day = '2026-12-24';` (3 faciles, 4 moyens, 3 durs, noms exacts de `PRODUCTS`).
- **Ajouter un produit au jeu** : l'ajouter à `PRODUCTS` **et** à `clikea_products`, sinon le tirage ne le connaît pas ; un nom présent en base mais absent de `PRODUCTS` fait échouer `fetchGrid` (message « grille indisponible »).
- **Statistiques** : `select * from clikea_product_stats order by pct_correct;` dans l'éditeur SQL Supabase.

## Classement Supabase (partie libre)

- Projet : `vubopkycvzzqufpqxpbg` (Supabase).
- Table : `public.clikea_scores`.

| Colonne | Type | Rôle |
|---|---|---|
| `id` | uuid | clé primaire, générée par la base |
| `name` | text | pseudo du joueur, tronqué à 20 caractères côté client |
| `score` | int | points sur 100 |
| `correct` | int | nombre de bonnes réponses |
| `total` | int | nombre de questions (20) |
| `difficulty` | text | `easy` ou `hard` |
| `lang` | text | langue de la partie |
| `duration_s` | int | durée de la partie, plafonnée à 7200 s |
| `created_at` | timestamptz | date d'insertion |

- **Clé utilisée** : clé publiable (`sb_publishable_...`) présente dans `index.html`. Elle ne permet que lecture et insertion ; les tests ont montré qu'une suppression renvoie 401.
- **Lecture du classement** : `select=name,score,correct,difficulty,created_at&difficulty=eq.<niveau>&order=score.desc,created_at.asc&limit=20`.
- **Position du joueur** : requête `count=exact` sur `score=gt.<score>` pour le niveau, lue dans l'en-tête `Content-Range`.
- **Droits** : `TRUNCATE`, `TRIGGER` et `REFERENCES` ont été retirés au public le 22/11/2026 (ils contournent la RLS).
- **Limites connues** : pas de modération du pseudo, pas d'anti-triche — n'importe qui peut insérer un score avec cette clé. Acceptable pour un jeu gratuit, à traiter si le classement devient un argument public.

## Analytics PostHog

- Hôte : `https://eu.i.posthog.com` (UE).
- Aucun SDK : `track()` envoie un POST JSON sur `/capture/` via `navigator.sendBeacon` (repli `fetch` avec `keepalive`).
- Propriétés communes : `distinct_id`, `$current_url`, `lang`, `difficulty`, `app: 'clikea'`.
- Événements émis :

| Événement | Propriétés |
|---|---|
| `clikea_view` | `lang`, `referrer` |
| `clikea_game_started` | `difficulty`, `pool`, `lang` |
| `clikea_question_answered` | `product`, `mode`, `correct`, `gain`, `question`, `difficulty` |
| `clikea_game_finished` | `score`, `correct`, `total`, `difficulty`, `duration_s`, `best_streak`, `lang` |
| `clikea_score_submitted` | `ok`, `score`, `difficulty` |
| `clikea_name_added` | `score`, `difficulty` |
| `clikea_defi_view` | `score`, `has_name` |
| `clikea_share_sheet` | `lang` |
| `clikea_share` | `mode` (`native`, `download`, `copy`, `copy_text`, `x`, `whatsapp`, `linkedin`) |
| `clikea_lang_changed` | `lang` |
| `clikea_difficulty_selected` | `difficulty` |
| `clikea_daily_submitted` | `ok`, `score` |
| `clikea_daily_grid_error` | `day`, `error` |
| `clikea_free_opened` | — |

Tous les événements portent aussi `kind` (`daily`, `replay`, `free`) et `day`.

`track()` est neutralisé quand `?selftest=1` est présent, pour ne pas polluer les données de production.

## Ticket et partage

- L'écran de fin est du HTML/CSS : bandeau bleu avec logo monochrome, tampon incliné, score, pourcentage de joueurs battus, bande jaune de statistiques, code-barres.
- L'image partagée est dessinée à part sur un `<canvas>` de **1080 × 1350** (`drawTrophy`), dans le même langage visuel, avec le logo dessiné en tracés (`drawLogo`).
- **Résultat texte** (`shareGrid`, `resultText`) : une ligne `CLIKEA 52/100 · 13/20 noms · série 6`, puis quatre lignes de cinq cases (🟩 juste, 🟥 raté, 🟨 temps écoulé), puis le lien. Aucun nom de produit : le partage ne spoile pas.
- **Défi** : `shareUrl(source)` construit un lien avec `utm_source`, et si le score est supérieur à 0, `defi` et `par`. L'accueil lit ces paramètres (`readChallenge`) et affiche un bandeau jaune ; le pseudo est échappé.
- Partage : `navigator.share` avec fichier si disponible (iOS/Android), sinon téléchargement du PNG, sinon copie du texte. X, WhatsApp et LinkedIn sont de **vrais liens** (`<a target="_blank" rel="noopener">`, href recalculé après la partie) et non des `window.open`, pour éviter les bloqueurs de fenêtres et laisser le système ouvrir l'application installée. Instagram et Copier restent des boutons : Instagram n'a pas d'API web de publication, il passe par la feuille de partage du téléphone. Une note sous les cibles explique ce fonctionnement, et un message s'affiche après 1,6 s si rien ne s'est ouvert sur mobile.
- Le texte de partage est localisé et contient le score, le nombre de noms trouvés, la grille et le lien.

## Aperçu de lien

Balises statiques dans `<head>` : `og:title`, `og:description`, `og:image` (`https://clikeagame.com/og.png`, 1200 × 630), `og:url`, `og:locale` et ses variantes, `twitter:card` en `summary_large_image`. L'aperçu ne dépend pas du score : c'est une image unique, générique.

`robots.txt` et `sitemap.xml` déclarent le domaine.

## Hébergement

- **GitHub Pages**, dépôt `clac1212/clikea`, branche `main`, racine.
- **Domaine** : `clikeagame.com` (fichier `CNAME`), HTTPS forcé, certificat GitHub. `www.clikeagame.com` pointe dessus.
- **DNS** : OVH — quatre `A` GitHub Pages sur la racine, `CNAME` `www` vers `clac1212.github.io`.
- **Redirection** : `clac1212.github.io/clikea/` renvoie un 301 vers le domaine.
- **Miroir** : `https://clever-bloom-q2pw.here.now/`, republication manuelle depuis le dossier `clikea/`.
- **Pièges déjà rencontrés** : un `CNAME` pointant vers un domaine non validé fait rediriger GitHub Pages vers un domaine fantôme (page d'attente de l'hébergeur, JSON en 404). Toujours contrôler `CNAME` et le code HTTP des deux URL après un changement de domaine.

## Contrôles (`?selftest=1`)

La suite s'exécute dans la page publiée, sans outil externe. Elle vérifie notamment : intégrité de la base (≥ 100 produits, noms et images uniques, champs complets, types localisés), présence des balises Open Graph, photos locales, bouton de copie, déroulement d'une partie simulée, grille de partage, lien de défi avec `utm_source`, ticket à 0 point, partage, contraintes Supabase. Elle affiche `SELFTEST PASS n/n`. Relevé du 21 novembre 2026 : **416/416** sur `clikeagame.com` et sur le miroir. Depuis le 22 novembre, **420/420** (ajout des contrôles sur les liens de partage).

`?demo=1` affiche directement l'écran de fin avec un score fixe (52/100) pour régler le ticket.

## Contraintes de style à respecter

- Pas de dépendance externe, pas de build : toute modification reste dans `index.html`.
- Une seule source de vérité pour les produits et les libellés ; ne pas recopier une liste dans le HTML et dans le JS.
- Toute nouvelle chaîne visible doit exister dans les cinq langues.
- Le parcours doit rester sans défilement à 390 px de large.
