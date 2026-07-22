import type { APIRoute } from 'astro';
import { makeBrowserClient } from '../../lib/supabase';

export const POST: APIRoute = async (ctx) => {
  const form = await ctx.request.formData();
  const email = String(form.get('email') ?? '').trim().toLowerCase();
  const next = String(form.get('next') ?? '/me');

  if (!email || !email.includes('@')) {
    return ctx.redirect('/login?error=invalid');
  }

  if (!ctx.locals.runtime.env.SUPABASE_URL) {
    return ctx.redirect('/login?error=config');
  }

  const client = makeBrowserClient(ctx);
  const origin = new URL(ctx.request.url).origin;
  const { error } = await client.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${origin}/api/login/callback?next=${encodeURIComponent(next)}`,
    },
  });

  if (error) {
    return ctx.redirect(`/login?error=${encodeURIComponent(error.message)}`);
  }
  return ctx.redirect(`/login?sent=${encodeURIComponent(email)}`);
};
