import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/addon_model.dart';
import '../../../../core/models/food_item.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Shows the Swiggy/Zomato-style add-on selection bottom sheet.
/// Returns List<SelectedAddon> when user confirms, or null if dismissed.
Future<List<SelectedAddon>?> showAddonSelectionSheet({
  required BuildContext context,
  required FoodItem item,
  required List<AddonGroup> addonGroups,
}) {
  return showModalBottomSheet<List<SelectedAddon>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddonSelectionSheet(item: item, addonGroups: addonGroups),
  );
}

class AddonSelectionSheet extends StatefulWidget {
  final FoodItem item;
  final List<AddonGroup> addonGroups;
  const AddonSelectionSheet({super.key, required this.item, required this.addonGroups});

  @override
  State<AddonSelectionSheet> createState() => _AddonSelectionSheetState();
}

class _AddonSelectionSheetState extends State<AddonSelectionSheet> {
  // groupId -> set of selected option IDs
  final Map<String, Set<String>> _selections = {};

  @override
  void initState() {
    super.initState();
    // Pre-select first option for SINGLE required groups
    for (final group in widget.addonGroups) {
      _selections[group.id] = {};
      if (group.isSingle && group.isRequired && group.options.isNotEmpty) {
        _selections[group.id] = {group.options.first.id};
      }
    }
  }

  bool get _canAdd {
    for (final group in widget.addonGroups) {
      if (group.isRequired) {
        final sel = _selections[group.id] ?? {};
        if (sel.isEmpty) return false;
      }
    }
    return true;
  }

  double get _addonTotal {
    double total = 0;
    for (final group in widget.addonGroups) {
      final sel = _selections[group.id] ?? {};
      for (final opt in group.options) {
        if (sel.contains(opt.id)) total += opt.price;
      }
    }
    return total;
  }

  List<SelectedAddon> _buildSelectedAddons() {
    return widget.addonGroups.map((group) {
      final sel = _selections[group.id] ?? {};
      final chosen = group.options.where((o) => sel.contains(o.id)).toList();
      return SelectedAddon(
        groupId: group.id,
        groupName: group.displayName,
        selectedOptions: chosen,
      );
    }).where((a) => a.selectedOptions.isNotEmpty).toList();
  }

  void _toggleOption(AddonGroup group, AddonOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      final sel = _selections[group.id] ??= {};
      if (group.isSingle) {
        // Radio: always replace selection
        sel
          ..clear()
          ..add(option.id);
      } else {
        // Checkbox: toggle
        if (sel.contains(option.id)) {
          sel.remove(option.id);
        } else {
          // Respect max_selection
          if (group.maxSelection != null && sel.length >= group.maxSelection!) return;
          sel.add(option.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = widget.item.price;
    final totalUnit = basePrice + _addonTotal;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                // Item image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.item.imageUrl,
                    width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64, height: 64, color: AppColors.surface,
                      child: const Icon(Icons.fastfood_rounded, color: Colors.white24, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name, style: AppTextStyles.headingMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Customise your order', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 28, indent: 24, endIndent: 24),

          // Addon groups scrollable
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: widget.addonGroups.map((group) => _buildGroupSection(group)).toList(),
            ),
          ),

          // Bottom bar
          _buildBottomBar(basePrice, _addonTotal, totalUnit),
        ],
      ),
    );
  }

  Widget _buildGroupSection(AddonGroup group) {
    final sel = _selections[group.id] ?? {};
    final isSatisfied = !group.isRequired || sel.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Row(
            children: [
              Expanded(
                child: Text(group.displayName, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: group.isRequired
                      ? (isSatisfied ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15))
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: group.isRequired
                        ? (isSatisfied ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4))
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  group.isRequired ? (isSatisfied ? 'Done' : 'Required') : 'Optional',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: group.isRequired
                        ? (isSatisfied ? Colors.green : Colors.red[300])
                        : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
          if (group.isMulti)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                group.maxSelection != null
                    ? 'Select up to '
                    : 'Select any',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled, fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),

          // Options
          ...group.options.map((option) => _buildOptionTile(group, option, sel)),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withOpacity(0.06)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(AddonGroup group, AddonOption option, Set<String> sel) {
    final isSelected = sel.contains(option.id);
    return InkWell(
      onTap: () => _toggleOption(group, option),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Radio / Checkbox visual
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: group.isSingle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: group.isMulti ? BorderRadius.circular(5) : null,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      group.isSingle ? Icons.circle : Icons.check_rounded,
                      size: group.isSingle ? 8 : 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Option name
            Expanded(
              child: Text(
                option.name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),

            // Price
            Text(
              option.price == 0 ? 'FREE' : '+₹',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: option.price == 0
                    ? Colors.green[400]
                    : (isSelected ? AppColors.primary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double base, double addonTotal, double total) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          // Price breakdown
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹ / item',
                  style: AppTextStyles.priceLarge,
                ),
                if (addonTotal > 0)
                  Text(
                    'Base ₹ + addons ₹',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Add to Cart button
          ElevatedButton(
            onPressed: _canAdd
                ? () => Navigator.of(context).pop(_buildSelectedAddons())
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canAdd ? AppColors.primary : Colors.white12,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              elevation: _canAdd ? 4 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_shopping_cart_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  _canAdd ? 'Add to Cart' : 'Select required',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
