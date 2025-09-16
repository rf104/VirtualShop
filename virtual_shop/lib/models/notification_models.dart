enum NotificationType {
  orderUpdate,
  newMessage,
  followerActivity,
  productLike,
  orderDelivered,
  paymentUpdate,
  productAdded,
  reviewReceived,
  systemAlert,
  promotion,
}

enum NotificationPriority { low, normal, high, urgent }

enum NotificationStatus { unread, read, archived, deleted }

class NotificationModel {
  final String id;
  final String recipientAuthId;
  final String? senderAuthId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? actionUrl;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final DateTime? deletedAt;

  NotificationModel({
    required this.id,
    required this.recipientAuthId,
    this.senderAuthId,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.title,
    required this.message,
    this.actionUrl,
    this.entityType,
    this.entityId,
    this.metadata = const {},
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
    this.deletedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientAuthId: json['recipient_auth_id'] as String,
      senderAuthId: json['sender_auth_id'] as String?,
      type: _parseNotificationType(json['type'] as String),
      priority: _parseNotificationPriority(
        json['priority'] as String? ?? 'normal',
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      actionUrl: json['action_url'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      status: _parseNotificationStatus(json['status'] as String? ?? 'unread'),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_auth_id': recipientAuthId,
      'sender_auth_id': senderAuthId,
      'type': _notificationTypeToString(type),
      'priority': _notificationPriorityToString(priority),
      'title': title,
      'message': message,
      'action_url': actionUrl,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'status': _notificationStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientAuthId,
    String? senderAuthId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    String? actionUrl,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
    DateTime? deletedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientAuthId: recipientAuthId ?? this.recipientAuthId,
      senderAuthId: senderAuthId ?? this.senderAuthId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get isRead => status == NotificationStatus.read;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isDeleted => deletedAt != null;
  bool get isArchived => status == NotificationStatus.archived;

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'new_message':
        return NotificationType.newMessage;
      case 'follower_activity':
        return NotificationType.followerActivity;
      case 'product_like':
        return NotificationType.productLike;
      case 'order_delivered':
        return NotificationType.orderDelivered;
      case 'payment_update':
        return NotificationType.paymentUpdate;
      case 'product_added':
        return NotificationType.productAdded;
      case 'review_received':
        return NotificationType.reviewReceived;
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.systemAlert;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return 'order_update';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.followerActivity:
        return 'follower_activity';
      case NotificationType.productLike:
        return 'product_like';
      case NotificationType.orderDelivered:
        return 'order_delivered';
      case NotificationType.paymentUpdate:
        return 'payment_update';
      case NotificationType.productAdded:
        return 'product_added';
      case NotificationType.reviewReceived:
        return 'review_received';
      case NotificationType.systemAlert:
        return 'system_alert';
      case NotificationType.promotion:
        return 'promotion';
    }
  }

  static NotificationPriority _parseNotificationPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  static String _notificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

  static NotificationStatus _parseNotificationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'unread':
        return NotificationStatus.unread;
      case 'read':
        return NotificationStatus.read;
      case 'archived':
        return NotificationStatus.archived;
      case 'deleted':
        return NotificationStatus.deleted;
      default:
        return NotificationStatus.unread;
    }
  }

  static String _notificationStatusToString(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.unread:
        return 'unread';
      case NotificationStatus.read:
        return 'read';
      case NotificationStatus.archived:
        return 'archived';
      case NotificationStatus.deleted:
        return 'deleted';
    }
  }
}

class NotificationBatch {
  final String id;
  final String recipientAuthId;
  final NotificationType type;
  final String title;
  final String message;
  final String? actionUrl;
  final int notificationCount;
  final String? latestNotificationId;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final DateTime? deletedAt;

  NotificationBatch({
    required this.id,
    required this.recipientAuthId,
    required this.type,
    required this.title,
    required this.message,
    this.actionUrl,
    this.notificationCount = 0,
    this.latestNotificationId,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
    this.deletedAt,
  });

  factory NotificationBatch.fromJson(Map<String, dynamic> json) {
    return NotificationBatch(
      id: json['id'] as String,
      recipientAuthId: json['recipient_auth_id'] as String,
      type: NotificationModel._parseNotificationType(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      actionUrl: json['action_url'] as String?,
      notificationCount: json['notification_count'] as int? ?? 0,
      latestNotificationId: json['latest_notification_id'] as String?,
      status: NotificationModel._parseNotificationStatus(
        json['status'] as String? ?? 'unread',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_auth_id': recipientAuthId,
      'type': NotificationModel._notificationTypeToString(type),
      'title': title,
      'message': message,
      'action_url': actionUrl,
      'notification_count': notificationCount,
      'latest_notification_id': latestNotificationId,
      'status': NotificationModel._notificationStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  bool get isRead => status == NotificationStatus.read;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isDeleted => deletedAt != null;
}

class NotificationPreferences {
  final String id;
  final String userAuthId;
  final NotificationType notificationType;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userAuthId,
    required this.notificationType,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone = 'UTC',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userAuthId: json['user_auth_id'] as String,
      notificationType: NotificationModel._parseNotificationType(
        json['notification_type'] as String,
      ),
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_auth_id': userAuthId,
      'notification_type': NotificationModel._notificationTypeToString(
        notificationType,
      ),
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'in_app_enabled': inAppEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
