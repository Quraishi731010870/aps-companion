import { useMemo, useState, type ReactNode } from 'react'
import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Alert, Box, Button, CircularProgress, CssBaseline, ThemeProvider, Typography, createTheme } from '@mui/material'
import { AuthProvider, useAuth } from './auth/AuthContext'
import { PortalLayout } from './layout/PortalLayout'
import { LoginPage } from './pages/LoginPage'
import { DashboardPage } from './pages/DashboardPage'
import { TransactionsPage } from './pages/TransactionsPage'
import { TransactionDetailPage } from './pages/TransactionDetailPage'
import { CustomerDetailPage } from './pages/CustomerDetailPage'
import { CustomersPage } from './pages/CustomersPage'
import { IntegrationRequiredPage } from './pages/IntegrationRequiredPage'
import { AlertsPage, MonitoringIntegrationPage, MonitoringOverviewPage, TransactionMonitoringPage } from './pages/MonitoringPages'
import { ConfigurationPage } from './pages/configuration/ConfigurationPage'
import { AuditLogsPage } from './pages/audit/AuditLogsPage'
import { UsersPage } from './pages/UsersPage'
import { NotificationsPage } from './pages/NotificationsPage'
import { DynamicContentPage } from './pages/configuration/DynamicContentPage'
import { ReportsPage } from './pages/ReportsPage'
import { ColorModeContext, type ColorMode } from './layout/ColorModeContext'
import './App.css'

const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false, staleTime: 15_000, refetchOnWindowFocus: false } } })
function buildTheme(mode: ColorMode) {
  const dark = mode === 'dark'
  return createTheme({
    cssVariables: true,
    palette: { mode, primary: { main: dark ? '#4fd1aa' : '#087f67', dark: '#05624f', light: '#dff2ec' }, secondary: { main: '#4b78a0' }, background: { default: dark ? '#0c171c' : '#f3f6f7', paper: dark ? '#132229' : '#fff' }, success: { main: '#16866e' }, warning: { main: '#b97819' }, error: { main: '#bb4b48' }, divider: dark ? '#294047' : '#e3eaeb' },
    shape: { borderRadius: 12 },
    typography: { fontFamily: 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif', h4: { fontWeight: 760, letterSpacing: '-.035em' }, h5: { fontWeight: 720, letterSpacing: '-.025em' }, h6: { fontWeight: 700 } },
    components: {
      MuiButton: { defaultProps: { disableElevation: true }, styleOverrides: { root: { textTransform: 'none', fontWeight: 680, borderRadius: 9 } } },
      MuiPaper: { styleOverrides: { root: { backgroundImage: 'none' } } },
      MuiTextField: { defaultProps: { variant: 'outlined' } },
      MuiTableCell: { styleOverrides: { head: { fontSize: 11, fontWeight: 750, letterSpacing: '.07em', textTransform: 'uppercase', whiteSpace: 'nowrap' } } },
      MuiChip: { styleOverrides: { root: { fontWeight: 650 } } },
    },
  })
}

function RequireSession() {
  const { session, ready } = useAuth()
  if (!ready) return <Box className="auth-loading"><CircularProgress /><Typography>Checking administrator session…</Typography></Box>
  if (!session || new Date(session.expiresAt).getTime() <= Date.now()) return <Navigate to="/login" replace />
  return <Outlet />
}

function PermissionGate({ permission, children }: { permission: import('./api/adminApi').AdminPermission; children: ReactNode }) {
  const { session } = useAuth()
  if (!session?.permissions.includes(permission)) return <Box sx={{ maxWidth: 680, mx: 'auto', mt: 8 }}><Alert severity="error"><Typography fontWeight={700}>Access denied</Typography>Your administrator account does not have permission to view this section.</Alert></Box>
  return children
}

function ForbiddenLanding() {
  return <Box className="auth-loading"><Typography variant="h5">Page not found</Typography><Button href="/app/dashboard">Return to overview</Button></Box>
}

function AppRoutes() {
  return <Routes>
    <Route path="/login" element={<LoginPage />} />
    <Route path="/preview" element={<PortalLayout preview />}>
      <Route index element={<Navigate to="dashboard" replace />} />
      <Route path="dashboard" element={<DashboardPage />} />
      <Route path="transactions" element={<TransactionsPage />} />
      <Route path="transactions/:id" element={<TransactionDetailPage />} />
      <Route path="customers" element={<CustomersPage />} />
      <Route path="customers/:id" element={<CustomerDetailPage />} />
      <Route path="notifications" element={<IntegrationRequiredPage title="Notifications" detail="No notification delivery, targeting, or history API is configured. FCM or another provider has not been identified." />} />
      <Route path="reports" element={<IntegrationRequiredPage title="Reports" detail="The existing data API does not provide report aggregates, date-range queries, exports, or authorized report permissions." />} />
      <Route path="monitoring/overview" element={<MonitoringOverviewPage />} />
      <Route path="monitoring/transactions" element={<TransactionMonitoringPage />} />
      <Route path="monitoring/alerts" element={<AlertsPage />} />
      <Route path="monitoring/services" element={<IntegrationRequiredPage title="Application and service monitoring" detail="The API contract does not yet expose service discovery, process status, uptime, ports, or per-service health checks." />} />
      <Route path="monitoring/apis" element={<IntegrationRequiredPage title="API monitoring" detail="Endpoint availability, HTTP status, latency, request/error/timeout rates, and time series require a backend telemetry adapter." />} />
      <Route path="monitoring/servers" element={<IntegrationRequiredPage title="Server monitoring" detail="Host discovery, CPU, memory, disk, load, network metrics, and service uptime require a configured monitoring provider and authenticated API." />} />
      <Route path="monitoring/database" element={<IntegrationRequiredPage title="Database monitoring" detail="Database availability, connections, query performance, capacity, and errors require an authorized monitoring integration." />} />
      <Route path="monitoring/network" element={<IntegrationRequiredPage title="Network monitoring" detail="Connectivity, latency, packet loss, and port status are not available from the current project or monitoring service." />} />
      <Route path="monitoring/grafana" element={<MonitoringIntegrationPage integration="grafana" />} />
      <Route path="monitoring/zabbix" element={<MonitoringIntegrationPage integration="zabbix" />} />
      <Route path="monitoring/*" element={<IntegrationRequiredPage title="Monitoring" detail="This monitoring page has no configured authorized data source." />} />
      <Route path="security/*" element={<IntegrationRequiredPage title="Security administration" detail="There are no admin identity, administrator, role, permission, audit-log, or login-history APIs." />} />
      <Route path="configuration" element={<IntegrationRequiredPage title="Application settings" detail="No authenticated application configuration API is available. Mobile-only local preferences are not treated as authoritative settings." />} />
      <Route path="configuration/content" element={<IntegrationRequiredPage title="Dynamic content" detail="Content preview requires the authenticated backend." />} />
      <Route path="*" element={<ForbiddenLanding />} />
    </Route>
    <Route path="/app" element={<RequireSession />}><Route element={<PortalLayout />}>
      <Route index element={<Navigate to="dashboard" replace />} />
      <Route path="dashboard" element={<PermissionGate permission="dashboard.view"><DashboardPage /></PermissionGate>} />
      <Route path="transactions" element={<PermissionGate permission="transactions.view"><TransactionsPage /></PermissionGate>} />
      <Route path="transactions/:id" element={<PermissionGate permission="transactions.view"><TransactionDetailPage /></PermissionGate>} />
      <Route path="customers" element={<PermissionGate permission="customers.view"><CustomersPage /></PermissionGate>} />
      <Route path="customers/:id" element={<PermissionGate permission="customers.view"><CustomerDetailPage /></PermissionGate>} />
      <Route path="notifications" element={<PermissionGate permission="notifications.view"><NotificationsPage /></PermissionGate>} />
      <Route path="reports" element={<PermissionGate permission="reports.view"><ReportsPage /></PermissionGate>} />
      <Route path="monitoring/overview" element={<PermissionGate permission="monitoring.view"><MonitoringOverviewPage /></PermissionGate>} />
      <Route path="monitoring/transactions" element={<PermissionGate permission="monitoring.view"><TransactionMonitoringPage /></PermissionGate>} />
      <Route path="monitoring/alerts" element={<PermissionGate permission="monitoring.view"><AlertsPage /></PermissionGate>} />
      <Route path="monitoring/services" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="Application and service monitoring" detail="The API contract does not yet expose service discovery, process status, uptime, ports, or per-service health checks." /></PermissionGate>} />
      <Route path="monitoring/apis" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="API monitoring" detail="Endpoint availability, HTTP status, latency, request/error/timeout rates, and time series require a backend telemetry adapter." /></PermissionGate>} />
      <Route path="monitoring/servers" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="Server monitoring" detail="Host discovery, CPU, memory, disk, load, network metrics, and service uptime require a configured monitoring provider and authenticated API." /></PermissionGate>} />
      <Route path="monitoring/database" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="Database monitoring" detail="Database availability, connections, query performance, capacity, and errors require an authorized monitoring integration." /></PermissionGate>} />
      <Route path="monitoring/network" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="Network monitoring" detail="Connectivity, latency, packet loss, and port status are not available from the current project or monitoring service." /></PermissionGate>} />
      <Route path="monitoring/grafana" element={<PermissionGate permission="monitoring.view"><MonitoringIntegrationPage integration="grafana" /></PermissionGate>} />
      <Route path="monitoring/zabbix" element={<PermissionGate permission="monitoring.view"><MonitoringIntegrationPage integration="zabbix" /></PermissionGate>} />
      <Route path="monitoring/*" element={<PermissionGate permission="monitoring.view"><IntegrationRequiredPage title="Monitoring" detail="This monitoring page has no configured authorized data source." /></PermissionGate>} />
      <Route path="security/audit" element={<PermissionGate permission="audit.view"><AuditLogsPage /></PermissionGate>} />
      <Route path="security/admins" element={<PermissionGate permission="users.view"><UsersPage /></PermissionGate>} />
      <Route path="security/*" element={<PermissionGate permission="users.view"><IntegrationRequiredPage title="Security administration" detail="Administrator and role management UI is being connected to the backend-enforced RBAC APIs." /></PermissionGate>} />
      <Route path="configuration" element={<PermissionGate permission="configuration.view"><ConfigurationPage /></PermissionGate>} />
      <Route path="configuration/content" element={<PermissionGate permission="configuration.view"><DynamicContentPage /></PermissionGate>} />
      <Route path="*" element={<ForbiddenLanding />} />
    </Route></Route>
    <Route path="*" element={<Navigate to="/login" replace />} />
  </Routes>
}

export default function App() {
  const [mode, setMode] = useState<ColorMode>(() => window.localStorage.getItem('payafghan-color-mode') === 'dark' ? 'dark' : 'light')
  const colorMode = useMemo(() => ({ mode, toggle: () => setMode(current => {
    const next = current === 'light' ? 'dark' : 'light'
    window.localStorage.setItem('payafghan-color-mode', next)
    return next
  }) }), [mode])
  const theme = useMemo(() => buildTheme(mode), [mode])
  return <QueryClientProvider client={queryClient}><ColorModeContext.Provider value={colorMode}><ThemeProvider theme={theme}><CssBaseline /><AuthProvider><AppRoutes /></AuthProvider></ThemeProvider></ColorModeContext.Provider></QueryClientProvider>
}
