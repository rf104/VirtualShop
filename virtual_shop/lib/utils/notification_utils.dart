import 'package:intl/intl.dart';
import '../models/notification_models.dart';

class NotificationUtils {
  /// Format the time difference between now and the given date
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get the appropriate icon for a notification type
  static String getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return '📦';
      case NotificationType.newMessage:
        return '💬';
      case NotificationType.followerActivity:
        return '👥';
      case NotificationType.productLike:
        return '❤️';
      case NotificationType.orderDelivered:
        return '✅';
      case NotificationType.paymentUpdate:
        return '💳';
      case NotificationType.productAdded:
        return '🛍️';
      case NotificationType.reviewReceived:
        return '⭐';
      case NotificationType.systemAlert:
        return '⚠️';
      case NotificationType.promotion:
        return '🎉';
    }
  }

  /// Get the appropriate color for a notification priority
  static String getNotificationColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return '#4CAF50'; // Green
      case NotificationPriority.normal:
        return '#2196F3'; // Blue
      case NotificationPriority.high:
        return '#FF9800'; // Orange
      case NotificationPriority.urgent:
        return '#F44336'; // Red
    }
  }

  /// Check if a notification is expired
  static bool isNotificationExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Format notification time for display
  static String formatNotificationTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      // Same day - show time
      return DateFormat('h:mm a').format(createdAt);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(createdAt);
    } else {
      // More than a week - show date
      return DateFormat('MMM d').format(createdAt);
    }
  }

  /// Group notifications by date
  static Map<String, List<T>> groupNotificationsByDate<T>(
    List<T> notifications,
    DateTime Function(T) getCreatedAt,
  ) {
    final grouped = <String, List<T>>{};
    final now = DateTime.now();

    for (final notification in notifications) {
      final createdAt = getCreatedAt(notification);
      final difference = now.difference(createdAt);

      String groupKey;
      if (difference.inDays == 0) {
        groupKey = 'Today';
      } else if (difference.inDays == 1) {
        groupKey = 'Yesterday';
      } else if (difference.inDays < 7) {
        groupKey = DateFormat('EEEE').format(createdAt);
      } else {
        groupKey = DateFormat('MMM d, y').format(createdAt);
      }

      grouped.putIfAbsent(groupKey, () => []).add(notification);
    }

    return grouped;
  }

  /// Check if user is in quiet hours
  static bool isInQuietHours(String? quietHoursStart, String? quietHoursEnd) {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    try {
      final now = DateTime.now();
      final startTime = _parseTimeString(quietHoursStart);
      final endTime = _parseTimeString(quietHoursEnd);

      final currentTime = TimeOfDay.fromDateTime(now);

      // Handle cases where quiet hours cross midnight
      if (_isTimeAfter(endTime, startTime)) {
        // Normal case: start < end (e.g., 22:00 - 08:00)
        return _isTimeAfterOrEqual(currentTime, startTime) ||
            _isTimeBeforeOrEqual(currentTime, endTime);
      } else {
        // Same day: start < end (e.g., 08:00 - 22:00)
        return _isTimeAfterOrEqual(currentTime, startTime) &&
            _isTimeBeforeOrEqual(currentTime, endTime);
      }
    } catch (e) {
      return false;
    }
  }

  static TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour ||
        (time1.hour == time2.hour && time1.minute > time2.minute);
  }

  static bool _isTimeAfterOrEqual(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour ||
        (time1.hour == time2.hour && time1.minute >= time2.minute);
  }

  static bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour < time2.hour ||
        (time1.hour == time2.hour && time1.minute <= time2.minute);
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}
