import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Device request signing format, shared with
/// `backend/src/devices/request-signature.ts`. Any change must change both
/// files and keep the shared test vector passing on both sides.
abstract final class RequestSignature {
  static const scheme = 'AFGHANPAY-ED25519-V1';

  static const timestampHeader = 'X-Request-Timestamp';
  static const nonceHeader = 'X-Request-Nonce';
  static const signatureHeader = 'X-Device-Signature';

  /// The bytes that are signed: any change to method, path, time, nonce or
  /// body invalidates the signature. [path] includes the query string.
  static String canonical({
    required String method,
    required String path,
    required String timestamp,
    required String nonce,
    required List<int> body,
  }) => [
    scheme,
    method.toUpperCase(),
    path,
    timestamp,
    nonce,
    _hex(SHA256Digest().process(Uint8List.fromList(body))),
  ].join('\n');

  /// Path and query exactly as sent, matching Express's `originalUrl`.
  static String pathOf(Uri uri) =>
      uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Unpadded base64url, the encoding used for keys, nonces and signatures.
String base64UrlNoPad(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');
