import { environment, isTrustedAdminApiUrl } from '../config/environment'

export type AdminPermission =
  | 'dashboard.view' | 'customers.view' | 'customers.manage' | 'users.view' | 'users.create' | 'users.update' | 'users.disable'
  | 'transactions.view' | 'transactions.search' | 'transactions.export' | 'transactions.reverse' | 'reports.view' | 'reports.export'
  | 'notifications.view' | 'notifications.create' | 'notifications.send' | 'monitoring.view' | 'monitoring.manage'
  | 'configuration.view' | 'configuration.update' | 'audit.view'

export interface AdminSession {
  adminId: string
  displayName: string
  role: string
  permissions: AdminPermission[]
  expiresAt: string
}

export interface DashboardSummary {
  usersTotal?: number
  usersActive?: number
  customersTotal?: number
  customersActive?: number
  transactionsTotal?: number
  successRate?: number
  successfulTransactions?: number
  failedTransactions?: number
  pendingTransactions?: number
  reversedTransactions?: number
  transactionAmount?: string
  trend?: Array<{ label: string; value: number }>
  services?: Array<{ name: string; status: 'healthy' | 'warning' | 'critical' | 'unavailable' }>
  recentActivity?: Array<{ id: string; type: string; customer?: string; amount: string; currency: string; status: string; createdAt: string }>
}

export interface TransactionFilters {
  page: number
  pageSize: number
  sort: string
  search?: string
  transactionId?: string
  reference?: string
  customer?: string
  account?: string
  phone?: string
  operation?: string
  status?: string
  responseCode?: string
  dateFrom?: string
  dateTo?: string
  timeFrom?: string
  timeTo?: string
  amountFrom?: string
  amountTo?: string
  currency?: string
  channel?: string
  source?: string
  destination?: string
}

export interface Transaction {
  id: string
  rrn?: string
  reference?: string
  customer?: string
  operationCode: number
  operationLabel: string
  amount: number
  currency: string
  status: string
  source?: string
  destination?: string
  channel?: string
  createdAt: string
  updatedAt?: string
  responseCode?: string
  timeline?: Array<{ label: string; at: string; detail?: string }>
  supportedActions?: string[]
}

export interface Customer {
  id: string
  customerNo?: string
  name: string
  phoneMasked?: string
  status: string
  createdAt?: string
  lastActivityAt?: string
}
/** Operator actions; the backend decides which apply (`actions`) from the current status. */
export type StatusAction = 'activate' | 'deactivate' | 'block' | 'unblock'
export interface Controlled { status: string; actions?: StatusAction[] }
export interface CustomerAccount extends Controlled { id: string; type: string; maskedNumber?: string; currency?: string; availableBalance?: number }
export interface CustomerCard extends Controlled { id: string; maskedPan: string; createdAt?: string }
export interface CustomerDevice extends Controlled { id: string; platform: string; name?: string | null; boundAt?: string | null; lastSeenAt?: string | null }
export interface CustomerDetails extends Customer {
  emailMasked?: string
  kycStatus?: string
  actions?: StatusAction[]
  accounts?: CustomerAccount[]
  cards?: CustomerCard[]
  devices?: CustomerDevice[]
  activity?: Array<{ id: string; event: string; at: string }>
}
/** What a status action applies to: the customer itself, or one of their accounts, cards or devices. */
export type StatusTarget =
  | { kind: 'customer'; customerId: string }
  | { kind: 'account' | 'card' | 'device'; customerId: string; id: string }
export interface CustomerFilters {
  page: number; pageSize: number; search?: string; status?: string; sort?: string
  dateFrom?: string; dateTo?: string; lastActivityFrom?: string; lastActivityTo?: string
}

export interface Page<T> { items: T[]; total: number; page: number; pageSize: number }
export interface SystemConfiguration { id: string; key: string; value: Record<string, unknown>; scope: string; description: string; version: number; updatedAt: string }
export interface FeatureFlag { id: string; key: string; name: string; enabled: boolean; platform: string; minimumVersion?: string; configuration: Record<string, unknown>; version: number; updatedAt: string }
export interface AuditRecord { id: string; actorSnapshot: string; action: string; resource: string; resourceId?: string; oldValue?: unknown; newValue?: unknown; requestId: string; result: string; createdAt: string }
export interface AdminUser { id: string; email?: string; phone?: string; displayName: string; principalType: string; status: string; createdAt: string; roles: Array<{ role: { code: string; name: string } }> }
export interface NotificationRecord { id: string; title: string; body: string; status: string; createdAt: string; sentAt?: string }
export interface DynamicContent { id: string; key: string; locale: string; platform: string; title: string; body: string; enabled: boolean; metadata: Record<string, unknown>; version: number; updatedAt: string }
export interface TransactionReportRow { status: string; currency: string; _count: number; _sum: { amount: string | number | null } }
export interface UserReport { total: number; byStatus: Array<{ status: string; _count: number }> }
export type ServiceStatus = 'healthy' | 'warning' | 'critical' | 'unavailable'
export interface MonitoringService { name: string; status: ServiceStatus; checkedAt?: string; detail?: string }
export interface MonitoringOverview {
  services: MonitoringService[]
  integrations: { zabbix: ServiceStatus; grafana: ServiceStatus }
  infrastructure?: Array<{ name: string; value: number; unit: string; status: ServiceStatus }>
  alerts?: { critical: number; high: number; warning: number; info: number }
}
export interface TransactionMonitoring {
  volume: number
  successRate: number
  failureRate: number
  declineRate: number
  pending: number
  reversals: number
  latencyMs?: number
  trend?: Array<{ label: string; successful: number; failed: number; pending: number }>
  byType?: Array<{ label: string; count: number }>
  byResponseCode?: Array<{ label: string; count: number }>
  latencyTrend?: Array<{ label: string; milliseconds: number }>
}
export interface AlertRecord {
  id: string; source: string; host?: string; service?: string; description: string
  severity: 'critical' | 'high' | 'medium' | 'warning' | 'info'
  status: string; createdAt: string; updatedAt?: string
}
export interface AlertFilters {
  page: number; pageSize: number; severity?: string; source?: string
  host?: string; service?: string; status?: string; dateFrom?: string; dateTo?: string
}

export class AdminApiError extends Error {
  constructor(readonly code: 'integration_required' | 'unauthorized' | 'forbidden' | 'network' | 'server' | 'validation' | 'conflict', message: string) {
    super(message)
    this.name = 'AdminApiError'
  }
}

export interface AdminApi {
  readonly configured: boolean
  getSession(): Promise<AdminSession>
  login(operator: string, password: string): Promise<AdminSession>
  logout(): Promise<void>
  getDashboard(): Promise<DashboardSummary>
  listTransactions(filters: TransactionFilters): Promise<Page<Transaction>>
  getTransaction(id: string): Promise<Transaction>
  listCustomers(filters: CustomerFilters): Promise<Page<Customer>>
  getCustomer(id: string): Promise<CustomerDetails>
  updateStatus(target: StatusTarget, action: StatusAction, reason: string): Promise<{ id: string; status: string }>
  getMonitoringOverview(): Promise<MonitoringOverview>
  getTransactionMonitoring(filters: Pick<TransactionFilters, 'dateFrom' | 'dateTo' | 'operation' | 'status' | 'channel' | 'source' | 'destination'>): Promise<TransactionMonitoring>
  listAlerts(filters: AlertFilters): Promise<Page<AlertRecord>>
  listConfiguration(): Promise<SystemConfiguration[]>
  updateConfiguration(key: string, value: Record<string, unknown>, description?: string): Promise<SystemConfiguration>
  listFeatures(): Promise<FeatureFlag[]>
  updateFeature(key: string, enabled: boolean): Promise<FeatureFlag>
  listAuditLogs(page?: number): Promise<Page<AuditRecord>>
  listUsers(page?: number, search?: string): Promise<Page<AdminUser>>
  updateUserStatus(id: string, status: string): Promise<AdminUser>
  listNotifications(page?: number): Promise<Page<NotificationRecord>>
  createNotification(title: string, body: string): Promise<NotificationRecord>
  listContent(): Promise<DynamicContent[]>
  updateContent(key: string, locale: string, value: Pick<DynamicContent, 'title' | 'body' | 'enabled' | 'metadata'>): Promise<DynamicContent>
  getTransactionReport(): Promise<TransactionReportRow[]>
  getUserReport(): Promise<UserReport>
}

class BackendRequiredApi implements AdminApi {
  readonly configured = false
  private unavailable(): never { throw new AdminApiError('integration_required', 'Authenticated Afghan EMI admin API is not configured.') }
  async getSession(): Promise<AdminSession> { return this.unavailable() }
  async login(): Promise<AdminSession> { return this.unavailable() }
  async logout(): Promise<void> { return this.unavailable() }
  async getDashboard(): Promise<DashboardSummary> { return this.unavailable() }
  async listTransactions(): Promise<Page<Transaction>> { return this.unavailable() }
  async getTransaction(): Promise<Transaction> { return this.unavailable() }
  async listCustomers(): Promise<Page<Customer>> { return this.unavailable() }
  async getCustomer(): Promise<CustomerDetails> { return this.unavailable() }
  async updateStatus(): Promise<{ id: string; status: string }> { return this.unavailable() }
  async getMonitoringOverview(): Promise<MonitoringOverview> { return this.unavailable() }
  async getTransactionMonitoring(): Promise<TransactionMonitoring> { return this.unavailable() }
  async listAlerts(): Promise<Page<AlertRecord>> { return this.unavailable() }
  async listConfiguration(): Promise<SystemConfiguration[]> { return this.unavailable() }
  async updateConfiguration(): Promise<SystemConfiguration> { return this.unavailable() }
  async listFeatures(): Promise<FeatureFlag[]> { return this.unavailable() }
  async updateFeature(): Promise<FeatureFlag> { return this.unavailable() }
  async listAuditLogs(): Promise<Page<AuditRecord>> { return this.unavailable() }
  async listUsers(): Promise<Page<AdminUser>> { return this.unavailable() }
  async updateUserStatus(): Promise<AdminUser> { return this.unavailable() }
  async listNotifications(): Promise<Page<NotificationRecord>> { return this.unavailable() }
  async createNotification(): Promise<NotificationRecord> { return this.unavailable() }
  async listContent(): Promise<DynamicContent[]> { return this.unavailable() }
  async updateContent(): Promise<DynamicContent> { return this.unavailable() }
  async getTransactionReport(): Promise<TransactionReportRow[]> { return this.unavailable() }
  async getUserReport(): Promise<UserReport> { return this.unavailable() }
}

/**
 * Same-origin/BFF-oriented adapter. Sessions remain HttpOnly cookies; the
 * browser never receives bearer, Zabbix, Grafana, or database credentials.
 * The matching endpoint contract is documented in backend/admin-api/README.md.
 */
export class FetchAdminApi implements AdminApi {
  readonly configured: boolean
  private readonly base: string
  private csrfToken: string | null = null
  // Wrapped so native fetch is never invoked with this object as `this`
  // (browsers throw "Illegal invocation").
  constructor(baseUrl: string, private readonly fetcher: typeof fetch = (input, init) => fetch(input, init)) {
    this.configured = isTrustedAdminApiUrl(baseUrl)
    this.base = baseUrl.replace(/\/$/, '')
  }

  async getSession() { return this.request<AdminSession>('/api/admin/v1/auth/session') }
  async login(operator: string, password: string) {
    const csrfToken = await this.getCsrfToken()
    return this.request<AdminSession>('/api/admin/v1/auth/login', { method: 'POST', body: JSON.stringify({ operator, password }), csrfToken, notifyUnauthorized: false })
  }
  async logout() { try { await this.request<void>('/api/admin/v1/auth/logout', { method: 'POST', body: '{}', csrfToken: await this.getCsrfToken() }) } finally { this.csrfToken = null } }
  getDashboard() { return this.request<DashboardSummary>('/api/v1/dashboard/summary') }
  listTransactions(filters: TransactionFilters) { return this.request<Page<Transaction>>(`/api/v1/transactions?${this.params(filters)}`) }
  getTransaction(id: string) { return this.request<Transaction>(`/api/v1/transactions/${encodeURIComponent(id)}`) }
  listCustomers(filters: CustomerFilters) { return this.request<Page<Customer>>(`/api/v1/customers?${this.params(filters)}`) }
  getCustomer(id: string) { return this.request<CustomerDetails>(`/api/v1/customers/${encodeURIComponent(id)}`) }
  async updateStatus(target: StatusTarget, action: StatusAction, reason: string) {
    const customer = `/api/v1/customers/${encodeURIComponent(target.customerId)}`
    const path = target.kind === 'customer' ? `${customer}/status` : `${customer}/${target.kind}s/${encodeURIComponent(target.id)}/status`
    return this.request<{ id: string; status: string }>(path, { method: 'PATCH', body: JSON.stringify({ action, reason }), csrfToken: await this.getCsrfToken() })
  }
  getMonitoringOverview() { return this.request<MonitoringOverview>('/api/v1/monitoring/health') }
  getTransactionMonitoring(filters: Pick<TransactionFilters, 'dateFrom' | 'dateTo' | 'operation' | 'status' | 'channel' | 'source' | 'destination'>) { return this.request<TransactionMonitoring>(`/api/v1/monitoring/transactions?${this.params(filters)}`) }
  listAlerts(filters: AlertFilters) { return this.request<Page<AlertRecord>>(`/api/v1/monitoring/alerts?${this.params(filters)}`) }
  listConfiguration() { return this.request<SystemConfiguration[]>('/api/v1/configuration') }
  async updateConfiguration(key: string, value: Record<string, unknown>, description?: string) { return this.request<SystemConfiguration>(`/api/v1/configuration/${encodeURIComponent(key)}`, { method: 'PUT', body: JSON.stringify({ value, description }), csrfToken: await this.getCsrfToken() }) }
  listFeatures() { return this.request<FeatureFlag[]>('/api/v1/features') }
  async updateFeature(key: string, enabled: boolean) { return this.request<FeatureFlag>(`/api/v1/features/${encodeURIComponent(key)}`, { method: 'PUT', body: JSON.stringify({ enabled }), csrfToken: await this.getCsrfToken() }) }
  listAuditLogs(page = 0) { return this.request<Page<AuditRecord>>(`/api/v1/audit-logs?page=${page}&pageSize=25`) }
  listUsers(page = 0, search = '') { return this.request<Page<AdminUser>>(`/api/v1/users?${this.params({ page, pageSize: 25, search })}`) }
  async updateUserStatus(id: string, status: string) { return this.request<AdminUser>(`/api/v1/users/${encodeURIComponent(id)}/status`, { method: 'PATCH', body: JSON.stringify({ status }), csrfToken: await this.getCsrfToken() }) }
  listNotifications(page = 0) { return this.request<Page<NotificationRecord>>(`/api/v1/notifications?page=${page}&pageSize=25`) }
  async createNotification(title: string, body: string) { return this.request<NotificationRecord>('/api/v1/notifications', { method: 'POST', body: JSON.stringify({ title, body }), csrfToken: await this.getCsrfToken() }) }
  listContent() { return this.request<DynamicContent[]>('/api/v1/content') }
  async updateContent(key: string, locale: string, value: Pick<DynamicContent, 'title' | 'body' | 'enabled' | 'metadata'>) { return this.request<DynamicContent>(`/api/v1/content/${encodeURIComponent(key)}?locale=${encodeURIComponent(locale)}`, { method: 'PUT', body: JSON.stringify(value), csrfToken: await this.getCsrfToken() }) }
  getTransactionReport() { return this.request<TransactionReportRow[]>('/api/v1/reports/transactions') }
  getUserReport() { return this.request<UserReport>('/api/v1/reports/users') }

  private params(value: object) {
    const params = new URLSearchParams()
    Object.entries(value).forEach(([key, item]) => { if (item !== undefined && item !== '') params.set(key, String(item)) })
    return params.toString()
  }
  private async getCsrfToken() {
    if (this.csrfToken) return this.csrfToken
    const payload = await this.request<{ csrfToken: string }>('/api/admin/v1/auth/csrf', { notifyUnauthorized: false })
    if (!payload?.csrfToken) throw new AdminApiError('server', 'Security token was not provided by the admin service.')
    this.csrfToken = payload.csrfToken
    return payload.csrfToken
  }
  private async request<T>(path: string, options: { method?: string; body?: string; csrfToken?: string; notifyUnauthorized?: boolean } = {}): Promise<T> {
    if (!this.configured) throw new AdminApiError('integration_required', 'Configure a secure admin API URL to continue.')
    const controller = new AbortController()
    const timer = window.setTimeout(() => controller.abort(), 12_000)
    try {
      const response = await this.fetcher(`${this.base}${path}`, {
        method: options.method ?? 'GET', credentials: 'include', signal: controller.signal,
        headers: { Accept: 'application/json', ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...(options.csrfToken ? { 'X-CSRF-Token': options.csrfToken } : {}) },
        body: options.body,
      })
      if (response.status === 401) {
        if (options.notifyUnauthorized !== false) window.dispatchEvent(new Event('admin:unauthorized'))
        throw new AdminApiError('unauthorized', 'Your administrator session has expired. Sign in again.')
      }
      if (response.status === 403) throw new AdminApiError('forbidden', 'Your administrator account is not authorized for this action.')
      if (response.status === 409) throw new AdminApiError('conflict', 'This change is not allowed from the current status. Refresh and try again.')
      if (response.status === 400 || response.status === 422) throw new AdminApiError('validation', 'The request was rejected. Review the entered filters or information.')
      if (!response.ok) throw new AdminApiError('server', `The admin service returned HTTP ${response.status}.`)
      if (response.status === 204) return undefined as T
      try { return await response.json() as T } catch { throw new AdminApiError('server', 'The admin service returned an invalid response.') }
    } catch (error) {
      if (error instanceof AdminApiError) throw error
      throw new AdminApiError('network', error instanceof DOMException && error.name === 'AbortError' ? 'The admin service request timed out.' : 'The admin service could not be reached.')
    } finally { window.clearTimeout(timer) }
  }
}

const apiBase = environment.apiBaseUrl
export const adminApi: AdminApi = apiBase && isTrustedAdminApiUrl(apiBase) ? new FetchAdminApi(apiBase) : new BackendRequiredApi()
