-- LMS v1 schema
-- Per projects/lms/_index.md §1 (data model)
-- Owner: operator (jhl.burke@gmail.com)
-- Reuses existing Supabase project axwipqlykysnxudnejvi.

-- 1. Profiles
create table if not exists public.LMS_profiles (
  user_id      uuid primary key references auth.users on delete cascade,
  full_name    text,
  company      text,
  role         text not null default 'learner' check (role in ('learner','instructor','admin')),
  tz           text default 'UTC',
  created_at   timestamptz not null default now()
);

-- Auto-create profile on signup
create or replace function public.LMS_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.LMS_profiles (user_id, full_name, company)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'company'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists LMS_on_auth_user_created on auth.users;
create trigger LMS_on_auth_user_created
  after insert on auth.users
  for each row execute function public.LMS_handle_new_user();

-- 2. Courses
create table if not exists public.LMS_courses (
  id               uuid primary key default gen_random_uuid(),
  slug             text unique not null,
  title            text not null,
  description      text,
  content_type     text not null check (content_type in ('elearning','pdf','youtube','workshop')),
  asset_url        text,
  widget_key       text,
  duration_minutes int,
  is_published     boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index if not exists LMS_courses_published_idx on public.LMS_courses (is_published, created_at desc);

-- 3. Workshops (extends courses for scheduled events)
create table if not exists public.LMS_workshops (
  course_id        uuid primary key references public.LMS_courses on delete cascade,
  starts_at        timestamptz not null,
  ends_at          timestamptz not null,
  capacity         int,
  meeting_url      text,
  recording_url    text,
  instructor_id    uuid references public.LMS_profiles,
  -- per-workshop reminder preferences
  remind_24h       boolean not null default true,
  remind_1h        boolean not null default true,
  remind_15m       boolean not null default false
);
create index if not exists LMS_workshops_starts_idx on public.LMS_workshops (starts_at);

-- 4. Enrollments
create table if not exists public.LMS_enrollments (
  user_id      uuid not null references public.LMS_profiles on delete cascade,
  course_id    uuid not null references public.LMS_courses on delete cascade,
  enrolled_at  timestamptz not null default now(),
  enrolled_by  uuid references public.LMS_profiles,
  status       text not null default 'active' check (status in ('active','completed','withdrawn')),
  primary key (user_id, course_id)
);
create index if not exists LMS_enrollments_user_idx on public.LMS_enrollments (user_id, enrolled_at desc);
create index if not exists LMS_enrollments_course_idx on public.LMS_enrollments (course_id);

-- 5. Completions (one row per user×course)
create table if not exists public.LMS_completions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.LMS_profiles on delete cascade,
  course_id           uuid not null references public.LMS_courses on delete cascade,
  completed_at        timestamptz not null default now(),
  completion_method   text not null,
  certificate_url     text,
  unique (user_id, course_id)
);
create index if not exists LMS_completions_user_idx on public.LMS_completions (user_id, completed_at desc);

-- 6. Notification queue
create table if not exists public.LMS_notification_queue (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.LMS_profiles on delete cascade,
  template    text not null,
  payload     jsonb not null default '{}'::jsonb,
  send_at     timestamptz not null default now(),
  sent_at     timestamptz,
  resend_id   text,
  error       text,
  attempts    int not null default 0
);
create index if not exists LMS_notif_pending_idx on public.LMS_notification_queue (send_at) where sent_at is null;
