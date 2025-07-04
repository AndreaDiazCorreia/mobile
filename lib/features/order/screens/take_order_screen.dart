import 'package:circular_countdown/circular_countdown.dart';
import 'package:dart_nostr/nostr/model/event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/data/models/enums/order_type.dart';
import 'package:mostro_mobile/data/models/nostr_event.dart';
import 'package:mostro_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:mostro_mobile/features/order/widgets/order_app_bar.dart';
import 'package:mostro_mobile/shared/widgets/order_cards.dart';
import 'package:mostro_mobile/shared/providers/order_repository_provider.dart';
import 'package:mostro_mobile/shared/utils/currency_utils.dart';
import 'package:mostro_mobile/shared/widgets/custom_card.dart';

class TakeOrderScreen extends ConsumerWidget {
  final String orderId;
  final OrderType orderType;
  final TextEditingController _fiatAmountController = TextEditingController();
  final TextEditingController _lndAddressController = TextEditingController();
  final TextTheme textTheme = AppTheme.theme.textTheme;

  TakeOrderScreen({super.key, required this.orderId, required this.orderType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(eventProvider(orderId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: OrderAppBar(
          title: orderType == OrderType.buy
              ? 'BUY ORDER DETAILS'
              : 'SELL ORDER DETAILS'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSellerAmount(ref, order!),
            const SizedBox(height: 16),
            _buildPaymentMethod(order),
            const SizedBox(height: 16),
            _buildCreatedOn(order),
            const SizedBox(height: 16),
            _buildOrderId(context),
            const SizedBox(height: 16),
            _buildCreatorReputation(order),
            const SizedBox(height: 24),
            _buildCountDownTime(order.expirationDate),
            const SizedBox(height: 36),
            _buildActionButtons(context, ref, order),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerAmount(WidgetRef ref, NostrEvent order) {
    final selling = orderType == OrderType.sell ? 'Selling' : 'Buying';
    final currencyFlag = CurrencyUtils.getFlagFromCurrency(order.currency!);
    final amountString = '${order.fiatAmount} ${order.currency} $currencyFlag';
    final priceText = order.amount == '0' ? 'at market price' : '';

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Someone is $selling Sats',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'for $amountString',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (priceText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  priceText,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderId(BuildContext context) {
    return OrderIdCard(
      orderId: orderId,
    );
  }

  Widget _buildCountDownTime(DateTime expiration) {
    Duration countdown = Duration(hours: 0);
    final now = DateTime.now();
    if (expiration.isAfter(now)) {
      countdown = expiration.difference(now);
    }

    return Column(
      children: [
        CircularCountdown(
          countdownTotal: 24,
          countdownRemaining: countdown.inHours,
        ),
        const SizedBox(height: 16),
        Text('Time Left: ${countdown.toString().split('.')[0]}'),
      ],
    );
  }

  Widget _buildPaymentMethod(NostrEvent order) {
    final methods = order.paymentMethods.isNotEmpty
        ? order.paymentMethods.join(', ')
        : 'No payment method';

    return PaymentMethodCard(
      paymentMethod: methods,
    );
  }

  Widget _buildCreatedOn(NostrEvent order) {
    return CreatedDateCard(
      createdDate: formatDateTime(order.createdAt!),
    );
  }

  Widget _buildCreatorReputation(NostrEvent order) {
  // For now, show placeholder data matching TradeDetailScreen
  // In a real implementation, this would come from the order creator's data
  const rating = 3.1;
  const reviews = 15;
  const days = 7;

  return CreatorReputationCard(
    rating: rating,
    reviews: reviews,
    days: days,
  );
}

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, NostrEvent order) {
    final orderDetailsNotifier =
        ref.read(orderNotifierProvider(orderId).notifier);

    final buttonText =
        orderType == OrderType.buy ? 'SELL BITCOIN' : 'BUY BITCOIN';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppTheme.theme.outlinedButtonTheme.style,
            child: const Text('CLOSE'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              // Check if this is a range order
              if (order.fiatAmount.minimum != order.fiatAmount.maximum) {
                // Show dialog to get the amount
                String? errorText;
                final enteredAmount = await showDialog<int>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Enter Amount'),
                          content: TextField(
                            controller: _fiatAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter an amount between ${order.fiatAmount.minimum} and ${order.fiatAmount.maximum}',
                              errorText: errorText,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              key: const Key('submitAmountButton'),
                              onPressed: () {
                                final inputAmount = int.tryParse(
                                    _fiatAmountController.text.trim());
                                if (inputAmount == null) {
                                  setState(() {
                                    errorText = "Please enter a valid number.";
                                  });
                                } else if (inputAmount <
                                        order.fiatAmount.minimum ||
                                    inputAmount > order.fiatAmount.maximum!) {
                                  setState(() {
                                    errorText =
                                        "Amount must be between ${order.fiatAmount.minimum} and ${order.fiatAmount.maximum}.";
                                  });
                                } else {
                                  Navigator.of(context).pop(inputAmount);
                                }
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (enteredAmount != null) {
                  if (orderType == OrderType.buy) {
                    await orderDetailsNotifier.takeBuyOrder(
                        order.orderId!, enteredAmount);
                  } else {
                    final lndAddress = _lndAddressController.text.trim();
                    await orderDetailsNotifier.takeSellOrder(
                      order.orderId!,
                      enteredAmount,
                      lndAddress.isEmpty ? null : lndAddress,
                    );
                  }
                }
              } else {
                // Not a range order – use the existing logic.
                final fiatAmount =
                    int.tryParse(_fiatAmountController.text.trim());
                if (orderType == OrderType.buy) {
                  await orderDetailsNotifier.takeBuyOrder(
                      order.orderId!, fiatAmount);
                } else {
                  final lndAddress = _lndAddressController.text.trim();
                  await orderDetailsNotifier.takeSellOrder(
                    order.orderId!,
                    fiatAmount,
                    lndAddress.isEmpty ? null : lndAddress,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mostroGreen,
            ),
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }

  String formatDateTime(DateTime dt) {
    // Formato más amigable: Día de semana, Día Mes Año a las HH:MM (Zona horaria)
    final dateFormatter = DateFormat('EEE, MMM dd yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final formattedDate = dateFormatter.format(dt);
    final formattedTime = timeFormatter.format(dt);
    
    // Simplificar la zona horaria a solo GMT+/-XX
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    
    return '$formattedDate at $formattedTime (GMT$sign$hours)';
  }
}
