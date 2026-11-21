# Pourquoi CLIKEA

Ce document répond à trois questions : quel problème le jeu règle, à quoi ressemble la réussite, et pourquoi le jeu est fait comme il est. Il sert de référence quand une décision de design ou de contenu est ambiguë.

## Le problème

Tout le monde connaît les noms IKEA, presque personne ne sait qu'il les connaît. C'est un savoir de salon, drôle à exhiber, et honteux à rater. Les jeux qui marchent sur les réseaux reposent sur ce type de savoir partagé : un drapeau pour Worldle, un logo pour Logoquiz, une commune pour Metrodoku, un mot pour Wordle. CLIKEA prend le catalogue IKEA comme terrain de jeu.

Deuxième problème, plus pratique : la plupart des jeux de connaissance en ligne demandent un compte, une installation ou une explication. CLIKEA doit se comprendre et se jouer sans rien expliquer.

## L'objectif

**Faire de CLIKEA un jeu qui circule seul**, c'est-à-dire dont les joueurs amènent les joueurs, sans budget publicitaire.

Objectif de moyen terme : un jeu identifiable en une image (« le jeu des noms IKEA »), jouable en trois minutes sur téléphone, dont le ticket de score donne envie de défier quelqu'un.

Ce que ça implique concrètement :

- **Une partie courte et complète** : 20 produits, un score sur 100, une fin nette.
- **Aucune friction d'entrée** : pas de compte, pas d'e-mail, pas d'installation. Un pseudo suffit, et il est facultatif pour jouer — il ne sert qu'au classement.
- **Un objet partageable** : le ticket de fin est une image autonome, lisible hors contexte, avec le nom du jeu et l'URL. C'est le vecteur d'acquisition principal.
- **Un mobile d'abord** : le jeu doit tenir à l'écran d'un téléphone sans défilement, parce que c'est là qu'il sera ouvert depuis un post.

## Le public

- **Cœur de cible** : 18-35 ans, France, à l'aise avec X, TikTok et les jeux de saga quotidienne (Wordle, SUTOM, Cémantix).
- **Cible secondaire** : public international anglophone et hispanophone, d'où les cinq langues.
- **Non-cible** : acheteurs IKEA cherchant un produit, ou joueurs cherchant un jeu long et profond. Le jeu n'est ni un catalogue ni un jeu de gestion.

## Comment on saura que ça marche

Les événements PostHog permettent de suivre l'entonnoir suivant :

1. `clikea_view` → visiteurs.
2. `clikea_game_started` → taux de démarrage (objectif : la majorité des visiteurs lance une partie).
3. `clikea_game_finished` → taux de parties terminées (le principal signal de qualité perçue).
4. `clikea_share` / `clikea_share_sheet` → taux de partage par partie terminée.
5. Visiteurs entrants avec `referrer` ou paramètre de campagne → coefficient viral (combien de nouveaux joueurs par partie partagée).

Aucun objectif chiffré n'a été fixé à ce jour. La première étape est d'avoir une base de référence propre sur ces cinq indicateurs, puis de se fixer une cible sur le taux de parties terminées et le taux de partage.

## Principes de conception

Ces principes viennent des décisions prises pendant la construction ; ils ne sont pas théoriques.

1. **Un jeu se reconnaît avant de s'expliquer.** Le mot « jeu » apparaît dès la première ligne, le bouton principal dit « Jouer », et aucun vocabulaire de boutique n'apparaît avant la partie. Une version antérieure parlait « d'achats » et de « ticket de caisse » dès l'accueil : elle a été corrigée parce qu'elle faisait croire à une boutique.
2. **Un seul bouton principal par écran.** Après une réponse, un seul bouton : « Produit suivant », puis « Voir mon score » sur la dernière question. Le bouton « Voir le ticket » en cours de partie a été supprimé : on va au bout des 20.
3. **Le verdict se lit d'un coup d'œil.** Photo entourée en vert si la réponse est juste, en rouge sinon ; tampon incliné « Bonne réponse / La réponse / Temps écoulé ».
4. **Rien d'inventé.** La fiche produit n'affiche que le nom, le type, le prix et, quand il existe, un fait vérifié (« Le saviez-vous ? »). Un fait non vérifié est omis.
5. **Le mobile est la contrainte, pas une adaptation.** Tout le parcours est contrôlé à 390 px de large sur 844, 700 et 620 px de haut, sans défilement ni débordement latéral.
6. **Le score doit être honnête.** Barème affiché avant la partie (1 / 3 / 5 points), temps écoulé compté comme une erreur, score nul non envoyé au classement.
7. **Pas de friction technique.** Une seule page, aucune dépendance, aucun build, aucun cookie publicitaire.
8. **Le pastiche est assumé mais discret.** Le jeu n'est pas officiel et ne le prétend pas ; la mention a été retirée de l'écran de jeu pour ne pas alourdir le parcours, et figure dans ce dépôt.

## Non-objectifs

- **Pas de monétisation** : ni publicité, ni affiliation, ni vente. Cela protège l'expérience et limite le risque vis-à-vis de la marque.
- **Pas de compte utilisateur** : pas de profil, pas de mot de passe, pas de série persistante entre appareils.
- **Pas de partie quotidienne verrouillée** : on peut rejouer autant de fois qu'on veut (le format Wordle « une partie par jour » n'a pas été retenu à ce stade).
- **Pas d'application native** : le web mobile suffit.
- **Pas de logique de jeu côté serveur** : le classement est un simple dépôt de scores, sans anti-triche.

## Journal des décisions

Toutes les entrées datent du 21 novembre 2026, jour de construction du jeu.

| Décision | Raison |
|---|---|
| Base de 109 produits, photos et prix du catalogue français | Assez large pour que deux parties ne se ressemblent pas. |
| Deux niveaux seulement (49 cultes / 60 autres) | Un troisième niveau « moyen » compliquait le choix sans changer le plaisir. |
| Trois modes disponibles dans les deux niveaux | Seuls les produits changent : le barème reste comparable. |
| Chrono de 10 s en Duo et Carré, aucun en Cash | En Cash on écrit le nom ; un chrono aurait puni la frappe, pas la connaissance. |
| Ticket de fin coloré, sans imprimante | L'animation d'imprimante a été essayée puis retirée : plus lourde, moins « putaclic » que le ticket coloré avec tampon. |
| Logo CLIKEA permanent pendant la partie, monochrome sur le ticket | Reconnaissance de marque à chaque écran, sans surcharger. |
| Domaine `clikeagame.com` plutôt que `clikea.eu` | `clikea.fr` et `clikea.com` appartiennent à une société existante (CLIKEA 360°) ; un TLD proche du nom exposait à une confusion et à une plainte. |
| Sous-domaine `clikea.js.org` abandonné | Demande refusée par les mainteneurs de js.org : les sous-domaines sont réservés aux projets dont JavaScript est le sujet. Le `CNAME` a été retiré. |
| Compte X `@clikeagame` | `@clikea` était pris. Le nom du domaine et le handle sont alignés. |

## Risques identifiés

- **Marque** : pastiche d'une marque déposée. Le jeu est gratuit, non officiel, sans utilisation du logo officiel ; le risque de demande de retrait reste non nul. Précédent documenté : IKEA a fait envoyer une mise en demeure à un jeu vidéo nommé « STYR », sans le mot IKEA, en invoquant l'enseigne bleu-jaune, le nom scandinave et les sols gris, avec 10 jours pour retirer les signes (2022). Détail dans [`VIRALITE.md`](VIRALITE.md#marque--le-risque-est-documenté-pas-théorique).
- **Dépendance aux images IKEA** : les photos sont liées au CDN d'ikea.com, sans copie locale.
- **Classement non modéré** : pseudo libre, score forgeable avec la clé publique.
- **Documentation de déploiement incomplète** : la commande de republication du miroir here.now n'est pas consignée.
