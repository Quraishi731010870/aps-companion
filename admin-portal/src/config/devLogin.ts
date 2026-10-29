/**
 * Local development only: pre-fills the sign-in form from the git-ignored
 * `.env.development.local`. Vite loads that file only for `npm run dev`, and
 * `import.meta.env.DEV` is false in builds, so nothing reaches a bundle.
 * The operator still presses Sign in; nothing signs in on its own.
 */
export const devLogin = import.meta.env.DEV
  ? { operator: import.meta.env.VITE_DEV_ADMIN_OPERATOR ?? '', password: import.meta.env.VITE_DEV_ADMIN_PASSWORD ?? '' }
  : { operator: '', password: '' }
