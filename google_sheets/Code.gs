/**
 * PayAfghan Google Sheets prototype database API.
 * Bind this script to the PayAfghan Database spreadsheet, run setupDatabase(),
 * set Script Property API_KEY, then deploy as a Web app (execute as owner).
 */

const TABLES = {
  Transactions: [
    'transactionId', 'rrn', 'createdAt', 'transactionType', 'title', 'source',
    'destination', 'amount', 'currency', 'fee', 'direction', 'reference',
    'status', 'institution', 'channel', 'cardNumber', 'idempotencyKey'
  ],
  Users: ['userId', 'fullName', 'phone', 'locale', 'kycStatus', 'createdAt', 'active'],
  Cards: ['cardId', 'userId', 'maskedPan', 'issuer', 'token', 'linkedAt', 'active'],
  Bills: ['billId', 'biller', 'customerNumber', 'customerName', 'amount', 'currency', 'dueDate', 'status'],
  Limits: ['limitId', 'userId', 'cycle', 'operation', 'maxAmount', 'maxCount', 'currency', 'active'],
  Settings: ['key', 'value', 'scope', 'updatedAt'],
  Institutions: ['institutionId', 'name', 'currency', 'locale', 'baseUrl', 'active'],
  Notifications: ['notificationId', 'userId', 'type', 'locale', 'title', 'message', 'createdAt', 'read'],
  AuditLog: ['auditId', 'createdAt', 'level', 'actor', 'action', 'entity', 'details', 'sessionId']
};

function setupDatabase() {
  const book = SpreadsheetApp.getActiveSpreadsheet();
  Object.keys(TABLES).forEach(name => {
    let sheet = book.getSheetByName(name);
    if (!sheet) sheet = book.insertSheet(name);
    const headers = TABLES[name];
    if (sheet.getLastRow() === 0) {
      sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
      sheet.getRange(1, 1, 1, headers.length)
        .setFontWeight('bold')
        .setBackground('#087f67')
        .setFontColor('#ffffff');
      sheet.setFrozenRows(1);
    }
  });
  seedDatabase_();
}

function doGet(event) {
  try {
    authorize_(event.parameter.apiKey);
    const action = event.parameter.action || '';
    if (action === 'listTransactions') {
      return json_({ok: true, data: readRows_('Transactions').reverse().slice(0, 200)});
    }
    if (action === 'getSettings') {
      return json_({ok: true, data: readRows_('Settings')});
    }
    if (action === 'health') {
      return json_({ok: true, spreadsheetId: SpreadsheetApp.getActive().getId()});
    }
    throw new Error('Unsupported action');
  } catch (error) {
    return json_({ok: false, error: String(error.message || error)});
  }
}

function doPost(event) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);
    const body = JSON.parse(event.postData.contents || '{}');
    authorize_(body.apiKey);
    if (body.action === 'createTransaction') return createTransaction_(body.data || {});
    if (body.action === 'saveSetting') return saveSetting_(body.data || {});
    if (body.action === 'linkCard') return linkCard_(body.data || {});
    throw new Error('Unsupported action');
  } catch (error) {
    return json_({ok: false, error: String(error.message || error)});
  } finally {
    lock.releaseLock();
  }
}

function createTransaction_(data) {
  ['transactionType', 'source', 'destination', 'idempotencyKey'].forEach(key => {
    if (data[key] === undefined || data[key] === '') throw new Error('Missing ' + key);
  });
  const existing = readRows_('Transactions').find(row => row.idempotencyKey === data.idempotencyKey);
  if (existing) return json_({ok: true, ...existing, duplicate: true});
  const now = new Date().toISOString();
  const rrn = Utilities.formatDate(new Date(), 'GMT', 'yyMMddHHmmss') + Math.floor(Math.random() * 1000);
  const row = {
    transactionId: 'EMI-' + Utilities.getUuid(), rrn, createdAt: now,
    transactionType: data.transactionType, title: data.title || 'PayAfghan transaction',
    source: data.source, destination: data.destination, amount: Number(data.amount || 0),
    currency: data.currency || 'AFN', fee: Number(data.fee || 0),
    direction: data.direction || 'debit', reference: data.reference || '',
    status: 'successful', institution: data.institution || 'Afghan EMI',
    channel: 'PayAfghan Mobile', cardNumber: maskCard_(data.source),
    idempotencyKey: data.idempotencyKey
  };
  appendObject_('Transactions', row);
  appendObject_('AuditLog', {
    auditId: Utilities.getUuid(), createdAt: now, level: 'INFO', actor: 'mobile-customer',
    action: 'CREATE_TRANSACTION', entity: row.transactionId,
    details: JSON.stringify({type: row.transactionType, amount: row.amount}), sessionId: ''
  });
  return json_({ok: true, ...row, message: 'Transaction saved to Google Sheets'});
}

function saveSetting_(data) {
  appendObject_('Settings', {
    key: data.key, value: JSON.stringify(data.value), scope: data.scope || 'global',
    updatedAt: new Date().toISOString()
  });
  return json_({ok: true, message: 'Setting saved'});
}

function linkCard_(data) {
  const row = {
    cardId: Utilities.getUuid(), userId: data.userId || 'USR-ASIF-001',
    maskedPan: maskCard_(data.cardNumber || ''), issuer: data.issuer || 'APS',
    token: 'TOKEN-' + Utilities.getUuid(), linkedAt: new Date().toISOString(), active: true
  };
  appendObject_('Cards', row);
  return json_({ok: true, data: row});
}

function readRows_(name) {
  const sheet = SpreadsheetApp.getActive().getSheetByName(name);
  if (!sheet || sheet.getLastRow() < 2) return [];
  const values = sheet.getDataRange().getValues();
  const headers = values.shift();
  return values.filter(row => row.some(value => value !== '')).map(row => {
    const object = {};
    headers.forEach((header, index) => object[header] = row[index]);
    return object;
  });
}

function appendObject_(name, object) {
  const sheet = SpreadsheetApp.getActive().getSheetByName(name);
  const headers = TABLES[name];
  sheet.appendRow(headers.map(header => object[header] === undefined ? '' : object[header]));
}

function authorize_(provided) {
  const expected = PropertiesService.getScriptProperties().getProperty('API_KEY');
  if (!expected || provided !== expected) throw new Error('Unauthorized');
}

function maskCard_(value) {
  const digits = String(value).replace(/\D/g, '');
  return digits.length >= 4 ? '•••• ' + digits.slice(-4) : 'tokenized card';
}

function json_(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

function seedDatabase_() {
  const users = SpreadsheetApp.getActive().getSheetByName('Users');
  if (users.getLastRow() === 1) appendObject_('Users', {
    userId: 'USR-ASIF-001', fullName: 'Asif Quraishi', phone: '+93 731010870',
    locale: 'en', kycStatus: 'basic-pending', createdAt: new Date().toISOString(), active: true
  });
  const institutions = SpreadsheetApp.getActive().getSheetByName('Institutions');
  if (institutions.getLastRow() === 1) appendObject_('Institutions', {
    institutionId: 'AF-EMI-001', name: 'Afghan EMI', currency: 'AFN', locale: 'en,fa',
    baseUrl: '', active: true
  });
}
