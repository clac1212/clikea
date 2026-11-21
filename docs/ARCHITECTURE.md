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
  i: "https://www.ikea.com/fr/fr/images/products/....jpg" }
```

- `n` : nom IKEA, unique. Sert d'identifiant et de réponse.
- `t` : type de meuble par langue. Le code tolère une chaîne simple (`typeOf`).
- `p` : prix indicatif en euros, catalogue français.
- `i` : URL de la photo, non copiée localement.

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

## Persistance locale (`localStorage`)

| Clé | Usage |
|---|---|
| `clikea-lang` | Langue choisie (sinon langue du navigateur, sinon `fr`). |
| `clikea-did` | Identifiant d'appareil aléatoire pour PostHog (`distinct_id`), pas d'identification personnelle. |
| `clikea-best:<pseudo normalisé>` | Record personnel affiché sur le ticket. |

Tous les accès sont dans des `try/catch` : la navigation privée iOS peut lever une exception.

## Internationalisation

`I18N` contient cinq paquets (`fr`, `en`, `es`, `de`, `it`) avec les mêmes clés. `t(key, vars)` lit la clé dans la langue courante, retombe sur le français, et remplace les `{placeholders}`. `applyLang` met à jour les textes du DOM, la description meta et le `<select id="lang">`. Le contenu produit (types) est localisé dans `PRODUCTS`.

Le français est la langue de référence : une clé manquante dans une autre langue s'affiche en français plutôt que de casser l'écran.

## Classement Supabase

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
| `clikea_share_sheet` | `lang` |
| `clikea_share` | `mode` (`native`, `download`, `copy`, `x`, `whatsapp`, `linkedin`) |
| `clikea_lang_changed` | `lang` |
| `clikea_difficulty_selected` | `difficulty` |

`track()` est neutralisé quand `?selftest=1` est présent, pour ne pas polluer les données de production.

## Ticket et partage

- L'écran de fin est du HTML/CSS : bandeau bleu avec logo monochrome, tampon incliné, score, pourcentage de joueurs battus, bande jaune de statistiques, code-barres.
- L'image partagée est dessinée à part sur un `<canvas>` de **1080 × 1350** (`drawTrophy`), dans le même langage visuel, avec le logo dessiné en tracés (`drawLogo`).
- Partage : `navigator.share` avec fichier si disponible (iOS/Android), sinon téléchargement du PNG, sinon copie du texte. Boutons X, WhatsApp, LinkedIn ouvrent des intentions web ; Instagram ouvre la feuille de partage native.
- Le texte de partage est localisé et contient le score, le nombre de noms trouvés et l'URL courante.

## Hébergement

- **GitHub Pages**, dépôt `clac1212/clikea`, branche `main`, racine.
- **Domaine** : `clikeagame.com` (fichier `CNAME`), HTTPS forcé, certificat GitHub. `www.clikeagame.com` pointe dessus.
- **DNS** : OVH — quatre `A` GitHub Pages sur la racine, `CNAME` `www` vers `clac1212.github.io`.
- **Redirection** : `clac1212.github.io/clikea/` renvoie un 301 vers le domaine.
- **Miroir** : `https://clever-bloom-q2pw.here.now/`, republication manuelle depuis le dossier `clikea/`.
- **Pièges déjà rencontrés** : un `CNAME` pointant vers un domaine non validé fait rediriger GitHub Pages vers un domaine fantôme (page d'attente de l'hébergeur, JSON en 404). Toujours contrôler `CNAME` et le code HTTP des deux URL après un changement de domaine.

## Contrôles (`?selftest=1`)

La suite s'exécute dans la page publiée, sans outil externe. Elle vérifie notamment : intégrité de la base (≥ 100 produits, noms et images uniques, champs complets, types localisés), barème (100 points), taille de partie (20), présence des écrans, déroulement d'une partie simulée, ticket à 0 point, partage, contraintes Supabase. Elle affiche `SELFTEST PASS n/n`. Relevé du 21 novembre 2026 : **402/402** sur `clikeagame.com` et sur le miroir.

`?demo=1` affiche directement l'écran de fin avec un score fixe (52/100) pour régler le ticket.

## Contraintes de style à respecter

- Pas de dépendance externe, pas de build : toute modification reste dans `index.html`.
- Une seule source de vérité pour les produits et les libellés ; ne pas recopier une liste dans le HTML et dans le JS.
- Toute nouvelle chaîne visible doit exister dans les cinq langues.
- Le parcours doit rester sans défilement à 390 px de large.
