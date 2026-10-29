import { describe, expect, it, vi } from 'vitest'
import { AdminApiError, FetchAdminApi } from './adminApi'

function json(body: unknown, status = 200) {
  return new Response(body === undefined ? null : JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })
}

describe('FetchAdminApi security and request contract', () => {
  it('calls the global fetch unbound, as browsers require', async () => {
    // Native fetch throws "Illegal invocation" when called with another object as `this`.
    const strictFetch = vi.fn(function (this: unknown) {
      if (this !== undefined && this !== globalThis) throw new TypeError('Illegal invocation')
      return Promise.resolve(json({ csrfToken: 'csrf-test' }))
    })
    vi.stubGlobal('fetch', strictFetch)
    try {
      const api = new FetchAdminApi('http://localhost:8080')
      await expect(api.login('operator', 'password-value')).resolves.toBeDefined()
      expect(strictFetch).toHaveBeenCalledTimes(2)
    } finally {
      vi.unstubAllGlobals()
    }
  })

  it('loads an HttpOnly-cookie session and sends no browser bearer token', async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(json({ csrfToken: 'csrf-test' })).mockResolvedValueOnce(json({ adminId: 'a-1', displayName: 'Operator', role: 'Operations', permissions: ['transactions.view'], expiresAt: '2026-10-01T00:00:00Z' }))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await api.login('operator', 'password-value')
    const [csrfCall, loginCall] = fetcher.mock.calls
    expect(csrfCall[0]).toBe('http://localhost:8080/api/admin/v1/auth/csrf')
    expect(loginCall[1]?.credentials).toBe('include')
    expect(new Headers(loginCall[1]?.headers).get('X-CSRF-Token')).toBe('csrf-test')
    expect(new Headers(loginCall[1]?.headers).has('Authorization')).toBe(false)
    expect(loginCall[1]?.body).toContain('password-value')
    expect(localStorage.length).toBe(0)
  })

  it('serializes filters and pagination to the backend instead of filtering in-browser', async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(json({ items: [], total: 0, page: 0, pageSize: 25 }))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await api.listTransactions({ page: 0, pageSize: 25, sort: 'createdAt:desc', status: 'failed', operation: '700', responseCode: '522', dateFrom: '2026-09-27', phone: '+93700000000' })
    const requestUrl = new URL(fetcher.mock.calls[0][0] as string)
    expect(requestUrl.searchParams.get('status')).toBe('failed')
    expect(requestUrl.searchParams.get('operation')).toBe('700')
    expect(requestUrl.searchParams.get('responseCode')).toBe('522')
    expect(requestUrl.searchParams.get('phone')).toBe('+93700000000')
  })

  it('fails closed for insecure API URLs and sanitizes server error bodies', async () => {
    const insecure = new FetchAdminApi('http://api.example.test')
    await expect(insecure.getDashboard()).rejects.toMatchObject({ code: 'integration_required' })
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(new Response('sensitive internal trace', { status: 500 }))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await expect(api.getDashboard()).rejects.toEqual(expect.objectContaining({ code: 'server', message: 'The admin service returned HTTP 500.' }))
    await expect(api.getDashboard()).rejects.not.toThrow('sensitive internal trace')
  })

  it('signals expired sessions and surfaces forbidden responses safely', async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(json({}, 403))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await expect(api.getDashboard()).rejects.toMatchObject({ code: 'forbidden' })
    const unauthorizedFetch = vi.fn<typeof fetch>().mockResolvedValueOnce(json({}, 401))
    const unauthorizedApi = new FetchAdminApi('http://localhost:8080', unauthorizedFetch)
    const expired = vi.fn()
    window.addEventListener('admin:unauthorized', expired, { once: true })
    await expect(unauthorizedApi.getDashboard()).rejects.toBeInstanceOf(AdminApiError)
    expect(expired).toHaveBeenCalledOnce()
  })

  it('sends status actions with a reason and CSRF token to the matching resource', async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(json({ csrfToken: 'csrf-test' })).mockImplementation(async () => json({ id: 'x', status: 'blocked' }))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await api.updateStatus({ kind: 'customer', customerId: 'c-1' }, 'block', 'Suspected fraud')
    await api.updateStatus({ kind: 'card', customerId: 'c-1', id: 'card-1' }, 'unblock', 'Cleared')
    const [, customerCall, cardCall] = fetcher.mock.calls
    expect(customerCall[0]).toBe('http://localhost:8080/api/v1/customers/c-1/status')
    expect(customerCall[1]).toMatchObject({ method: 'PATCH', body: JSON.stringify({ action: 'block', reason: 'Suspected fraud' }), headers: expect.objectContaining({ 'X-CSRF-Token': 'csrf-test' }) })
    expect(cardCall[0]).toBe('http://localhost:8080/api/v1/customers/c-1/cards/card-1/status')
  })

  it('reports a refused status transition as a conflict', async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValueOnce(json({ csrfToken: 'csrf-test' })).mockResolvedValueOnce(json({ code: 'STATUS_TRANSITION_INVALID' }, 409))
    const api = new FetchAdminApi('http://localhost:8080', fetcher)
    await expect(api.updateStatus({ kind: 'device', customerId: 'c-1', id: 'd-1' }, 'activate', 'Retry')).rejects.toMatchObject({ code: 'conflict' })
  })
})
