# Plan viral v1

Proposé par Buzz (marketing) le 23 novembre 2026, à valider par CLIKEA. Rien n'est publié avant validation. Complète [`STRATEGIE-SOCIALE.md`](STRATEGIE-SOCIALE.md), [`VIRALITE.md`](VIRALITE.md) et [`LANCEMENT.md`](LANCEMENT.md) sans les répéter.

**En une phrase** : CLIKEA donne déjà envie de partager (un finisseur sur quatre partage), mais chaque partage touche une seule personne et presque personne n'arrive de l'extérieur. Le plan teste d'abord des canaux gratuits qui touchent beaucoup de monde d'un coup (créateurs, communautés, agrégateurs, vidéos courtes), puis propose deux petits changements de partage pour que chaque envoi rapporte plus.

## 1. Diagnostic

### Les chiffres (PostHog, 20 au 23 novembre 2026, extraits le 23 à midi)

| Jour | Visiteurs | Parties lancées | Parties finies | 10 du jour envoyés | Partages | Ouvertures de défi |
|---|---|---|---|---|---|---|
| 20/11 | 21 | 5 | 3 | 0 | 1 | 0 |
| 21/11 | 135 | 58 | 38 | 0 | 5 | 3 |
| 22/11 | 59 | 126 | 94 | 15 | 26 | 16 |
| 23/11 (matin) | 65 | 36 | 25 | 12 | 10 | 10 |

Sur les 5 derniers jours :
- **Une audience surtout française, venue en direct.** 129 visiteurs en France, dont 54 lancent une partie (42 %). Les 92 visiteurs « États-Unis » ne lancent qu'une partie à eux tous : ce sont presque tous des robots ou des aperçus de lien. Il faut les exclure des tuiles, sinon le taux de démarrage est faux de moitié.
- **Provenance** : 253 visiteurs sans `utm_source` ni référent, une poignée via WhatsApp (3), Facebook (6), Bing (5), Instagram (3), YouTube (2). Aucun canal extérieur n'a encore amené plus de 10 personnes.
- **Le partage est fort** : 13 joueurs sur 46 qui finissent une partie partagent (28 %). Les modes : texte copié (10), X (9), partage natif (10), ouverture de l'image (5), WhatsApp (3).
- **La boucle est courte** : 14 personnes ont ouvert un lien de défi, 7 ont lancé une partie (50 %). Un partage rapporte donc environ 0,3 nouveau joueur, d'où un coefficient viral K ≈ 0,28 × 1 × 0,5 ≈ **0,15**. Il faudrait K > 1 pour que le jeu grossisse seul.
- **Rétention** : 7 joueurs sur 46 sont revenus finir une partie un autre jour (15 %) ; le 10 du jour n'existe que depuis le 22/11, la mesure J+1 et J+7 commence.
- **Durée** : une partie finie dure 89 s en moyenne, dans la bonne fenêtre.
- **Mobile** : la donnée appareil manque sur la majorité des vues ; à corriger dans la tuile (lire `$raw_user_agent` ou `$device_type`).

### Ce qui rend CLIKEA partageable

1. **Un sujet universel et drôle** : tout le monde a un meuble IKEA, personne ne connaît son nom. Le thème a déjà fait le buzz (« Ikea or Death? », défi de prononciation d'IKEA UAE).
2. **Un échec drôle à raconter** : le jeu est dur, et rater « BARLAST » se raconte mieux que réussir.
3. **Un résultat sans spoiler** : `CLIKEA du jour #N · 34/50`, deux lignes de cases, la série 🔥 et un lien de défi.
4. **Zéro friction** : gratuit, sans compte, 6 langues, partie en 90 s.

### Ce qui freine

1. **Personne ne le voit de l'extérieur.** Le jeu ne circule que dans le premier cercle de César. Tous les jeux du benchmark ont eu une **étincelle publique** : un tweet, un post Reddit, un article, un créateur.
2. **Le partage va vers une seule personne** (WhatsApp, copier-coller). Il fait jouer un ami, pas un groupe ou un public.
3. **Le lien de défi ne donne pas assez envie dans l'aperçu** : dans WhatsApp, l'aperçu montre l'image générique, pas « Léa a fait 34/50, tu fais mieux ? ».
4. **Le texte partagé ne raconte rien** : un score et des cases. Il manque l'anecdote qui fait répondre (« j'ai raté le n° 7, comme 83 % des joueurs »).
5. **Les comptes sociaux partent de zéro** et TikTok n'existe pas encore : le canal de volume n'est pas branché.
6. **Le risque de marque IKEA** limite les formats (pas de logo, captures du jeu plutôt que photos brutes).

## 2. Benchmark

Huit jeux comparables. Wordle et Métrodoku sont détaillés dans [`VIRALITE.md`](VIRALITE.md) ; les autres viennent d'une recherche du 23/11/2026. « Non vérifié » signale ce qui n'a pas de source solide.

| Jeu | Lancement | Étincelle | Partage | Chiffres | Leçon pour CLIKEA |
|---|---|---|---|---|---|
| **Wordle** | oct. 2021 | des amis, puis Twitter quand la grille d'émojis (inventée par une joueuse néo-zélandaise) est ajoutée | grille d'émojis sans spoiler | 90 joueurs le 1/11/2021 → 300 000 le 2/1/2022 ; 1,2 M de résultats sur Twitter du 1er au 13/1 | le format de partage a déclenché la vague |
| **Métrodoku** | 2/4/2026 | cercle d'amis, puis X, puis Le Parisien | grille + score | 1 000 joueurs après une semaine, ≈ 30 000 par jour un mois après | séquence cercle → X → presse, cas français le plus proche |
| **Costcodle** (prix Costco) | sept. 2023 | vidéos TikTok de gens qui jouent (« can you guess the price ») ; forum de fans qui poste chaque jour depuis juillet 2024 | « Costcodle #301 5/6 » + émojis + lien | non vérifiés ; aucune réaction de Costco trouvée ; clones (Tescodle) | **le cas le plus proche** : une marque que tout le monde connaît + des vidéos où l'on joue face caméra suffisent à durer 2 ans sans presse |
| **Framed** (images de films) | début 2022 | presse ciné et jeux (NME, GameSpot, PC Gamer) qui l'appelle « Wordle pour cinéphiles » | résultat partageable sur Twitter | non vérifiés | mécanique la plus proche (une image, un nom) ; « le Wordle de X » suffit à attirer la presse spécialisée |
| **Worldle** (pays) | 27/1/2022 | Twitter géographie et voyage ; créateur français solo, jeu fait en quelques jours | grille + distance | 10 000 joueurs les 10 premiers jours, puis ≈ 500 000 à 970 000 par jour en février | une niche passionnée peut porter un jeu à un million en 3 semaines |
| **Bandle** (musique, créateur français) | août 2022 | le youtubeur Northernlion, puis en 2024 des streamers et TikTokeurs qui jouent en direct ; « aucun marketing » selon le créateur | grille | plus de 100 000 joueurs par jour en 2025 | **les créateurs qui jouent face caméra** sont le seul moteur sourcé de croissance après 2023 |
| **TimeGuessr** (photo → année et lieu) | 5/3/2023 | youtubeurs GeoWizard, Northernlion, Ludwig (non vérifié) | défi du jour + parties à envoyer à des amis | non vérifiés | un jeu de photo se regarde bien en vidéo ; viser les créateurs de la niche |
| **IKEA or Death?** | oct. 2013 | Facebook ; concept en une ligne | partage Facebook | plus de 225 000 partages, serveurs saturés ; IKEA : « no involvement », ni procès ni partenariat | le thème IKEA est viral par nature, et la marque reste neutre si le ton est bienveillant |
| **Heardle** (musique) | 26/2/2022 | interview Variety, puis Spotify qui joue sur Twitter | grille | pic de 69 M de visites en mars 2022 ; racheté par Spotify en juillet 2022, fermé en 2023 | une marque peut aussi récupérer un jeu de fan |

### Cinq leçons

1. **Chaque décollage a eu une étincelle publique dans une niche** : Twitter géo (Worldle), Reddit (LoLdle, GeoGuessr), youtubeurs (Bandle, TimeGuessr), TikTok (Costcodle). La presse arrive après. CLIKEA n'a pas encore eu la sienne.
2. **Pour un jeu de devinette d'images, le moteur récent est la vidéo où quelqu'un joue** (Costcodle, Bandle, TimeGuessr) : une réaction, une surprise, un échec drôle. D'où H1, H3 et H9.
3. **Le partage montre le score, jamais la réponse, et raconte quelque chose** : l'ordre des erreurs dans Connections, le « 5/6 » de Costcodle. CLIKEA l'a déjà ; on peut y ajouter le piège (H5).
4. **Un concept en une ligne est repris tel quel** : « le Wordle des noms IKEA » est notre accroche presse.
5. **Les marques réagissent peu aux jeux de fan bienveillants** (IKEA en 2013, Costco), mais IKEA a réagi à des visuels de magasin en 2022 : on garde la mention de non-affiliation et pas de logo.

Sources : [Costcodle sur GitHub](https://github.com/KermWasTaken/costcodle) · [forum Woot](https://forums.woot.com/t/price-is-costco/1756375) · [vidéo TikTok Costcodle](https://www.tiktok.com/@michael.dicostanzo/video/7321879091345460523) · [Framed, NME](https://www.nme.com/news/wordle-spin-off-framed-asks-cinema-fans-to-guess-films-from-still-images-3189472) · [Framed, GameSpot](https://www.gamespot.com/articles/framed-is-a-wordle-like-with-scenes-from-movies/1100-6501819/) · [Worldle, Independent via Yahoo](https://www.yahoo.com/news/worldle-map-game-tests-travel-082808025.html) · [Worldle, Tribune](https://tribune.com.pk/story/2349125/wordles-geography-spin-off-worldle-reaches-1-million-users) · [Bandle, Berklee](https://online.berklee.edu/takenote/bandle-creator-johann-levy-on-the-music-quiz-100k-daily-players-love/) · [Bandle, NBC via AOL](https://www.aol.com/news/bandle-wordle-song-guessing-game-230604066.html) · [TimeGuessr, PCWorld](https://www.pcworld.com/article/3233865/geoguessr-fans-should-try-this-addictive-history-game.html) · [IKEA or Death, GMA](https://www.goodmorningamerica.com/news/story/ad-agencys-viral-site-ikeaordeath-pokes-fun-swedish-20545270) · [Heardle, TechCrunch](https://techcrunch.com/2022/07/12/spotify-acquired-heardle-wordle-music-game) · [Wordle, The Spinoff](https://thespinoff.co.nz/media/13-01-2022/those-coloured-boxes-on-twitter-are-new-zealands-fault) · [Wordle, Wikipédia](https://en.wikipedia.org/wiki/Wordle) · [Connections, TechCrunch](https://techcrunch.com/2023/08/28/connections-is-the-new-york-times-most-played-game-after-wordle) · Métrodoku : voir [`VIRALITE.md`](VIRALITE.md).

## 3. Hypothèses de croissance

Notation ICE de 1 à 10 : **I**mpact si ça marche, **C**onfiance (preuves du benchmark), **F**acilité (temps, coût, dépendances). Score = moyenne. « Produit » signale une idée à coder par CLIKEA.

| # | Hypothèse | I | C | F | Score |
|---|---|---|---|---|---|
| H1 | **Créateurs et streamers qui jouent en direct.** Un streamer ou un TikTokeur qui joue au 10 du jour devant son public apporte plus que 30 posts de notre compte. Cible : streamers FR « just chatting » qui jouent déjà à Sutom, Cémantix ou GeoGuessr, et créateurs déco ou humour IKEA. | 9 | 7 | 6 | 7,3 |
| H2 | **Agrégateurs et listes de jeux quotidiens.** Les sites qui recensent les jeux quotidiens et les « -dle » amènent un public qui joue chaque jour, gratuitement et sans effort. | 5 | 7 | 9 | 7,0 |
| H3 | **« IKEA ou pas IKEA ? » en vidéo courte.** Un vrai nom IKEA contre un nom de ville suédoise, de groupe de metal ou de Pokémon fait plus de vues et de commentaires que « devine le nom ». | 8 | 6 | 7 | 7,0 |
| H4 | **Le défi lisible dans l'aperçu** (produit). Une image d'aperçu générée avec « Léa : 34/50. Tu fais mieux ? » augmente les ouvertures de défi par partage. | 7 | 6 | 7 | 6,7 |
| H5 | **Le texte partagé raconte un piège** (produit). Ajouter une ligne « Raté : le n° 7, comme 83 % des joueurs » fait répondre et ouvrir le lien. | 6 | 5 | 8 | 6,3 |
| H6 | **L'amorçage organisé des cercles.** César, Ben et Simon envoient chacun le 10 du jour dans 5 groupes pendant 5 jours, avec leur score. Les groupes privés sont le cœur du bouche-à-oreille (Wordle, Métrodoku). | 5 | 7 | 7 | 6,3 |
| H7 | **Reddit avec un angle propre à chaque communauté.** r/WebGames (règles relevées), r/IKEA après accord des modérateurs, et un angle suédois (« même les Suédois ratent ») sur r/sweden si les règles le permettent. | 7 | 5 | 6 | 6,0 |
| H8 | **Le calendrier de l'Avent CLIKEA** (contenu, pas produit). Du 1er au 24 décembre, chaque contenu porte « case n° X » ; les fêtes et le Black Friday mettent IKEA dans toutes les têtes. | 6 | 4 | 8 | 6,0 |
| H9 | **Le micro-trottoir devant un magasin IKEA.** César filme des passants (avec leur accord) qui devinent le nom d'un produit sur son téléphone. Les vraies réactions sont le format le plus repris sur TikTok. | 8 | 5 | 4 | 5,7 |
| H10 | **Les classements de bande** (produit). Un lien de groupe affiche le classement du jour d'une bande d'amis (WhatsApp, open space, famille). Chaque groupe joue alors tous les jours. | 8 | 5 | 4 | 5,7 |
| H11 | **Le jeu du bureau.** Un post LinkedIn de César (« le jeu qui occupe notre open space à 9 h ») et un message prêt à coller dans Slack ou Teams : la pause café est le moment de Wordle. | 6 | 5 | 6 | 5,7 |
| H12 | **Le piège de la veille sur X et Bluesky à 8 h** plutôt qu'à 18 h 30, en même temps que le nouveau 10 du jour, pour prendre le trajet du matin. | 4 | 5 | 9 | 6,0 |
| H13 | **Groupes Facebook IKEA et bons plans** avec l'accord des admins : un public plus âgé, qui partage beaucoup par WhatsApp. | 5 | 5 | 5 | 5,0 |
| H14 | **Presse « insolite » et comptes d'anecdotes** (Konbini, Topito, Brut, comptes « le saviez-vous »). L'angle : « comment IKEA nomme ses meubles » + chiffre du jeu. Seulement après un premier pic. | 9 | 4 | 4 | 5,7 |
| H15 | **Le défi des Suédois.** Une vidéo où des Suédois (créateurs ou amis) jouent et échouent sur des noms de leur propre langue, en version anglaise : un angle international. | 7 | 4 | 4 | 5,0 |

**Idées non retenues pour l'instant** : Show HN et Product Hunt (un pic surtout américain, avant que l'anglais tienne) ; publicité (interdite sans accord de César) ; concours avec récompense (interdit par TikTok contre de l'engagement, et coûteux).

## 4. Calendrier de tests (24 novembre au 7 décembre 2026)

Cinq tests, choisis pour leur score et parce qu'ils ne dépendent pas d'un compte qui n'existe pas encore (sauf T3, qui démarre dès que TikTok est créé, et sur Reels et Shorts en attendant).

| Test | Hypothèse | Canal | Ce qu'on fait | Indicateur | Seuil de réussite | Dates |
|---|---|---|---|---|---|---|
| **T1 Créateurs** | H1 | DM Instagram et X depuis @clikeagame, e-mail par César | 15 messages personnalisés : 8 streamers FR qui jouent déjà à des jeux quotidiens, 7 créateurs déco ou humour. Lien `?utm_source=createur&utm_campaign=<pseudo>` par personne. Aucune contrepartie payée. | réponses ; visiteurs par lien | 3 réponses et 1 créateur qui joue en public, ou 100 visiteurs sur les liens | envoi 25–27/11, bilan 7/12 |
| **T2 Agrégateurs** | H2 | sites de listes de jeux quotidiens | Proposition gratuite à 6 listes : [dles (GitHub)](https://github.com/qubit10/dles), [dles.aukspot.com](https://dles.aukspot.com/), [DLES.gg](https://www.producthunt.com/products/dles-gg), [Dle Hunt](https://10015.io/product/dle-hunt), [la bibliothèque de The Word Finder](https://www.thewordfinder.com/blog/?p=1761), et un message à [Alucare](https://www.alucare.fr/top-4-jeux-comme-cemantix/) pour ses listes en français. Lien `?utm_source=liste&utm_campaign=<site>`. | visiteurs `utm_source=liste` et parties finies | 50 visiteurs et 20 parties finies sur 2 semaines | 24–28/11, bilan 7/12 |
| **T3 Vidéo courte** | H3 | Reels et Shorts via Buffer, TikTok dès sa création | 6 vidéos « IKEA ou pas IKEA ? » contre 6 « devine avant la réponse », en alternance, même heure. | vues médianes, commentaires, visiteurs `utm_source=instagram/youtube/tiktok` | le format gagnant a ≥ 1,5 fois les vues médianes de l'autre et ≥ 20 visiteurs au total | 26/11–7/12 |
| **T4 Cercles** | H6 | WhatsApp et groupes privés de César, Ben et Simon | 5 jours d'envoi du 10 du jour dans 5 groupes chacun, avec le texte du jeu tel quel. | ouvertures de défi par partage, nouveaux joueurs du 10 du jour | ≥ 0,8 ouverture de défi par partage et 40 joueurs du 10 du jour un jour donné | 24–28/11, bilan 1/12 |
| **T5 Reddit** | H7 | r/WebGames, r/IKEA après accord des modérateurs | Un post chacun, depuis le vrai compte de César ou Ben, réponses aux commentaires pendant 2 h. | votes, visiteurs `utm_source=reddit` | 100 visiteurs sur un post, ou 20 votes positifs | r/WebGames 29/11 (samedi), r/IKEA dès l'accord, bilan 7/12 |

**Propositions produit à coder par CLIKEA** (une seule nouveauté visible par version) :
1. **H4, l'aperçu du défi** en premier : l'image d'aperçu du lien porte le score et le pseudo à battre. Rien ne change dans le jeu lui-même. Mesure : ouvertures de défi par partage, avant et après (seuil : +30 %).
2. **H5, la ligne du piège** dans le texte copié, ensuite, sur une autre version.
3. **Un filtre anti-robots** sur les tuiles PostHog (exclure les vues sans partie ni clic, ou les agents connus) : pas visible des joueurs.

**Ce qui doit être validé** : les 15 messages de T1 (je les rédige, vous les relisez), la liste de T2, les deux nouveaux formats vidéo de T3, l'implication de César, Ben et Simon pour T4 et T5, et le décalage de l'heure X de H12 (je propose de le tester en semaine 3).

## 5. Métriques et rythme de bilan

**Indicateur principal** : joueurs du 10 du jour (appareils qui finissent la grille du jour), hors robots. Point de départ : 15 le 22/11. Objectif à 2 semaines : 50 un jour donné ; à 6 semaines : 1 000 (seuil presse).

| Métrique | Calcul | Départ | Pourquoi |
|---|---|---|---|
| Joueurs du 10 du jour | appareils avec `clikea_daily_submitted` par jour | 15 | l'habitude |
| Visiteurs réels | appareils avec `clikea_view`, hors robots | ≈ 30/jour en France | la portée |
| Provenance | visiteurs et parties finies par `utm_source` et `utm_campaign` | 95 % direct | quel canal marche |
| Taux de partage | joueurs qui partagent ÷ joueurs qui finissent | 28 % | l'envie de partager |
| Rendement d'un partage | ouvertures de défi ÷ partages | ≈ 0,5–1 | la portée d'un partage |
| Conversion du défi | parties lancées ÷ ouvertures de défi | 50 % | l'aperçu donne envie |
| Coefficient viral K | taux de partage × ouvertures par partage × conversion | ≈ 0,15 | > 1 = croissance seule |
| Rétention J+1 et J+7 | joueurs du 10 du jour revenus | 15 % (sur 5 jours) | l'habitude tient |
| Contenus | vues, commentaires, envois, clics par post | — | quel format marche |

**Rythme**
- **Chaque lundi à 9 h**, je t'envoie le bilan : les chiffres de la semaine, chaque test (gardé, coupé ou prolongé), un seul changement proposé pour la semaine suivante.
- **Chaque jour**, je lis le tableau de bord et je ne te préviens que d'un pic ou d'une panne.
- **Règle de décision** : un test qui n'atteint pas son seuil à sa date de fin sort ; un test qui le dépasse passe au calendrier validé.
- Premier bilan : lundi 1er décembre (T4 et premiers chiffres de T2, T3) ; bilan complet du plan : lundi 8 décembre.

## 6. Règles suivies

- À visage découvert seulement : messages et posts signés CLIKEA ou par César, Ben ou Simon depuis leurs vrais comptes ; ni faux comptes, ni faux avis.
- Règles de chaque communauté relues le jour du post.
- Aucune dépense ; aucune contrepartie payée aux créateurs.
- Jamais la grille du jour dans un contenu public.
- Mention « jeu de fan, non affilié à IKEA » partout.

## 7. Sources

Données : tableau de bord PostHog du projet CLIKEA, requêtes du 23/11/2026. Sources du benchmark : voir la section 2.

**Non vérifié** : la part exacte de robots dans les visiteurs américains (déduite de l'absence de parties) ; les règles actuelles de r/sweden ; la liste précise des agrégateurs qui acceptent encore des inscriptions.

## 8. Validation (CLIKEA, 23 novembre 2026)

- **Validés** : T1 Créateurs (validé par César, messages relus par CLIKEA puis César avant envoi), T2 Agrégateurs (formulaires seulement, pas la suggestion GitHub), T3 Vidéo courte (les deux formats).
- **Non validés pour l'instant par César** : T4 Cercles, T5 Reddit, la suggestion GitHub sur « dles ». Ne pas les lancer ; on en reparle au bilan du 1er décembre.
- **Produit** : 1) filtre anti-robots sur les tuiles PostHog, tout de suite (invisible) ; 2) H4 aperçu du défi avec le score, version suivante (il faut une fonction serveur pour l'image d'aperçu, le site est statique) ; 3) H5 ligne du piège, version d'après.
- **Contraintes** : Buffer gratuit = 10 posts programmés par canal ; ne jamais montrer la grille du jour.
