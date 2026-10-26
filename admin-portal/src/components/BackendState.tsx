import { Alert, Paper, Stack, Typography } from '@mui/material'
import { ErrorOutlineRounded } from '@mui/icons-material'

export function BackendState({ detail = 'This project does not currently expose an authenticated admin API for this data. No sample or fabricated records are displayed.' }: { detail?: string }) {
  return <Paper className="backend-state" elevation={0}><Stack direction="row" spacing={1.5} alignItems="flex-start"><ErrorOutlineRounded color="warning" /><div><Typography variant="h6">Backend integration required</Typography><Typography color="text.secondary">{detail}</Typography></div></Stack><Alert severity="warning" variant="outlined" sx={{ mt: 2 }}>No live data source configured · mutations disabled</Alert></Paper>
}
