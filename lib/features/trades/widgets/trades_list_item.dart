import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/data/models/enums/role.dart';
import 'package:mostro_mobile/data/models/enums/status.dart';
import 'package:mostro_mobile/data/models/enums/order_type.dart';
import 'package:mostro_mobile/data/models/nostr_event.dart';
import 'package:mostro_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:mostro_mobile/shared/providers/session_notifier_provider.dart';
import 'package:mostro_mobile/shared/providers/time_provider.dart';
import 'package:mostro_mobile/shared/utils/currency_utils.dart';

class TradesListItem extends ConsumerWidget {
  final NostrEvent trade;

  const TradesListItem({super.key, required this.trade});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timeProvider);
    final session = ref.watch(sessionProvider(trade.orderId!));
    final role = session?.role;
    final isBuying = role == Role.buyer;
    final orderState = ref.watch(orderNotifierProvider(trade.orderId!));

    // Determine if the user is the creator of the order based on role and order type
    final isCreator = isBuying
        ? trade.orderType == OrderType.buy
        : trade.orderType == OrderType.sell;

    return GestureDetector(
      onTap: () {
        context.push('/trade_detail/${trade.orderId}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1D212C), // Mismo color que el fondo de órdenes en home
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - Trade info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row: Buy/Sell Bitcoin text + status and role chips
                    Row(
                      children: [
                        Text(
                          isBuying ? 'Buying Bitcoin' : 'Selling Bitcoin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusChip(orderState.status),
                        const SizedBox(width: 8),
                        _buildRoleChip(isCreator),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Flag + Amount and currency + Premium/Discount
                    Row(
                      children: [
                        Text(
                          CurrencyUtils.getFlagFromCurrency(
                                  trade.currency ?? '') ??
                              '',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trade.fiatAmount.minimum} ${trade.currency ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Show premium/discount if different from zero
                        if (trade.premium != null && trade.premium != '0')
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    double.tryParse(trade.premium!) != null &&
                                            double.parse(trade.premium!) > 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${double.tryParse(trade.premium!) != null && double.parse(trade.premium!) > 0 ? '+' : ''}${trade.premium}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Third row: Payment methods (muestra todos los métodos de pago separados por comas)
                    trade.paymentMethods.isNotEmpty
                        ? Text(
                            trade.paymentMethods.join(', '),
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          )
                        : Text(
                            'Bank Transfer',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                  ],
                ),
              ),
              // Right side - Arrow icon
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(bool isCreator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isCreator ? Colors.blue.shade700 : Colors.teal.shade700, // Cambiado de verde a teal para "Taken by you"
        borderRadius: BorderRadius.circular(12), // Más redondeado
      ),
      child: Text(
        isCreator ? 'Created by you' : 'Taken by you',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(Status status) {
    Color backgroundColor;
    Color textColor; // Ya no siempre blanca
    String label;

    switch (status) {
      case Status.active:
        backgroundColor = const Color(0xFF1E3A8A).withOpacity(0.3); // Azul oscuro con transparencia
        textColor = const Color(0xFF93C5FD); // Azul claro
        label = 'Active';
        break;
      case Status.pending:
        backgroundColor = const Color(0xFF854D0E).withOpacity(0.3); // Ámbar oscuro con transparencia
        textColor = const Color(0xFFFCD34D); // Ámbar claro
        label = 'Pending';
        break;
      case Status.fiatSent:
        backgroundColor = const Color(0xFF065F46).withOpacity(0.3); // Verde oscuro con transparencia
        textColor = const Color(0xFF6EE7B7); // Verde claro
        label = 'Fiat-sent';
        break;
      case Status.canceled:
      case Status.canceledByAdmin:
      case Status.cooperativelyCanceled:
        backgroundColor = Colors.grey.shade800.withOpacity(0.3);
        textColor = Colors.grey.shade300;
        label = 'Canceled';
        break;
      case Status.settledByAdmin:
      case Status.settledHoldInvoice:
        backgroundColor = const Color(0xFF581C87).withOpacity(0.3); // Morado oscuro con transparencia
        textColor = const Color(0xFFC084FC); // Morado claro
        label = 'Settled';
        break;
      case Status.completedByAdmin:
        backgroundColor = const Color(0xFF065F46).withOpacity(0.3); // Verde oscuro con transparencia
        textColor = const Color(0xFF6EE7B7); // Verde claro
        label = 'Completed';
        break;
      case Status.dispute:
        backgroundColor = const Color(0xFF7F1D1D).withOpacity(0.3); // Rojo oscuro con transparencia
        textColor = const Color(0xFFFCA5A5); // Rojo claro
        label = 'Dispute';
        break;
      case Status.expired:
        backgroundColor = Colors.grey.shade800.withOpacity(0.3);
        textColor = Colors.grey.shade300;
        label = 'Expired';
        break;
      case Status.success:
        backgroundColor = const Color(0xFF065F46).withOpacity(0.3); // Verde oscuro con transparencia
        textColor = const Color(0xFF6EE7B7); // Verde claro
        label = 'Success';
        break;
      case Status.waitingBuyerInvoice:
        backgroundColor = const Color(0xFF1E3A8A).withOpacity(0.3); // Azul oscuro con transparencia
        textColor = const Color(0xFF93C5FD); // Azul claro
        label = 'Waiting Invoice';
        break;
      case Status.waitingPayment:
        backgroundColor = const Color(0xFF1E3A8A).withOpacity(0.3); // Azul oscuro con transparencia
        textColor = const Color(0xFF93C5FD); // Azul claro
        label = 'Waiting Payment';
        break;
      case Status.inProgress:
        backgroundColor = const Color(0xFF1E3A8A).withOpacity(0.3); // Azul oscuro con transparencia
        textColor = const Color(0xFF93C5FD); // Azul claro
        label = 'In Progress';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // Más redondeado
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor, // Color específico para cada estado
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
