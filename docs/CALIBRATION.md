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
