import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/firebase_push_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটিফিকেশন'),
        actions: [
          if (notifProv.notifications.isNotEmpty && notifProv.unreadCount > 0)
            TextButton(
              onPressed: () => notifProv.markAllAsRead(),
              child: const Text('সব পড়া হয়েছে', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifProv.fetchNotifications(),
        child: notifProv.isLoading && notifProv.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : notifProv.notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'কোনো নোটিফিকেশন নেই',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'নতুন আপডেট বা পরীক্ষার ফলাফল এখানে প্রদর্শিত হবে',
                          style: TextStyle(color: SikhunTheme.mutedDark, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifProv.notifications.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifProv.notifications[index];
                      return _buildNotificationTile(context, item, notifProv);
                    },
                  ),
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel item, NotificationProvider notifProv) {
    return Container(
      color: item.isRead ? Colors.transparent : SikhunTheme.primary.withAlpha(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: item.isRead ? Colors.grey.shade200 : SikhunTheme.primary.withAlpha(30),
          child: Icon(
            _getNotificationIcon(item.type),
            color: item.isRead ? Colors.grey.shade600 : SikhunTheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              style: const TextStyle(fontSize: 12.5, color: SikhunTheme.textDark),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(fontSize: 11, color: SikhunTheme.mutedDark),
                ),
                if (item.actionUrl != null) ...[
                  const SizedBox(width: 10),
                  const Text(
                    'বিস্তারিত দেখুন →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SikhunTheme.primary),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: !item.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SikhunTheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!item.isRead) {
            notifProv.markAsRead(item.id);
          }
          if (item.actionUrl != null) {
            FirebasePushService.openNotificationLink(item.actionUrl!);
          }
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'exam':
      case 'exam_reminder':
        return Icons.quiz_outlined;
      case 'book':
      case 'book_recommendation':
        return Icons.menu_book_outlined;
      case 'wallet':
      case 'wallet_transaction':
      case 'wallet_low_balance':
        return Icons.account_balance_wallet_outlined;
      case 'admission_notice':
        return Icons.school_outlined;
      case 'job_news':
        return Icons.work_outline;
      case 'blog_post':
        return Icons.article_outlined;
      case 'plan_update':
      case 'subscription_expiry':
        return Icons.workspace_premium_outlined;
      case 'special_offer':
        return Icons.local_offer_outlined;
      case 'announcement':
      case 'admin_broadcast':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘণ্টা আগে';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
