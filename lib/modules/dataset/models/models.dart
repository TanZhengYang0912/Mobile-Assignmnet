class EquipmentNode {
  final String? nodeId;
  final String nodeName;
  final String utilityType;
  final String? zoneId;
  final String? facilityName;
  final String? facilityCity;
  final String status;
  final DateTime? createdAt;
  final String? manufacturer;
  final DateTime? installationDate;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final int healthScore;
  final String? firmwareVersion;
  final String? ipAddress;

  const EquipmentNode({
    this.nodeId,
    required this.nodeName,
    required this.utilityType,
    this.zoneId,
    this.facilityName,
    this.facilityCity,
    required this.status,
    this.createdAt,
    this.manufacturer,
    this.installationDate,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    this.healthScore = 100,
    this.firmwareVersion,
    this.ipAddress,
  });

  Map<String, Object?> toMap() => {
        if (nodeId != null) 'node_id': nodeId,
        'node_name': nodeName,
        'utility_type': utilityType,
        if (zoneId != null) 'zone_id': zoneId,
        if (facilityName != null) 'facility_name': facilityName,
        if (facilityCity != null) 'facility_city': facilityCity,
        'status': status,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (installationDate != null)
          'installation_date': installationDate!.toIso8601String(),
        if (lastMaintenanceDate != null)
          'last_maintenance_date': lastMaintenanceDate!.toIso8601String(),
        if (nextMaintenanceDate != null)
          'next_maintenance_date': nextMaintenanceDate!.toIso8601String(),
        'health_score': healthScore,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (ipAddress != null) 'ip_address': ipAddress,
      };

  factory EquipmentNode.fromMap(Map<String, Object?> map) => EquipmentNode(
        nodeId: map['node_id'] as String?,
        nodeName: map['node_name'] as String,
        utilityType: map['utility_type'] as String,
        zoneId: map['zone_id'] as String?,
        facilityName: map['facility_name'] as String?,
        facilityCity: map['facility_city'] as String?,
        status: map['status'] as String,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
        manufacturer: map['manufacturer'] as String?,
        installationDate: map['installation_date'] != null
            ? DateTime.parse(map['installation_date'] as String)
            : null,
        lastMaintenanceDate: map['last_maintenance_date'] != null
            ? DateTime.parse(map['last_maintenance_date'] as String)
            : null,
        nextMaintenanceDate: map['next_maintenance_date'] != null
            ? DateTime.parse(map['next_maintenance_date'] as String)
            : null,
        healthScore: map['health_score'] as int? ?? 100,
        firmwareVersion: map['firmware_version'] as String?,
        ipAddress: map['ip_address'] as String?,
      );

  EquipmentNode copyWith({
    String? nodeId,
    String? nodeName,
    String? utilityType,
    String? zoneId,
    String? facilityName,
    String? facilityCity,
    String? status,
    DateTime? createdAt,
    String? manufacturer,
    DateTime? installationDate,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    int? healthScore,
    String? firmwareVersion,
    String? ipAddress,
  }) {
    return EquipmentNode(
      nodeId: nodeId ?? this.nodeId,
      nodeName: nodeName ?? this.nodeName,
      utilityType: utilityType ?? this.utilityType,
      zoneId: zoneId ?? this.zoneId,
      facilityName: facilityName ?? this.facilityName,
      facilityCity: facilityCity ?? this.facilityCity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      manufacturer: manufacturer ?? this.manufacturer,
      installationDate: installationDate ?? this.installationDate,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      healthScore: healthScore ?? this.healthScore,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}

class UtilityLog {
  final String? logId;
  final String nodeId;
  final DateTime? timestamp;
  final double usageValue;
  final bool isAnomaly;

  const UtilityLog({
    this.logId,
    required this.nodeId,
    this.timestamp,
    required this.usageValue,
    this.isAnomaly = false,
  });

  Map<String, Object?> toMap() => {
        if (logId != null) 'log_id': logId,
        'node_id': nodeId,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
        'usage_value': usageValue,
        'is_anomaly': isAnomaly,
      };

  factory UtilityLog.fromMap(Map<String, Object?> map) => UtilityLog(
        logId: map['log_id'] as String?,
        nodeId: map['node_id'] as String,
        timestamp: map['timestamp'] != null
            ? DateTime.parse(map['timestamp'] as String)
            : null,
        usageValue: (map['usage_value'] as num).toDouble(),
        isAnomaly: map['is_anomaly'] as bool? ?? false,
      );
}
