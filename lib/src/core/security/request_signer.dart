import 'package:flutter/foundation.dart';

/// What the backend needs to bind this installation to the customer at login.
@immutable
class DeviceBinding {
  const DeviceBinding({
    required this.installationId,
    required this.platform,
    required this.publicKey,
  });

  final String installationId;

  /// `ANDROID`, `IOS` or `WEB`.
  final String platform;

  /// Raw Ed25519 public key, unpadded base64url.
  final String publicKey;

  Map<String, String> toJson() => {
    'installationId': installationId,
    'platform': platform,
    'publicKey': publicKey,
  };
}

/// Signs API requests with this device's key so the backend can check that
/// they come from the device bound to the session.
abstract interface class RequestSigner {
  Future<DeviceBinding> binding();

  /// Signature headers for one request; call again for every retry.
  Future<Map<String, String>> sign({
    required String method,
    required Uri uri,
    required List<int> body,
  });
}
