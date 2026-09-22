// Addon models for the Cinema Eats customer app.
// These represent add-on groups, options, and customer selections.

class AddonOption {
  final String id;
  final String groupId;
  final String name;
  final double price;
  final bool isAvailable;
  final int sortOrder;

  AddonOption({
    required this.id,
    required this.groupId,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  factory AddonOption.fromMap(Map<String, dynamic> map) {
    return AddonOption(
      id: map['id']?.toString() ?? '',
      groupId: map['group_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isAvailable: map['is_available'] as bool? ?? true,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'group_id': groupId,
    'name': name,
    'price': price,
    'is_available': isAvailable,
  };
}

class AddonGroup {
  final String id;
  final String cinemaId;
  final String name;
  final String displayName;
  final String selectionType; // 'SINGLE' | 'MULTI'
  final bool isRequired;
  final int minSelection;
  final int? maxSelection;
  final int sortOrder;
  final List<AddonOption> options;

  AddonGroup({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.displayName,
    required this.selectionType,
    required this.isRequired,
    this.minSelection = 0,
    this.maxSelection,
    this.sortOrder = 0,
    this.options = const [],
  });

  bool get isSingle => selectionType == 'SINGLE';
  bool get isMulti => selectionType == 'MULTI';

  factory AddonGroup.fromMap(Map<String, dynamic> map, {List<AddonOption> options = const []}) {
    return AddonGroup(
      id: map['id']?.toString() ?? '',
      cinemaId: map['cinema_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? map['name']?.toString() ?? '',
      selectionType: map['selection_type']?.toString() ?? 'SINGLE',
      isRequired: map['is_required'] as bool? ?? false,
      minSelection: (map['min_selection'] as num?)?.toInt() ?? 0,
      maxSelection: (map['max_selection'] as num?)?.toInt(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      options: options,
    );
  }
}

/// Represents a customer's selection within one AddonGroup.
class SelectedAddon {
  final String groupId;
  final String groupName;
  final List<AddonOption> selectedOptions;

  SelectedAddon({
    required this.groupId,
    required this.groupName,
    required this.selectedOptions,
  });

  double get extraPrice =>
      selectedOptions.fold(0.0, (sum, o) => sum + o.price);

  Map<String, dynamic> toMap() => {
    'group_id': groupId,
    'group': groupName,
    'options': selectedOptions
        .map((o) => {'name': o.name, 'price': o.price})
        .toList(),
  };

  factory SelectedAddon.fromMap(Map<String, dynamic> map) {
    final rawOptions = (map['options'] as List<dynamic>? ?? []);
    return SelectedAddon(
      groupId: map['group_id']?.toString() ?? '',
      groupName: map['group']?.toString() ?? '',
      selectedOptions: rawOptions.map((o) {
        final om = o as Map<String, dynamic>;
        return AddonOption(
          id: '',
          groupId: map['group_id']?.toString() ?? '',
          name: om['name']?.toString() ?? '',
          price: (om['price'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
    );
  }
}
