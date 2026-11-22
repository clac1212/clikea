# Viralité : recherches et plan

Ce document rassemble ce qu'on sait de la circulation des petits jeux web, l'audit de CLIKEA, et un plan de lancement. Les faits sont sourcés ; les hypothèses et estimations sont signalées comme telles.

## Le projet viralité en trois volets

- **Ce document** : les preuves (cas comparables, canaux, risques) et l'état du produit.
- [`MODES.md`](MODES.md) : les modes de jeu (10 du jour, duel, chrono, virée), la récurrence et l'ordre de construction.
- [`LANCEMENT.md`](LANCEMENT.md) : les comptes sociaux, les bios, les piliers de contenu et le calendrier sur 30 jours.

**Recommandation d'ordre** : le 10 du jour d'abord (récurrence), le bouton « Défier » juste après (acquisition 1 → 1), puis **on s'arrête et on lit les chiffres**. Le chrono et la virée restent en réserve : ils n'entrent que si le quotidien tient. Les comptes se préparent en parallèle, mais ne se lancent pas tous en même temps.

## 1. Ce que font les jeux qui ont décollé

### Wordle

- **La courbe** : 90 joueurs le 1er novembre 2021, plus de 300 000 le 2 janvier 2022, plus de 2 millions une semaine plus tard. **1,2 million de résultats partagés sur Twitter entre le 1er et le 13 janvier 2022.** 4,8 milliards de parties en 2023. Source : [Wikipédia (en), Wordle](https://en.wikipedia.org/wiki/Wordle).
- **Le déclencheur documenté n'est pas le jeu, c'est le partage.** Des amis néo-zélandais bricolent un affichage en carrés colorés ; Wardle l'intègre fin décembre 2021, et le jeu décolle sur Twitter.
- **Une seule grille par jour, identique pour tous.** Wardle l'explique par la rareté : « ça donne envie d'y revenir », et la session tient en trois minutes. Aucun test public ne chiffre l'effet.
- **Le format gagnant est du texte, pas une image** : une ligne « Wordle 196 4/6 » et une grille d'émojis, copiable partout, sans lien, sans spoiler.
- **Même Wordle : plus de 60 % des joueurs ne partageaient jamais leur score** ([Flourish](https://flourish.studio/blog/the-rise-of-wordle/)). Le partage est un comportement minoritaire, mais suffisant.

### Métrodoku

Le cas français le plus proche de CLIKEA.

- Première grille le **2 avril 2026**, développée en une semaine sur des données RATP ouvertes.
- **1 000 joueurs après une semaine, près de 30 000 joueurs quotidiens un mois plus tard**, 2 600 abonnés sur X. Le créateur : « **C'est vraiment X qui a fait accélérer tout ça.** » Source : [Le Parisien, 30 avril 2026](https://www.leparisien.fr/paris-75/metrodoku-le-jeu-qui-rend-fou-pres-de-30-000-habitues-du-metro-parisien-chaque-jour-30-04-2026-JFW5WBE23NAUXOEZBJLVOQE5AE.php).
- Mécanique : une grille du jour, un score sur 900 pondéré par la rareté des réponses, un compteur d'erreurs, des archives, un bouton « abandonner et voir les solutions ».

### Les autres

- **SUTOM** : publié le 8 janvier 2022, codé en direct sur Twitch, code source libre, gratuit, **sans inscription** ([Wikipédia fr](https://fr.wikipedia.org/wiki/Sutom)).
- **Cémantix** : en ligne le 2 mars 2022, **sans inscription**, avec un classement de fin de partie ([Wikipédia fr](https://fr.wikipedia.org/wiki/C%C3%A9mantix)).
- **GeoGuessr** : lancé en 2013, diffusé d'abord par **un post Reddit puis Google Chrome Experiments**, 40 millions de comptes en juillet 2022 ([Wikipédia en](https://en.wikipedia.org/wiki/GeoGuessr)).
- Timeguessr, Framed, Tradle, Logoquiz : mécaniques publiques, **aucun chiffre d'audience vérifiable trouvé**.

### Le modèle commun

1. **Un rendez-vous** : une grille par jour, la même pour tous.
2. **Un score comparable** : un nombre qu'on peut citer.
3. **Un partage sans spoiler, et copiable** : le résultat, pas la réponse.
4. **Zéro friction** : pas de compte, pas d'application, chargement rapide.
5. **Un canal unique au départ** : X pour Wordle et Métrodoku, Reddit pour GeoGuessr.

CLIKEA a les briques 2, 3 et 4. **Il n'a pas la brique 1** (le rendez-vous quotidien), désormais le seul écart structurant avec les jeux qui installent une habitude.

## 2. Les cinq leviers, appliqués à CLIKEA

### Levier 1 — Un partage copiable, pas seulement une image

C'est la correction de conclusion la plus importante. Le format qui a fait tenir Wordle est **du texte** : il se colle dans un tweet, un message, un groupe WhatsApp, un commentaire TikTok. L'image exige un enregistrement puis un envoi, et elle n'apparaît pas dans le fil de discussion.

CLIKEA doit proposer les deux :

- **le ticket image** (déjà là) pour la fierté et l'esthétique ;
- **un résultat texte copiable** du type `CLIKEA 52/100 · 13/20 · série 6` avec une grille de cases vert/rouge par question, sans nom de produit, donc sans spoiler.

Le bouton « Copier mon résultat » doit être aussi visible que « Partager mon ticket ».

**Non vérifié** : aucune donnée publique ne compare ticket-image et grille emoji. L'observation est que le format texte a précédé le pic de Wordle.

### Levier 2 — Le rendez-vous quotidien

Le levier le plus puissant et le plus coûteux. Il demande :

- un tirage déterministe à partir de la date (même grille pour tous, sans serveur) ;
- un stockage local de la partie du jour ;
- un partage en cases, sans nom de produit ;
- éventuellement un minuteur avant la grille suivante.

Sans quotidien, CLIKEA reste un jeu qu'on essaie une fois ; avec, il devient un rendez-vous qu'on partage chaque matin. C'est ce qui a fait Métrodoku.

### Levier 3 — Le défi nominatif

Le partage actuel envoie sur l'accueil : le destinataire ne voit pas le score à battre, donc la boucle « je te bats » ne se ferme pas.

Correctif : encoder le score et le pseudo dans l'URL, afficher un bandeau (« César a marqué 52/100. Tu fais mieux ? »), et proposer au destinataire de renvoyer son score.

**Non vérifié** : le défi existe chez Timeguessr et GeoGuessr, mais aucune source ne montre que c'est le canal de décollage. Hypothèse raisonnable, pas un fait.

### Levier 4 — Zéro friction

Déjà bon : pas de compte, pas d'installation, cinq langues, mobile d'abord. Deux points à corriger :

- **Le poids** : environ 1,2 Mo de photos par partie, plus le HTML.
- **Le pseudo obligatoire** : le seul champ à remplir avant de jouer.

### Levier 5 — Un lancement, pas une mise en ligne

Un jeu circule parce qu'un premier groupe en parle au même moment, pas parce qu'il est en ligne.

## 3. État du produit après les correctifs

Les cinq correctifs identifiés par la recherche ont été appliqués le 21 novembre 2026.

| Correctif | État |
|---|---|
| **Résultat texte copiable** | Fait. `CLIKEA 52/100 · 13/20 noms · série 6` + grille de 20 cases vert/rouge/jaune, sans nom de produit. Bouton « Copier mon résultat » sur l'écran de fin et dans la feuille de partage. |
| **Balises Open Graph + image d'aperçu** | Fait. `og:image` pointe sur `og.png`, 1200 × 630, avec titre, description, `twitter:card`. |
| **Défi nominatif** | Fait. Le lien partagé porte `?defi=52&par=Cesar` ; l'accueil affiche un bandeau « Cesar a marqué 52/100. Tu fais mieux ? ». |
| **Suivi des canaux** | Fait. Chaque lien partagé porte `utm_source` (`x`, `whatsapp`, `linkedin`, `copy`, `native`). Événement `clikea_defi_view` à l'arrivée. |
| **Pseudo facultatif** | Fait. On joue sans nom ; à la fin, un champ permet de l'ajouter pour envoyer le score. |
| **Photos locales** | Fait. 109 WebP de 640 × 640, 1,5 Mo au total, 4 à 37 Ko par photo : environ 160 Ko par partie au lieu de 1,2 Mo. |

### Ce qui reste

1. **Mode quotidien** : le levier le plus puissant, non fait. C'est l'investissement qui transforme un jeu essayé une fois en rendez-vous.
2. **Pages SEO** : « Tous les noms de produits IKEA », une page par thème. Le domaine est déjà déclaré dans `robots.txt` et `sitemap.xml`.
3. **Anti-triche du classement** : la clé publiable permet d'insérer n'importe quel score.
4. **Test réel du partage natif** : l'API Web Share n'est pas vérifiable dans le navigateur headless ; à contrôler sur un iPhone et un Android.

## 4. Canaux de diffusion

### Vue d'ensemble

| Canal | Rôle | Potentiel | Piège |
|---|---|---|---|
| TikTok / Reels / Shorts | Volume, découverte | Le seul canal capable de faire du volume | Demande du rythme et du montage |
| X | Niche, presse, early adopters | A fait décoller Métrodoku | Faible audience FR, liens dépréciés |
| Reddit | Pic ponctuel | Bon si le bon subreddit | Beaucoup de subs interdisent les jeux |
| Presse FR | Crédibilité | Fort sur ce type de jeu | Peu de places, pitch personnalisé obligatoire |
| SEO | Long terme | Cumulatif | 3 à 6 mois avant résultat |

### TikTok, Reels, Shorts — le canal de volume

- **Ne pas viser 15 s.** Une étude Buffer sur 1,1 million de TikToks trouve que les vidéos de **plus de 60 s** ont **43,2 % de portée en plus** que celles de 30 à 60 s, avec **11,3 s de visionnage médian** contre 6,9 s ([Buffer, 2025](https://buffer.com/resources/longer-tiktoks-get-more-views/)). Cibler **45 à 75 s** : le temps de montrer une partie, pas juste un logo.
- **54 % des vues TikTok viennent du For You Page**, avec 4,2 % d'engagement par vue ([Socialinsider, 2026](https://www.socialinsider.io/blog/social-media-reach/)). Sur Instagram, seuls les Reels de 3 min maximum sont recommandés aux non-abonnés ; YouTube Shorts plafonne à 3 min.
- **75 % des vidéos mobiles sont regardées sans son** : sous-titres obligatoires.
- **Formats qui percent pour un jeu de devinettes** : capture d'écran + réaction ; duel en split-screen ; « vrai nom IKEA ou faux ? » ; score final affiché en gros.
- **Le hook tient dans les 2 premières secondes** : le meuble à l'écran, une question, ou le score final teasé.
- **Exemples réels** : GeoGuessr anime un compte TikTok à 515,7 k abonnés ; @georainbolt dépasse 3,2 M.

### X — la niche et les journalistes, pas le grand public français

- **C'est le canal documenté du cas français le plus proche** (Métrodoku, 30 000 joueurs quotidiens un mois après le lancement). Mais X ne pèse que **11 % de l'usage hebdomadaire pour l'information en France**, derrière Facebook (26 %), YouTube (21 %) et Instagram (16 %) ([Reuters Institute, 2025](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2025/france)). X sert à toucher journalistes, indie hackers et la niche anglophone.
- **Les liens externes sont historiquement désavantagés** : le Washington Post a mesuré environ 5 secondes de délai avant chargement, et X a retiré les titres des aperçus en octobre 2023 ([Wikipédia en](https://en.wikipedia.org/wiki/Twitter_under_Elon_Musk)). En octobre 2025, X teste un assouplissement, avec un classement passé au temps passé ([Tomorrow's Publisher](https://tomorrowspublisher.today/content-creation/x-softens-stance-on-external-links/)). Tactique : publier l'image native, mettre le lien en réponse.
- **Les réponses pèsent plus que les likes** dans le classement — environ 13,5 contre 0,5 selon une analyse du code ouvert ([adlibrary](https://adlibrary.com/guides/x-twitter-algorithm-explained)), chiffres rapportés, non revérifiés ici. Conséquence pratique : répondre chez des comptes plus gros est le seul levier réel d'un compte à 0 abonné.
- **Limites d'un compte neuf** : 50 posts originaux et 200 réponses par jour ([X Help](https://help.x.com/en/rules-and-policies/x-limits)). Cadence raisonnable : **1 à 3 posts par jour**, plus des réponses.
- **Ce qui marche** : montrer une photo de meuble et demander le nom en reply. Les réponses des gens sont le contenu.

### Reddit — bon trafic, nombreux pièges

- **r/InternetIsBeautiful interdit explicitement les webgames, quiz et puzzles** : c'est le piège n°1, beaucoup de jeux s'y font supprimer ([règles](https://www.reddit.com/r/InternetIsBeautiful/about/rules/)).
- **r/WebGames** accepte un jeu original : lien direct vers un seul jeu, **pas d'inscription**, pas de lien de parrainage, titre commençant par le nom du jeu, **3 mois minimum avant de reposter** ([règles](https://www.reddit.com/r/WebGames/about/rules/)).
- **r/IKEA** (254 k abonnés) tolère très mal la promo ; **r/france** supprime la pub et bannit les comptes créés pour l'autopromotion.
- Sur 64 subreddits analysés, **58 % interdisent l'autopromotion ou la conditionnent au ratio 9:1** ([OneUp](https://oneup.today/tools/reddit-self-promotion-checker)).
- **Bon post** : titre factuel, capture, « j'ai fait ce petit jeu, dites-moi si les noms sont justes », réponses aux commentaires pendant deux heures. Pas de lien dans le titre, pas de copier-coller sur dix subs le même jour.

### Hacker News et Product Hunt — un pic, pas une croissance

- **Show HN** : ton non promotionnel exigé ([guidelines](https://news.ycombinator.com/newsguidelines.html)). Une place en front page tient 1 à 6 h, avec **8 000 à 25 000 visiteurs** ([postmortem](https://marcotm.com/articles/stats-of-being-on-the-hacker-news-front-page/)) ; seuls **8,15 % des Show HN** restent plus de 60 min en front page ([LaunchEngine](https://launchengine.app/launch/show-hn-tips)). Viser 9 h-12 h heure de l'Est, un jour de semaine.
- **Product Hunt** : le lancement commence à **minuit Pacifique, soit 9 h à Paris**. Le samedi, il faut 165 points médians pour le top 5 contre 235 le jeudi, avec 10,7 lancements le samedi contre 30,4 le mardi ([Mean CEO, 2026](https://blog.mean.ceo/product-hunt-launch-statistics/)). Seulement **3 à 4 % des produits sont « featured »**. Trafic réaliste : **500 à 3 000 visites** pour un top 5 ([LaunchBuff](https://launchbuff.com/blog/product-hunt-launch-traffic)).
- **BetaList** : revue en 3 à 10 jours, file gratuite de plusieurs semaines, intérêt faible pour un jeu.
- **Facebook** : portée organique moyenne d'une page **1,25 %** ([Socialinsider](https://www.socialinsider.io/blog/social-media-reach/)) ; les groupes font mieux mais exigent une participation préalable.

### Presse et créateurs

- **Korben** accepte les propositions via sa page contact, à condition d'aller droit au but et de ne pas envoyer de spam générique ([Korben](https://korben.info/contact)). Numerama et Presse-citron passent par formulaires.
- **Le Parisien a couvert Métrodoku** : la presse généraliste française marche sur ce type de jeu.
- **Côté déco** : IKEA Hackers et le compte Instagram **@ikeahack** (1,86 M abonnés) sont plus pertinents qu'un média tech.
- **Pitch efficace** : un chiffre inattendu, un visuel prêt, une exclusivité, pas d'envoi groupé visible.

### SEO — lent, mais c'est le seul actif qui reste

- IKEA compte environ **12 000 produits** en ligne ; ikea.com attire **225,7 M de visites par mois** ([Semrush](https://www.semrush.com/website/ikea.com/overview/)). Les recherches produit appartiennent à IKEA.
- Un site neuf (DR 0) ne peut pas ranker sur « ikea » ni « kallax ». Les requêtes accessibles sont informationnelles : « liste des noms de produits IKEA », « comment IKEA nomme ses produits », « quiz nom de meuble IKEA ».
- **Concurrents déjà positionnés** : Sporcle, BuzzFeed, FunGenerators, PurposeGames — des pages faibles, souvent sans jeu jouable. C'est là que se joue la longue traîne.
- **Éviter 12 000 pages produit** : contenu mince, risque de pénalité. Trois à cinq pages suffisent.
- **Délai réaliste** : 3 à 6 mois.

## 5. Plan de lancement sur 30 jours

**Semaine 0 — fait (21 novembre 2026)**
- Les cinq correctifs du §3 sont en ligne.
- Image d'aperçu 1200 × 630, balises sociales, `robots.txt` et `sitemap.xml`.
- Reste à préparer : bannière X, trois captures (accueil, question, ticket), trois scripts de 45-75 s.

**Semaine 1 — amorcer**
- 5 posts X : un meuble par jour, réponse en reply.
- Un post « J'ai fait un jeu » avec le ticket.
- **r/WebGames** (pas r/InternetIsBeautiful), après lecture des règles.
- Un Show HN en anglais, 9 h-12 h heure de l'Est.

**Semaine 2 — volume**
- 3 vidéos courtes, même contenu, trois accroches, sur TikTok et Reels.
- Répondre aux commentaires, c'est là que se joue la portée.
- Comparer clics et parties terminées par `utm_source`.

**Semaine 3 — presse**
- Pitch personnalisé à 5 médias tech français, 3 créateurs TikTok, 2 comptes déco.
- Publier « Tous les noms de produits IKEA ».
- Product Hunt un samedi (moins de concurrence), à 9 h Paris.

**Semaine 4 — décider**
- Quel canal amène des joueurs qui terminent et qui partagent.
- Décider du mode quotidien : à faire seulement si le taux de partie terminée est bon.

## 6. Mesurer

| Indicateur | Calcul | Ce qu'il dit |
|---|---|---|
| Taux de démarrage | `clikea_game_started` / `clikea_view` | L'accueil convainc |
| Taux de fin | `clikea_game_finished` / `clikea_game_started` | Le jeu tient jusqu'au bout |
| Taux de partage | `clikea_share` / `clikea_game_finished` | Le ticket donne envie |
| Part des visiteurs venus d'un partage | vues avec `utm_source=share` / vues totales | La boucle tourne |
| Coefficient viral (K) | partages × visiteurs par partage / joueurs | K > 1 : croissance organique |

- **Un K inférieur à 1 est la norme.** 0,2 à 0,8 est considéré comme sain, le gaming allant de 0,4 à 1,2 ([Kompassify](https://www.kompassify.com/blog/viral-coefficient)).
- **Ordres de grandeur réalistes pour un lancement sans audience** : quelques centaines de visites par canal, 1 000 à 5 000 au total si un post Reddit ou une vidéo accroche ; X restera sous 1 000 impressions par post les premières semaines.
- **Session mobile médiane d'un jeu casual** : 3,1 à 3,5 min. Une partie de CLIKEA doit rester dans cette fenêtre.

## 7. Risques

### Marque : le risque est documenté, pas théorique

- **IKEA contre *The Store Is Closed* (2022)** : sans le mot « IKEA », avec un magasin nommé « STYR » et des meubles génériques, IKEA a fait envoyer une mise en demeure exigeant le retrait « de tous les signes associés aux magasins IKEA » **sous 10 jours**, au titre de la concurrence déloyale. Motifs : enseigne bleu-jaune à nom scandinave, bâtiment bleu, chemises jaunes, sol gris. Sources : [GamesIndustry.biz](https://www.gamesindustry.biz/ikea-issues-cease-and-desist-against-indie-developer), [PC Gamer](https://www.pcgamer.com/ikea-threatens-to-sue-the-maker-of-an-infinite-furniture-store-survival-game/).
- **NYT contre les clones de Wordle (2024)** : au moins trois DMCA, dont un contre un dépôt forké 1 900 fois ; le NYT revendique non seulement le nom mais **la grille 5×6 et les tuiles vertes** ([404 Media](https://www.404media.co/nytimes-files-copyright-takedowns-against-hundreds-of-wordle-clones/)).
- **SUTOM contre France Télévisions (2022)** : courrier d'avocat sur le nom, propriété de la marque MOTUS ; accord fin mars 2022 autorisant la poursuite ([Wikipédia fr](https://fr.wikipedia.org/wiki/Sutom)).
- **Nintendo et les fan games** : *Pokémon Uranium* (1,5 million de téléchargements la première semaine) et *AM2R* retirés après DMCA.

**Lecture** : le retrait dépend d'un **faisceau d'indices visuels** (couleurs, formes, vocabulaire) et de similitudes de nom, pas du seul nom exact. CLIKEA cumule le bleu et le jaune, un nom construit sur IKEA, et le mot IKEA dans son titre. C'est le risque principal du projet : il faut pouvoir retirer le nom et les visuels vite.

### Autres risques

- **Dépendance au CDN IKEA** : une URL changée casse une image.
- **Classement trompé** : si le jeu grossit, un classement faux devient un sujet public.
- **Mode quotidien** : il crée une attente ; une grille manquée se voit.
- **Confondre vues et joueurs** : un pic HN ou Product Hunt est technique et majoritairement américain, avec un rebond très élevé.

## 8. Sources

- [Wikipédia (en), Wordle](https://en.wikipedia.org/wiki/Wordle) — courbe, partages, rachat, 4,8 Md de parties.
- [Le Parisien, 30 avril 2026](https://www.leparisien.fr/paris-75/metrodoku-le-jeu-qui-rend-fou-pres-de-30-000-habitues-du-metro-parisien-chaque-jour-30-04-2026-JFW5WBE23NAUXOEZBJLVOQE5AE.php) — chiffres et rôle de X pour Métrodoku.
- [Flourish](https://flourish.studio/blog/the-rise-of-wordle/) — 60 % de joueurs qui ne partagent pas.
- [Wikipédia (fr), SUTOM](https://fr.wikipedia.org/wiki/Sutom), [Cémantix](https://fr.wikipedia.org/wiki/C%C3%A9mantix) — sans inscription, litige de marque.
- [Wikipédia (en), GeoGuessr](https://en.wikipedia.org/wiki/GeoGuessr) — Reddit et Chrome Experiments.
- [Wikipédia (en), Twitter under Elon Musk](https://en.wikipedia.org/wiki/Twitter_under_Elon_Musk), [Tomorrow's Publisher](https://tomorrowspublisher.today/content-creation/x-softens-stance-on-external-links/) — liens ralentis, titres retirés, test 2025.
- [adlibrary](https://adlibrary.com/guides/x-twitter-algorithm-explained), [X Help](https://help.x.com/en/rules-and-policies/x-limits) — pondération des réponses, limites de compte.
- [Reuters Institute, Digital News Report 2025, France](https://reutersinstitute.politics.ox.ac.uk/digital-news-report/2025/france) — usage de X en France.
- [Buffer](https://buffer.com/resources/longer-tiktoks-get-more-views/), [Socialinsider](https://www.socialinsider.io/blog/social-media-reach/) — durée des vidéos, portée, engagement.
- [r/InternetIsBeautiful](https://www.reddit.com/r/InternetIsBeautiful/about/rules/), [r/WebGames](https://www.reddit.com/r/WebGames/about/rules/), [OneUp](https://oneup.today/tools/reddit-self-promotion-checker) — règles Reddit.
- [HN guidelines](https://news.ycombinator.com/newsguidelines.html), [postmortem HN](https://marcotm.com/articles/stats-of-being-on-the-hacker-news-front-page/), [LaunchEngine](https://launchengine.app/launch/show-hn-tips) — Show HN.
- [Mean CEO](https://blog.mean.ceo/product-hunt-launch-statistics/), [LaunchBuff](https://launchbuff.com/blog/product-hunt-launch-traffic) — Product Hunt.
- [Semrush](https://www.semrush.com/website/ikea.com/overview/), [Ingka Group](https://www.ingka.com/newsroom/ikea-retail-reveals-top-product-searches-for-2024/) — SEO.
- [Kompassify](https://www.kompassify.com/blog/viral-coefficient) — coefficient viral.
- [GamesIndustry.biz](https://www.gamesindustry.biz/ikea-issues-cease-and-desist-against-indie-developer), [PC Gamer](https://www.pcgamer.com/ikea-threatens-to-sue-the-maker-of-an-infinite-furniture-store-survival-game/), [404 Media](https://www.404media.co/nytimes-files-copyright-takedowns-against-hundreds-of-wordle-clones/) — mises en demeure et DMCA.
- [ogp.me](https://ogp.me/) — `og:image` requise.

### Ce qui n'a pas pu être vérifié

- Les conversions réelles par canal ; les chiffres d'audience de Timeguessr, Framed, Tradle, Logoquiz.
- L'effet causal du streak, du ticket-image et du défi entre amis.
- La pondération exacte des réponses dans le classement X (chiffres rapportés, code non consulté ici).
- Le retour complet des liens X à leur portée antérieure.
- Les règles à jour de chaque subreddit (à relire avant chaque post).
