import { Alert, Box, Chip, Paper, Stack, Typography } from '@mui/material'
import { ErrorOutlineRounded } from '@mui/icons-material'

export function IntegrationRequiredPage({ title, detail }: { title: string; detail: string }) {
  return <Box>
    <Typography variant="h4" className="page-title">{title}</Typography>
    <Typography color="text.secondary" sx={{ mb: 3 }}>Operational data and actions are available only through an authenticated backend.</Typography>
    <Paper className="integration-detail" elevation={0}>
      <Stack direction="row" spacing={2} alignItems="flex-start">
        <ErrorOutlineRounded color="warning" sx={{ fontSize: 32 }} />
        <Box><Typography variant="h6">Backend integration required</Typography><Typography color="text.secondary" sx={{ mt: 1 }}>{detail}</Typography></Box>
        <Chip label="NOT CONNECTED" color="warning" variant="outlined" />
      </Stack>
      <Alert severity="info" sx={{ mt: 2 }}>No sample production records are generated or displayed. This page will become operational when the authorized API is available.</Alert>
    </Paper>
  </Box>
}
