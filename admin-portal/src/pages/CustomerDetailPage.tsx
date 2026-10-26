import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Chip, Paper, Skeleton, Stack, Table, TableBody, TableCell, TableHead, TableRow, Typography } from '@mui/material'
import { adminApi } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { usePreviewMode } from '../layout/PreviewContext'
import { formatDate } from './TransactionsPage'

export function CustomerDetailPage() {
  const { id = '' } = useParams()
  const preview = usePreviewMode()
  const query = useQuery({ queryKey: ['customer', id], queryFn: () => adminApi.getCustomer(id), enabled: adminApi.configured && !preview && !!id })
  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">CUSTOMERS / PROFILE</Typography><Typography variant="h4">Customer details</Typography><Typography color="text.secondary">Only masked contact/account data and authorized activity are displayed.</Typography></Box></Box>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests live customer details.' : 'Customer detail service is not configured. No worksheet data is used.'} />
      : query.isPending ? <Skeleton variant="rounded" height={260} />
        : query.isError ? <Alert severity="error">Customer details unavailable. The backend did not return authorized customer data.</Alert>
          : query.data && <>
            <Paper className="detail-panel" elevation={0}><Stack direction="row" justifyContent="space-between"><Box><Typography variant="overline" color="text.secondary">CUSTOMER ID</Typography><Typography variant="h5">{query.data.id}</Typography><Typography>{query.data.name}</Typography></Box><Chip label={query.data.status} variant="outlined" /></Stack><Box className="detail-grid" sx={{ mt: 3 }}>{[['Phone', query.data.phoneMasked], ['Email', query.data.emailMasked], ['Registered', formatDate(query.data.createdAt)], ['Last activity', formatDate(query.data.lastActivityAt)]].map(([label, value]) => <Box key={label}><Typography variant="caption" color="text.secondary">{label}</Typography><Typography fontWeight={650}>{value || 'Not provided by API'}</Typography></Box>)}</Box></Paper>
            <Paper className="panel" elevation={0} sx={{ mt: 2 }}><Typography variant="h6" sx={{ mb: 1 }}>Accounts</Typography>{query.data.accounts?.length ? <Table size="small"><TableHead><TableRow>{['Account ID', 'Type', 'Masked number', 'Currency', 'Status'].map(label => <TableCell key={label}>{label}</TableCell>)}</TableRow></TableHead><TableBody>{query.data.accounts.map(account => <TableRow key={account.id}><TableCell>{account.id}</TableCell><TableCell>{account.type}</TableCell><TableCell>{account.maskedNumber ?? '—'}</TableCell><TableCell>{account.currency ?? '—'}</TableCell><TableCell>{account.status}</TableCell></TableRow>)}</TableBody></Table> : <Typography color="text.secondary" sx={{ py: 2 }}>No account data supplied by the authorized customer service.</Typography>}</Paper>
            <Paper className="panel" elevation={0} sx={{ mt: 2 }}><Typography variant="h6">Recent activity</Typography>{query.data.activity?.length ? query.data.activity.map(event => <Stack key={event.id} direction="row" justifyContent="space-between" sx={{ py: 1.5, borderBottom: '1px solid #edf0f1' }}><Typography>{event.event}</Typography><Typography variant="body2" color="text.secondary">{formatDate(event.at)}</Typography></Stack>) : <Typography color="text.secondary" sx={{ py: 2 }}>No activity history supplied by the authorized customer service.</Typography>}</Paper>
          </>}
  </>
}
