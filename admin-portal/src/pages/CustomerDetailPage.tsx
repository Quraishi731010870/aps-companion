import type { ReactNode } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Paper, Skeleton, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography } from '@mui/material'
import { adminApi } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { StatusActions, StatusChip } from '../components/StatusControls'
import { usePreviewMode } from '../layout/PreviewContext'
import { formatDate } from './TransactionsPage'

export function CustomerDetailPage() {
  const { id = '' } = useParams()
  const preview = usePreviewMode()
  const query = useQuery({ queryKey: ['customer', id], queryFn: () => adminApi.getCustomer(id), enabled: adminApi.configured && !preview && !!id })
  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">CUSTOMERS / PROFILE</Typography><Typography variant="h4">Customer details</Typography><Typography color="text.secondary">Only masked contact, account and card data is displayed. Status changes are audited with a reason.</Typography></Box></Box>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests live customer details.' : 'Customer detail service is not configured. No worksheet data is used.'} />
      : query.isPending ? <Skeleton variant="rounded" height={260} />
        : query.isError ? <Alert severity="error">Customer details unavailable. The backend did not return authorized customer data.</Alert>
          : <>
            <Paper className="detail-panel" elevation={0}>
              <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" gap={2}>
                <Box><Typography variant="overline" color="text.secondary">CUSTOMER {query.data.customerNo ?? 'ID'}</Typography><Typography variant="h5">{query.data.name}</Typography><Typography variant="body2" color="text.secondary">{query.data.id}</Typography></Box>
                <Stack spacing={1} alignItems={{ xs: 'flex-start', sm: 'flex-end' }}><StatusChip status={query.data.status} /><StatusActions target={{ kind: 'customer', customerId: id }} actions={query.data.actions} name={query.data.name} /></Stack>
              </Stack>
              <Box className="detail-grid" sx={{ mt: 3 }}>{[['Phone', query.data.phoneMasked], ['Email', query.data.emailMasked], ['KYC', query.data.kycStatus], ['Registered', formatDate(query.data.createdAt)], ['Last activity', formatDate(query.data.lastActivityAt)]].map(([label, value]) => <Box key={label}><Typography variant="caption" color="text.secondary">{label}</Typography><Typography fontWeight={650}>{value || 'Not provided by API'}</Typography></Box>)}</Box>
            </Paper>
            <ControlPanel title="Wallet accounts" empty="No accounts for this customer." headers={['Account', 'Type', 'Currency', 'Balance']}>
              {query.data.accounts?.map(account => <TableRow key={account.id}><TableCell>{account.maskedNumber ?? account.id}</TableCell><TableCell>{account.type}</TableCell><TableCell>{account.currency ?? '—'}</TableCell><TableCell>{account.availableBalance?.toLocaleString(undefined, { minimumFractionDigits: 2 }) ?? '—'}</TableCell><StatusCells status={account.status}><StatusActions target={{ kind: 'account', customerId: id, id: account.id }} actions={account.actions} name={`Account ${account.maskedNumber ?? account.id}`} /></StatusCells></TableRow>)}
            </ControlPanel>
            <ControlPanel title="Saved cards" empty="No saved cards. Cards the customer removed are not listed." headers={['Card', 'Linked']}>
              {query.data.cards?.map(card => <TableRow key={card.id}><TableCell sx={{ fontFamily: 'monospace' }}>{card.maskedPan}</TableCell><TableCell>{formatDate(card.createdAt)}</TableCell><StatusCells status={card.status}><StatusActions target={{ kind: 'card', customerId: id, id: card.id }} actions={card.actions} name={`Card ${card.maskedPan}`} /></StatusCells></TableRow>)}
            </ControlPanel>
            <ControlPanel title="Devices" empty="No devices registered." headers={['Device', 'Platform', 'Bound', 'Last seen']}>
              {query.data.devices?.map(device => <TableRow key={device.id}><TableCell>{device.name || device.id}</TableCell><TableCell>{device.platform}</TableCell><TableCell>{formatDate(device.boundAt ?? undefined)}</TableCell><TableCell>{formatDate(device.lastSeenAt ?? undefined)}</TableCell><StatusCells status={device.status}><StatusActions target={{ kind: 'device', customerId: id, id: device.id }} actions={device.actions} name={`${device.platform} device ${device.name || device.id}`} /></StatusCells></TableRow>)}
            </ControlPanel>
            <Paper className="panel" elevation={0} sx={{ mt: 2 }}><Typography variant="h6">Recent activity</Typography>{query.data.activity?.length ? query.data.activity.map(event => <Stack key={event.id} direction="row" justifyContent="space-between" sx={{ py: 1.5, borderBottom: '1px solid #edf0f1' }}><Typography>{event.event}</Typography><Typography variant="body2" color="text.secondary">{formatDate(event.at)}</Typography></Stack>) : <Typography color="text.secondary" sx={{ py: 2 }}>No activity history supplied by the authorized customer service.</Typography>}</Paper>
          </>}
  </>
}

function ControlPanel({ title, empty, headers, children }: { title: string; empty: string; headers: string[]; children?: ReactNode[] }) {
  return <Paper className="panel" elevation={0} sx={{ mt: 2 }}>
    <Typography variant="h6" sx={{ mb: 1 }}>{title}</Typography>
    {children?.length
      ? <TableContainer><Table size="small"><TableHead><TableRow>{[...headers, 'Status', ''].map(label => <TableCell key={label}>{label}</TableCell>)}</TableRow></TableHead><TableBody>{children}</TableBody></Table></TableContainer>
      : <Typography color="text.secondary" sx={{ py: 2 }}>{empty}</Typography>}
  </Paper>
}

function StatusCells({ status, children }: { status: string; children: ReactNode }) {
  return <><TableCell><StatusChip status={status} /></TableCell><TableCell align="right">{children}</TableCell></>
}
