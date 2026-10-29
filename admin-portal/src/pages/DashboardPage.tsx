import { Alert, Box, Button, Chip, Paper, Skeleton, Stack, Typography } from '@mui/material'
import { AutorenewRounded, AccountBalanceWalletOutlined, ApiOutlined, AssessmentOutlined, HealthAndSafetyOutlined, PeopleAltOutlined, ShieldOutlined, TimelineRounded } from '@mui/icons-material'
import { useQuery } from '@tanstack/react-query'
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis } from 'recharts'
import { adminApi, type DashboardSummary } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { usePreviewMode } from '../layout/PreviewContext'

export function DashboardPage() {
  const preview = usePreviewMode()
  const query = useQuery({ queryKey: ['dashboard'], queryFn: () => adminApi.getDashboard(), enabled: adminApi.configured && !preview, refetchInterval: 30_000 })
  return <>
    <Box className="page-heading"><Box><Typography variant="overline">OPERATIONS / CONTROL ROOM</Typography><Typography variant="h4">Overview</Typography><Typography color="text.secondary">Operational visibility for customer, transaction, and platform services.</Typography></Box><Stack direction="row" spacing={1} alignItems="center"><Chip className="environment-chip" size="small" icon={<ApiOutlined />} label={preview ? 'UNCONNECTED PREVIEW' : query.isSuccess ? 'API RESPONDING' : query.isError ? 'API ERROR' : adminApi.configured ? 'API CONFIGURED' : 'BACKEND NOT CONFIGURED'} color={query.isSuccess && !preview ? 'success' : query.isError && !preview ? 'error' : preview ? 'warning' : 'default'} variant="outlined" /><Button variant="outlined" startIcon={<AutorenewRounded />} disabled={!adminApi.configured || preview || query.isFetching} onClick={() => void query.refetch()}>Refresh</Button></Stack></Box>
    {(!adminApi.configured || preview) ? <><BackendState detail="Preview mode never requests live admin data. Live operational data is unavailable; connect a protected admin backend to populate this workspace." /><CapabilityGrid /></> : query.isPending ? <Stack spacing={2}><Skeleton variant="rounded" height={126} /><Skeleton variant="rounded" height={320} /></Stack> : query.isError ? <Alert severity="error" action={<Button color="inherit" size="small" onClick={() => void query.refetch()}>Retry</Button>}>Dashboard data could not be loaded. Check the admin API status or contact your administrator.</Alert> : query.data ? <Summary data={query.data} /> : <BackendState />}
  </>
}

function CapabilityGrid() {
  const items = [
    { name: 'Customer operations', description: 'Customer administration API is not connected.', icon: <PeopleAltOutlined />, area: 'CUSTOMERS' },
    { name: 'Transaction operations', description: 'Transaction search and summary APIs are not connected.', icon: <AccountBalanceWalletOutlined />, area: 'OPERATIONS' },
    { name: 'Notifications', description: 'No delivery provider or notification management API is configured.', icon: <AssessmentOutlined />, area: 'SERVICES' },
    { name: 'Infrastructure monitoring', description: 'No monitoring data source is configured.', icon: <HealthAndSafetyOutlined />, area: 'MONITORING' },
    { name: 'Administrator security', description: 'Identity, roles, and permission APIs are not connected.', icon: <ShieldOutlined />, area: 'SECURITY' },
    { name: 'Audit trail', description: 'Persistent administrator audit API is not connected.', icon: <TimelineRounded />, area: 'GOVERNANCE' },
  ]
  return <><Stack className="section-intro" direction="row" justifyContent="space-between" alignItems="flex-end"><Box><Typography variant="overline">SERVICE READINESS</Typography><Typography variant="h6">Operational modules</Typography><Typography variant="body2" color="text.secondary">These modules become live when their protected backend integrations are available.</Typography></Box><Chip size="small" variant="outlined" label="6 integrations required" /></Stack><Box className="capability-grid">{items.map(({ name, description, icon, area }) => <Paper key={name} className="capability-card" elevation={0}><Box className="capability-icon">{icon}</Box><Box className="capability-copy"><Typography className="capability-area">{area}</Typography><Typography fontWeight={750}>{name}</Typography><Typography variant="body2" color="text.secondary" sx={{ mt: .65 }}>{description}</Typography><Chip size="small" label="Not configured" variant="outlined" /></Box></Paper>)}</Box></>
}

function Summary({ data }: { data: DashboardSummary }) {
  const cards: [string, string | number | null | undefined][] = [['Users', data.usersTotal], ['Active users', data.usersActive], ['Customers', data.customersTotal], ['Transactions', data.transactionsTotal], ['Successful', data.successfulTransactions], ['Failed', data.failedTransactions], ['Pending', data.pendingTransactions], ['Success rate', data.successRate == null ? null : `${data.successRate}%`]]
  return <><Box className="metric-grid">{cards.map(([label, value]) => <Paper key={label} className="metric-card" elevation={0}><Typography color="text.secondary">{label}</Typography><Typography variant="h4">{value ?? '—'}</Typography></Paper>)}</Box><Box className="two-column"><Paper className="panel" elevation={0}><Typography variant="h6">Transaction trend</Typography>{data.trend?.length ? <Box sx={{ height: 200, mt: 1 }}><ResponsiveContainer width="100%" height="100%"><BarChart data={data.trend} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}><CartesianGrid stroke="#edf1f2" vertical={false} /><XAxis dataKey="label" tickLine={false} axisLine={false} tick={{ fill: '#74868b', fontSize: 11 }} /><Tooltip /><Bar dataKey="value" name="Transactions" fill="#16866e" radius={[5, 5, 0, 0]} maxBarSize={34} /></BarChart></ResponsiveContainer></Box> : <Typography color="text.secondary" sx={{ py: 5 }}>Trend data was not returned by the API.</Typography>}</Paper><Paper className="panel" elevation={0}><Typography variant="h6">Service health</Typography>{data.services?.length ? data.services.map(service => <Stack key={service.name} direction="row" justifyContent="space-between" sx={{ py: 1.5, borderBottom: '1px solid #edf0f1' }}><Typography>{service.name}</Typography><Chip size="small" label={service.status} /></Stack>) : <Typography color="text.secondary" sx={{ py: 5 }}>No service health data was returned.</Typography>}</Paper></Box></>
}
