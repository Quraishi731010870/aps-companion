import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Alert, Button, Chip, Dialog, DialogActions, DialogContent, DialogContentText, DialogTitle, Stack, TextField, type ChipProps } from '@mui/material'
import { adminApi, AdminApiError, type StatusAction, type StatusTarget } from '../api/adminApi'
import { useAuth } from '../auth/AuthContext'

const statusColor: Record<string, ChipProps['color']> = { active: 'success', blocked: 'error', disabled: 'default', locked: 'warning', pending: 'warning', closed: 'default' }

export function StatusChip({ status }: { status: string }) {
  return <Chip size="small" variant="outlined" color={statusColor[status] ?? 'default'} label={status} />
}

const actionLabel: Record<StatusAction, string> = { activate: 'Activate', deactivate: 'Deactivate', block: 'Block', unblock: 'Unblock' }
const actionColor: Record<StatusAction, 'primary' | 'warning' | 'error' | 'success'> = { activate: 'success', deactivate: 'warning', block: 'error', unblock: 'primary' }
const targetLabel: Record<StatusTarget['kind'], string> = { customer: 'customer', account: 'account', card: 'card', device: 'device' }

/** What each action does to the customer, so the operator confirms knowingly. */
function consequence(kind: StatusTarget['kind'], action: StatusAction): string {
  const restore = action === 'activate' || action === 'unblock'
  if (kind === 'customer') return restore ? 'The customer can sign in and make payments again.' : 'The customer is signed out on every device and cannot sign in or make payments.'
  if (kind === 'account') return restore ? 'Payments from this wallet are allowed again.' : 'The wallet is hidden in the app and payments are refused.'
  if (kind === 'card') return restore ? 'The customer can pay with this card again.' : 'Payments with this card are refused, including when it is typed in again.'
  return restore ? 'The customer can sign in from this device again.' : 'Sessions on this device end at once and its signed requests are refused.'
}

/**
 * Buttons for the actions the backend allows on an item, behind
 * `customers.manage`. Each action asks for a reason, which is audited.
 */
export function StatusActions({ target, actions, name }: { target: StatusTarget; actions?: StatusAction[]; name: string }) {
  const { session } = useAuth()
  const [pending, setPending] = useState<StatusAction | null>(null)
  if (!session?.permissions.includes('customers.manage') || !actions?.length) return null
  return <>
    <Stack direction="row" spacing={1} justifyContent="flex-end">
      {actions.map(action => <Button key={action} size="small" variant="outlined" color={actionColor[action]} onClick={() => setPending(action)}>{actionLabel[action]}</Button>)}
    </Stack>
    {pending && <StatusActionDialog target={target} action={pending} name={name} onClose={() => setPending(null)} />}
  </>
}

function StatusActionDialog({ target, action, name, onClose }: { target: StatusTarget; action: StatusAction; name: string; onClose: () => void }) {
  const client = useQueryClient()
  const [reason, setReason] = useState('')
  const mutation = useMutation({
    mutationFn: () => adminApi.updateStatus(target, action, reason.trim()),
    onSuccess: async () => {
      await Promise.all([client.invalidateQueries({ queryKey: ['customer', target.customerId] }), client.invalidateQueries({ queryKey: ['customers'] })])
      onClose()
    },
  })
  const title = `${actionLabel[action]} ${targetLabel[target.kind]}`
  return <Dialog open onClose={mutation.isPending ? undefined : onClose} fullWidth maxWidth="sm">
    <DialogTitle>{title}</DialogTitle>
    <DialogContent>
      <DialogContentText sx={{ mb: 2 }}><strong>{name}</strong>. {consequence(target.kind, action)}</DialogContentText>
      <TextField autoFocus fullWidth multiline minRows={2} label="Reason (recorded in the audit log)" value={reason} onChange={event => setReason(event.target.value)} inputProps={{ maxLength: 500 }} />
      {mutation.isError && <Alert severity="error" sx={{ mt: 2 }}>{mutation.error instanceof AdminApiError ? mutation.error.message : 'The change could not be saved.'}</Alert>}
    </DialogContent>
    <DialogActions>
      <Button onClick={onClose} disabled={mutation.isPending}>Cancel</Button>
      <Button variant="contained" color={actionColor[action]} disabled={reason.trim().length < 3 || mutation.isPending} onClick={() => mutation.mutate()}>{title}</Button>
    </DialogActions>
  </Dialog>
}
