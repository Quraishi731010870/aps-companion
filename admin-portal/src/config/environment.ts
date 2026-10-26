/** Public, non-secret browser configuration. Never add credentials here. */
export const environment = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL?.trim() ?? '',
}

export function isSecureServiceUrl(value: string) {
  if (!value) return false
  try {
    const parsed = new URL(value, window.location.origin)
    return parsed.protocol === 'https:' || parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1'
  } catch {
    return false
  }
}

export function isTrustedAdminApiUrl(value: string) {
  if (!isSecureServiceUrl(value)) return false
  try {
    const target = new URL(value, window.location.origin)
    const localHosts = new Set(['localhost', '127.0.0.1', '::1'])
    const localDevelopment = localHosts.has(target.hostname) && localHosts.has(window.location.hostname)
    return target.origin === window.location.origin || localDevelopment
  } catch {
    return false
  }
}
