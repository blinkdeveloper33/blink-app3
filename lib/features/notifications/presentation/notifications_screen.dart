import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate loading notifications
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _notifications = [
          NotificationItem(
            id: '1',
            title: 'Payment Received',
            message: 'You received \$50.00 from John Doe',
            type: NotificationType.payment,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
          NotificationItem(
            id: '2',
            title: 'Account Connected',
            message: 'Your bank account was successfully connected',
            type: NotificationType.account,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
          ),
          NotificationItem(
            id: '3',
            title: 'Security Alert',
            message: 'New login detected from a new device',
            type: NotificationType.security,
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isRead: false,
          ),
          NotificationItem(
            id: '4',
            title: 'Promotion',
            message: 'Get 5% cashback on your next transaction',
            type: NotificationType.promotion,
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            isRead: true,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildNotificationIcon(NotificationType type, bool isDarkMode) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.payment:
        icon = Icons.payment;
        color = Colors.green;
        break;
      case NotificationType.account:
        icon = Icons.account_balance;
        color = const Color(0xFF2196F3);
        break;
      case NotificationType.security:
        icon = Icons.security;
        color = Colors.red;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white)
              : (isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF2196F3).withOpacity(0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2))
                : (isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : const Color(0xFF2196F3).withOpacity(0.2)),
          ),
        ),
        child: InkWell(
          onTap: () {
            haptics.Haptics.vibrate(haptics.HapticsType.light);
            // Handle notification tap
            setState(() {
              notification.isRead = true;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type, isDarkMode),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _getTimeAgo(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 80,
                color: isDarkMode ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'No Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up! Check back later for new notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            haptics.Haptics.vibrate(haptics.HapticsType.light);
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
              },
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : const Color(0xFF2196F3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.white : const Color(0xFF2196F3),
                ),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) =>
                      _buildNotificationItem(_notifications[index]),
                ),
    );
  }
}

enum NotificationType {
  payment,
  account,
  security,
  promotion,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}
