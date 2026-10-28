import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/api_client.dart';

part 'config_repository.g.dart';

@Riverpod(keepAlive: true)
ConfigRepository configRepository(Ref ref) =>
    ConfigRepository(ref.watch(apiClientProvider));

class MobileConfiguration {
  const MobileConfiguration({
    required this.version,
    required this.updatedAt,
    required this.values,
    required this.features,
    required this.content,
    required this.fromCache,
  });

  /// Safe default used before the first load and when nothing is cached.
  static const empty = MobileConfiguration(
    version: 0,
    updatedAt: null,
    values: {},
    features: {},
    content: [],
    fromCache: true,
  );

  final int version;
  final DateTime? updatedAt;
  final Map<String, dynamic> values;
  final Map<String, bool> features;
  final List<Map<String, dynamic>> content;
  final bool fromCache;
  bool featureEnabled(String key, {bool safeDefault = false}) =>
      features[key] ?? safeDefault;
  bool get maintenanceMode => values['maintenanceMode'] == true;
  String? get maintenanceMessage => switch (values['maintenanceMessage']) {
    final String message => message,
    _ => null,
  };
}

class ConfigRepository {
  ConfigRepository(this.api);
  final ApiClient api;
  static const _cacheKey = 'afghanpay_mobile_config_v1';
  Future<MobileConfiguration> load() async {
    try {
      final json = await api.getJson(
        '/api/v1/configuration/mobile/current',
        authenticated: false,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_cacheKey, jsonEncode(json));
      return _parse(json, false);
    } catch (_) {
      final preferences = await SharedPreferences.getInstance();
      final cached = preferences.getString(_cacheKey);
      if (cached != null) {
        return _parse(jsonDecode(cached) as Map<String, dynamic>, true);
      }
      return MobileConfiguration.empty;
    }
  }

  MobileConfiguration _parse(Map<String, dynamic> json, bool fromCache) {
    final configurations =
        (json['configuration'] as Map?)?.cast<String, dynamic>() ?? const {};
    final merged = <String, dynamic>{};
    for (final value in configurations.values) {
      if (value is Map) {
        merged.addAll(value.cast<String, dynamic>());
      }
    }
    final features = <String, bool>{};
    for (final value in (json['features'] as List? ?? const [])) {
      if (value is Map && value['key'] is String) {
        features[value['key'] as String] = value['enabled'] == true;
      }
    }
    return MobileConfiguration(
      version: json['version'] as int? ?? 0,
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
      values: merged,
      features: features,
      content: (json['content'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList(growable: false),
      fromCache: fromCache,
    );
  }
}
