import 'package:flutter/material.dart';
import 'package:mostro_mobile/core/app_theme.dart';
import 'package:mostro_mobile/features/order/widgets/form_section.dart';

class PremiumSection extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PremiumSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Define the premium value display as the icon
    final premiumValueIcon = Text(
      value.toStringAsFixed(1),
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
    );
    
    // Use the FormSection for consistent styling
    return FormSection(
      title: 'Premium (%) ',
      icon: premiumValueIcon,
      iconBackgroundColor: const Color(0xFF764BA2), // Purple color for premium
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF764BA2),
              inactiveTrackColor: AppTheme.backgroundInactive,
              thumbColor: AppTheme.textPrimary,
              overlayColor: const Color(0xFF764BA2).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: -10,
              max: 10,
              divisions: 200,
              onChanged: onChanged,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '-10%',
                  style: TextStyle(color: AppTheme.statusError, fontSize: 12),
                ),
                Text(
                  '+10%',
                  style: TextStyle(color: AppTheme.statusSuccess, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      // Add an info icon as extra content
      extraContent: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: AppTheme.textSubtle,
          ),
        ),
      ),
    );
  }
}
