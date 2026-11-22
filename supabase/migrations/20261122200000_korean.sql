-- Coréen : langue acceptée partout, type coréen de chaque article.
alter table public.clikea_articles add column type_ko text;
alter table public.clikea_scores drop constraint clikea_scores_lang_check;
alter table public.clikea_scores add constraint clikea_scores_lang_check check (lang in ('fr','en','es','de','it','ko'));
alter table public.clikea_daily_scores drop constraint clikea_daily_scores_lang_check;
alter table public.clikea_daily_scores add constraint clikea_daily_scores_lang_check check (lang in ('fr','en','es','de','it','ko'));
alter table public.clikea_answers drop constraint clikea_answers_lang_check;
alter table public.clikea_answers add constraint clikea_answers_lang_check check (lang in ('fr','en','es','de','it','ko'));
