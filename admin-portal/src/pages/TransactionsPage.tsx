import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Accordion, AccordionDetails, AccordionSummary, Alert, Box, Button, Chip, MenuItem, Paper, Select, Skeleton, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField, Typography } from '@mui/material'
import { FilterAltOutlined, SearchRounded } from '@mui/icons-material'
import { adminApi, type Transaction, type TransactionFilters } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { transactionTypes } from '../config/transactionTypes'
import { usePreviewMode } from '../layout/PreviewContext'

export function TransactionsPage() {
  const preview = usePreviewMode()
  const [filters, setFilters] = useState<TransactionFilters>({ page: 0, pageSize: 25, sort: 'createdAt:desc' })
  const [search, setSearch] = useState('')
  const [debounced, setDebounced] = useState('')
  useEffect(() => { const timer = window.setTimeout(() => setDebounced(search.trim()), 350); return () => window.clearTimeout(timer) }, [search])
  useEffect(() => setFilters(old => ({ ...old, search: debounced || undefined, page: 0 })), [debounced])
  const query = useQuery({ queryKey: ['transactions', filters], queryFn: () => adminApi.listTransactions(filters), enabled: adminApi.configured && !preview })
  const clear = () => { setSearch(''); setDebounced(''); setFilters({ page: 0, pageSize: 25, sort: 'createdAt:desc' }) }
  const setFilter = (key: keyof TransactionFilters, value: string) => setFilters(old => ({ ...old, [key]: value || undefined, page: 0 }))
  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">OPERATIONS</Typography><Typography variant="h4">Transactions</Typography><Typography color="text.secondary">Search payment activity. Filters and page requests are sent to the backend.</Typography></Box><Button variant="outlined" startIcon={<FilterAltOutlined />} onClick={clear}>Clear filters</Button></Box>
    <Paper className="panel filter-panel" elevation={0}>
      <Stack direction={{ xs: 'column', lg: 'row' }} spacing={1.25}>
        <TextField size="small" label="Transaction ID, RRN or reference" value={search} onChange={e => setSearch(e.target.value)} fullWidth />
        <Select size="small" displayEmpty value={filters.status ?? ''} onChange={e => setFilter('status', e.target.value)} sx={{ minWidth: 165 }}><MenuItem value="">All statuses</MenuItem>{['successful', 'failed', 'processing', 'reversed'].map(value => <MenuItem value={value} key={value}>{value}</MenuItem>)}</Select>
        <Select size="small" displayEmpty value={filters.operation ?? ''} onChange={e => setFilter('operation', e.target.value)} sx={{ minWidth: 190 }}><MenuItem value="">All types</MenuItem>{transactionTypes.map(({ code, label }) => <MenuItem value={code} key={code}>{label}</MenuItem>)}</Select>
        <Button variant="contained" startIcon={<SearchRounded />} disabled={!adminApi.configured} onClick={() => setFilters(old => ({ ...old, search: search.trim() || undefined, page: 0 }))}>Search</Button>
      </Stack>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.25} sx={{ mt: 1.5 }}>
        <TextField size="small" type="date" label="From date" InputLabelProps={{ shrink: true }} value={filters.dateFrom ?? ''} onChange={e => setFilter('dateFrom', e.target.value)} />
        <TextField size="small" type="date" label="To date" InputLabelProps={{ shrink: true }} value={filters.dateTo ?? ''} onChange={e => setFilter('dateTo', e.target.value)} />
        <TextField size="small" type="number" label="Amount from" value={filters.amountFrom ?? ''} onChange={e => setFilter('amountFrom', e.target.value)} />
        <TextField size="small" type="number" label="Amount to" value={filters.amountTo ?? ''} onChange={e => setFilter('amountTo', e.target.value)} />
        <TextField size="small" label="Currency" value={filters.currency ?? ''} onChange={e => setFilter('currency', e.target.value)} sx={{ maxWidth: 125 }} />
      </Stack>
      <Accordion disableGutters elevation={0} sx={{ mt: 1, '&:before': { display: 'none' } }}>
        <AccordionSummary expandIcon={<FilterAltOutlined />}><Typography variant="body2" fontWeight={700}>More filters</Typography></AccordionSummary>
        <AccordionDetails><Box className="filter-grid">
          <TextField size="small" label="Transaction ID" value={filters.transactionId ?? ''} onChange={e => setFilter('transactionId', e.target.value)} />
          <TextField size="small" label="RRN / reference" value={filters.reference ?? ''} onChange={e => setFilter('reference', e.target.value)} />
          <TextField size="small" label="Customer" value={filters.customer ?? ''} onChange={e => setFilter('customer', e.target.value)} />
          <TextField size="small" label="Account" value={filters.account ?? ''} onChange={e => setFilter('account', e.target.value)} />
          <TextField size="small" label="Phone" value={filters.phone ?? ''} onChange={e => setFilter('phone', e.target.value)} />
          <TextField size="small" label="Response code" value={filters.responseCode ?? ''} onChange={e => setFilter('responseCode', e.target.value)} />
          <TextField size="small" type="time" label="From time" InputLabelProps={{ shrink: true }} value={filters.timeFrom ?? ''} onChange={e => setFilter('timeFrom', e.target.value)} />
          <TextField size="small" type="time" label="To time" InputLabelProps={{ shrink: true }} value={filters.timeTo ?? ''} onChange={e => setFilter('timeTo', e.target.value)} />
          <TextField size="small" label="Source" value={filters.source ?? ''} onChange={e => setFilter('source', e.target.value)} />
          <TextField size="small" label="Destination" value={filters.destination ?? ''} onChange={e => setFilter('destination', e.target.value)} />
          <Select size="small" value={filters.sort} onChange={e => setFilters(old => ({ ...old, sort: e.target.value, page: 0 }))}><MenuItem value="createdAt:desc">Newest first</MenuItem><MenuItem value="createdAt:asc">Oldest first</MenuItem><MenuItem value="amount:desc">Amount high to low</MenuItem><MenuItem value="amount:asc">Amount low to high</MenuItem></Select>
        </Box></AccordionDetails>
      </Accordion>
      <Typography variant="caption" color="text.secondary">All filters, sorting, and pagination are sent to the server. Financial actions and export remain disabled until supported by the backend.</Typography>
    </Paper>
    {!adminApi.configured || preview ? <BackendState detail={preview ? 'Preview mode never requests live transaction records.' : 'The current Sheets integration can return only a limited recent transaction list and has no protected admin search, filtering, pagination, response-code, or transaction-action API.'} /> : query.isPending ? <Stack spacing={1}><Skeleton height={52} /><Skeleton height={230} /></Stack> : query.isError ? <Alert severity="error">Transactions could not be loaded. Check the service status or contact your administrator.</Alert> : <TransactionsTable items={query.data.items} total={query.data.total} filters={filters} setFilters={setFilters} />}
  </>
}

function TransactionsTable({ items, total, filters, setFilters }: { items: Transaction[]; total: number; filters: TransactionFilters; setFilters: React.Dispatch<React.SetStateAction<TransactionFilters>> }) {
  const navigate = useNavigate()
  return <Paper className="table-panel" elevation={0}><TableContainer><Table size="small"><TableHead><TableRow>{['Transaction / RRN', 'Type', 'Source → Destination', 'Amount', 'Channel', 'Created', 'Status'].map(v => <TableCell key={v}>{v}</TableCell>)}</TableRow></TableHead><TableBody>
    {items.map(tx => <TableRow hover key={tx.id} className="clickable-row" onClick={() => navigate(encodeURIComponent(tx.id))}><TableCell><Typography variant="body2" fontWeight={700}>{tx.id}</Typography><Typography variant="caption" color="text.secondary">{tx.rrn ?? tx.reference ?? '—'}</Typography></TableCell><TableCell>{tx.operationLabel}</TableCell><TableCell>{tx.source ?? '—'} <span className="muted-arrow">→</span> {tx.destination ?? '—'}</TableCell><TableCell>{new Intl.NumberFormat('en-US').format(tx.amount)} {tx.currency}</TableCell><TableCell>{tx.channel ?? '—'}</TableCell><TableCell>{formatDate(tx.createdAt)}</TableCell><TableCell><Chip size="small" variant="outlined" label={tx.status} /></TableCell></TableRow>)}
    {!items.length && <TableRow><TableCell colSpan={7}><Typography align="center" color="text.secondary" sx={{ py: 4 }}>No matching transactions.</Typography></TableCell></TableRow>}
  </TableBody></Table></TableContainer><TablePagination component="div" count={total} page={filters.page} rowsPerPage={filters.pageSize} rowsPerPageOptions={[10, 25, 50, 100]} onPageChange={(_, page) => setFilters(old => ({ ...old, page }))} onRowsPerPageChange={e => setFilters(old => ({ ...old, pageSize: Number(e.target.value), page: 0 }))} /></Paper>
}

// eslint-disable-next-line react-refresh/only-export-components
export function formatDate(value?: string) { if (!value) return '—'; const date = new Date(value); return Number.isNaN(date.getTime()) ? '—' : new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeStyle: 'short' }).format(date) }
