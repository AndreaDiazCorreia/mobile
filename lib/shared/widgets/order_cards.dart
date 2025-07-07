import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/shared/widgets/custom_card.dart';
import 'package:mostro_mobile/generated/l10n.dart';

/// Card that displays order amount information
class OrderAmountCard extends StatelessWidget {
  final String title;
  final String amount;
  final String currency;
  final String? currencyFlag;
  final String? priceText;
  final String? premiumText;
  final String? satText;

  const OrderAmountCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    this.currencyFlag,
    this.priceText,
    this.premiumText,
    this.satText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
                'for $amount $currency${currencyFlag ?? ''}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (priceText?.isNotEmpty == true) ...[
                const SizedBox(width: 8),
                Text(
                  priceText!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
              if (premiumText?.isNotEmpty == true) ...[
                const SizedBox(width: 8),
                Text(
                  premiumText!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          if (satText?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              '${satText!} sats',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card that displays payment method information
class PaymentMethodCard extends StatelessWidget {
  final String paymentMethod;

  const PaymentMethodCard({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.payment,
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context)!.paymentMethod,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentMethod,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card that displays the created date
class CreatedDateCard extends StatelessWidget {
  final String createdDate;

  const CreatedDateCard({super.key, required this.createdDate});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context)!.createdOn,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card that displays the order ID with a copy button
class OrderIdCard extends StatelessWidget {
  final String orderId;

  const OrderIdCard({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context)!.orderId,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  orderId,
                  style: const TextStyle(
                    color: AppTheme.mostroGreen,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: orderId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context)!.orderIdCopied),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card that displays the creator's reputation
class CreatorReputationCard extends StatelessWidget {
  final double rating;
  final int reviews;
  final int days;

  const CreatorReputationCard({
    super.key,
    required this.rating,
    required this.reviews,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context)!.creatorReputation,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Rating section
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star,
                            color: AppTheme.mostroGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context)!.rating,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Reviews section
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviews.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context)!.reviews,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Days section
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            days.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.of(context)!.days,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card that displays a notification message with an icon
class NotificationMessageCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const NotificationMessageCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
