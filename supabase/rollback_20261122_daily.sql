-- Annule la migration 20261122120000_daily.sql (les données du 10 du jour sont perdues).
select cron.unschedule('clikea-plan-days');
drop view if exists public.clikea_product_stats;
drop function if exists public.clikea_plan_days(integer);
drop function if exists public.clikea_daily_set_name(date, text, text);
drop table if exists public.clikea_answers;
drop table if exists public.clikea_daily_scores;
drop table if exists public.clikea_daily_grid;
drop table if exists public.clikea_products;
