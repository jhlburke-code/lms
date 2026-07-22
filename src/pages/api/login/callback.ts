import type { APIRoute } from 'astro';
import { makeBrowserClient, setSessionCookies } from '../../../lib/supabase';

export const GET: APIRoute = async (ctx) => {
  const url = new URL(ctx.request.url);
  const code = url.searchParams.get('code');
  const next = url.searchParams.get('next') ?? '/me';

  if (!code) {
    return ctx.redirect('/login?error=invalid');
  }

  const client = makeBrowserClient(ctx);
  const { data, error } = await client.auth.exchangeCodeForSession(code);

  if (error || !data.session) {
    return ctx.redirect(`/login?error=${encodeURIComponent(error?.message ?? 'exchange_failed')}`);
  }

  await setSessionCookies(ctx, data.session);
  return ctx.redirect(next);
};
