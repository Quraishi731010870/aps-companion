import { useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Chip, Divider, Paper, Skeleton, Stack, Typography } from '@mui/material'
import { adminApi } from '../api/adminApi'
import { BackendState } from '../components/BackendState'
import { usePreviewMode } from '../layout/PreviewContext'
import { formatDate } from './TransactionsPage'

export function TransactionDetailPage() {
  const { id = '' } = useParams()
  const preview = usePreviewMode()
  const query = useQuery({ queryKey: ['transaction', id], queryFn: () => adminApi.getTransaction(id), enabled: adminApi.configured && !preview && !!id })

  return <>
    <Box className="page-heading"><Box><Typography variant="overline" color="primary">OPERATIONS / TRANSACTIONS</Typography><Typography variant="h4">Transaction detail</Typography><Typography color="text.secondary">Processing information and timeline as returned by the backend.</Typography></Box></Box>
    {!adminApi.configured || preview
      ? <BackendState detail={preview ? 'Preview mode never requests live transaction details.' : 'Transaction details, request/response traces, lifecycle events, and safe transaction controls require a protected backend API.'} />
      : query.isPending ? <Skeleton variant="rounded" height={220} />
        : query.isError ? <Alert severity="error">Transaction detail unavailable. The backend did not return authorized transaction details.</Alert>
          : query.data && <>
            <Paper className="detail-panel" elevation={0}>
              <Stack direction="row" justifyContent="space-between"><Box><Typography variant="overline" color="text.secondary">TRANSACTION ID</Typography><Typography variant="h5">{query.data.id}</Typography></Box><Chip label={query.data.status} variant="outlined" /></Stack>
              <Divider sx={{ my: 2 }} />
              <Box className="detail-grid">{[
                ['RRN / Reference', query.data.rrn ?? query.data.reference],
                ['Type', query.data.operationLabel],
                ['Amount', `${new Intl.NumberFormat('en-US').format(query.data.amount)} ${query.data.currency}`],
                ['Date and time', formatDate(query.data.createdAt)],
                ['Source', query.data.source], ['Destination', query.data.destination],
                ['Channel', query.data.channel], ['Response code', query.data.responseCode],
              ].map(([key, value]) => <Box key={key}><Typography variant="caption" color="text.secondary">{key}</Typography><Typography fontWeight={650}>{value || 'Not provided by API'}</Typography></Box>)}</Box>
            </Paper>
            <Paper className="panel" elevation={0}>
              <Typography variant="h6">Processing timeline</Typography>
              {query.data.timeline?.length
                ? <Box className="timeline">{query.data.timeline.map((event, index) => <Box key={`${event.at}-${index}`} className="timeline-item"><span className="timeline-dot" /><Box><Typography fontWeight={700}>{event.label}</Typography><Typography variant="body2" color="text.secondary">{formatDate(event.at)}{event.detail ? ` · ${event.detail}` : ''}</Typography></Box></Box>)}</Box>
                : <Typography color="text.secondary" sx={{ py: 3 }}>No lifecycle events were returned. Stages are not inferred.</Typography>}
            </Paper>
          </>}
  </>
}
