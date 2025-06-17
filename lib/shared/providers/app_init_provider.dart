import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mostro_mobile/features/key_manager/key_manager_provider.dart';
import 'package:mostro_mobile/features/chat/providers/chat_room_providers.dart';
import 'package:mostro_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:mostro_mobile/features/settings/settings.dart';
import 'package:mostro_mobile/features/settings/settings_provider.dart';
import 'package:mostro_mobile/shared/providers/background_service_provider.dart';
import 'package:mostro_mobile/shared/providers/nostr_service_provider.dart';
import 'package:mostro_mobile/shared/providers/session_notifier_provider.dart';

final appInitializerProvider = FutureProvider<void>((ref) async {
  final nostrService = ref.read(nostrServiceProvider);
  await nostrService.init(ref.read(settingsProvider));

  final keyManager = ref.read(keyManagerProvider);
  await keyManager.init();

  final sessionManager = ref.read(sessionNotifierProvider.notifier);
  await sessionManager.init();

  ref.listen<Settings>(settingsProvider, (previous, next) {
    sessionManager.updateSettings(next);
    ref.read(backgroundServiceProvider).updateSettings(next);
  });

  final cutoff = DateTime.now().subtract(const Duration(hours: 24));

  for (final session in sessionManager.sessions) {
    if (session.orderId != null && session.startTime.isAfter(cutoff)) {
      ref.read(orderNotifierProvider(session.orderId!).notifier);
    }

    if (session.peer != null && session.startTime.isAfter(cutoff)) {
      ref.read(chatRoomsProvider(session.orderId!).notifier).subscribe();
    }
  }
});
