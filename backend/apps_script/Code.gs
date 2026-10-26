const SHEET_NAME = 'Users';
const HEADERS = ['ID', 'Name', 'Email', 'Phone', 'Status'];

// This token must match GOOGLE_SHEETS_SERVICE_TOKEN in the Flutter app.
// A token shipped in a mobile app can be extracted; it is a basic gate for
// this prototype, not strong authentication for sensitive production data.
// Run once in the Apps Script editor as the spreadsheet owner to grant the
// script its Sheets permission and verify the worksheet/header configuration.
function authorizeSpreadsheetAccess() {
  getUsersSheet_();
}

function doGet(event) {
  try {
    authorize_(event);
    const action = event.parameter.action || 'listUsers';
    if (action !== 'listUsers') throw new Error('Unsupported action.');
    const sheet = getUsersSheet_();
    const lastRow = sheet.getLastRow();
    const users = lastRow < 2
      ? []
      : sheet.getRange(2, 1, lastRow - 1, HEADERS.length).getDisplayValues()
          .filter(row => row.some(value => value !== ''));
    return json_({ok: true, users: users});
  } catch (error) {
    return json_({ok: false, error: error.message || String(error)});
  }
}

function doPost(event) {
  try {
    const request = JSON.parse(event.postData.contents || '{}');
    authorize_(event, request.token);
    if (event.parameter.action !== 'appendUser') {
      throw new Error('Unsupported action.');
    }
    const user = request.user || {};
    const row = HEADERS.map(header => safeCell_(user[header.toLowerCase()]));
    if (row.some(value => value === '')) {
      throw new Error('All five user fields are required.');
    }

    const lock = LockService.getScriptLock();
    lock.waitLock(10000);
    try {
      const sheet = getUsersSheet_();
      const nextRow = Math.max(sheet.getLastRow() + 1, 2);
      sheet.getRange(nextRow, 1, 1, HEADERS.length).setValues([row]);
    } finally {
      lock.releaseLock();
    }
    return json_({ok: true, message: 'User added.'});
  } catch (error) {
    return json_({ok: false, error: error.message || String(error)});
  }
}

function authorize_(event, bodyToken) {
  const expected = PropertiesService.getScriptProperties()
    .getProperty('SERVICE_TOKEN');
  const supplied = String(
    bodyToken || (event.parameter && event.parameter.token) || ''
  );
  if (!expected || !constantTimeEquals_(supplied, expected)) {
    throw new Error('Unauthorized service request.');
  }
}

function getUsersSheet_() {
  const spreadsheetId = PropertiesService.getScriptProperties()
    .getProperty('SPREADSHEET_ID');
  if (!spreadsheetId) throw new Error('Spreadsheet configuration is missing.');
  const spreadsheet = SpreadsheetApp.openById(spreadsheetId);
  const sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (!sheet) throw new Error('Worksheet "' + SHEET_NAME + '" was not found.');
  const firstRow = sheet.getRange(1, 1, 1, HEADERS.length).getDisplayValues()[0];
  if (firstRow.every(value => value === '')) {
    sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
  } else if (HEADERS.some((header, index) => firstRow[index] !== header)) {
    throw new Error('The first row must be: ' + HEADERS.join(' | '));
  }
  return sheet;
}

function safeCell_(value) {
  const text = String(value == null ? '' : value).trim();
  return /^[=+@\-]/.test(text) ? "'" + text : text;
}

function constantTimeEquals_(left, right) {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

function json_(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
      .setMimeType(ContentService.MimeType.JSON);
}
