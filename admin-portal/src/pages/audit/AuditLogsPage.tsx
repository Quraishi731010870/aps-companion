import { Alert, Box, Chip, Paper, Skeleton, Table, TableBody, TableCell, TableHead, TableRow, Typography } from '@mui/material'
import { useQuery } from '@tanstack/react-query'
import { adminApi } from '../../api/adminApi'

export function AuditLogsPage() {
  const query = useQuery({ queryKey: ['audit-logs'], queryFn: () => adminApi.listAuditLogs() })
  return <><Box className="page-heading"><Box><Typography variant="overline">SECURITY / GOVERNANCE</Typography><Typography variant="h4">Audit logs</Typography><Typography color="text.secondary">Append-oriented administrative activity from the backend.</Typography></Box></Box>{query.isPending ? <Skeleton variant="rounded" height={320} /> : query.isError ? <Alert severity="error">Audit logs could not be loaded.</Alert> : <Paper className="panel" elevation={0}><Table size="small"><TableHead><TableRow><TableCell>Time</TableCell><TableCell>Actor</TableCell><TableCell>Action</TableCell><TableCell>Resource</TableCell><TableCell>Result</TableCell><TableCell>Request ID</TableCell></TableRow></TableHead><TableBody>{query.data?.items.map(item => <TableRow key={item.id}><TableCell>{new Date(item.createdAt).toLocaleString()}</TableCell><TableCell>{item.actorSnapshot}</TableCell><TableCell>{item.action}</TableCell><TableCell>{item.resource}{item.resourceId ? ` / ${item.resourceId}` : ''}</TableCell><TableCell><Chip size="small" label={item.result} color={item.result === 'SUCCESS' ? 'success' : 'error'} /></TableCell><TableCell>{item.requestId}</TableCell></TableRow>)}</TableBody></Table></Paper>}</>
}
