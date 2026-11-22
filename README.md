# CLIKEA

**Le jeu des noms IKEA.** Une photo de meuble, vingt produits tirés au sort, un nom à retrouver. Gratuit, sans compte, en cinq langues.

- **Jouer** : https://clikeagame.com
- **Miroir** : https://clever-bloom-q2pw.here.now/
- **Code** : https://github.com/clac1212/clikea (branche `main`)

## Pourquoi ce jeu

Les jeux qui circulent le mieux sont ceux qu'on comprend en deux secondes et qu'on peut montrer en une image. Les noms IKEA sont un savoir absurde que presque tout le monde possède sans le savoir : on a tous monté un BILLY. CLIKEA transforme ce réflexe en partie de trois minutes, puis en ticket de score partageable.

L'objectif n'est pas de vendre quelque chose : c'est de faire revenir les joueurs et de les faire inviter leurs proches, sans budget publicitaire. Le détail (public, métriques, principes, non-objectifs, décisions) est dans [`docs/POURQUOI.md`](docs/POURQUOI.md).

## Règles

- **20 produits** tirés au sort dans le vivier du niveau choisi.
- **Deux niveaux** : *facile* (49 produits cultes) et *difficile* (les 60 autres). Mêmes trois modes dans les deux.
- **Pseudo facultatif** : on peut jouer sans nom. Sans nom, le score n'est pas envoyé au classement et un champ apparaît à la fin pour l'ajouter.
- **Trois modes**, choisis à chaque question :
  - **Duo** — 2 noms proposés, **1 pt** ;
  - **Carré** — 4 noms proposés, **3 pts** ;
  - **Cash** — saisie libre, aucune proposition, **5 pts**.
- **Chrono de 10 s** en Duo et Carré. En Cash, pas de chrono : on tape le nom. Temps écoulé = question perdue.
- **Score maximum : 100**. Le score n'est envoyé au classement que s'il est supérieur à 0.
- **Classement public** : les 20 meilleurs scores par niveau, une ligne par partie.
- **Ticket de fin** : tampon (Top 10 %, Top 50 %, À rejouer, Sans faute), pourcentage de joueurs battus, produits reconnus, meilleure série, points, code-barres.
- **Deux façons de partager** :
  - **résultat texte copiable** — `CLIKEA 52/100 · 13/20 noms · série 6` suivi d'une grille de cases vert/rouge, sans aucun nom de produit, donc sans spoiler ;
  - **image PNG du ticket** en 1080 × 1350, via le partage natif du téléphone, sinon téléchargement.
- **Défi nominatif** : un lien partagé contient le score (`?defi=52&par=Cesar`) ; l'accueil affiche « Cesar a marqué 52/100. Tu fais mieux ? ».
- **Traçabilité** : chaque lien partagé porte un `utm_source` (x, whatsapp, linkedin, copy, native).

## Ce que contient le dépôt

| Fichier | Rôle |
|---|---|
| `index.html` | Tout le jeu : HTML, CSS, JavaScript, données produits, logo SVG, génération du ticket, traductions. Aucun build, aucune dépendance. |
| `img/` | Les 109 photos produit en WebP, 640 × 640, servies localement (~1,5 Mo au total, 4 à 37 Ko par photo). |
| `og.png` | Image d'aperçu 1200 × 630 pour les partages de lien (Open Graph, Twitter Card). |
| `produits.json` | Source de la base produits (109 entrées : nom, type localisé, prix, URL photo d'origine). **Non chargée au runtime** — les données sont embarquées dans `index.html`. Sert d'archive éditable. |
| `types.json` | Archive des libellés de types par langue. Non chargée au runtime. |
| `CNAME` | Domaine personnalisé GitHub Pages : `clikeagame.com`. |
| `robots.txt`, `sitemap.xml` | Indexation du domaine. |
| `docs/` | Pourquoi, architecture, viralité. |

## Développement

```bash
cd clikea
python3 -m http.server 8000
# http://localhost:8000
```

Deux paramètres d'URL utiles :

- `?selftest=1` — suite de contrôles (base produits, tirage, barème, ticket, partage, base de scores). Affiche `SELFTEST PASS n/n`.
- `?demo=1` — ouvre directement l'écran de fin avec un score de démonstration (52/100) pour régler le ticket sans jouer.

Il n'y a ni `npm install`, ni bundler, ni test runner : la page est le produit.

## Publication

1. **GitHub Pages** : `git push origin main`. Le déploiement est automatique (Pages, branche `main`, racine). Le domaine `clikeagame.com` est déclaré dans `CNAME`, HTTPS forcé activé, certificat émis par GitHub.
2. **DNS (OVH)** : quatre enregistrements `A` sur la racine vers `185.199.108.153`, `.109.153`, `.110.153`, `.111.153`, et un `CNAME` `www` vers `clac1212.github.io`.
3. **Miroir here.now** : republié depuis le même dossier `clikea/` avec l'API here.now :

```bash
python3 scripts/publish-mirror.py            # slug clever-bloom-q2pw
```

Le script lit la clé dans `~/.herenow/credentials`, envoie `index.html`, `og.png`, `robots.txt`, `sitemap.xml` et `img/`, puis finalise la version. Sans clé, here.now créerait un site anonyme qui expire en 24 h : le script refuse ce cas.

Contrôle après publication :

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://clikeagame.com/
curl -s https://clikeagame.com/ | grep -o '<title>[^<]*</title>'
curl -s -o /dev/null -w '%{http_code}\n' https://clever-bloom-q2pw.here.now/
```

## Données et mesure

- **Classement** : Supabase, projet `vubopkycvzzqufpqxpbg`, table `public.clikea_scores`. La clé publiable est dans `index.html` — c'est normal, elle ne permet que lecture et insertion ; la suppression est refusée.
- **Analytics** : PostHog EU (`https://eu.i.posthog.com`), projet « CLIKEA ». Événements : `clikea_view`, `clikea_defi_view`, `clikea_game_started`, `clikea_question_answered`, `clikea_game_finished`, `clikea_score_submitted`, `clikea_name_added`, `clikea_share_sheet`, `clikea_share`, `clikea_lang_changed`, `clikea_difficulty_selected`.
- Détail des schémas, permissions et flux : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Notes et limites

- **Pastiche non officiel**, sans lien avec IKEA. Le logo reprend la logique du logo IKEA (cartouche bleu, ellipse jaune, mot en tracés) sans fichier de police ni asset IKEA.
- **Photos** : copies locales en WebP dans `img/`, redimensionnées à 640 × 640, à partir du CDN `ikea.com`. Le fichier `produits.json` garde les URL d'origine.
- **Prix** : catalogue français au moment de la constitution de la base, indicatifs.
- **Pas de compte, pas de modération du pseudo** : le classement accepte tout nom de 24 caractères, et un score peut être forgé (la clé publique autorise l'insertion).
- **Aperçu de lien** : balises Open Graph et Twitter Card avec `og.png` ; l'aperçu ne montre pas le score du joueur, seulement l'image générique du jeu.
- **Défi** : le score et le pseudo passent par l'URL ; le pseudo est échappé avant affichage.
- Les données embarquées dans `index.html` et les fichiers `produits.json` / `types.json` peuvent diverger : la source de vérité à l'exécution est `index.html`.

## Documentation

- [`docs/POURQUOI.md`](docs/POURQUOI.md) — problème, public, objectif, métriques, principes, non-objectifs, journal des décisions.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — structure du code, flux de jeu, données, Supabase, PostHog, hébergement, contrôles.
- [`docs/VIRALITE.md`](docs/VIRALITE.md) — recherches sur la viralité des jeux web et état du produit.
- [`docs/MODES.md`](docs/MODES.md) — modes de jeu (10 du jour, duel, chrono, virée), récurrence, ordre de construction.
- [`docs/LANCEMENT.md`](docs/LANCEMENT.md) — comptes sociaux, bios, piliers de contenu, calendrier 30 jours.
