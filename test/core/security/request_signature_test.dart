import 'dart:convert';

import 'package:afghan_emi/src/core/security/device_key_signer.dart';
import 'package:afghan_emi/src/core/security/request_signature.dart';
import 'package:afghan_emi/src/core/storage/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// Shared with backend/src/devices/request-signature.spec.ts: RFC 8032 test 1
// key, a fixed request and its (deterministic) Ed25519 signature.
const _seed = 'nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A';
const _publicKey = '11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo';
const _timestamp = 1793260800000;
const _nonce = 'bm9uY2UtMTIzNDU2Nzg5MA';
const _body = '{"amount":1500,"currency":"AFN"}';
const _canonical =
    'AFGHANPAY-ED25519-V1\nPOST\n/api/v1/transactions\n1793260800000\n'
    'bm9uY2UtMTIzNDU2Nzg5MA\n'
    'c002e953b937dd89941191670b2f24bc3d1beb0f4281787332a82824098cdada';
const _signature =
    '6IUjnCKgSUIuV9LOPe6jg4gvqS0lwS1d9esKvRzTPMGTaO3EpA0970JkyhN6yENkVMzHx2KmWtAFDCxCPW6WDw';

void main() {
  test('canonical request matches the shared test vector', () {
    expect(
      RequestSignature.canonical(
        method: 'post',
        path: '/api/v1/transactions',
        timestamp: '$_timestamp',
        nonce: _nonce,
        body: utf8.encode(_body),
      ),
      _canonical,
    );
  });

  test('pathOf keeps the query string as sent', () {
    expect(
      RequestSignature.pathOf(
        Uri.parse('http://x/api/v1/items?page=0&q=a%20b'),
      ),
      '/api/v1/items?page=0&q=a%20b',
    );
    expect(
      RequestSignature.pathOf(Uri.parse('http://x/api/v1/me')),
      '/api/v1/me',
    );
  });

  test('the device signer reproduces the shared signature', () async {
    mockSecureStorage(
      values: {
        SecureKey.deviceKey: jsonEncode({
          'installationId': 'install-0123456789abcdef',
          'seed': _seed,
        }),
      },
    );
    final signer = DeviceKeySigner(
      SecureStore(),
      clock: () => DateTime.fromMillisecondsSinceEpoch(_timestamp),
      nonce: () => _nonce,
    );

    expect((await signer.binding()).publicKey, _publicKey);
    expect(
      await signer.sign(
        method: 'POST',
        uri: Uri.parse('http://localhost:8081/api/v1/transactions'),
        body: utf8.encode(_body),
      ),
      {
        RequestSignature.timestampHeader: '$_timestamp',
        RequestSignature.nonceHeader: _nonce,
        RequestSignature.signatureHeader: _signature,
      },
    );
  });
}
