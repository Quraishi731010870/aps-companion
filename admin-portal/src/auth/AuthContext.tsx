import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { adminApi, type AdminSession } from '../api/adminApi'

interface AuthValue {
  session: AdminSession | null
  ready: boolean
  signIn: (operator: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}
const AuthContext = createContext<AuthValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const queryClient = useQueryClient()
  const [session, setSession] = useState<AdminSession | null>(null)
  const [ready, setReady] = useState(!adminApi.configured)
  useEffect(() => {
    if (!adminApi.configured) return
    let mounted = true
    void adminApi.getSession().then(value => { if (mounted) setSession(value) }).catch(() => { if (mounted) setSession(null) }).finally(() => { if (mounted) setReady(true) })
    return () => { mounted = false }
  }, [])
  useEffect(() => {
    const expire = () => { setSession(null); queryClient.clear() }
    window.addEventListener('admin:unauthorized', expire)
    return () => window.removeEventListener('admin:unauthorized', expire)
  }, [queryClient])
  useEffect(() => {
    if (!session) return
    const remaining = new Date(session.expiresAt).getTime() - Date.now()
    if (remaining <= 0) { setSession(null); queryClient.clear(); return }
    const timer = window.setTimeout(() => { setSession(null); queryClient.clear() }, remaining)
    return () => window.clearTimeout(timer)
  }, [session, queryClient])
  const value: AuthValue = {
    session,
    ready,
    async signIn(operator, password) { setSession(await adminApi.login(operator, password)) },
    async signOut() { try { await adminApi.logout() } finally { setSession(null); queryClient.clear() } },
  }
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth must be used inside AuthProvider')
  return value
}
