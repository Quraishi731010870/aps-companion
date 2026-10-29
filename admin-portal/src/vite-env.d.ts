/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string
  /** Development only (`.env.development.local`); see config/devLogin.ts. */
  readonly VITE_DEV_ADMIN_OPERATOR?: string
  readonly VITE_DEV_ADMIN_PASSWORD?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
