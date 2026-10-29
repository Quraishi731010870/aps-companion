import { PrismaClient, AccountStatus, AlertSeverity, AlertStatus, AuditResult, ConfigurationScope, NotificationStatus, Platform, PrincipalType } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();
const permissions = [
  'dashboard.view', 'users.view', 'users.create', 'users.update', 'users.disable', 'customers.view', 'customers.manage',
  'transactions.view', 'transactions.search', 'transactions.export', 'transactions.reverse',
  'notifications.view', 'notifications.create', 'notifications.send', 'configuration.view',
  'configuration.update', 'monitoring.view', 'monitoring.manage', 'reports.view', 'reports.export', 'audit.view',
];
const rolePermissions: Record<string, string[]> = {
  SUPER_ADMIN: permissions,
  ADMINISTRATOR: permissions.filter((value) => value !== 'monitoring.manage'),
  OPERATIONS: ['dashboard.view', 'customers.view', 'transactions.view', 'transactions.search', 'transactions.export'],
  SUPPORT: ['dashboard.view', 'customers.view', 'transactions.view', 'notifications.view'],
  MONITORING: ['dashboard.view', 'monitoring.view'],
  AUDITOR: ['dashboard.view', 'transactions.view', 'reports.view', 'audit.view'],
  READ_ONLY: ['dashboard.view', 'customers.view', 'transactions.view', 'notifications.view', 'configuration.view', 'monitoring.view', 'reports.view', 'audit.view'],
};
const types = [
  ['702', 'Balance Inquiry', false], ['774', 'Purchase', true], ['618', 'Cash In', true], ['700', 'Cash Out', true],
  ['511', 'Payment Info', false], ['508', 'Save Payment', true], ['785', 'Wallet to Card', true],
  ['781', 'Card to Wallet', true], ['689', 'Card to Card', true], ['651', 'Card Title Fetch', false],
] as const;

async function main(): Promise<void> {
  if (process.env.NODE_ENV === 'production') throw new Error('The development seed must never run in production.');
  const password = process.env.SEED_ADMIN_PASSWORD;
  if (!password || password.length < 12) throw new Error('Set SEED_ADMIN_PASSWORD to a local development password of at least 12 characters.');
  const mobilePassword = process.env.SEED_MOBILE_PASSWORD ?? password;
  const mobilePhone = process.env.SEED_MOBILE_PHONE ?? '+93790000001';
  if (mobilePassword.length < 8) throw new Error('SEED_MOBILE_PASSWORD must contain at least 8 characters.');
  for (const code of permissions) await prisma.permission.upsert({ where: { code }, update: {}, create: { code, description: `Development permission: ${code}` } });
  for (const [code, grants] of Object.entries(rolePermissions)) {
    const role = await prisma.role.upsert({ where: { code }, update: {}, create: { code, name: code.replaceAll('_', ' '), description: 'Development/UAT role', system: true } });
    const rows = await prisma.permission.findMany({ where: { code: { in: grants } } });
    await prisma.rolePermission.createMany({ data: rows.map((item) => ({ roleId: role.id, permissionId: item.id })), skipDuplicates: true });
  }
  const passwordHash = await argon2.hash(password, { type: argon2.argon2id });
  const mobilePasswordHash = await argon2.hash(mobilePassword, { type: argon2.argon2id });
  const admin = await prisma.user.upsert({ where: { email: 'admin@afghanpay.test' }, update: { passwordHash, status: AccountStatus.ACTIVE }, create: { email: 'admin@afghanpay.test', displayName: 'Development Administrator', passwordHash, principalType: PrincipalType.ADMIN, status: AccountStatus.ACTIVE, activatedAt: new Date() } });
  const adminRole = await prisma.role.findUniqueOrThrow({ where: { code: 'SUPER_ADMIN' } });
  await prisma.userRole.createMany({ data: [{ userId: admin.id, roleId: adminRole.id }], skipDuplicates: true });

  // One test customer for the mobile app, with an empty wallet. No sample
  // transactions: data is created through the API.
  const user = await prisma.user.upsert({ where: { email: 'customer001@example.test' }, update: { phone: mobilePhone, passwordHash: mobilePasswordHash, status: AccountStatus.ACTIVE }, create: { email: 'customer001@example.test', phone: mobilePhone, displayName: 'Demo Customer 001', passwordHash: mobilePasswordHash, principalType: PrincipalType.MOBILE_USER, status: AccountStatus.ACTIVE, activatedAt: new Date() } });
  const customer = await prisma.customer.upsert({ where: { userId: user.id }, update: {}, create: { userId: user.id, customerNo: 'DEMO-CUS-001', kycStatus: 'VERIFIED', status: AccountStatus.ACTIVE } });
  await prisma.account.upsert({ where: { accountNo: 'WALLET-AF000001' }, update: {}, create: { customerId: customer.id, accountNo: 'WALLET-AF000001', type: 'WALLET', currency: 'AFN' } });
  for (const [code, name, financial] of types) await prisma.transactionType.upsert({ where: { code }, update: { name, financial }, create: { code, name, financial, enabled: true, configuration: { source: 'APS H2H v1.6', development: true } } });
  await prisma.systemConfiguration.upsert({ where: { key: 'mobile.application' }, update: {}, create: { key: 'mobile.application', scope: ConfigurationScope.PUBLIC_MOBILE, value: { applicationName: 'AfghanPay', maintenanceMode: false, supportPhone: '+93000000000', supportedCurrencies: ['AFN', 'USD'] }, description: 'Development mobile configuration', updatedBy: admin.id } });
  await prisma.dynamicContent.upsert({ where: { key_locale_platform: { key: 'home.welcome', locale: 'en', platform: Platform.ALL } }, update: {}, create: { key: 'home.welcome', locale: 'en', platform: Platform.ALL, title: 'Welcome to AfghanPay', body: 'Development content managed by the AfghanPay operations portal.', metadata: { synthetic: true }, updatedBy: admin.id } });
  for (const [key, name] of [['cash_out', 'Cash Out'], ['card_to_card', 'Card to Card'], ['notifications', 'Notifications']]) await prisma.featureFlag.upsert({ where: { key }, update: {}, create: { key, name, enabled: true, platform: Platform.ALL, configuration: { development: true } } });
  if (!(await prisma.notification.findFirst({ where: { title: 'Development environment ready' } }))) await prisma.notification.create({ data: { title: 'Development environment ready', body: 'This is synthetic AfghanPay development data.', status: NotificationStatus.SENT, sentAt: new Date(), createdBy: admin.id } });
  await prisma.monitoringService.upsert({ where: { key: 'afghanpay-api' }, update: {}, create: { key: 'afghanpay-api', name: 'AfghanPay API', type: 'APPLICATION', configuration: { development: true } } });
  if (!(await prisma.alert.findFirst({ where: { code: 'DEMO_ALERT' } }))) await prisma.alert.create({ data: { severity: AlertSeverity.INFO, status: AlertStatus.OPEN, code: 'DEMO_ALERT', title: 'Development monitoring alert', safeDetail: { synthetic: true } } });
  if (!(await prisma.auditLog.findFirst({ where: { requestId: 'seed-development-data' } }))) await prisma.auditLog.create({ data: { actorId: admin.id, actorSnapshot: admin.email ?? 'development-admin', action: 'DEVELOPMENT_SEED', resource: 'database', requestId: 'seed-development-data', result: AuditResult.SUCCESS, newValue: { synthetic: true, customers: 30, transactions: 500 } } });
  console.log('Development seed complete. Login: admin@afghanpay.test; password came from SEED_ADMIN_PASSWORD.');
}

main().finally(() => prisma.$disconnect());
