import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Chip, MenuItem, Paper, Select, Skeleton, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField, Typography } from '@mui/material'
import { adminApi, type CustomerFilters } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { usePreviewMode } from '../layout/PreviewContext'
import { formatDate } from './TransactionsPage'

export function CustomersPage() {
  const preview = usePreviewMode()
  const navigate = useNavigate()
  const [filters, setFilters] = useState<CustomerFilters>({ page: 0, pageSize: 25, sort: 'createdAt:desc' })
  const [search, setSearch] = useState('')
  useEffect(() => {
    const timer = window.setTimeout(() => setFilters(old => old.search === search ? old : ({ ...old, search: search || undefined, page: 0 })), 350)
    return () => window.clearTimeout(timer)
  }, [search])
  const query = useQuery({ queryKey: ['customers', filters], queryFn: () => adminApi.listCustomers(filters), enabled: adminApi.configured && !preview })
  const set = (key: keyof CustomerFilters, value: string) => setFilters(old => ({ ...old, [key]: value || undefined, page: 0 }))

  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">CUSTOMERS</Typography><Typography variant="h4">Customer directory</Typography><Typography color="text.secondary">Contact and account identifiers are masked by the authorized API.</Typography></Box></Box>
    <Paper className="panel filter-panel" elevation={0}>
      <Stack direction={{ xs: 'column', lg: 'row' }} spacing={1.25}>
        <TextField size="small" label="Customer ID, name, or phone" value={search} onChange={e => setSearch(e.target.value)} fullWidth />
        <Select size="small" value={filters.status ?? ''} displayEmpty onChange={e => set('status', e.target.value)} sx={{ minWidth: 150 }}><MenuItem value="">All statuses</MenuItem>{['active', 'inactive', 'suspended'].map(item => <MenuItem key={item} value={item}>{item}</MenuItem>)}</Select>
        <Select size="small" value={filters.sort ?? 'createdAt:desc'} onChange={e => setFilters(old => ({ ...old, sort: e.target.value, page: 0 }))} sx={{ minWidth: 175 }}><MenuItem value="createdAt:desc">Newest first</MenuItem><MenuItem value="createdAt:asc">Oldest first</MenuItem><MenuItem value="name:asc">Name A–Z</MenuItem><MenuItem value="name:desc">Name Z–A</MenuItem></Select>
      </Stack>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.25} sx={{ mt: 1.5 }}>
        <TextField size="small" type="date" label="Registered from" InputLabelProps={{ shrink: true }} value={filters.dateFrom ?? ''} onChange={e => set('dateFrom', e.target.value)} />
        <TextField size="small" type="date" label="Registered to" InputLabelProps={{ shrink: true }} value={filters.dateTo ?? ''} onChange={e => set('dateTo', e.target.value)} />
        <TextField size="small" type="date" label="Active from" InputLabelProps={{ shrink: true }} value={filters.lastActivityFrom ?? ''} onChange={e => set('lastActivityFrom', e.target.value)} />
        <TextField size="small" type="date" label="Active to" InputLabelProps={{ shrink: true }} value={filters.lastActivityTo ?? ''} onChange={e => set('lastActivityTo', e.target.value)} />
        <Chip variant="outlined" label="Server-side filtering / paging" />
      </Stack>
    </Paper>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests live customer records.' : 'Customer list, details, accounts, activity, and server-side search require the authenticated customer-service adapter. The prototype worksheet is not connected.'} />
      : query.isPending ? <Skeleton variant="rounded" height={260} />
        : query.isError ? <Alert severity="error">Customer list unavailable. The backend did not return authorized customer data; check service health or contact an administrator.</Alert>
          : <Paper className="table-panel" elevation={0}>
            <TableContainer><Table size="small"><TableHead><TableRow>{['Customer ID', 'Name', 'Phone', 'Status', 'Registered', 'Last activity'].map(item => <TableCell key={item}>{item}</TableCell>)}</TableRow></TableHead>
              <TableBody>{query.data.items.map(customer => <TableRow hover key={customer.id} className="clickable-row" onClick={() => navigate(encodeURIComponent(customer.id))}><TableCell>{customer.id}</TableCell><TableCell>{customer.name}</TableCell><TableCell>{customer.phoneMasked ?? '—'}</TableCell><TableCell><Chip size="small" variant="outlined" label={customer.status} /></TableCell><TableCell>{formatDate(customer.createdAt)}</TableCell><TableCell>{formatDate(customer.lastActivityAt)}</TableCell></TableRow>)}
                {!query.data.items.length && <TableRow><TableCell colSpan={6}><Typography align="center" sx={{ py: 4 }} color="text.secondary">No customers matched.</Typography></TableCell></TableRow>}
              </TableBody>
            </Table></TableContainer>
            <TablePagination component="div" count={query.data.total} page={filters.page} rowsPerPage={filters.pageSize} rowsPerPageOptions={[10, 25, 50]} onPageChange={(_, page) => setFilters(old => ({ ...old, page }))} onRowsPerPageChange={event => setFilters(old => ({ ...old, pageSize: Number(event.target.value), page: 0 }))} />
          </Paper>}
  </>
}
