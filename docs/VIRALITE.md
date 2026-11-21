# Viralité : recherches et plan

Ce document rassemble ce qu'on sait de la circulation des petits jeux web, l'audit de CLIKEA, et un plan de lancement. Les faits sont sourcés ; les estimations sont signalées comme telles.

## 1. Ce que font les jeux qui ont décollé

### Wordle

Le cas de référence, et le plus documenté.

- **Le partage a été ajouté après le lancement** : le jeu est en ligne à la mi-octobre 2021, la copie du résultat en émojis arrive en décembre 2021. Le succès suit immédiatement : 90 joueurs le 1er novembre 2021, plus de deux millions quelques semaines plus tard. Source : [Wikipédia (fr), Wordle](https://fr.wikipedia.org/wiki/Wordle), qui cite TechCrunch et le Guardian.
- **Une seule grille par jour, identique pour tous.** C'est ce qui transforme un jeu solo en conversation : tout le monde parle de la même chose le même jour.
- **Les facteurs de succès listés** : simplicité, gratuité, absence de publicité, résultat partageable sur les réseaux, aucune application à installer, et le fait de ne pas être addictif puisqu'on ne joue qu'une fois par jour. Même source.
- **Le format de partage ne révèle pas la réponse** : une grille d'émojis carrés, sans les lettres. N'importe qui peut le lire sans être spoilé, et ceux qui n'ont pas joué comprennent qu'il se passe quelque chose.

### Métrodoku

Observé directement sur [metrodoku.fr](https://metrodoku.fr/) le 21 novembre 2026.

- **« Grille du jour »** unique, avec un score sur 900 et un compteur d'erreurs.
- Bouton **« Abandonner et voir les solutions »** : le jeu assume que la frustration doit avoir une sortie.
- Développé **par une seule personne**, avec un lien de soutien Ko-fi, un compte X [@metrodoku](https://x.com/metrodoku), un blog et des archives des grilles précédentes.
- Leçon : un jeu de niche (les stations de métro) peut vivre durablement avec un rendez-vous quotidien, des archives et une communauté, sans équipe.

### Le modèle commun

Les jeux de ce type qui durent partagent quatre briques :

1. **Un rendez-vous** : une grille par jour, la même pour tous.
2. **Un score comparable** : un nombre que l'on peut citer (« 4/6 », « 742/900 », « 52/100 »).
3. **Un partage sans spoiler** : on montre le résultat, pas la réponse.
4. **Zéro friction** : pas de compte, pas d'application, un chargement rapide.

CLIKEA a les briques 2, 3 (en image) et 4. **Il n'a pas la brique 1.** C'est le principal écart avec les jeux qui installent une habitude.

## 2. Les cinq leviers, appliqués à CLIKEA

### Levier 1 — Un objet partageable

Le ticket de fin existe déjà et il est bon : score, pourcentage de joueurs battus, tampon, code-barres. Deux corrections le rendent vraiment utile :

- **Une image attachée au lien.** Aujourd'hui l'image n'existe que si le joueur la partage depuis la feuille de partage. Un lien collé à la main n'a aucun aperçu.
- **Un texte qui donne envie de cliquer sans avoir joué.** Le texte actuel (« J'ai marqué 52/100… Saurez-vous faire mieux ? ») est correct ; il lui manque le score du destinataire à battre.

### Levier 2 — Le rendez-vous quotidien

C'est le levier le plus puissant et le plus coûteux. Il demande :

- un tirage déterministe à partir de la date (même grille pour tous, sans serveur) ;
- un stockage local de la partie du jour (une seule grille par jour et par appareil) ;
- un partage en émojis ou en cases, sans nom de produit, pour ne rien spoiler ;
- éventuellement un minuteur avant la grille suivante, comme Wordle.

Sans quotidien, CLIKEA reste un jeu qu'on essaie une fois ; avec, il devient un rendez-vous qu'on partage chaque matin.

### Levier 3 — Le défi nominatif

Le partage actuel envoie sur l'accueil. Le destinataire ne voit pas le score à battre, donc la boucle « je te bats » ne se ferme pas.

Correctif : encoder le score et le pseudo dans l'URL, afficher un bandeau d'accueil (« César a marqué 52/100. Tu fais mieux ? »), et proposer au destinataire de renvoyer son score. Chaque défi devient une nouvelle arête du graphe social.

### Levier 4 — Zéro friction

Déjà bon : pas de compte, pas d'installation, cinq langues, mobile d'abord. Deux points à surveiller :

- **Le poids** : environ 1,2 Mo de photos par partie, en plus du HTML. Sur un réseau mobile moyen, c'est une seconde ou deux de trop.
- **Le pseudo obligatoire** pour démarrer : il bloque l'entrée. Le rendre facultatif (et l'attribuer au moment du classement) supprime le seul champ à remplir.

### Levier 5 — Un lancement, pas une mise en ligne

Un jeu ne circule pas parce qu'il est en ligne, mais parce qu'un premier groupe en parle au même moment. Voir le plan au §4.

## 3. Audit produit : ce qui freine, vérifié dans le code

| Frein | Constat | Effet | Effort |
|---|---|---|---|
| **Pas de balises Open Graph ni Twitter Card** | Aucune balise `og:*` / `twitter:*` dans `index.html` | Un lien collé sur X, WhatsApp, Discord ou LinkedIn s'affiche en texte nu, sans image ni description | Faible |
| **Pas d'image d'aperçu** | Le ticket est généré côté client, jamais attaché à l'URL | Un post avec le lien seul n'a aucun visuel | Faible |
| **Aucun défi nominatif** | Le partage renvoie vers l'accueil | La boucle « je bats ton score » ne se ferme pas | Moyen |
| **Pas de mode quotidien** | Parties illimitées | Pas de rendez-vous, pas de conversation quotidienne | Moyen à élevé |
| **Pas de série mise en avant** | `bestStreak` reste interne au ticket | Pas d'objet de fierté récurrent | Faible |
| **Photos distantes non optimisées** | 20 photos du CDN ikea.com, 47 à 72 Ko chacune, sans `srcset` ; ~1,2 Mo par partie + 138 Ko de HTML | Premier écran lent sur mobile | Moyen |
| **Pseudo obligatoire** | Blocage si le champ est vide | Une étape de plus avant de jouer | Faible |
| **Pas de page par produit** | Une seule page ; `robots.txt` et `sitemap.xml` absents | Aucune prise sur les recherches « nom de produit ikea » | Moyen |
| **Classement forgeable** | Clé Supabase publiable, insertion libre | Crédibilité du classement | Moyen |
| **Aucun suivi de canal** | PostHog ne voit que `referrer` | Impossible de savoir quel canal amène des joueurs | Faible |

### Les cinq correctifs à faire avant tout lancement

1. **Balises Open Graph + image 1200 × 630** (ticket ou logo + « Devinez le nom. 10 secondes. »). Sans ça, chaque partage de lien perd son visuel.
2. **Défi nominatif** : `?defi=52&par=Cesar`, bandeau d'accueil, partage retour.
3. **`?utm_source=` ajouté automatiquement** aux liens partagés depuis le jeu.
4. **Pseudo facultatif** au démarrage (attribué au moment de l'envoi du score).
5. **Photos locales en WebP** avec dimensions déclarées.

Aucun de ces cinq points ne change les règles ; ils changent la façon dont le jeu circule.

## 4. Canaux de diffusion

### X (Twitter) — canal principal

- **Format** : image du ticket + une phrase courte, le lien en réponse ou en second temps. L'image fait le travail ; le lien seul est invisible.
- **Cadence** : un post par jour maximum au début, sur un compte neuf. Les rafales de liens sont le meilleur moyen de se faire classer comme spam.
- **Ce qui marche pour un jeu** : montrer une photo de meuble et demander le nom en reply (« Sans regarder : c'est quoi, ça ? »). La réponse des gens est le contenu.
- **Non vérifié ici** : l'idée répandue selon laquelle un lien dans le corps du post réduirait la portée. Aucune source officielle récente ne la confirme ; le lien en réponse est une précaution, pas une certitude.

### TikTok, Reels, Shorts

- **Format** : capture d'écran du jeu + réaction. Les deux premières secondes doivent poser la question (« Tu connais le nom de ce meuble IKEA ? »), pas montrer un logo.
- **Série** : un meuble par vidéo, avec le nom révélé à la fin. Le format se décline à l'infini avec 109 produits.
- **Sous-titres obligatoires** : la majorité des vues se fait sans son.
- **Lien** : en bio, pas dans le clip (les liens cliquables n'existent pas dans la vidéo).

### Reddit

- **Subreddits plausibles** : r/InternetIsBeautiful, r/WebGames, r/jeuxvideo, r/france, r/IKEA, r/sweden, r/Design.
- **Règle d'or** : lire les règles du subreddit avant de poster, et poster en participant, pas en publicitaire. Plusieurs de ces communautés interdisent l'autopromotion ou exigent un compte ancien.
- **Format qui passe** : « J'ai fait un jeu où il faut deviner les noms IKEA » + une capture, pas un lien nu.

### Hacker News / Product Hunt

- **Show HN** : un post unique, factuel, qui explique ce qui a été construit et comment, sans superlatif. Le public technique aime les pages uniques sans dépendance.
- **Product Hunt** : préparation d'une page, d'un visuel et d'un premier commentaire ; le jour compte moins que la mobilisation de quelques soutiens réels.
- **Attente réaliste** : ces canaux donnent un pic d'un jour, pas une croissance. Ils servent à amorcer, pas à durer.

### Presse et créateurs

- **Médias tech français** : Korben, Presse-citron, Numerama, Clubic, Frandroid. Pitch court : « un Wordle des noms IKEA, 109 produits, 5 langues, sans compte ».
- **Blogs déco et IKEA** : le sujet « les noms IKEA sont absurdes » est un marronnier ; le jeu est un prétexte à article.
- **Créateurs TikTok/YouTube** : un message personnalisé, pas un copier-coller.

### SEO — le canal durable

Les jeux de ce type vivent aussi sur les recherches « solution » et « liste ». Trois pages suffisent :

- « Tous les noms de produits IKEA (liste) » ;
- « Comment retenir les noms IKEA » ;
- une page par niveau ou par thème (cuisine, chambre, salon).

C'est moins spectaculaire qu'un post viral, mais ça compose dans le temps.

## 5. Plan de lancement sur 30 jours

**Semaine 0 — préparer (avant tout post)**
- Les cinq correctifs du §3.
- Une image d'aperçu 1200 × 630 et une bannière X.
- Trois captures prêtes : accueil, question, ticket.

**Semaine 1 — amorcer**
- Publier 5 posts sur X : un meuble par jour, la réponse en reply.
- Un post « J'ai fait un jeu » avec le ticket.
- Poster sur 2 subreddits choisis après lecture des règles.
- Un Show HN en anglais.

**Semaine 2 — tester les formats**
- 3 vidéos courtes (TikTok/Reels/Shorts), même contenu, trois accroches différentes.
- Comparer les taux de clic et de partie terminée par canal grâce aux `utm_source`.

**Semaine 3 — presse**
- Pitch à 5 médias tech français et 5 créateurs, personnalisé.
- Publier la page « Tous les noms de produits IKEA ».

**Semaine 4 — décider**
- Lire les chiffres : quel canal amène des joueurs qui terminent une partie et qui partagent.
- Décider du mode quotidien : c'est l'investissement qui change l'échelle, à faire seulement si le taux de partie terminée est bon.

## 6. Mesurer

Indicateurs à suivre dans PostHog, par canal (`utm_source`) :

| Indicateur | Calcul | Ce qu'il dit |
|---|---|---|
| Taux de démarrage | `clikea_game_started` / `clikea_view` | La promesse de l'accueil convainc |
| Taux de fin | `clikea_game_finished` / `clikea_game_started` | Le jeu tient jusqu'au bout |
| Taux de partage | `clikea_share` / `clikea_game_finished` | Le ticket donne envie |
| Part des visiteurs venus d'un partage | vues avec `utm_source=share` / vues totales | La boucle tourne |
| Coefficient viral (K) | partages × visiteurs par partage / joueurs | K > 1 : croissance organique |

Aucun objectif chiffré n'est fixé à ce jour : la première étape est une base de référence propre.

## 7. Risques

- **Marque IKEA** : pastiche d'une marque déposée. Un jeu gratuit et non officiel limite le risque, ne l'annule pas. Une demande de retrait reste possible ; prévoir de pouvoir retirer les photos et le nom immédiatement.
- **Dépendance au CDN IKEA** : une URL changée casse une image. Des copies locales règlent le problème et allègent le jeu.
- **Classement trompé** : si le jeu grossit, un classement faux devient un sujet public.
- **Mode quotidien** : il crée une attente. Une grille manquée un jour est visible.

## 8. Sources

- [Wikipédia (fr), Wordle](https://fr.wikipedia.org/wiki/Wordle) — chiffres de lancement, dates, facteurs de succès.
- [TechCrunch, interview de Josh Wardle](https://techcrunch.com/2022/01/12/josh-wardle-interview-wordle/) — cité par Wikipédia.
- [The Guardian, « What is Wordle? »](https://www.theguardian.com/games/2021/dec/23/what-is-wordle-the-new-viral-word-game-delighting-the-internet) — ajout du partage.
- [metrodoku.fr](https://metrodoku.fr/) — grille du jour, score sur 900, modèle solo, observé le 21 novembre 2026.
- [sutom.nocle.fr](https://sutom.nocle.fr/) — jeu quotidien francophone.
- Audit CLIKEA : lecture de `index.html` et mesures sur `clikeagame.com` le 21 novembre 2026.

### Ce qui n'a pas pu être vérifié

- Les chiffres de conversion par canal (aucune donnée publique fiable trouvée).
- L'effet réel d'un lien dans un post X sur la portée, en 2026.
- Les règles à jour de chaque subreddit (à relire avant chaque post).
- Les statistiques de fréquentation de Métrodoku et SUTOM (non publiques).
