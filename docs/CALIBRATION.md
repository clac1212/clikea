# Calibrage : un jeu qui apprend de ses joueurs

Version partageable : https://karma-arbor-g2wk.here.now/

Décidé le 22 novembre 2026. Remplace la logique « inédits d'abord » de `PRODUITS.md` pour le choix des produits ; la fraîcheur et les plafonds restent.

## Le problème

- Un nom IKEA qu'on ne connaît pas ne se devine pas : en Carré, on tire au sort (1 chance sur 4). Un produit inconnu ne rend pas le jeu dur, il le rend aléatoire, donc ennuyeux.
- Données du 22/11 après l'import de 1 737 gammes (≈ 520 réponses, une dizaine d'appareils) : cultes trouvés à 81–89 %, non-cultes « populaires » à 55 %, non-cultes peu connus à 41 % (presque le hasard en Carré). Cash choisi → 90 % de réussite : le mode choisi révèle ce que le joueur sait. Niveaux très écartés (un appareil à 85 % sur 279 réponses, un autre à 29 % sur 194). Moyenne du 10 du jour : 13,6 / 50.
- La difficulté de départ vient du nombre d'avis ikea.com : elle surestime ce que le public connaît.

## Le principe

Chaque réponse mesure deux choses : **la difficulté réelle du produit** et **le niveau du joueur**. On choisit ensuite les produits pour un dosage qui fait plaisir : assez de connus pour se sentir fort, une zone où l'on joue vraiment, quelques défis. Les premiers joueurs calibrent ; ensuite la formule tourne seule.

Appuis :
- Les versions faciles mais intéressantes d'un jeu sont les plus jouées (Lomas et al., CHI 2013 et 2017, > 10 000 joueurs).
- La pratique adaptative vise ≈ 75 % de réussite, avec un modèle Elo qui tient compte du hasard des QCM (Pelánek 2014, 2016 ; Papoušek et Pelánek 2015).
- Wordle choisit des mots courants ; un mot rare (PARER) a cassé ≈ 60 % des séries un jour donné.
- La règle pic-fin (Kahneman 1993) : commencer et finir sur du connu.

## Le modèle

- Chance de trouver : `c + (1 − c) × σ(niveau − difficulté)`, avec `c` = 1/2 en Duo, 1/4 en Carré, 0 en Cash.
- **Difficulté d'un produit** (`clikea_families.difficulty`) : Elo, première rencontre de chaque appareil seulement, mise à jour chaque nuit. Les réponses du mode calibrage comptent (comme un Cash : je connais = juste).
- **Recalage des produits jamais joués** : chaque nuit, l'écart moyen entre difficulté mesurée et difficulté de départ (cultes et non-cultes séparément, dès 5 gammes mesurées) est appliqué à toutes les gammes encore jamais jouées.
- **Niveau de référence** (`ref_theta`) : le niveau pour lequel la réussite prédite sur les réponses réelles des 30 derniers jours égale la réussite observée. Plus robuste que la moyenne des niveaux Elo au démarrage. Publié chaque nuit dans `clikea_settings`.
- **Niveau d'un joueur** : gardé sur l'appareil (`localStorage clikea-level`), démarre à `ref_theta`, mis à jour après chaque réponse (même formule, pas K = max(0,15 ; 0,8 / (1 + 0,05 n))). Les questions d'orthographe ne comptent pas.

## Classements et record d'arcade

Version partageable : https://wander-thistle-sp2a.here.now/

- **Plus de choix facile / difficile** : la partie libre est adaptative, ce choix faisait doublon. Un seul bouton « Partie libre · 20 produits ».
- **Deux classements** : « Du jour » (même grille pour tous, sur 50, avec l'historique jour par jour) et « Record » (meilleur score de tous les temps en partie libre, sans plafond, `clikea_scores.difficulty = 'arcade'`). Les anciens scores `easy` / `hard` restent en base mais ne sont plus affichés : ils ne sont pas comparables.
- **Pourquoi des multiplicateurs** : sans eux, un record de partie libre récompenserait les débutants (l'adaptation donne des produits durs aux bons joueurs) et pousserait à effacer ses données ; il plafonnerait aussi à 100. Références : Scrabble (valeur selon la rareté, 1 à 10), Jeopardy! (valeur connue avant de choisir), Tetris et Pac-Man (le coup risqué paie beaucoup plus).
- **Rareté** (`rarityOf`) : chance qu'un joueur de niveau `ref_theta` trouve le produit en Cash. Commun ≥ 0,6 ; rare 0,3 – 0,6 ; très rare < 0,3 (réglages `rare_common`, `rare_rare`). Recalculée chaque nuit avec les difficultés.
- **Barème partie libre** : Cash 5 / 10 / 15 ; Carré 3 / 4 / 6 ; Duo 1 (jamais de multiplicateur : on y devine une fois sur deux). Réglages `pts_cash_rare`, `pts_cash_very`, `pts_carre_rare`, `pts_carre_very`. Pas de multiplicateur sur les questions d'orthographe ni dans le 10 du jour.
- **Affichage** : l'étiquette « Rare ×2 » ou « Très rare ×3 » apparaît sur la photo avant le choix du mode, et chaque bouton de mode montre ce qu'il rapporte ; la réponse affiche « +10 pts · Cash · ×2 ». Les produits rares ont des faux noms de la même famille visuelle.
- **Ticket de partie libre** : score en points (sans « /100 »), record personnel de l'appareil, place au classement record ; le message de fin se base sur les produits trouvés.

## Réseau et retours (le mécanisme invisible)

Version partageable : https://dewy-inlet-bfx2.here.now/

L'idée : « je l'ai déjà vu, celui-là ! ». On a envie de le trouver, et à force de le recroiser on le connaît, comme les stations dans Métrodoku. Rien n'est visible pour le joueur : seuls la composition des grilles et le retour des produits changent.

- **Le réseau** (`clikea_families.pool`, recalculé chaque nuit par `clikea_refresh_pool`) :
  - `core` = cultes + produits connus au calibrage par au moins une personne + produits retrouvés ≥ 60 % (10 réponses minimum) ;
  - `seen` = les 200 meilleures ventes les plus notées parmi les familles qu'on repère chez soi ou en magasin (meubles, rangement, luminaires, miroirs, jouets) ;
  - un produit du cœur vu au moins 3 jours dans le 10 du jour et retrouvé moins de 35 % du temps en sort (hors cultes).
- **10 du jour v4** (`clikea_plan_days`, `clikea_pick4`) : 2 sûrs (cultes) en ouverture, 1 culte en clôture, 3 rappels, 2 revenants, 1 nouveau du réseau, 1 piège hors réseau.
  - Retours à intervalles croissants : 2 jours après le 1er passage, puis 7, 21 et 45 jours. Rappels et revenants : les plus ratés d'abord.
  - Un culte au plus une fois par semaine ; jamais deux jours de suite.
  - « Comment ça s'écrit ? » : 1 par jour (place 5 ou 6), parfois une 2e sur le culte de clôture, seulement sur un culte, un produit du cœur ou un produit déjà passé deux fois.
  - Au démarrage, sans historique, les places de revenants passent aux rappels puis aux nouveaux : la composition se met en place en 3 semaines.
- **Partie libre** (`adaptiveQueue`) : 3 sûrs (2 en entrée, 1 en clôture), jusqu'à 6 « à revoir », 4 des 10 du jour des 7 derniers jours, 2 nouveaux du réseau, le reste dans la zone (50–85 %), réseau d'abord. Jamais un produit du 10 du jour tant qu'on ne l'a pas joué.
- **Mémoire par joueur** (`clikea-level.mem`, boîtes de Leitner) : bonne réponse → boîte suivante ; erreur → 2 boîtes en arrière. Retour après 1, 1, 3, 7, 21 puis 45 jours selon la boîte. Les produits en boîte ≥ 2 sont prioritaires pour « comment ça s'écrit ? ».
- **Mesure** : vue `clikea_return_stats` — réussite selon le rang de la rencontre (1re, 2e, 3e…) par format. Si l'apprentissage invisible marche, la réussite monte avec le rang.

## Partie libre : adaptée à chaque joueur

Pour chaque produit, chance de le trouver en Carré pour ce joueur, puis :

| Part | Chance | Rôle |
|---|---|---|
| 25 % | ≥ 85 % | confiance (dont des cultes) |
| 60 % | 50 – 85 % | la zone où l'on joue vraiment |
| 15 % | 30 – 50 % | défis |

- 10 % des 20 produits sont pris parmi les gammes **peu mesurées** (moins de 8 premières rencontres), dans la zone ou les défis : c'est ainsi qu'on mesure les nouveautés sans décourager.
- Jamais de produit sous 30 % (quasi inconnu).
- Ordre : deux produits sûrs, le reste mélangé, un produit sûr pour finir.
- Parties enchaînées : chaque partie lancée dans les 2 h relève le niveau de 0,15 (ça devient plus dur).
- « Produits difficiles » : niveau + 0,8 (sélection plus exigeante, classement séparé).
- Répétition : un produit vu revient après 3 jours, jamais deux fois dans une partie. Les cultes reviennent donc régulièrement.

## L'orthographe : la deuxième façon de jouer un produit

Un produit qu'on connaît redevient un défi quand la question porte sur son écriture. C'est ainsi qu'on réutilise les cultes et les produits déjà trouvés sans lassitude.

- **Quand** : seulement sur des produits connus du joueur — cultes, produits « sûrs » pour lui (≥ 85 %), ou déjà trouvés (mémoire `known` dans `clikea-level`). Jamais sur un produit inconnu : il faut savoir ce que c'est pour juger l'écriture.
- **Partie libre** : 3 ou 4 questions d'orthographe sur 20, jamais sur les deux premières ni sur la dernière. Jusqu'à 2 produits déjà trouvés il y a plus de 3 jours reviennent exprès, en priorité en orthographe.
- **10 du jour** : une question d'orthographe chaque jour, sur une place sûre (1, 2 ou 10), réservée aux cultes et aux produits mesurés (au moins 8 premières rencontres).
- **Fausses orthographes** : des variantes de lettres crédibles (sons proches K/C, KS/X, V/W ; lettres doublées ou simples ; voyelles voisines), une par famille de piège quand c'est possible. **Aucune variante qui ne change qu'un accent** : le jeu ignore les accents, y compris en Cash d'orthographe où seules les lettres comptent (KALLAX oui, KALAX non). Jamais un vrai nom IKEA.
- **Mesure séparée** : l'orthographe n'entre pas dans la difficulté Elo du produit ; sa réussite propre est dans `clikea_product_stats.pct_ortho`.

## 10 du jour : calibré sur l'ensemble des joueurs

Même grille pour tous, donc pas d'adaptation individuelle. Chance en Carré pour un joueur de niveau `ref_theta` :

| Places | Chance | Rôle et fraîcheur préférée |
|---|---|---|
| 1, 2, 10 | ≥ 85 % | sûrs : cultes en 1 et 10 |
| 3 à 6 | 60 – 85 % | zone : rappel, inédit, revenant, inédit |
| 7, 8 | 45 – 60 % | plus durs |
| 9 | 26 – 30 % | le piège du jour |

- À chaque place, le tirage essaie d'abord un produit **mesuré** (au moins 8 premières rencontres) avec la fraîcheur voulue ; sinon la même bande sans préférence, puis bande élargie de 0,10 puis 0,25 (en prenant parmi les 5 plus faciles pour les places sûres), puis tout produit non plafonné.
- Plafonds inchangés : produit ordinaire au plus une fois par 7 jours et 10 fois en tout ; culte au moins 10 jours d'écart.
- « Inédit » = jamais montré dans le 10 du jour, plus « inconnu ».
- Objectif de suivi : score moyen ≈ 28 / 50, scores étalés (vue `clikea_daily_stats`).

## Chaque nuit (22 h 00 UTC, tâche `clikea-nightly`)

`clikea_nightly()` : Elo sur les nouvelles réponses → recalage des gammes jamais jouées → `ref_theta` mis à jour → grilles futures `auto` supprimées et retirées sur 7 jours (la grille du jour et les grilles `manual` ne bougent pas). Le calibrage se voit donc dès le lendemain.

## Mode calibrage (équipe)

`https://clikeagame.com/?calibrage=1` : photo, nom, type ; « Je connais » / « Je ne connais pas » au premier réflexe ; « Signaler et passer » (trop niche, photo, type faux → `clikea_flags`). Les gammes les moins mesurées passent en premier. Réponses enregistrées en `source = 'calib'` : hors classement, hors série, mais elles alimentent la difficulté. Outil interne, en français seulement.

## Réglages (`clikea_settings`, modifiables sans republier)

`free_conf_min` 0,85 · `free_zone_min` 0,50 · `free_share_conf` 0,25 · `free_share_defi` 0,15 · `free_explore` 0,10 · `free_session_step` 0,15 · `free_repeat_days` 3 · `calibrated_min` 8 · `daily_b1` 0,85 · `daily_b2` 0,60 · `daily_b3` 0,45 · `daily_b4` 0,30 · `daily_target_score` 28 · `ref_theta` (nuit).

Le jeu charge réglages et difficultés au démarrage (`clikea_settings`, `rpc/clikea_difficulties`) ; sans réseau, il garde les valeurs embarquées.

## Suivre et régler

```sql
select * from clikea_daily_stats order by day desc limit 14;          -- répartition des scores du jour
select * from clikea_product_stats where answers >= 10 order by pct_correct;  -- produits trop durs
select product, reason, count(*) from clikea_flags group by 1, 2 order by 3 desc;  -- signalements
select public.clikea_nightly();                                        -- relancer le calibrage à la main
```

- Score moyen du jour sous 22 / 50 plusieurs jours de suite → relever `daily_b2` et `daily_b3` (les places choisissent des produits plus faciles). Au-dessus de 34 → les baisser.
- Un produit signalé « trop niche » par deux personnes : `update clikea_families set playable = false where name = '…'`.

## Limites connues

- Tant que peu de gammes sont mesurées, les places « zone » du 10 du jour reposent sur la difficulté de départ recalée : des noms peu connus peuvent encore passer. Le mode calibrage accélère la sortie de cette phase.
- Le niveau du joueur vit sur l'appareil : il repart de `ref_theta` sur un nouvel appareil.
