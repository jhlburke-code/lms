-- Demo seed for Phase 1 catalog visibility.
-- Production content lands via /admin/courses once that exists (Phase 3).
-- Safe to delete / never re-run idempotently.

insert into public.LMS_courses (slug, title, description, content_type, widget_key, asset_url, duration_minutes, is_published)
values
  (
    'change-management-v1',
    'Change Management Framework',
    'A 6-card interactive tour of how core organizational roles shift their focus during transformation.',
    'elearning',
    'tabbed-content',
    null,
    8,
    true
  ),
  (
    'ai-team-transformation-v1',
    'AI Team Transformation',
    'How roles, decisions, and trust shift when AI enters the team. Five short lessons.',
    'elearning',
    'ai-team-transformation',
    null,
    12,
    true
  ),
  (
    'compliance-refresher-2026',
    'Compliance Refresher 2026',
    'Annual compliance essentials. Read and confirm at the end.',
    'pdf',
    null,
    'https://elearning-test.jhl-burke.workers.dev/eLearning1.pdf',
    15,
    true
  ),
  (
    'intro-to-prompting',
    'Intro to Prompting',
    'Six-minute primer on writing prompts that get useful answers.',
    'youtube',
    null,
    'https://www.youtube.com/embed/dQw4w9WgXcQ',
    6,
    true
  )
on conflict (slug) do update set
  title = excluded.title,
  description = excluded.description,
  content_type = excluded.content_type,
  widget_key = excluded.widget_key,
  asset_url = excluded.asset_url,
  duration_minutes = excluded.duration_minutes,
  is_published = excluded.is_published;
