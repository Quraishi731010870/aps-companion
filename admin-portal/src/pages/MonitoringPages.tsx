import { useState, type ReactNode } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Alert, Box, Chip, MenuItem, Paper, Select, Skeleton, Stack, Table,
  TableBody, TableCell, TableHead, TablePagination, TableRow, TextField, Typography,
} from '@mui/material'
import {
  Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer,
  Tooltip, XAxis, YAxis,
} from 'recharts'
import { adminApi, type ServiceStatus } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { transactionTypes } from '../config/transactionTypes'
import { usePreviewMode } from '../layout/PreviewContext'
import { formatDate } from './TransactionsPage'

const statusColor: Record<ServiceStatus, 'success' | 'warning' | 'error' | 'default'> = {
  healthy: 'success', warning: 'warning', critical: 'error', unavailable: 'default',
}
const statusLabel: Record<ServiceStatus, string> = {
  healthy: 'Healthy', warning: 'Degraded', critical: 'Critical', unavailable: 'Unavailable',
}

function Status({ value }: { value: ServiceStatus }) {
  return <Chip size="small" color={statusColor[value]} variant={value === 'unavailable' ? 'outlined' : 'filled'} label={statusLabel[value]} />
}

export function MonitoringOverviewPage() {
  const preview = usePreviewMode()
  const query = useQuery({
    queryKey: ['monitoring-overview'], queryFn: () => adminApi.getMonitoringOverview(),
    enabled: adminApi.configured && !preview,
    refetchInterval: adminApi.configured && !preview ? 30_000 : false,
  })
  const health: ServiceStatus = !adminApi.configured || preview ? 'unavailable' : query.data ? 'healthy' : query.isError ? 'critical' : 'unavailable'

  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">MONITORING</Typography><Typography variant="h4">System overview</Typography><Typography color="text.secondary">Service and infrastructure state from the authorized monitoring adapter.</Typography></Box><Status value={health} /></Box>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests monitoring data.' : 'Monitoring API is not configured. No service, infrastructure, or alert values are generated.'} />
      : query.isPending ? <Skeleton variant="rounded" height={280} />
        : query.isError ? <Alert severity="error">Monitoring service could not be reached. No cached or sample metrics are shown.</Alert>
          : query.data && <>
            <Box className="capability-grid">{query.data.services.map(service => <Paper key={service.name} className="capability-card" elevation={0}><Stack direction="row" justifyContent="space-between" gap={1} alignItems="center"><Typography fontWeight={700}>{service.name}</Typography><Status value={service.status} /></Stack><Typography variant="caption" color="text.secondary">{service.detail ?? (service.checkedAt ? `Last checked ${formatDate(service.checkedAt)}` : 'No check timestamp supplied')}</Typography></Paper>)}</Box>
            <Box className="two-column" sx={{ mt: 2 }}>
              <Paper className="panel" elevation={0}><Typography variant="h6">Infrastructure</Typography>{query.data.infrastructure?.length ? query.data.infrastructure.map(metric => <Stack key={metric.name} direction="row" justifyContent="space-between" alignItems="center" sx={{ py: 1.5, borderBottom: '1px solid #edf0f1' }}><Typography>{metric.name}</Typography><Stack direction="row" spacing={1} alignItems="center"><Typography fontWeight={700}>{metric.value}{metric.unit}</Typography><Status value={metric.status} /></Stack></Stack>) : <Typography color="text.secondary" sx={{ py: 3 }}>No infrastructure metrics returned by the monitoring service.</Typography>}</Paper>
              <Paper className="panel" elevation={0}><Typography variant="h6">Monitoring integrations</Typography><Stack direction="row" justifyContent="space-between" sx={{ py: 1.5 }}><Typography>Zabbix</Typography><Status value={query.data.integrations.zabbix} /></Stack><Stack direction="row" justifyContent="space-between" sx={{ py: 1.5 }}><Typography>Grafana</Typography><Status value={query.data.integrations.grafana} /></Stack></Paper>
            </Box>
            <Paper className="panel" elevation={0} sx={{ mt: 2 }}><Typography variant="h6">Alert summary</Typography><Stack direction="row" spacing={1} sx={{ mt: 2, flexWrap: 'wrap' }}>{(['critical', 'high', 'warning', 'info'] as const).map(level => <Chip key={level} label={`${level}: ${query.data.alerts?.[level] ?? '—'}`} color={level === 'critical' ? 'error' : level === 'high' ? 'warning' : 'default'} variant="outlined" />)}</Stack></Paper>
          </>}
  </>
}

export function TransactionMonitoringPage() {
  const preview = usePreviewMode()
  const [filters, setFilters] = useState({ dateFrom: '', dateTo: '', operation: '', status: '', channel: '', source: '', destination: '' })
  const query = useQuery({
    queryKey: ['transaction-monitoring', filters], queryFn: () => adminApi.getTransactionMonitoring(filters),
    enabled: adminApi.configured && !preview,
    refetchInterval: adminApi.configured && !preview ? 15_000 : false,
  })
  const set = (key: keyof typeof filters, value: string) => setFilters(old => ({ ...old, [key]: value }))

  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">MONITORING / TRANSACTIONS</Typography><Typography variant="h4">Transaction performance</Typography><Typography color="text.secondary">Aggregates and trends reported by the transaction monitoring API.</Typography></Box></Box>
    <Paper className="panel filter-panel" elevation={0}><Stack direction={{ xs: 'column', md: 'row' }} spacing={1.25}>
      <TextField size="small" type="date" label="From" InputLabelProps={{ shrink: true }} value={filters.dateFrom} onChange={e => set('dateFrom', e.target.value)} />
      <TextField size="small" type="date" label="To" InputLabelProps={{ shrink: true }} value={filters.dateTo} onChange={e => set('dateTo', e.target.value)} />
      <Select size="small" displayEmpty value={filters.operation} onChange={e => set('operation', e.target.value)}><MenuItem value="">All operation types</MenuItem>{transactionTypes.map(item => <MenuItem key={item.code} value={item.code}>{item.label}</MenuItem>)}</Select>
      <Select size="small" displayEmpty value={filters.status} onChange={e => set('status', e.target.value)}><MenuItem value="">All statuses</MenuItem>{['processing', 'successful', 'failed', 'reversed'].map(item => <MenuItem key={item} value={item}>{item}</MenuItem>)}</Select>
      <TextField size="small" label="Channel" value={filters.channel} onChange={e => set('channel', e.target.value)} />
      <TextField size="small" label="Source" value={filters.source} onChange={e => set('source', e.target.value)} />
      <TextField size="small" label="Destination" value={filters.destination} onChange={e => set('destination', e.target.value)} />
    </Stack></Paper>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests monitoring data.' : 'Transaction monitoring requires authenticated server-side aggregates and event telemetry; the mobile prototype cannot supply reliable success, failure, latency, or reversal metrics.'} />
      : query.isPending ? <Skeleton variant="rounded" height={300} />
        : query.isError ? <Alert severity="error">Transaction monitoring API unavailable. No synthetic metrics are displayed.</Alert>
          : query.data && <>
            <Box className="metric-grid">{[['Volume', query.data.volume], ['Success rate', `${query.data.successRate}%`], ['Failure rate', `${query.data.failureRate}%`], ['Decline rate', `${query.data.declineRate}%`], ['Pending', query.data.pending], ['Reversals', query.data.reversals], ['Avg. latency', query.data.latencyMs == null ? '—' : `${query.data.latencyMs} ms`]].map(([label, value]) => <Paper key={label} className="metric-card" elevation={0}><Typography color="text.secondary">{label}</Typography><Typography variant="h5">{value}</Typography></Paper>)}</Box>
            <Box className="two-column" sx={{ mt: 2 }}><Paper className="panel" elevation={0}><Typography variant="h6">Volume by status</Typography><Chart data={query.data.trend} x="label"><Bar dataKey="successful" name="Successful" fill="#16866e" /><Bar dataKey="failed" name="Failed" fill="#bb4b48" /><Bar dataKey="pending" name="Pending" fill="#b97819" /></Chart></Paper><Paper className="panel" elevation={0}><Typography variant="h6">Processing latency</Typography>{query.data.latencyTrend?.length ? <Box sx={{ height: 240, mt: 2 }}><ResponsiveContainer width="100%" height="100%"><LineChart data={query.data.latencyTrend}><CartesianGrid stroke="#edf1f2" vertical={false} /><XAxis dataKey="label" /><YAxis /><Tooltip /><Line dataKey="milliseconds" name="ms" stroke="#315f87" /></LineChart></ResponsiveContainer></Box> : <Typography color="text.secondary" sx={{ py: 5 }}>Latency series was not supplied.</Typography>}</Paper></Box>
            <Box className="two-column" sx={{ mt: 2 }}><Paper className="panel" elevation={0}><Typography variant="h6">Volume by transaction type</Typography><Chart data={query.data.byType} x="label"><Bar dataKey="count" name="Transactions" fill="#315f87" /></Chart></Paper><Paper className="panel" elevation={0}><Typography variant="h6">Response codes</Typography><Chart data={query.data.byResponseCode} x="label"><Bar dataKey="count" name="Responses" fill="#b97819" /></Chart></Paper></Box>
          </>}
  </>
}

function Chart({ data, x, children }: { data?: Array<Record<string, string | number>>; x: string; children: ReactNode }) {
  return data?.length ? <Box sx={{ height: 240, mt: 2 }}><ResponsiveContainer width="100%" height="100%"><BarChart data={data}><CartesianGrid stroke="#edf1f2" vertical={false} /><XAxis dataKey={x} /><Tooltip />{children}</BarChart></ResponsiveContainer></Box> : <Typography color="text.secondary" sx={{ py: 5 }}>No series returned by the monitoring API.</Typography>
}

export function AlertsPage() {
  const preview = usePreviewMode()
  const [filters, setFilters] = useState({ page: 0, pageSize: 25, severity: '', source: '', host: '', service: '', status: '', dateFrom: '', dateTo: '' })
  const query = useQuery({
    queryKey: ['monitoring-alerts', filters], queryFn: () => adminApi.listAlerts(filters),
    enabled: adminApi.configured && !preview,
    refetchInterval: adminApi.configured && !preview ? 30_000 : false,
  })
  const update = (key: keyof typeof filters, value: string) => setFilters(old => ({ ...old, [key]: value, page: 0 }))

  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">MONITORING / ALERTS</Typography><Typography variant="h4">Alert center</Typography><Typography color="text.secondary">Problems from the configured monitoring integration.</Typography></Box></Box>
    <Paper className="panel filter-panel" elevation={0}><Stack direction={{ xs: 'column', md: 'row' }} spacing={1}>
      <Select size="small" displayEmpty value={filters.severity} onChange={e => update('severity', e.target.value)}><MenuItem value="">All severities</MenuItem>{['critical', 'high', 'medium', 'warning', 'info'].map(item => <MenuItem key={item} value={item}>{item}</MenuItem>)}</Select>
      <TextField size="small" label="Source" value={filters.source} onChange={e => update('source', e.target.value)} />
      <TextField size="small" label="Host" value={filters.host} onChange={e => update('host', e.target.value)} />
      <TextField size="small" label="Service" value={filters.service} onChange={e => update('service', e.target.value)} />
      <Select size="small" displayEmpty value={filters.status} onChange={e => update('status', e.target.value)}><MenuItem value="">All statuses</MenuItem>{['open', 'acknowledged', 'resolved'].map(item => <MenuItem key={item} value={item}>{item}</MenuItem>)}</Select>
      <TextField size="small" type="date" label="From" InputLabelProps={{ shrink: true }} value={filters.dateFrom} onChange={e => update('dateFrom', e.target.value)} />
      <TextField size="small" type="date" label="To" InputLabelProps={{ shrink: true }} value={filters.dateTo} onChange={e => update('dateTo', e.target.value)} />
    </Stack></Paper>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests alert data.' : 'No Zabbix/monitoring alert API is configured. Alert state, acknowledgement, and resolution are unavailable.'} />
      : query.isPending ? <Skeleton variant="rounded" height={240} />
        : query.isError ? <Alert severity="error">Alert service unavailable. No sample alerts are displayed.</Alert>
          : <Paper className="table-panel" elevation={0}>
            <Table size="small"><TableHead><TableRow>{['Alert', 'Source / Host', 'Service', 'Severity', 'Status', 'Created', 'Updated'].map(item => <TableCell key={item}>{item}</TableCell>)}</TableRow></TableHead>
              <TableBody>{query.data.items.map(alert => <TableRow key={alert.id}><TableCell><Typography fontWeight={700}>{alert.description}</Typography><Typography variant="caption" color="text.secondary">{alert.id}</Typography></TableCell><TableCell>{alert.source}{alert.host ? ` / ${alert.host}` : ''}</TableCell><TableCell>{alert.service ?? '—'}</TableCell><TableCell>{alert.severity}</TableCell><TableCell>{alert.status}</TableCell><TableCell>{formatDate(alert.createdAt)}</TableCell><TableCell>{formatDate(alert.updatedAt)}</TableCell></TableRow>)}
                {!query.data.items.length && <TableRow><TableCell colSpan={7}><Typography align="center" sx={{ py: 4 }} color="text.secondary">No alerts returned.</Typography></TableCell></TableRow>}
              </TableBody>
            </Table>
            <TablePagination component="div" count={query.data.total} page={filters.page} rowsPerPage={filters.pageSize} rowsPerPageOptions={[10, 25, 50]} onPageChange={(_, page) => setFilters(old => ({ ...old, page }))} onRowsPerPageChange={event => setFilters(old => ({ ...old, pageSize: Number(event.target.value), page: 0 }))} />
          </Paper>}
  </>
}

export function MonitoringIntegrationPage({ integration }: { integration: 'zabbix' | 'grafana' }) {
  const preview = usePreviewMode()
  const query = useQuery({ queryKey: ['monitoring-integration', integration], queryFn: () => adminApi.getMonitoringOverview(), enabled: adminApi.configured && !preview })
  const title = integration === 'zabbix' ? 'Zabbix' : 'Grafana'
  const status = query.data?.integrations[integration] ?? 'unavailable'
  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">MONITORING / INTEGRATIONS</Typography><Typography variant="h4">{title}</Typography><Typography color="text.secondary">Monitoring integration status is supplied by the authenticated admin backend.</Typography></Box><Status value={status} /></Box>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests integration status.' : `${title} is not connected to an admin monitoring API. Credentials and monitoring tokens must remain server-side.`} />
      : query.isPending ? <Skeleton variant="rounded" height={150} />
        : query.isError ? <Alert severity="error">Could not retrieve {title} integration status.</Alert>
          : <Paper className="panel" elevation={0}><Typography variant="h6">{status === 'unavailable' ? `${title} integration not configured` : `${title} integration status`}</Typography><Typography color="text.secondary" sx={{ mt: 1 }}>{status === 'healthy' ? 'The backend reports this integration as connected. Dashboard access still requires an authorized URL or SSO handoff from the backend.' : 'No authenticated integration data or guessed service URLs are used.'}</Typography></Paper>}
  </>
}
