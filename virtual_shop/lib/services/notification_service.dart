import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_models.dart';
import '../utils/supabase_service.dart';

class NotificationService {
  static final SupabaseClient _supabase = supabase;

  /// Fetch notifications for the current user
  static Future<List<NotificationModel>> fetchNotifications({
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
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      return (response as List)
          .map(
            (json) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
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
          .eq('status', 'unread');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
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
          .count();

      return response.count;
    } catch (e) {
      return 0;
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
}
