import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { APIContext } from 'astro';

const ADMIN_EMAILS = new Set<string>([
  'jhl.burke@gmail.com', // operator bootstrap — see supabase/migrations/0002_admin_email.sql
]);

export function isAdminEmail(email: string | null | undefined): boolean {
  return !!email && ADMIN_EMAILS.has(email.toLowerCase());
}

export function makeBrowserClient(ctx: APIContext): SupabaseClient {
  // For SSR — reads anon JWT from cookie if present.
  const headers = new Headers();
  return createClient(
    ctx.locals.runtime.env.SUPABASE_URL,
    ctx.locals.runtime.env.SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: { headers },
    },
  );
}

export function makeAuthenticatedClient(ctx: APIContext): SupabaseClient {
  const accessToken = ctx.cookies.get('sb-access-token')?.value;
  const refreshToken = ctx.cookies.get('sb-refresh-token')?.value;
  const client = createClient(
    ctx.locals.runtime.env.SUPABASE_URL,
    ctx.locals.runtime.env.SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
    },
  );
  if (accessToken && refreshToken) {
    client.auth.setSession({ access_token: accessToken, refresh_token: refreshToken });
  }
  return client;
}

export async function setSessionCookies(ctx: APIContext, session: { access_token: string; refresh_token: string }) {
  ctx.cookies.set('sb-access-token', session.access_token, {
    path: '/', httpOnly: true, secure: true, sameSite: 'lax', maxAge: 60 * 60,
  });
  ctx.cookies.set('sb-refresh-token', session.refresh_token, {
    path: '/', httpOnly: true, secure: true, sameSite: 'lax', maxAge: 60 * 60 * 24 * 7,
  });
}

export function clearSessionCookies(ctx: APIContext) {
  ctx.cookies.delete('sb-access-token', { path: '/' });
  ctx.cookies.delete('sb-refresh-token', { path: '/' });
}

export async function getCurrentUser(ctx: APIContext): Promise<{ id: string; email: string } | null> {
  const client = makeAuthenticatedClient(ctx);
  const { data } = await client.auth.getUser();
  if (!data.user) return null;
  return { id: data.user.id, email: data.user.email ?? '' };
}
