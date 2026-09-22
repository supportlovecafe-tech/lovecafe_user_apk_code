import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/addon_model.dart';
import '../models/food_item.dart';

/// Fetches all addon_groups with their available options for a given cinema.
/// Cached per cinemaId for the session.
final addonGroupsProvider =
    FutureProvider.family<List<AddonGroup>, String>((ref, cinemaId) async {
  try {
    final allGroupsResp = await Supabase.instance.client
        .from('addon_groups')
        .select('*')
        .eq('cinema_id', cinemaId)
        .order('sort_order', ascending: true);

    final groups = List<Map<String, dynamic>>.from(allGroupsResp as List);
    if (groups.isEmpty) return [];

    final groupIds = groups.map((g) => g['id'].toString()).toList();

    // Fetch all available options for these groups
    final optionsResp = await Supabase.instance.client
        .from('addon_options')
        .select('*')
        .inFilter('group_id', groupIds)
        .eq('is_available', true)
        .order('sort_order', ascending: true);

    final optionsByGroup = <String, List<AddonOption>>{};
    for (final optMap in (optionsResp as List)) {
      final gid = optMap['group_id'].toString();
      optionsByGroup.putIfAbsent(gid, () => []);
      optionsByGroup[gid]!.add(AddonOption.fromMap(optMap as Map<String, dynamic>));
    }

    return groups.map((gMap) {
      final gid = gMap['id'].toString();
      return AddonGroup.fromMap(gMap, options: optionsByGroup[gid] ?? []);
    }).toList();
  } catch (e) {
    print('Error fetching addon groups: $e');
    return [];
  }
});

/// Fetches all addon_group_assignments for a cinema.
final addonAssignmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, cinemaId) async {
  try {
    final resp = await Supabase.instance.client
        .from('addon_group_assignments')
        .select('*')
        .eq('cinema_id', cinemaId);
    return List<Map<String, dynamic>>.from(resp as List);
  } catch (e) {
    print('Error fetching addon assignments: $e');
    return [];
  }
});

/// Returns the list of AddonGroups that apply to a specific food item,
/// merging item-level and category-level assignments.
List<AddonGroup> getAddonsForItem({
  required FoodItem item,
  required List<AddonGroup> allGroups,
  required List<Map<String, dynamic>> assignments,
}) {
  final itemCategory = item.category.toLowerCase();
  final applicableGroupIds = <String>{};

  for (final a in assignments) {
    final foodItemId = a['food_item_id']?.toString();
    final category = a['category']?.toString();
    final groupId = a['group_id']?.toString() ?? '';

    if (foodItemId != null && foodItemId == item.id) {
      applicableGroupIds.add(groupId);
    } else if (foodItemId == null && category != null &&
        category.toLowerCase() == itemCategory) {
      applicableGroupIds.add(groupId);
    }
  }

  return allGroups
      .where((g) => applicableGroupIds.contains(g.id) && g.options.isNotEmpty)
      .toList();
}
