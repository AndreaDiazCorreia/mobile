import 'dart:async';

import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mostro_mobile/data/models/chat_room.dart';
import 'package:mostro_mobile/data/models/session.dart';
import 'package:mostro_mobile/features/chat/providers/chat_room_providers.dart';
import 'package:mostro_mobile/shared/providers/session_notifier_provider.dart';

class ChatRoomsNotifier extends StateNotifier<List<ChatRoom>> {
  final Ref ref;
  final _logger = Logger();

  StreamSubscription<NostrEvent>? _subscription;

  ChatRoomsNotifier(this.ref) : super(const []) {
    loadChats();
  }

  void subscribe(Session session) {
    if (session.sharedKey == null) {
      _logger.e('Shared key is null');
      return;
    }
    
  }

  /// Reload all chat rooms by triggering their notifiers to resubscribe to events.
  void reloadAllChats() {
    for (final chat in state) {
      try {
        final notifier = ref.read(chatRoomsProvider(chat.orderId).notifier);
        if (notifier.mounted) {
          notifier.reload();
        }
      } catch (e) {
        _logger.e('Failed to reload chat for orderId ${chat.orderId}: $e');
      }
    }
  }

  Future<void> loadChats() async {
    final sessions = ref.read(sessionNotifierProvider.notifier).sessions;
    if (sessions.isEmpty) {
      _logger.i("No sessions yet, skipping chat load.");
      return;
    }
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 36));

    try {
      final chats = sessions
          .where(
        (s) => s.peer != null && s.startTime.isAfter(cutoff),
      )
          .map((s) {
        final chat = ref.read(chatRoomsProvider(s.orderId!));
        return chat;
      }).toList();
      if (chats.isNotEmpty) {
        state = chats;
      } else {
        _logger.i("No chats found for sessions, keeping previous state.");
      }
    } catch (e) {
      _logger.e(e);
    }
  }
}
