import { useState, type FormEvent } from 'react'
import { Alert, Avatar, Box, Button, Paper, TextField, Typography } from '@mui/material'
import { ShieldOutlined } from '@mui/icons-material'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { adminApi } from '../api/adminApi'
import { devLogin } from '../config/devLogin'

export function LoginPage() {
  const [operator, setOperator] = useState(devLogin.operator)
  const [password, setPassword] = useState(devLogin.password)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { signIn } = useAuth()
  const navigate = useNavigate()

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(''); setLoading(true)
    try { await signIn(operator.trim(), password); setPassword(''); navigate('/app/dashboard', { replace: true }) }
    catch (e) { setError(e instanceof Error ? e.message : 'Sign-in service is unavailable.'); setPassword('') }
    finally { setLoading(false) }
  }

  return <Box className="login-page"><Box className="login-orb orb-one" /><Box className="login-orb orb-two" /><Paper className="login-card" elevation={0}>
    <Box className="login-brand"><Avatar className="brand-mark">P</Avatar><Box><Typography className="brand-name">PayAfghan</Typography><Typography className="brand-caption">ADMINISTRATION</Typography></Box></Box>
    <Typography variant="h4" className="login-title">Sign in to operations</Typography><Typography color="text.secondary">Use your organization-issued administrator account.</Typography>
    <Alert severity="warning" icon={<ShieldOutlined />} sx={{ mt: 3, mb: 2 }}>Admin authentication is not configured. A protected identity service and server-managed session are required.</Alert>
    {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
    <Box component="form" onSubmit={submit} className="login-form">
      <TextField label="Email or operator ID" autoComplete="username" value={operator} onChange={e => setOperator(e.target.value)} required fullWidth disabled={!adminApi.configured} />
      <TextField label="Password" type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} required fullWidth disabled={!adminApi.configured} />
      <Button type="submit" variant="contained" size="large" disabled={!adminApi.configured || loading || !operator || !password}>{loading ? 'Signing in…' : 'Sign in'}</Button>
    </Box>
    <Button className="preview-link" onClick={() => navigate('/preview/dashboard')}>Open disconnected interface preview</Button>
    <Typography className="login-foot" variant="caption">The portal does not store passwords or session tokens in browser storage.</Typography>
  </Paper></Box>
}
