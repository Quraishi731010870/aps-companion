import { Alert, Box, Chip, Paper, Skeleton, Table, TableBody, TableCell, TableHead, TableRow, Typography } from '@mui/material'
import { useQuery } from '@tanstack/react-query'
import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from 'recharts'
import { adminApi } from '../api/adminApi'

const colors = ['#16866e', '#d49a3a', '#bb4b48', '#4b78a0', '#7d6ba8', '#718388']

export function ReportsPage() {
  const transactions = useQuery({ queryKey: ['reports', 'transactions'], queryFn: () => adminApi.getTransactionReport() })
  const users = useQuery({ queryKey: ['reports', 'users'], queryFn: () => adminApi.getUserReport() })
  if (transactions.isPending || users.isPending) return <><Heading /><Skeleton variant="rounded" height={360} /></>
  if (transactions.isError || users.isError) return <><Heading /><Alert severity="error">Report data could not be loaded from the backend.</Alert></>
  const statusData = transactions.data.map(row => ({ name: row.status, value: row._count }))
  return <><Heading /><Box className="metric-grid"><Paper className="metric-card" elevation={0}><Typography color="text.secondary">Total users</Typography><Typography variant="h4">{users.data.total}</Typography></Paper>{users.data.byStatus.map(row => <Paper className="metric-card" elevation={0} key={row.status}><Typography color="text.secondary">{row.status.toLowerCase()} users</Typography><Typography variant="h4">{row._count}</Typography></Paper>)}</Box><Box className="two-column"><Paper className="panel" elevation={0} sx={{ p: 2.5 }}><Typography variant="h6">Transaction status distribution</Typography><Box sx={{ height: 280 }}><ResponsiveContainer width="100%" height="100%"><PieChart><Pie data={statusData} dataKey="value" nameKey="name" innerRadius={58} outerRadius={90} paddingAngle={2}>{statusData.map((row, index) => <Cell key={row.name} fill={colors[index % colors.length]} />)}</Pie><Tooltip /><Legend /></PieChart></ResponsiveContainer></Box></Paper><Paper className="table-panel" elevation={0}><Table size="small"><TableHead><TableRow><TableCell>Status</TableCell><TableCell>Currency</TableCell><TableCell align="right">Count</TableCell><TableCell align="right">Amount</TableCell></TableRow></TableHead><TableBody>{transactions.data.map(row => <TableRow key={`${row.status}-${row.currency}`}><TableCell><Chip size="small" variant="outlined" label={row.status} /></TableCell><TableCell>{row.currency}</TableCell><TableCell align="right">{row._count}</TableCell><TableCell align="right">{new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 }).format(Number(row._sum.amount ?? 0))}</TableCell></TableRow>)}</TableBody></Table></Paper></Box></>
}

function Heading() { return <Box className="page-heading"><Box><Typography variant="overline">ANALYTICS / REPORTING</Typography><Typography variant="h4">Operational reports</Typography><Typography color="text.secondary">Live aggregates calculated from authoritative PostgreSQL records.</Typography></Box></Box> }
