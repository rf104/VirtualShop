// This file has been replaced by notification_service.dart
// and is no longer used in the project
// 
// All notification functionality has been moved to:
// - models/notification_models.dart 
// - services/notification_service.dart
// - utils/notification_utils.dart
    int limit = 50,
    int offset = 0,
    List<NotificationStatus>? statusFilter,
    List<NotificationType>? typeFilter,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase
          .from('notifications')
          .select()
          .eq('recipient_auth_id', currentUser.id)
          .not('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Apply status filter using the filter method
      if (statusFilter != null && statusFilter.isNotEmpty) {
        final statusStrings = statusFilter
            .map((s) => _notificationStatusToString(s))
            .toList();
        final statusList = statusStrings.map((s) => '"$s"').join(',');
        query = query.filter('status', 'in', '($statusList)');
      }

      // Apply type filter using the filter method
      if (typeFilter != null && typeFilter.isNotEmpty) {
        final typeStrings = typeFilter
            .map((t) => _notificationTypeToString(t))
            .toList();
        final typeList = typeStrings.map((s) => '"$s"').join(',');
        query = query.filter('type', 'in', '($typeList)');
      }

      final response = await query;
      
      return (response as List)
          .map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Fetch notification batches for the current user
  static Future<List<NotificationBatch>> fetchNotificationBatches({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notification_batches')
          .select()
          .eq('recipient_auth_id', currentUser.id)
          .not('deleted_at', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => NotificationBatch.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notification batches: $e');
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_auth_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark multiple notifications as read
  static Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final idList = notificationIds.map((id) => '"$id"').join(',');
      await _supabase
          .from('notifications')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .filter('id', 'in', '($idList)')
          .eq('recipient_auth_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to mark notifications as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_auth_id', currentUser.id)
          .eq('status', 'unread')
          .not('deleted_at', 'is', null);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Mark a notification batch as read
  static Future<void> markBatchAsRead(String batchId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notification_batches')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', batchId)
          .eq('recipient_auth_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to mark batch as read: $e');
    }
  }

  /// Archive a notification
  static Future<void> archiveNotification(String notificationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({'status': 'archived'})
          .eq('id', notificationId)
          .eq('recipient_auth_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to archive notification: $e');
    }
  }

  /// Delete a notification (soft delete)
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({
            'status': 'deleted',
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_auth_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('recipient_auth_id', currentUser.id)
          .eq('status', 'unread')
          .not('deleted_at', 'is', null)
          .count();

      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch notification preferences for the current user
  static Future<List<NotificationPreferences>> fetchNotificationPreferences() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_auth_id', currentUser.id);

      return (response as List)
          .map((json) => NotificationPreferences.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notification preferences: $e');
    }
  }

  /// Update notification preferences
  static Future<void> updateNotificationPreferences(
    NotificationType type,
    NotificationPreferences preferences,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('notification_preferences')
          .upsert({
            'user_auth_id': currentUser.id,
            'notification_type': _notificationTypeToString(type),
            'push_enabled': preferences.pushEnabled,
            'email_enabled': preferences.emailEnabled,
            'in_app_enabled': preferences.inAppEnabled,
            'quiet_hours_start': preferences.quietHoursStart,
            'quiet_hours_end': preferences.quietHoursEnd,
            'timezone': preferences.timezone,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_auth_id,notification_type');
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Create a new notification
  static Future<NotificationModel> createNotification({
    required String recipientAuthId,
    String? senderAuthId,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    required String title,
    required String message,
    String? actionUrl,
    String? entityType,
    String? entityId,
    Map<String, dynamic> metadata = const {},
    DateTime? expiresAt,
  }) async {
    try {
      final payload = {
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
        'expires_at': expiresAt?.toIso8601String(),
      };

      final response = await _supabase
          .from('notifications')
          .insert(payload)
          .select()
          .single();

      return NotificationModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Subscribe to real-time notification updates
  static RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(NotificationModel) onNotificationReceived,
  ) {
    return _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_auth_id',
            value: userId,
          ),
          callback: (payload) {
            final notification = NotificationModel.fromJson(
              Map<String, dynamic>.from(payload.newRecord),
            );
            onNotificationReceived(notification);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from real-time notification updates
  static Future<void> unsubscribeFromNotifications(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // Helper methods
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