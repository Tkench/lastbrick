-- Last Brick: one reminder email for people who signed up but haven't
-- confirmed their email.
--
-- Once an hour, anyone who signed up between 1 and 7 days ago and still
-- hasn't confirmed gets the "Confirm your email" email sent again, once.
-- It uses Supabase's own "resend" (the same as the Resend buttons in the
-- app), so it goes through Brevo with the branded template, and the new
-- link works even if the first one has expired.
--
-- Run it once in Supabase → SQL Editor. Safe to run again.
-- To stop the reminders:  select cron.unschedule('confirm-reminder');

create extension if not exists pg_cron;
create extension if not exists pg_net with schema extensions;

-- Who has been reminded, so nobody gets more than one.
create table if not exists public.confirm_reminders (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  sent_at timestamptz not null default now()
);
alter table public.confirm_reminders enable row level security; -- not readable from the app

create or replace function public.send_confirm_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  u record;
  n integer := 0;
begin
  for u in
    select id, email
    from auth.users
    where email_confirmed_at is null
      and email is not null
      and created_at < now() - interval '1 day'
      and created_at > now() - interval '7 days'
      and id not in (select user_id from public.confirm_reminders)
    order by created_at
    limit 20 -- a few at a time, well inside the email limits
  loop
    perform net.http_post(
      url := 'https://nioytuzuejdzznaxvlic.supabase.co/auth/v1/resend?redirect_to=' || 'https%3A%2F%2Flastbrick.co.uk%2F',
      body := jsonb_build_object('type', 'signup', 'email', u.email),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'apikey', 'sb_publishable_vWTdvZvwYgGsKhE0m7DbPg_MP_UbMqr'
      )
    );
    insert into public.confirm_reminders (user_id, email) values (u.id, u.email)
      on conflict do nothing;
    n := n + 1;
  end loop;
  return n;
end;
$$;

revoke execute on function public.send_confirm_reminders() from public, anon, authenticated;

-- Every hour, at 17 minutes past.
select cron.unschedule('confirm-reminder')
  where exists (select 1 from cron.job where jobname = 'confirm-reminder');
select cron.schedule('confirm-reminder', '17 * * * *', $$select public.send_confirm_reminders()$$);
