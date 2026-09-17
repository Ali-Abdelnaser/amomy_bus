class ParsedNotificationPayload {
  const ParsedNotificationPayload({
    required this.title,
    required this.body,
    required this.data,
  });

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

class NotificationPayloadParser {
  NotificationPayloadParser._();

  static ParsedNotificationPayload fromApnsPayload(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null || payload.isEmpty) {
      return const ParsedNotificationPayload(
        title: null,
        body: null,
        data: <String, dynamic>{},
      );
    }

    final aps = payload['aps'];
    final alert = aps is Map ? aps['alert'] : null;
    String? title;
    String? body;

    if (alert is Map) {
      title = _stringValue(alert['title']);
      body = _stringValue(alert['body']);
    } else if (alert is String) {
      body = alert;
    }

    return ParsedNotificationPayload(
      title: title,
      body: body,
      data: routingDataFrom(payload),
    );
  }

  static Map<String, dynamic> routingDataFrom(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) {
      return <String, dynamic>{};
    }

    final data = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (entry.key == 'aps' || entry.value == null) continue;
      data[entry.key] = entry.value;
    }
    return data;
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
