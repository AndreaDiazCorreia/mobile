import 'dart:math' as math;
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mostro_mobile/data/models/enums/status.dart';
import 'package:mostro_mobile/data/models/nostr_event.dart';
import 'package:mostro_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:mostro_mobile/shared/providers/order_repository_provider.dart';
import 'package:mostro_mobile/shared/providers/session_notifier_provider.dart';

final _logger = Logger();

final _statusFilter = {
  Status.canceled,
  Status.canceledByAdmin,
  Status.expired,
};

// Status filter provider - holds the currently selected status filter
final statusFilterProvider = StateProvider<Status?>((ref) => null);

// New provider that properly handles synthetic status filtering by checking OrderState
final filteredTradesWithOrderStateProvider =
    Provider<AsyncValue<List<NostrEvent>>>((ref) {
  final allOrdersAsync = ref.watch(orderEventsProvider);
  final sessions = ref.watch(sessionNotifierProvider);
  final selectedStatusFilter = ref.watch(statusFilterProvider);

  _logger.d(
      'Filtering trades with OrderState: Orders state=${allOrdersAsync.toString().substring(0, math.min(100, allOrdersAsync.toString().length))}, Sessions count=${sessions.length}, Status filter=${selectedStatusFilter?.value}');

  return allOrdersAsync.when(
    data: (allOrders) {
      final orderIds = sessions.map((s) => s.orderId).toSet();
      _logger
          .d('Got ${allOrders.length} orders and ${orderIds.length} sessions');

      // Make a copy to avoid modifying the original list
      final sortedOrders = List<NostrEvent>.from(allOrders);
      sortedOrders
          .sort((o1, o2) => o1.expirationDate.compareTo(o2.expirationDate));

      var filtered = sortedOrders.reversed
          .where((o) => orderIds.contains(o.orderId))
          .where((o) => !_statusFilter.contains(o.status));

      // Apply status filter if one is selected - check OrderState for synthetic statuses
      if (selectedStatusFilter != null) {
        filtered = filtered.where((order) {
          try {
            // Get the OrderState for this order to check the derived status
            final orderState = ref.read(orderNotifierProvider(order.orderId));
            return orderState.status == selectedStatusFilter;
          } catch (e) {
            _logger.w('Could not get OrderState for ${order.orderId}: $e');
            // Fallback to raw status comparison
            return order.status == selectedStatusFilter;
          }
        });
      }

      final result = filtered.toList();
      _logger.d('Filtered to ${result.length} trades');
      return AsyncValue.data(result);
    },
    loading: () {
      _logger.d('Orders loading');
      return const AsyncValue.loading();
    },
    error: (error, stackTrace) {
      _logger.e('Error filtering trades: $error');
      return AsyncValue.error(error, stackTrace);
    },
  );
});

// Keep the original provider for backward compatibility, but mark as deprecated
@Deprecated(
    'Use filteredTradesWithOrderStateProvider instead for proper synthetic status filtering')
final filteredTradesProvider = Provider<AsyncValue<List<NostrEvent>>>((ref) {
  final allOrdersAsync = ref.watch(orderEventsProvider);
  final sessions = ref.watch(sessionNotifierProvider);
  final selectedStatusFilter = ref.watch(statusFilterProvider);

  _logger.d(
      'Filtering trades: Orders state=${allOrdersAsync.toString().substring(0, math.min(100, allOrdersAsync.toString().length))}, Sessions count=${sessions.length}, Status filter=${selectedStatusFilter?.value}');

  return allOrdersAsync.when(
    data: (allOrders) {
      final orderIds = sessions.map((s) => s.orderId).toSet();
      _logger
          .d('Got ${allOrders.length} orders and ${orderIds.length} sessions');

      // Make a copy to avoid modifying the original list
      final sortedOrders = List<NostrEvent>.from(allOrders);
      sortedOrders
          .sort((o1, o2) => o1.expirationDate.compareTo(o2.expirationDate));

      var filtered = sortedOrders.reversed
          .where((o) => orderIds.contains(o.orderId))
          .where((o) => !_statusFilter.contains(o.status));

      // Apply status filter if one is selected
      if (selectedStatusFilter != null) {
        filtered = filtered.where((o) => o.status == selectedStatusFilter);
      }

      final result = filtered.toList();
      _logger.d('Filtered to ${result.length} trades');
      return AsyncValue.data(result);
    },
    loading: () {
      _logger.d('Orders loading');
      return const AsyncValue.loading();
    },
    error: (error, stackTrace) {
      _logger.e('Error filtering trades: $error');
      return AsyncValue.error(error, stackTrace);
    },
  );
});
