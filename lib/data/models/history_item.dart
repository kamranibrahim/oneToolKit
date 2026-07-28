class HistoryItem {
  HistoryItem({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.action,
    required this.timestamp,
    this.detail,
  });

  final String id;
  final String toolId;
  final String toolName;
  final String action;
  final DateTime timestamp;
  final String? detail;

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'toolName': toolName,
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        'detail': detail,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        toolName: json['toolName'] as String,
        action: json['action'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        detail: json['detail'] as String?,
      );
}
