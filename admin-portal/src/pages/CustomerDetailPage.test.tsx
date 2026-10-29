import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { AdminPermission, CustomerDetails } from '../api/adminApi'
import { CustomerDetailPage } from './CustomerDetailPage'

const api = vi.hoisted(() => ({ configured: true, getCustomer: vi.fn(), updateStatus: vi.fn() }))
const auth = vi.hoisted(() => ({ permissions: [] as AdminPermission[] }))
vi.mock('../api/adminApi', async (original) => ({ ...(await original<typeof import('../api/adminApi')>()), adminApi: api }))
vi.mock('../auth/AuthContext', () => ({ useAuth: () => ({ session: { permissions: auth.permissions } }) }))

const customer: CustomerDetails = {
  id: 'c-1', customerNo: 'DEMO-CUS-001', name: 'Demo Customer 001', status: 'active', actions: ['deactivate', 'block'],
  accounts: [{ id: 'a-1', type: 'WALLET', maskedNumber: '***********0001', currency: 'AFN', availableBalance: 0, status: 'active', actions: ['deactivate', 'block'] }],
  cards: [{ id: 'card-1', maskedPan: '603799******1234', status: 'blocked', actions: ['unblock'] }],
  devices: [{ id: 'd-1', platform: 'ANDROID', name: 'Pixel', status: 'active', actions: ['deactivate', 'block'] }],
}

function renderPage() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(<QueryClientProvider client={client}><MemoryRouter initialEntries={['/customers/c-1']}><Routes><Route path="/customers/:id" element={<CustomerDetailPage />} /></Routes></MemoryRouter></QueryClientProvider>)
}

describe('CustomerDetailPage status controls', () => {
  beforeEach(() => {
    api.getCustomer.mockReset().mockResolvedValue(customer)
    api.updateStatus.mockReset().mockResolvedValue({ id: 'card-1', status: 'active' })
  })

  it('shows statuses but no actions without customers.manage', async () => {
    auth.permissions = ['customers.view']
    renderPage()
    expect(await screen.findByText('603799******1234')).toBeInTheDocument()
    expect(screen.getAllByText('blocked')).toHaveLength(1)
    expect(screen.queryByRole('button', { name: 'Block' })).not.toBeInTheDocument()
  })

  it('unblocks a card only after a reason is given, then reloads the customer', async () => {
    auth.permissions = ['customers.view', 'customers.manage']
    renderPage()
    fireEvent.click(await screen.findByRole('button', { name: 'Unblock' }))
    const confirm = screen.getByRole('button', { name: 'Unblock card' })
    expect(confirm).toBeDisabled()
    fireEvent.change(screen.getByLabelText(/Reason/), { target: { value: 'Customer verified at branch' } })
    fireEvent.click(confirm)
    await waitFor(() => expect(api.updateStatus).toHaveBeenCalledWith({ kind: 'card', customerId: 'c-1', id: 'card-1' }, 'unblock', 'Customer verified at branch'))
    await waitFor(() => expect(api.getCustomer).toHaveBeenCalledTimes(2))
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
  })

  it('offers the actions the backend allows for each item', async () => {
    auth.permissions = ['customers.view', 'customers.manage']
    renderPage()
    await screen.findByText('Demo Customer 001')
    // Customer, wallet and device each offer deactivate and block; the blocked card offers unblock only.
    expect(screen.getAllByRole('button', { name: 'Block' })).toHaveLength(3)
    expect(screen.getAllByRole('button', { name: 'Unblock' })).toHaveLength(1)
    expect(screen.queryByRole('button', { name: 'Activate' })).not.toBeInTheDocument()
  })
})
