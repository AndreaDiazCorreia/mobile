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
import 'package:mostro_mobile/generated/l10n.dart';

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
              ? S.of(context)!.buyOrderDetails
              : S.of(context)!.sellOrderDetails),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSellerAmount(ref, order!, context),

            const SizedBox(height: 16),
            _buildPaymentMethod(order, context),
            const SizedBox(height: 16),
            _buildCreatedOn(order, context),

            const SizedBox(height: 16),
            _buildOrderId(context),
            const SizedBox(height: 16),
            _buildCreatorReputation(order, context),
            const SizedBox(height: 24),
            _buildCountDownTime(order.expirationDate, context),
            const SizedBox(height: 36),
            _buildActionButtons(context, ref, order),
          ],
        ),
      ),
    );
  }


  Widget _buildSellerAmount(
      WidgetRef ref, NostrEvent order, BuildContext context) {
    final selling = orderType == OrderType.sell
        ? S.of(context)!.selling
        : S.of(context)!.buying;
    final currencyFlag = CurrencyUtils.getFlagFromCurrency(order.currency!);
    final amountString = '${order.fiatAmount} ${order.currency} $currencyFlag';
    final priceText = order.amount == '0' ? S.of(context)!.atMarketPrice : '';

    return OrderAmountCard(
      title: S.of(context)!.someoneIsSelling(selling),
      amount: order.fiatAmount.toString(),
      currency: order.currency!,
      currencyFlag: currencyFlag,
      priceText: priceText,

    );
  }

  Widget _buildOrderId(BuildContext context) {

    return OrderIdCard(
      orderId: orderId,

    );
  }

  Widget _buildCountDownTime(DateTime expiration, BuildContext context) {
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
        Text(S.of(context)!.timeLeft(countdown.toString().split('.')[0])),
      ],
    );
  }

  Widget _buildPaymentMethod(NostrEvent order, BuildContext context) {
    final methods = order.paymentMethods.isNotEmpty
        ? order.paymentMethods.join(', ')
        : S.of(context)!.noPaymentMethod;

    return PaymentMethodCard(
      paymentMethod: methods,
    );
  }

  Widget _buildCreatedOn(NostrEvent order, BuildContext context) {
    return CreatedDateCard(
      createdDate: formatDateTime(order.createdAt!),
    );
  }

  Widget _buildCreatorReputation(NostrEvent order, BuildContext context) {
    final ratingInfo = order.rating;

    final rating = ratingInfo?.totalRating ?? 0.0;
    final reviews = ratingInfo?.totalReviews ?? 0;
    final days = ratingInfo?.days ?? 0;

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

    final buttonText = orderType == OrderType.buy
        ? S.of(context)!.sellBitcoin
        : S.of(context)!.buyBitcoin;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: AppTheme.theme.outlinedButtonTheme.style,
            child: Text(S.of(context)!.close),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              // Check if this is a range order
              if (order.fiatAmount.maximum != null &&
                  order.fiatAmount.minimum != order.fiatAmount.maximum) {
                // Show dialog to get the amount
                String? errorText;
                final enteredAmount = await showDialog<int>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text(S.of(context)!.enterAmount),
                          content: TextField(
                            controller: _fiatAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: S.of(context)!.enterAmountBetween(
                                  order.fiatAmount.minimum.toString(),
                                  order.fiatAmount.maximum.toString()),
                              errorText: errorText,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: Text(S.of(context)!.cancel),
                            ),
                            ElevatedButton(
                              key: const Key('submitAmountButton'),
                              onPressed: () {
                                final inputAmount = int.tryParse(
                                    _fiatAmountController.text.trim());
                                if (inputAmount == null) {
                                  setState(() {
                                    errorText =
                                        S.of(context)!.pleaseEnterValidNumber;
                                  });
                                } else if (inputAmount <
                                        order.fiatAmount.minimum ||
                                    (order.fiatAmount.maximum != null &&
                                        inputAmount >
                                            order.fiatAmount.maximum!)) {
                                  setState(() {
                                    errorText = S
                                        .of(context)!
                                        .amountMustBeBetween(
                                            order.fiatAmount.minimum.toString(),
                                            order.fiatAmount.maximum
                                                .toString());
                                  });
                                } else {
                                  Navigator.of(context).pop(inputAmount);
                                }
                              },
                              child: Text(S.of(context)!.submit),
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
    final dateFormatter = DateFormat('EEE, MMM dd yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final formattedDate = dateFormatter.format(dt);
    final formattedTime = timeFormatter.format(dt);

    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');

    return '$formattedDate at $formattedTime (GMT$sign$hours)';
  }
}
