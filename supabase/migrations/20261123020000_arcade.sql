-- Record d'arcade : un seul classement de partie libre, sans plafond, avec multiplicateurs de rareté.
alter table public.clikea_scores drop constraint clikea_scores_difficulty_check;
alter table public.clikea_scores add constraint clikea_scores_difficulty_check check (difficulty in ('easy', 'hard', 'arcade'));
alter table public.clikea_scores drop constraint clikea_scores_score_check;
-- 20 produits × 15 points au plus = 300 ; marge pour un futur réglage des multiplicateurs.
alter table public.clikea_scores add constraint clikea_scores_score_check check (score between 0 and 600);
alter table public.clikea_answers drop constraint clikea_answers_difficulty_check;
alter table public.clikea_answers add constraint clikea_answers_difficulty_check check (difficulty in ('easy', 'hard', 'arcade'));
insert into public.clikea_settings (key, value, note) values
  ('rare_common', 0.6, 'Rareté : commun si un joueur moyen le trouve en Cash au moins 6 fois sur 10'),
  ('rare_rare', 0.3, 'Rareté : rare entre ce seuil et rare_common ; très rare en dessous'),
  ('pts_cash_rare', 10, 'Partie libre : points d''un Cash juste sur un produit rare (×2)'),
  ('pts_cash_very', 15, 'Partie libre : points d''un Cash juste sur un produit très rare (×3)'),
  ('pts_carre_rare', 4, 'Partie libre : points d''un Carré juste sur un produit rare'),
  ('pts_carre_very', 6, 'Partie libre : points d''un Carré juste sur un produit très rare (×2)')
on conflict (key) do nothing;
