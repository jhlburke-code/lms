-- LMS RLS policies
-- Per projects/lms/_index.md §1 (data model)
-- Admin bootstrapped by email match (no chicken-and-egg with roles column).

-- Helper: is_admin() reads the JWT and matches email.
create or replace function public.LMS_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (auth.jwt() ->> 'email') in ('jhl.burke@gmail.com'),
    false
  );
$$;

-- ============================================================
-- LMS_profiles
-- ============================================================
alter table public.LMS_profiles enable row level security;

drop policy if exists LMS_profiles_select_self on public.LMS_profiles;
create policy LMS_profiles_select_self on public.LMS_profiles
  for select using (user_id = auth.uid() or LMS_is_admin());

drop policy if exists LMS_profiles_select_basic on public.LMS_profiles;
-- Authenticated users can read basic profile info of others (for "instructor X teaches Y").
create policy LMS_profiles_select_basic on public.LMS_profiles
  for select to authenticated using (true);

drop policy if exists LMS_profiles_update_self on public.LMS_profiles;
create policy LMS_profiles_update_self on public.LMS_profiles
  for update using (user_id = auth.uid() or LMS_is_admin())
  with check (user_id = auth.uid() or LMS_is_admin());

-- INSERT via trigger only; service_role can bypass.

-- ============================================================
-- LMS_courses
-- ============================================================
alter table public.LMS_courses enable row level security;

drop policy if exists LMS_courses_select_public on public.LMS_courses;
create policy LMS_courses_select_public on public.LMS_courses
  for select using (is_published = true or LMS_is_admin());

drop policy if exists LMS_courses_admin_write on public.LMS_courses;
create policy LMS_courses_admin_write on public.LMS_courses
  for all using (LMS_is_admin()) with check (LMS_is_admin());

-- ============================================================
-- LMS_workshops
-- ============================================================
alter table public.LMS_workshops enable row level security;

drop policy if exists LMS_workshops_select_public on public.LMS_workshops;
create policy LMS_workshops_select_public on public.LMS_workshops
  for select using (
    exists (select 1 from public.LMS_courses c where c.id = course_id and (c.is_published = true or LMS_is_admin()))
  );

drop policy if exists LMS_workshops_admin_write on public.LMS_workshops;
create policy LMS_workshops_admin_write on public.LMS_workshops
  for all using (LMS_is_admin()) with check (LMS_is_admin());

-- ============================================================
-- LMS_enrollments
-- ============================================================
alter table public.LMS_enrollments enable row level security;

drop policy if exists LMS_enrollments_select_self on public.LMS_enrollments;
create policy LMS_enrollments_select_self on public.LMS_enrollments
  for select using (user_id = auth.uid() or LMS_is_admin());

drop policy if exists LMS_enrollments_insert_self on public.LMS_enrollments;
create policy LMS_enrollments_insert_self on public.LMS_enrollments
  for insert with check (
    (user_id = auth.uid() and enrolled_by is null) or LMS_is_admin()
  );

drop policy if exists LMS_enrollments_update_self on public.LMS_enrollments;
create policy LMS_enrollments_update_self on public.LMS_enrollments
  for update using (user_id = auth.uid() or LMS_is_admin())
  with check (user_id = auth.uid() or LMS_is_admin());

drop policy if exists LMS_enrollments_delete_self on public.LMS_enrollments;
create policy LMS_enrollments_delete_self on public.LMS_enrollments
  for delete using (user_id = auth.uid() or LMS_is_admin());

-- ============================================================
-- LMS_completions
-- ============================================================
alter table public.LMS_completions enable row level security;

drop policy if exists LMS_completions_select_self on public.LMS_completions;
create policy LMS_completions_select_self on public.LMS_completions
  for select using (user_id = auth.uid() or LMS_is_admin());

drop policy if exists LMS_completions_insert_any_user on public.LMS_completions;
create policy LMS_completions_insert_any_user on public.LMS_completions
  for insert with check (user_id = auth.uid());

drop policy if exists LMS_completions_admin_write on public.LMS_completions;
create policy LMS_completions_admin_write on public.LMS_completions
  for all using (LMS_is_admin()) with check (LMS_is_admin());

-- ============================================================
-- LMS_notification_queue
-- ============================================================
alter table public.LMS_notification_queue enable row level security;

drop policy if exists LMS_notification_admin_only on public.LMS_notification_queue;
create policy LMS_notification_admin_only on public.LMS_notification_queue
  for all using (LMS_is_admin()) with check (LMS_is_admin());

-- ============================================================
-- Supabase Storage bucket (if it doesn't exist)
-- ============================================================
insert into storage.buckets (id, name, public)
values ('lms-assets', 'lms-assets', false)
on conflict (id) do nothing;
