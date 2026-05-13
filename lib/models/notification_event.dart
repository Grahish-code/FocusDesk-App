class NotificationBridge {
  final String id;
  final String packageName;
  final String title;
  final String text;
  final DateTime createAt;

  NotificationBridge({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.createAt,
  });
}