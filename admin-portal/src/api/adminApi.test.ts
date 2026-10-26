import { describe, expect, it } from 'vitest'
import { adminApi, AdminApiError } from './adminApi'

describe('admin API boundary', () => {
  it('fails closed when no authenticated backend adapter is configured', async () => {
    expect(adminApi.configured).toBe(false)
    await expect(adminApi.getDashboard()).rejects.toMatchObject({ code: 'integration_required' })
    await expect(adminApi.listTransactions({ page: 0, pageSize: 25, sort: 'createdAt:desc' }))
      .rejects.toBeInstanceOf(AdminApiError)
  })

  it('does not accept authentication or store a local token without a backend', async () => {
    await expect(adminApi.login('operator', 'not-a-real-password'))
      .rejects.toMatchObject({ code: 'integration_required' })
  })
})
