import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

final chatCountProvider = StateProvider<int>((ref) => 0);
final orderBookNotificationCountProvider = StateProvider<int>((ref) => 0);

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notification counts.
    final int chatCount = ref.watch(chatCountProvider);
    final int orderNotificationCount =
        ref.watch(orderBookNotificationCountProvider);

    return Container(
      // We remove the fixed height so it adapts automatically
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2C),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      // We use SafeArea with bottom:true to handle the bottom space automatically
      child: SafeArea(
        top: false, // We don't need safe area at the top
        bottom: true, // Only at the bottom
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 8), // We reduce the padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                LucideIcons.book,
                'Order Book',
                0,
              ),
              _buildNavItem(
                context,
                LucideIcons.zap,
                'My Trades',
                1,
                notificationCount: orderNotificationCount,
              ),
              _buildNavItem(
                context,
                LucideIcons.messageSquare,
                'Chat',
                2,
                notificationCount: chatCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index,
      {int? notificationCount}) {
    bool isActive = _isActive(context, index);

    // TODO: adjust with the app_theme
    Color iconColor = isActive ? const Color(0xFF8CC541) : Colors.white;
    Color textColor = isActive ? const Color(0xFF8CC541) : Colors.white;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum size to adapt
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 23, // A bit smaller
                ),
                if (notificationCount != null && notificationCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5), // Less space
            Text(
              label,
              style: GoogleFonts.inter(
                // Use Inter font for a more modern look
                fontSize: 12, // Smaller text
                fontWeight: FontWeight.w400, // Lighter weight
                color: textColor,
                letterSpacing:
                    -0.2, // Negative letter spacing for more condensed text
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(BuildContext context, int index) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    switch (index) {
      case 0:
        return currentLocation == '/';
      case 1:
        return currentLocation == '/order_book';
      case 2:
        return currentLocation == '/chat_list';
      default:
        return false;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    String nextRoute;
    switch (index) {
      case 0:
        nextRoute = '/';
        break;
      case 1:
        nextRoute = '/order_book';
        break;
      case 2:
        nextRoute = '/chat_list';
        break;
      default:
        return;
    }

    final currentLocation = GoRouterState.of(context).uri.toString();
    if (currentLocation != nextRoute) {
      context.push(nextRoute);
    }
  }
}
