# Modes de jeu et récurrence

Document de conception. Il répond à une seule question : **quels modes donnent envie de revenir et de défier quelqu'un**, sans casser la promesse « une photo, dix secondes, un nom ».

**Version partageable (pour Ben)** : https://vast-serenity-zg6e.here.now/ — recherche, recommandation et maquette cliquable du 5 du jour.

## 0. La règle de simplicité

**Un joueur ne doit jamais avoir à choisir un mode avant de jouer.**

Ce que font les jeux qui marchent :

- **Métrodoku** : une seule grille du jour, un score, des archives. Aucun sélecteur de mode, aucun niveau. C'est le jeu français de référence et il tourne à ~30 000 joueurs quotidiens.
- **Wordle** : un seul mode, une grille par jour. Le « mode difficile » est une option cachée dans les réglages, pas une porte d'entrée.
- **SUTOM, Cémantix** : une grille, un mot, pas de menu.

À l'inverse, GeoGuessr propose Duels, Battle Royale, Streaks, Tournois… mais c'est un jeu installé depuis 2013, avec une équipe et une scène compétitive. Ce n'est pas le modèle d'un jeu solo à un fichier.

**La psychologie du choix va dans le même sens, avec une nuance.** Le phénomène de surcharge de choix existe surtout quand les options sont équivalentes et que la personne découvre le produit ; il disparaît quand elle a une préférence claire ou de l'expérience ([Wikipédia, Overchoice](https://en.wikipedia.org/wiki/Overchoice)). La méta-analyse de Scheibehenne et al. (2010) trouve un effet moyen proche de zéro : **ce n'est donc pas une preuve, juste un argument de prudence.** Le vrai argument est produit : chaque mode ajoute une décision, un écran, un barème et une maintenance, et dilue le seul objet qui circule — le score.

**Conséquence pour CLIKEA** : une seule nouveauté visible à la fois. Le reste attend les chiffres.

## 1. Ce que la recherche dit des modes


- **Le rendez-vous quotidien est le moteur de retour documenté.** Wordle : une grille par jour, identique pour tous, 90 joueurs en novembre 2021 puis plus de 2 millions en janvier 2022. Métrodoku : une grille du jour, 1 000 joueurs après une semaine, ~30 000 joueurs quotidiens un mois plus tard.
- **Le duel est un format éprouvé, pas un canal de décollage prouvé.** GeoGuessr propose des Duels, des Team Duels, un Battle Royale et des séries « jusqu'à l'erreur » ([Wikipédia, GeoGuessr](https://en.wikipedia.org/wiki/GeoGuessr)). Aucune source publique ne mesure la part d'acquisition venue des duels.
- **La série « jusqu'à l'échec » est un format de comparaison simple** : un seul chiffre à montrer (« étage 14 », « 23 d'affilée »). C'est ce qui rend un score citable.
- **Le chrono produit du contenu vidéo.** Une partie de 60 s se filme et se commente ; une partie de 20 questions beaucoup moins.
- **Un mode = un chiffre partageable.** Dès qu'un mode n'a pas de score court à montrer, il n'aide pas la viralité, même s'il est amusant.

## 2. Deux modes, deux réserves

**À sortir** : le 5 du jour, puis le duel **comme action de partage** (pas comme entrée de menu).
**En réserve** : le chrono 60 et la virée. Ils ne sortent que si le quotidien tient ses chiffres.

### A. Le 5 du jour — la récurrence

**Règle.** Cinq produits, même tirage pour tout le monde, une seule partie par jour et par appareil. Cinq questions en Carré (4 noms), 3 points chacune : **score sur 15**. Pas de choix de mode, pas de chrono, 60 à 90 secondes.

**Pourquoi.** C'est le format Wordle/Métrodoku : tout le monde parle de la même grille le même jour, et le résultat se partage en une ligne. C'est le seul mode qui crée une habitude.

**Partage.** `CLIKEA du jour 12/15` + cinq cases (🟩🟥) + `🔥 6 jours` + lien.

**Série.** Compter les **jours consécutifs joués**, pas les sans-faute : une série qui casse à la première erreur décourage. Afficher la série sur l'accueil et dans le partage.

**Écran « déjà joué ».** Résultat du jour, bouton de partage, compte à rebours avant la grille suivante, et lien vers la partie libre pour ceux qui veulent rejouer.

**Technique.** Tirage déterministe à partir de la date (générateur seedé), verrou local, aucune modification de la base.

**Risques.** Un jour sans grille se voit ; une grille trop dure fait chuter la série ; le tricheur peut lire le code (comme Wordle), ce n'est pas grave.

### B. Le duel — l'acquisition, mais pas un mode

**Ce n'est pas une entrée de menu.** C'est un bouton « Défier un ami » sur l'écran de fin, qui envoie la grille qu'on vient de jouer. Le destinataire n'a aucun mode à choisir : il clique, il joue la même grille.

**Règle.** Un joueur termine le 5 du jour (ou la partie libre), partage un lien. L'ami joue **exactement la même grille**, voit le score à battre, et le résultat final (gagné / perdu / égalité). Revanche en un clic, avec une nouvelle graine.

**Pourquoi.** C'est la boucle 1 → 1 la plus directe : chaque partie peut amener un joueur nommé, et le perdant a une raison de rejouer. Contrairement au partage de score, le destinataire ne peut pas tricher sur la comparaison.

**Partage.** Lien `?duel=<graine>&par=<pseudo>&score=<n>` et texte « César mène 12–9. Ta revanche ? ».

**Technique.** Même moteur de tirage seedé que le 5 du jour, graine dans l'URL, aucun serveur. Le score du créateur est dans l'URL : il est déclaratif, donc falsifiable. Acceptable pour un jeu gratuit ; limiter l'affichage à « défi amical ».

**Risques.** Sans compte, pas d'historique de duels ; un lien modifié peut annoncer un faux score.

### C. Le chrono 60 — en réserve

**Règle.** 60 secondes, autant de produits que possible, en Duo (2 noms) pour tenir le rythme. Une erreur ne retire pas de temps : elle coûte la seconde de réflexion. Score = nombre de bonnes réponses.

**Pourquoi.** Format court, spectaculaire, qui se filme. C'est le mode qui alimente TikTok et les Shorts : « 17 trouvés en 60 secondes ».

**Partage.** `CLIKEA Chrono · 17 en 60 s` + lien de défi.

**Risques.** La pression favorise les clics au hasard ; à surveiller sur le taux de bonnes réponses.

### D. La virée — en réserve

**Règle.** Une seule partie, **trois vies**. Les premiers produits viennent du vivier facile, puis le difficile. Chaque bonne réponse augmente un multiplicateur (×1 à ×5) ; une erreur retire une vie et remet le multiplicateur à ×1. La partie s'arrête à zéro vie. Score = total de points ; « étage » = nombre de produits passés.

**Pourquoi.** La progression et le risque créent une histoire (« je suis mort à l'étage 14 »). C'est le mode le plus rejouable et celui qui donne les meilleurs clips de fin.

**Partage.** `CLIKEA La virée · étage 14 · 86 pts` + lien.

**Risques.** Partie plus longue (3 à 6 minutes), courbe de difficulté à régler, frustration si les trois vies partent trop vite.

## 3. Les idées secondaires

| Idée | Intérêt | Verdict |
|---|---|---|
| **Vrai ou faux nom** (un nom réel contre un nom inventé) | Très bon format social, facile à produire en vidéo | À garder comme générateur de contenu, pas comme mode principal |
| **Le prix** (deviner le prix) | Family-friendly, autre promesse | Hors sujet : CLIKEA est le jeu des noms |
| **Photo inverse** (un nom, quatre photos) | Variété, plus facile | Bon mode bonus |
| **Pass the phone** (deux joueurs sur un téléphone) | Soirées, couples | Utile pour les clips, pas pour l'acquisition en ligne |
| **Boss final** (produit rare à 10 points) | Pimente la partie libre | À intégrer dans la virée |
| **Thème du jour** (cuisine, chambre, enfant) | Variété éditoriale | Plus tard, quand le quotidien tourne |

## 4. Ordre de construction

| Étape | Quoi | Pourquoi | Effort |
|---|---|---|---|
| 1 | **Le 5 du jour + la série** | Récurrence, partage quotidien | Moyen |
| 2 | **Le bouton « Défier »** (même grille, lien seedé) | Acquisition 1 → 1, réutilise le tirage | Faible à moyen |
| 3 | **Rien de nouveau** | Lire les chiffres du quotidien avant d'ajouter quoi que ce soit | — |
| Réserve | Chrono 60, virée, vrai/faux | Contenu et rejouabilité, seulement si le quotidien tient | Moyen |

**Règle d'écran** : la page d'accueil garde **un seul bouton principal**. Le 5 du jour est le bouton jaune ; « Partie libre (20 produits) » devient un lien secondaire. Aucun carrousel de modes.

**Règle de version** : une seule nouveauté visible par mise en ligne. Si le quotidien et le duel sortent en même temps, ils sortent comme **un seul parcours** : « joue la grille du jour, puis défie quelqu'un ».

Le 5 du jour et le duel partagent le même moteur : une graine, un tirage, un score. Les construire ensemble évite de coder deux fois la même chose.

## 5. Récurrence : les règles à tenir

1. **Une grille par jour, à minuit local.** Pas de compte : le verrou est local, donc contournable. Ce n'est pas un problème, c'est un jeu gratuit.
2. **La série se compte en jours joués.** Elle s'affiche sur l'accueil, sur l'écran de fin et dans le partage.
3. **Un seul rappel doux.** Écran « reviens demain » avec compte à rebours. Pas de notification push tant qu'il n'y a pas de service worker : une PWA ajouterait du poids et des permissions pour peu de joueurs au départ.
4. **Un rendez-vous éditorial.** Un post chaque matin avec la photo du jour, sans donner la réponse. C'est le rappel qui marche aujourd'hui.
5. **Un récap hebdomadaire.** « La grille la plus ratée de la semaine », « le meilleur temps » : matière à post et à conversation.

## 6. Ce que ça change techniquement

- **Générateur seedé** : un `mulberry32` et un mélange de Fisher-Yates remplacent `Math.random` pour les modes à graine. Le même seed doit produire le même tirage sur tous les appareils.
- **Paramètres d'URL** : `?jour=AAAA-MM-JJ`, `?duel=<seed>&par=&score=`.
- **Stockage local** : `clikea-daily` (date, score, grille), `clikea-streak` (jours, dernière date), `clikea-duel` (en cours).
- **Base Supabase** : ne pas envoyer les scores quotidiens au même classement que la partie libre, sinon les deux se mélangent. Soit un classement par mode (colonne `mode`), soit pas de classement pour le quotidien au début.
- **Analytics** : `clikea_daily_started`, `clikea_daily_finished`, `clikea_duel_created`, `clikea_duel_joined`, `clikea_streak`, `clikea_mode_selected`.

## 7. Décisions à prendre

- **Le 5 du jour remplace-t-il l'accueil, ou reste-t-il une carte à côté de « Partie libre » ?** Recommandation : le bouton principal, et la partie libre en lien secondaire.
- **Le duel se joue-t-il en 5 ou 10 produits ?** Recommandation : 5, et uniquement comme bouton « Défier » après une partie.
- **La virée a-t-elle 3 vies ou 1 seule ?** Recommandation : 3 vies, **plus tard**, si le quotidien marche.
- **Faut-il un classement par mode dès le départ ?** Recommandation : non. Un seul classement pour la partie libre, des scores locaux pour le quotidien tant qu'il n'a pas son public.
- **Combien de modes visibles au maximum ?** Recommandation : **deux** — « Le 5 du jour » et « Partie libre ». Le duel est un bouton, pas une case.
