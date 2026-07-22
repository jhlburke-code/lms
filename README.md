# LMS — AIINOD Learning Hub

Small, intuitive Learning Management System for IONOS staff training. Self-enrollment on courses (eLearning widgets, PDFs, YouTube embeds, scheduled workshops). One operator today, expandable to instructors later.

**Live URL:** _populated on first successful deploy_

## Stack

- **Frontend + SSR**: Astro 4 with `@astrojs/cloudflare` adapter
- **Edge**: Cloudflare Pages (server-rendered)
- **Data + identity**: Supabase (Postgres + Auth + RLS)
- **Transactional email**: Resend (Phase 2)
- **Asset hosting**: Cloudflare R2 (signed URLs)
- **Workshop recordings**: Google Drive → R2 proxy or Cloudflare Stream

## Setup

```bash
npm install
cp .env.example .dev.vars
# fill in SUPABASE_URL, SUPABASE_ANON_KEY
npm run dev
```

## Deploy

Configured for Cloudflare Pages — connect the GitHub repo to Pages; Pages reads `.dev.vars` for environment bindings.

```bash
npm run build
npx wrangler pages deploy ./dist --project-name lms
```

## Project structure

```
src/
├── layouts/
├── lib/supabase.ts          Supabase clients (anonymous, authenticated)
├── pages/
│   ├── index.astro          Landing
│   ├── catalog.astro        Course list
│   ├── c/[slug].astro       Course detail
│   ├── login.astro          Magic-link request form
│   ├── me.astro             My learning
│   ├── learn/[slug].astro   Content runner
│   └── api/
│       ├── login.ts                 POST: send magic link
│       ├── login/callback.ts        GET:  exchange code, set cookies
│       └── enroll.ts                POST: self-enroll
└── styles/global.css
supabase/migrations/         SQL migrations (version-tracked via Supabase)
```

## Data model

See `~/Desktop/Hollup/projects/lms/_index.md` §1 for the canonical schema. Tables prefixed `LMS_*` to coexist with the existing `eLearning_*` tables in the same Supabase project.

## Admin bootstrap

One row — the operator (jhl.burke@gmail.com) — is granted the `admin` role via JWT email match in `LMS_is_admin()`. RLS policies use that function for admin gates.

## Phases

| | |
|---|---|
| Phase 1 — Spine | ✅ Auth + 4 public routes (`/`, `/catalog`, `/c/[slug]`, `/login`) |
| Phase 2 — Self-enroll + content | `/me` + enrollments + notifications cron + Resend |
| Phase 3 — Admin MVP | CRUD courses + R2 asset upload + bulk-enroll CSV |
| Phase 4 — Workshops | Workshops CRUD + meeting URLs + reminders |
| Phase 5 — Polish | Certificate PDF + audit log + tests + accessibility |

## Relationships

- Widget library lives in `jhlburke-code/eLearning` (sibling repo). Hosted at `elearning-test.jhl-burke.workers.dev` (Cloudflare Worker) or via GitHub Pages.
- This LMS imports those widgets via iframe (`content_type='elearning'` + `widget_key`).
