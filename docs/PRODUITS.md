# Produits : catalogue, difficulté, recette du 10 du jour

Version partageable : https://rapid-reef-8rww.here.now/ — décisions du 22 novembre 2026.

## Principes décidés

- **Le jeu reste dur.** Il récompense ceux qui connaissent. Aucun objectif de taux de réussite tant que les données ne sont pas représentatives.
- **Les photos restent copiées** dans `img/` pour l'instant. Risque connu : les conditions d'utilisation d'IKEA interdisent la copie de leurs images. À revoir avant une forte audience.
- **Workflows LLM** : DeepSeek V4.1 Flash via OpenCode Go (`opencode run -m opencode-go/deepseek-v4.1-flash`), qui lit les images.

## Base en deux niveaux

- **Gamme** (BILLY) : la réponse. Porte le statut culte, la note de difficulté, les statistiques, le dernier passage et le nombre de passages.
- **Article** (BILLY bibliothèque blanche, n° d'article) : ce qu'on montre. Porte la photo, le type en 5 langues, le prix, la catégorie, le nombre d'avis et le badge Top seller.
- Corrige le défaut actuel : un nom recouvrait plusieurs articles, avec des types incohérents d'une langue à l'autre (HEMNES, MALM, SUNDVIK, DUKTIG, NORDVIKEN, KALAS).

## Catalogue source

- Listes de produits ikea.com (France, 22/11/2026) : 32 614 articles, 2 597 gammes, dont 1 136 n'ont qu'un article. Environ 1 200 à 1 500 gammes jouables après tri (estimation).
- Fiches : API de recherche d'ikea.com (nom, type traduit, prix, photo, catégorie, avis, Top seller, nouveauté).
- LLM seulement pour : écarter l'impossible à deviner, choisir la photo, regrouper les familles visuelles, proposer des fausses orthographes.
- Cultes : liste IKEA Icons et presse, validée à la main, environ 40 gammes.

## Difficulté

- Une note par gamme, modèle Elo pour QCM (Pelánek) : chance = hasard + (1 − hasard) × σ(niveau − difficulté), hasard = 1/2 en Duo, 1/4 en Carré, 0 en Cash.
- Seule la première exposition de chaque joueur compte. Temps écoulé = mauvaise réponse.
- Note de départ calculée à l'import (avis cumulés sur plusieurs pays, Top seller, culte), puis recalculée chaque nuit.

## Fraîcheur : statuts au jour J

| Statut | Définition |
|---|---|
| Inédit | jamais montré dans le 10 du jour |
| Rappel | montré une seule fois, il y a 3 à 7 jours |
| Revenant | dernier passage il y a au moins 21 jours |
| Culte | dans la liste des cultes |

## Recette : 3 inédits, 1 rappel, 4 revenants, 2 cultes

| # | Fraîcheur | Difficulté | Format |
|---|---|---|---|
| 1 | Culte | facile | photo ou orthographe |
| 2 | Revenant | facile | photo |
| 3 | Rappel | moyen | photo |
| 4 | Revenant | moyen | photo |
| 5 | Inédit | moyen | photo |
| 6 | Revenant | moyen | photo ou orthographe |
| 7 | Inédit | dur | photo |
| 8 | Revenant | dur | photo |
| 9 | Inédit piège | très dur | photo |
| 10 | Culte | facile | photo ou orthographe |

- Simulation sur 2 ans : les inédits tiennent 304 jours avec 1 000 gammes, 404 jours avec 1 300. Ensuite la recette glisse vers les revenants ; les nouveautés IKEA importées chaque mois remplissent le stock d'inédits.
- Au démarrage, sans historique, les places de rappel et de revenant sont remplies par des inédits.

## Plafonds

- Produit ordinaire : au plus 1 apparition par 7 jours, sauf le rappel ; au plus 10 apparitions sur la vie du jeu.
- Culte : au moins 10 jours entre deux passages (moyenne attendue : tous les 20 jours avec 40 cultes et 2 par jour).
- Revenant : au moins 21 jours d'écart, priorité aux plus ratés.
- Un seul piège par jour, au plus une question d'orthographe par jour.

## Format orthographe

- Le nom est évident, le piège est l'écriture : KALLAX, KALAX, CALLAX, KALLAKS. Duo = 2 orthographes, Carré = 4, Cash = saisie exacte sans tolérance.
- Surtout pour les cultes qui reviennent, et environ un revenant sur cinq.
- Variantes par règles (lettres doublées, K/C, Ä/A, Å/AA), complétées par le LLM ; toute variante qui est un vrai nom IKEA est écartée.

## Séries

- **En ligne** : série = jours joués d'affilée (pas gagnés), minuit heure de Paris, gardée sur l'appareil, affichée à l'accueil, sur le ticket et dans le partage.
- **À ajouter** : jours joués au total, meilleure série, paliers 7 / 30 / 100 jours.
- **À décider** : un joker par semaine qui protège la série d'un jour manqué.

## Ordre de construction

1. Restructurer la base, corriger les incohérences, brancher difficulté, statuts, plafonds et recette.
2. Skill d'import en masse (~1 300 gammes, ~40 cultes, difficultés de départ, familles visuelles, orthographes).
3. Format orthographe, jours joués au total, meilleure série, paliers.
4. Après deux semaines de données : régler recette et faux noms, fixer des objectifs de score.
