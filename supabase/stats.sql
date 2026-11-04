-- Last Brick: visit counter and the private Stats page.
-- Paste this whole file into Supabase → SQL Editor → New query, then press Run.

-- 1. Visits: one row per device per day the app is opened. No IP address, no
--    account, nothing that identifies a person: just the day, three yes/no
--    answers (first time on this device? logged in? installed on the home screen?)
--    and where the visitor came from (a website name like "facebook.com", or a
--    tag from the link such as lastbrick.co.uk/?ref=reddit).
create table if not exists public.visits (
  id bigint generated always as identity primary key,
  day date not null default current_date,
  new_visitor boolean not null default false,
  has_account boolean not null default false,
  installed boolean not null default false
);
alter table public.visits add column if not exists source text check (length(source) <= 60);
alter table public.visits enable row level security;

drop policy if exists "Anyone can count a visit" on public.visits;
create policy "Anyone can count a visit" on public.visits
  for insert to anon, authenticated
  with check (day = current_date);

-- 1b. Steps: where new visitors stop. One row each time a device reaches a step
--     for the first time (visited, started, added a first item, saw the account
--     screen, tapped Create account, registered, confirmed their email), with
--     the link it first came from. No account, no IP, nothing identifying.
create table if not exists public.funnel (
  id bigint generated always as identity primary key,
  day date not null default current_date,
  step text not null,
  source text check (length(source) <= 60)
);
-- The steps that can be counted (updated when a new one is added, e.g. 'demo').
alter table public.funnel drop constraint if exists funnel_step_check;
alter table public.funnel add constraint funnel_step_check
  check (step in ('visit', 'start', 'tap_fig', 'tap_set', 'how', 'how_start', 'scan', 'demo', 'first_item', 'first_prompt', 'first_prompt_create', 'first_prompt_later', 'first_prompt_registered', 'gate', 'register_start', 'registered', 'confirmed'));
alter table public.funnel enable row level security;

drop policy if exists "Anyone can count a step" on public.funnel;
create policy "Anyone can count a step" on public.funnel
  for insert to anon, authenticated
  with check (day = current_date);

-- 2. Who can see the Stats page. Only accounts listed here.
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);
alter table public.admins enable row level security; -- no policies: not readable from the app

-- Tracey's account (from the first problem report).
insert into public.admins (user_id) values ('914fdbbc-5368-4e91-9346-1b089e4ae2c5')
on conflict do nothing;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- 3. Everything the Stats page shows, in one go, for a period: 'today',
-- 'yesterday', '7' (days), '30' (days, the default) or 'all'. Refuses anyone
-- not in admins. (Days are UTC, like the visit and step counts.)
drop function if exists public.admin_stats();
create or replace function public.admin_stats(period text default '30')
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
  d_to date := current_date;
  d_from date;
  t_from timestamptz;
  t_to timestamptz;
  chart_from date;
begin
  if not exists (select 1 from public.admins where user_id = auth.uid()) then
    raise exception 'Not allowed';
  end if;

  d_from := case period
    when 'today' then current_date
    when 'yesterday' then current_date - 1
    when '7' then current_date - 6
    when 'all' then date '2000-01-01'
    else current_date - 29 end;
  if period = 'yesterday' then d_to := current_date - 1; end if;
  t_from := d_from::timestamptz;
  t_to := (d_to + 1)::timestamptz;
  -- Visitors-per-day chart: the last 30 days, or every day since the first visit.
  chart_from := case when period = 'all'
    then greatest(coalesce((select min(day) from public.visits), current_date), current_date - 400)
    else current_date - 29 end;

  with items as (
    select d.user_id, s.key as num, s.value as item,
           case when jsonb_typeof(s.value->'addedAt') = 'number'
                then to_timestamp((s.value->>'addedAt')::numeric / 1000) end as added
    from public.user_data d
    cross join lateral jsonb_each(coalesce(d.data->'sets', '{}'::jsonb)) s
  ),
  -- Sets and minifigures added in the period (everything, for 'all').
  items_p as (
    select * from items where period = 'all' or (added >= t_from and added < t_to)
  ),
  per_item as (
    select i.user_id, i.num, i.item->>'name' as name, coalesce(i.item->>'img', '') as img,
           i.num like 'fig-%' as is_fig,
           coalesce(sum((p->>'qty')::int), 0) as need,
           coalesce(sum(least((p->>'have')::int, (p->>'qty')::int)), 0) as have,
           case when jsonb_typeof(i.item->'value') = 'number' then (i.item->>'value')::numeric end as value
    from items_p i
    left join lateral jsonb_array_elements(coalesce(i.item->'parts', '[]'::jsonb)) p on true
    group by i.user_id, i.num, i.item
  ),
  missing as (
    select p->>'key' as key, max(p->>'name') as name, max(p->>'colorName') as colour,
           max(p->>'img') as img, sum((p->>'qty')::int - least((p->>'have')::int, (p->>'qty')::int)) as missing,
           count(distinct i.user_id) as people
    from items_p i
    cross join lateral jsonb_array_elements(coalesce(i.item->'parts', '[]'::jsonb)) p
    where (p->>'have')::int < (p->>'qty')::int
    group by p->>'key'
  ),
  v as (select * from public.visits where day between d_from and d_to),
  f as (select * from public.funnel where day between d_from and d_to)
  select jsonb_build_object(
    'period', period,
    'visits', jsonb_build_object(
      'total', (select count(*) from v),
      'new', (select count(*) from v where new_visitor),
      'installed', (select count(*) from v where installed),
      'sources', (select coalesce(jsonb_agg(t), '[]') from (
        select coalesce(nullif(source, ''), 'direct') as source, count(*) as visits,
               count(*) filter (where new_visitor) as new_visitors
        from v group by 1 order by count(*) desc limit 40) t),
      'byDay', (select jsonb_agg(jsonb_build_array(g.d, coalesce(x.n, 0)) order by g.d)
                from generate_series(chart_from, current_date, interval '1 day') g(d)
                left join (select day, count(*) n from public.visits group by day) x on x.day = g.d::date),
      -- Still sent for older versions of the app:
      'today', (select count(*) from public.visits where day = current_date),
      'week', (select count(*) from public.visits where day > current_date - 7),
      'month', (select count(*) from public.visits where day > current_date - 30),
      'newMonth', (select count(*) from public.visits where day > current_date - 30 and new_visitor),
      'installedMonth', (select count(*) from public.visits where day > current_date - 30 and installed)
    ),
    'accounts', jsonb_build_object(
      'total', (select count(*) from auth.users),
      'new', (select count(*) from auth.users where created_at >= t_from and created_at < t_to),
      'active', (select count(*) from auth.users u where (u.last_sign_in_at >= t_from and u.last_sign_in_at < t_to)
                   or exists (select 1 from public.user_data d where d.user_id = u.id and d.updated_at >= t_from and d.updated_at < t_to)),
      'unconfirmed', (select count(*) from auth.users where email_confirmed_at is null and created_at >= t_from and created_at < t_to),
      -- Who hasn't confirmed yet, so you can get in touch (only you can see this page).
      'unconfirmedList', (select coalesce(jsonb_agg(t), '[]') from (
        select email, created_at from auth.users
        where email_confirmed_at is null and created_at >= t_from and created_at < t_to
        order by created_at desc limit 50) t),
      'byWeek', (select jsonb_agg(jsonb_build_array(g.w, coalesce(a.n, 0)) order by g.w)
                 from generate_series(
                   case when period = 'all'
                     then greatest(date_trunc('week', coalesce((select min(created_at) from auth.users), now())), date_trunc('week', now()) - interval '103 weeks')
                     else date_trunc('week', now()) - interval '11 weeks' end,
                   date_trunc('week', now()), interval '1 week') g(w)
                 left join (select date_trunc('week', created_at) w, count(*) n from auth.users group by 1) a on a.w = g.w),
      'week', (select count(*) from auth.users where created_at > now() - interval '7 days'),
      'activeWeek', (select count(*) from auth.users u where u.last_sign_in_at > now() - interval '7 days'
                       or exists (select 1 from public.user_data d where d.user_id = u.id and d.updated_at > now() - interval '7 days'))
    ),
    'collections', jsonb_build_object(
      'people', (select count(distinct user_id) from per_item),
      'sets', (select count(*) from per_item where not is_fig),
      'figs', (select count(*) from per_item where is_fig),
      'need', (select coalesce(sum(need), 0) from per_item),
      'have', (select coalesce(sum(have), 0) from per_item),
      'complete', (select count(*) from per_item where not is_fig and need > 0 and have >= need),
      'value', (select coalesce(sum(value), 0) from per_item),
      'lookedUp', (select count(*) from public.set_cache where key like 'set:%' and (period = 'all' or (fetched_at >= t_from and fetched_at < t_to))),
      'figsLookedUp', (select count(*) from public.set_cache where key like 'fig2:%' and (period = 'all' or (fetched_at >= t_from and fetched_at < t_to)))
    ),
    'topSets', (select coalesce(jsonb_agg(t), '[]') from (
      select num, max(name) as name, max(img) as img, count(*) as people
      from per_item where not is_fig group by num order by count(*) desc, max(name) limit 10) t),
    'topFigs', (select coalesce(jsonb_agg(t), '[]') from (
      select num, max(name) as name, max(img) as img, count(*) as people
      from per_item where is_fig group by num order by count(*) desc, max(name) limit 10) t),
    'mostMissing', (select coalesce(jsonb_agg(t), '[]') from (
      select key, name, colour, img, missing, people from missing order by people desc, missing desc limit 10) t),
    'funnel', jsonb_build_object(
      'counts', (select coalesce(jsonb_object_agg(step, n), '{}') from (
        select step, count(*) as n from f group by step) t),
      'bySource', (select coalesce(jsonb_agg(t), '[]') from (
        select coalesce(nullif(source, ''), 'unknown') as source,
               count(*) filter (where step = 'visit') as visit,
               count(*) filter (where step = 'first_item') as first_item,
               count(*) filter (where step = 'registered') as registered
        from f group by 1 order by 2 desc limit 40) t),
      'days2', (select coalesce(jsonb_object_agg(step, n), '{}') from (
        select step, count(*) as n from public.funnel where day >= current_date - 1 group by step) t),
      'week', (select coalesce(jsonb_object_agg(step, n), '{}') from (
        select step, count(*) as n from public.funnel where day > current_date - 7 group by step) t)
    ),
    'reports', jsonb_build_object(
      'total', (select count(*) from public.reports),
      'inPeriod', (select count(*) from public.reports where created_at >= t_from and created_at < t_to),
      'week', (select count(*) from public.reports where created_at > now() - interval '7 days'),
      'recent', (select coalesce(jsonb_agg(t), '[]') from (
        select created_at, kind, message, contact is not null as wants_reply
        from public.reports where created_at >= t_from and created_at < t_to
        order by id desc limit 20) t)
    )
  ) into result;
  return result;
end;
$$;

revoke execute on function public.admin_stats(text) from public, anon;
grant execute on function public.admin_stats(text) to authenticated;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;
