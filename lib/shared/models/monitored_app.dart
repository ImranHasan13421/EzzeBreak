class MonitoredApp {
  final String packageName;
  final String appName;
  final String? iconBase64;
  final bool isSystemApp;
  final bool isMonitored;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonitoredApp({
    required this.packageName,
    required this.appName,
    this.iconBase64,
    this.isSystemApp = false,
    this.isMonitored = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MonitoredApp copyWith({
    String? packageName,
    String? appName,
    String? iconBase64,
    bool? isSystemApp,
    bool? isMonitored,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonitoredApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconBase64: iconBase64 ?? this.iconBase64,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isMonitored: isMonitored ?? this.isMonitored,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'icon_base64': iconBase64,
      'is_system_app': isSystemApp ? 1 : 0,
      'is_monitored': isMonitored ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MonitoredApp.fromMap(Map<String, dynamic> map) {
    return MonitoredApp(
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      iconBase64: map['icon_base64'] as String?,
      isSystemApp: (map['is_system_app'] as int?) == 1,
      isMonitored: (map['is_monitored'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
