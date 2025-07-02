import 'package:circular_countdown/circular_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/data/models/enums/action.dart' as actions;
import 'package:mostro_mobile/data/models/enums/role.dart';
import 'package:mostro_mobile/data/models/enums/status.dart';
import 'package:mostro_mobile/features/order/models/order_state.dart';
import 'package:mostro_mobile/features/order/providers/order_notifier_provider.dart';
import 'package:mostro_mobile/features/order/widgets/order_app_bar.dart';
import 'package:mostro_mobile/features/trades/widgets/mostro_message_detail_widget.dart';
import 'package:mostro_mobile/shared/providers/session_notifier_provider.dart';
import 'package:mostro_mobile/shared/utils/currency_utils.dart';
import 'package:mostro_mobile/shared/widgets/custom_card.dart';
import 'package:mostro_mobile/shared/widgets/mostro_reactive_button.dart';

class TradeDetailScreen extends ConsumerWidget {
  final String orderId;
  final TextTheme textTheme = AppTheme.theme.textTheme;

  TradeDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradeState = ref.watch(orderNotifierProvider(orderId));
    // If message is null or doesn't have an Order payload, show loading
    final orderPayload = tradeState.order;
    if (orderPayload == null) {
      return const Scaffold(
        backgroundColor: AppTheme.dark1,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.dark1,
      appBar: OrderAppBar(title: 'ORDER DETAILS'),
      body: Builder(
        builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Display basic info about the trade:
                _buildSellerAmount(ref, tradeState),
                const SizedBox(height: 16),
                _buildOrderId(context),
                const SizedBox(height: 16),
                // Detailed info: includes the last Mostro message action text
                MostroMessageDetail(orderId: orderId),
                const SizedBox(height: 24),
                _buildCountDownTime(orderPayload.expiresAt != null ? orderPayload.expiresAt!*1000 : null),
                const SizedBox(height: 36),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildCloseButton(context),
                    ..._buildActionButtons(
                      context,
                      ref,
                      tradeState,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a card showing the user is "selling/buying X sats for Y fiat" etc.
  Widget _buildSellerAmount(WidgetRef ref, OrderState tradeState) {
    final session = ref.watch(sessionProvider(orderId));

    final selling = session!.role == Role.seller ? 'selling' : 'buying';
    final currencyFlag = CurrencyUtils.getFlagFromCurrency(
      tradeState.order!.fiatCode,
    );

    final amountString =
        '${tradeState.order!.fiatAmount} ${tradeState.order!.fiatCode} $currencyFlag';

    // If `orderPayload.amount` is 0, the trade is "at market price"
    final isZeroAmount = (tradeState.order!.amount == 0);
    final satText = isZeroAmount ? '' : ' ${tradeState.order!.amount}';
    final priceText = isZeroAmount ? 'at market price' : '';

    final premium = tradeState.order!.premium;
    final premiumText = premium == 0
        ? ''
        : (premium > 0)
            ? 'with a +$premium% premium'
            : 'with a $premium% discount';

    // Payment method
    final method = tradeState.order!.paymentMethod;
    final timestamp = formatDateTime(
      tradeState.order!.createdAt != null && tradeState.order!.createdAt! > 0
          ? DateTime.fromMillisecondsSinceEpoch(tradeState.order!.createdAt!*1000)
          : session.startTime,
    );
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              // Using Column with spacing = 2 isn't standard; using SizedBoxes for spacing is fine.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are $selling$satText sats for $amountString $priceText $premiumText',
                  style: AppTheme.theme.textTheme.bodyLarge,
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Created on: $timestamp',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Payment methods: $method',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show a card with the order ID that can be copied.
  Widget _buildOrderId(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SelectableText(
            orderId,
            style: const TextStyle(color: AppTheme.mostroGreen),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.mostroGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Build a circular countdown to show how many hours are left until expiration.
  Widget _buildCountDownTime(int? expiresAtTimestamp) {
    // Convert timestamp to DateTime
    final expiration = expiresAtTimestamp != null && expiresAtTimestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(expiresAtTimestamp)
        : DateTime.now().add(const Duration(hours: 24));

    // If expiration has passed, the difference is negative => zero.
    final now = DateTime.now();
    final Duration difference =
        expiration.isAfter(now) ? expiration.difference(now) : const Duration();

    // Display hours left
    final hoursLeft = difference.inHours.clamp(0, 9999);
    return Column(
      children: [
        CircularCountdown(
          countdownTotal: 24,
          countdownRemaining: hoursLeft,
        ),
        const SizedBox(height: 16),
        Text('Time Left: ${difference.toString().split('.').first}'),
      ],
    );
  }

  /// Main action button area, switching on `orderPayload.status`.
  /// Additional checks use `message.action` to refine which button to show.
  /// Following the Mostro protocol state machine for order flow.
  List<Widget> _buildActionButtons(
      BuildContext context, WidgetRef ref, OrderState tradeState) {
    final session = ref.watch(sessionProvider(orderId));
    final userRole = session?.role;

    if (userRole == null) {
      return [];
    }

    final userActions = tradeState.getActions(userRole);
    if (userActions.isEmpty) return [];

    final widgets = <Widget>[];

    for (final action in userActions) {
      // FSM-driven action mapping: ensure all actions are handled
      switch (action) {
        case actions.Action.cancel:
          String buttonText;
          Color buttonColor;

          if (tradeState.status == Status.active ||
              tradeState.status == Status.fiatSent) {
            buttonText = 'COOPERATIVE CANCEL';
            buttonColor = AppTheme.red1;
          } else {
            buttonText = 'CANCEL';
            buttonColor = AppTheme.red1;
          }

          widgets.add(_buildNostrButton(
            buttonText,
            action: action,
            backgroundColor: buttonColor,
            onPressed: () =>
                ref.read(orderNotifierProvider(orderId).notifier).cancelOrder(),
          ));
          break;

        case actions.Action.payInvoice:
          if (userRole == Role.seller) {
            final hasPaymentRequest = tradeState.paymentRequest != null;

            if (hasPaymentRequest) {
              widgets.add(_buildNostrButton(
                'PAY INVOICE',
                action: actions.Action.payInvoice,
                backgroundColor: AppTheme.mostroGreen,
                onPressed: () => context.push('/pay_invoice/$orderId'),
              ));
            }
          }
          break;

        case actions.Action.addInvoice:
          if (userRole == Role.buyer) {
            widgets.add(_buildNostrButton(
              'ADD INVOICE',
              action: actions.Action.addInvoice,
              backgroundColor: AppTheme.mostroGreen,
              onPressed: () => context.push('/add_invoice/$orderId'),
            ));
          }
          break;

        case actions.Action.fiatSent:
          if (userRole == Role.buyer) {
            widgets.add(_buildNostrButton(
              'FIAT SENT',
              action: actions.Action.fiatSent,
              backgroundColor: AppTheme.mostroGreen,
              onPressed: () => ref
                  .read(orderNotifierProvider(orderId).notifier)
                  .sendFiatSent(),
            ));
          }
          break;

        case actions.Action.disputeInitiatedByYou:
        case actions.Action.disputeInitiatedByPeer:
        case actions.Action.dispute:
          // Only allow dispute if not already disputed
          if (tradeState.action != actions.Action.disputeInitiatedByYou &&
              tradeState.action != actions.Action.disputeInitiatedByPeer &&
              tradeState.action != actions.Action.dispute) {
            widgets.add(_buildNostrButton(
              'DISPUTE',
              action: actions.Action.disputeInitiatedByYou,
              backgroundColor: AppTheme.red1,
              onPressed: () => ref
                  .read(orderNotifierProvider(orderId).notifier)
                  .disputeOrder(),
            ));
          }
          break;

        case actions.Action.release:
          if (userRole == Role.seller) {
            widgets.add(_buildNostrButton(
              'RELEASE',
              action: actions.Action.release,
              backgroundColor: AppTheme.mostroGreen,
              onPressed: () => ref
                  .read(orderNotifierProvider(orderId).notifier)
                  .releaseOrder(),
            ));
          }
          break;

        case actions.Action.takeSell:
          if (userRole == Role.buyer) {
            widgets.add(_buildNostrButton(
              'TAKE SELL',
              action: actions.Action.takeSell,
              backgroundColor: AppTheme.mostroGreen,
              onPressed: () => context.push('/take_sell/$orderId'),
            ));
          }
          break;

        case actions.Action.takeBuy:
          if (userRole == Role.seller) {
            widgets.add(_buildNostrButton(
              'TAKE BUY',
              action: actions.Action.takeBuy,
              backgroundColor: AppTheme.mostroGreen,
              onPressed: () => context.push('/take_buy/$orderId'),
            ));
          }
          break;

        // ✅ CASOS DE COOPERATIVE CANCEL: Ahora estos se manejan cuando el usuario ya inició/recibió cooperative cancel
        case actions.Action.cooperativeCancelInitiatedByYou:
          // El usuario ya inició cooperative cancel, ahora debe esperar respuesta
          widgets.add(_buildNostrButton(
            'CANCEL PENDING',
            action: actions.Action.cooperativeCancelInitiatedByYou,
            backgroundColor: Colors.grey,
            onPressed: null,
          ));
          break;

        case actions.Action.cooperativeCancelInitiatedByPeer:
          widgets.add(_buildNostrButton(
            'ACCEPT CANCEL',
            action: actions.Action.cooperativeCancelAccepted,
            backgroundColor: AppTheme.red1,
            onPressed: () =>
                ref.read(orderNotifierProvider(orderId).notifier).cancelOrder(),
          ));
          break;

        case actions.Action.cooperativeCancelAccepted:
          break;

        case actions.Action.purchaseCompleted:
          widgets.add(_buildNostrButton(
            'COMPLETE PURCHASE',
            action: actions.Action.purchaseCompleted,
            backgroundColor: AppTheme.mostroGreen,
            onPressed: () => ref
                .read(orderNotifierProvider(orderId).notifier)
                .releaseOrder(),
          ));
          break;

        case actions.Action.buyerTookOrder:
          widgets.add(_buildContactButton(context));
          break;

        case actions.Action.rate:
        case actions.Action.rateUser:
        case actions.Action.rateReceived:
          widgets.add(_buildNostrButton(
            'RATE',
            action: actions.Action.rate,
            backgroundColor: AppTheme.mostroGreen,
            onPressed: () => context.push('/rate_user/$orderId'),
          ));
          break;

        case actions.Action.sendDm:
          widgets.add(_buildContactButton(context));
          break;

        case actions.Action.holdInvoicePaymentCanceled:
        case actions.Action.buyerInvoiceAccepted:
        case actions.Action.waitingSellerToPay:
        case actions.Action.waitingBuyerInvoice:
        case actions.Action.adminCancel:
        case actions.Action.adminCanceled:
        case actions.Action.adminSettle:
        case actions.Action.adminSettled:
        case actions.Action.adminAddSolver:
        case actions.Action.adminTakeDispute:
        case actions.Action.adminTookDispute:
        case actions.Action.paymentFailed:
        case actions.Action.invoiceUpdated:
        case actions.Action.tradePubkey:
        case actions.Action.cantDo:
        case actions.Action.released:
          break;
        default:
          break;
      }
    }

    return widgets;
  }

  /// Helper method to build a NostrResponsiveButton with common properties
  Widget _buildNostrButton(
    String label, {
    required actions.Action action,
    required VoidCallback? onPressed,
    Color? backgroundColor,
  }) {
    return MostroReactiveButton(
      label: label,
      buttonStyle: ButtonStyleType.raised,
      orderId: orderId,
      action: action,
      backgroundColor: backgroundColor,
      onPressed: onPressed ?? () {}, // Provide empty function when null
      showSuccessIndicator: true,
      timeout: const Duration(seconds: 30),
    );
  }

  Widget _buildContactButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.push('/chat_room/$orderId');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.mostroGreen,
      ),
      child: const Text('CONTACT'),
    );
  }

  /// CLOSE
  Widget _buildCloseButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.go('/order_book'),
      style: AppTheme.theme.outlinedButtonTheme.style,
      child: const Text('CLOSE'),
    );
  }

  /// Format the date time to a user-friendly string with UTC offset
  String formatDateTime(DateTime dt) {
    final dateFormatter = DateFormat('EEE MMM dd yyyy HH:mm:ss');
    final formattedDate = dateFormatter.format(dt);
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final timeZoneName = dt.timeZoneName;
    return '$formattedDate GMT $sign$hours$minutes ($timeZoneName)';
  }
}
