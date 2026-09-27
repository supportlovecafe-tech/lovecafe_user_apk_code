import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/addon_model.dart';
import '../../../../core/models/food_item.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Shows a POS-style add-on customisation bottom sheet.
/// Returns List<SelectedAddon> when user confirms, or null if dismissed.
Future<List<SelectedAddon>?> showAddonSelectionSheet({
  required BuildContext context,
  required FoodItem item,
  required List<AddonGroup> addonGroups,
}) {
  return showModalBottomSheet<List<SelectedAddon>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddonSelectionSheet(item: item, addonGroups: addonGroups),
  );
}

// ─── Gold accent colour matching the POS "--accent-gold" variable ───────────
const Color _kGold = Color(0xFFFFC857);
const Color _kPrimary = Color(0xFFFF2F92);
const Color _kCardBg = Color(0xFF12121A);
const Color _kGroupCardBg = Color(0xFF1A1A24);
const Color _kGroupCardBorder = Color(0x0FFFFFFF);

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

  double get _total => widget.item.price + _addonTotal;

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
        // Radio: replace selection; allow deselect only for optional groups
        if (sel.contains(option.id) && !group.isRequired) {
          sel.clear();
        } else {
          sel
            ..clear()
            ..add(option.id);
        }
      } else {
        // Checkbox: toggle
        if (sel.contains(option.id)) {
          sel.remove(option.id);
        } else {
          if (group.maxSelection != null && sel.length >= group.maxSelection!) return;
          sel.add(option.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
          left: BorderSide(color: Color(0x1FFFFFFF), width: 1),
          right: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header: item name + base price ──────────────────────────────
          _buildHeader(),

          // Divider
          const Divider(color: Color(0x14FFFFFF), height: 1),

          // ── Scrollable option groups ─────────────────────────────────────
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              children: widget.addonGroups
                  .map((group) => _buildGroupCard(group))
                  .toList(),
            ),
          ),

          // ── Sticky footer: price + Cancel + ADD TO ORDER ─────────────────
          _buildFooter(),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize ${widget.item.name}',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Base: ₹${widget.item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _kGold,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(null),
              child: const SizedBox(
                width: 34,
                height: 34,
                child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Group card  (matches POS: rounded card, group badge, option rows)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGroupCard(AddonGroup group) {
    final sel = _selections[group.id] ?? {};
    final isSingle = group.isSingle;
    final isRequired = group.isRequired;
    final isSatisfied = !isRequired || sel.isNotEmpty;

    // Badge label
    final String badgeLabel = isRequired
        ? 'Required (Pick 1)'
        : (isSingle ? 'Optional (Pick 1)' : 'Optional (Multiple)');
    final Color badgeBg = isRequired
        ? _kPrimary.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.06);
    final Color badgeColor = isRequired ? _kPrimary : const Color(0xFF888899);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kGroupCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRequired && !isSatisfied
                ? Colors.red.withValues(alpha: 0.3)
                : _kGroupCardBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Group title row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Option rows ──────────────────────────────────────────────
            ...group.options.map((opt) => _buildOptionRow(group, opt, sel, isSingle)),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Single option row  (POS style: radio dot + name + gold price)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOptionRow(AddonGroup group, AddonOption option, Set<String> sel, bool isSingle) {
    final isSelected = sel.contains(option.id);

    return GestureDetector(
      onTap: () => _toggleOption(group, option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPrimary.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _kPrimary.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio / Checkbox indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: isSingle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isSingle ? null : BorderRadius.circular(4),
                color: isSelected ? _kPrimary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? _kPrimary : Colors.white38,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: isSingle ? 6 : 10,
                        height: isSingle ? 6 : 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: isSingle ? null : BorderRadius.circular(2),
                          shape: isSingle ? BoxShape.circle : BoxShape.rectangle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Option name
            Expanded(
              child: Text(
                option.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF888899),
                ),
              ),
            ),

            // Price in gold when selected, muted when not
            Text(
              option.price == 0
                  ? 'Free'
                  : '+₹${option.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? _kGold
                    : (option.price == 0
                        ? AppColors.success
                        : const Color(0xFF888899)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Footer: matches POS — "Total Item Price" + gold amount + Cancel + Add btn
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.30),
          border: const Border(
            top: BorderSide(color: Color(0x14FFFFFF), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Price column ───────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Total Item Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888899),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${_total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _kGold,
                    height: 1.1,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            // ── Cancel + Add to Order ──────────────────────────────────
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(null),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // ADD TO ORDER
                  Material(
                    color: _canAdd ? _kPrimary : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _canAdd
                          ? () => Navigator.of(context).pop(_buildSelectedAddons())
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text(
                          _canAdd ? 'ADD TO ORDER' : 'SELECT REQUIRED',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: _canAdd ? Colors.white : Colors.white38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
