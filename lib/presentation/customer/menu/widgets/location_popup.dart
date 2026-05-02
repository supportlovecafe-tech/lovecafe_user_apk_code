import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/cinema_hall.dart';
import '../../../../core/providers/cinema_halls_provider.dart';
import '../../../shared/widgets/safe_network_image.dart';

class LocationSelectionPopup extends ConsumerStatefulWidget {
  final Function(String hallId, String hallName, String screen, String seat)
      onSelected;

  const LocationSelectionPopup({super.key, required this.onSelected});

  @override
  ConsumerState<LocationSelectionPopup> createState() =>
      _LocationSelectionPopupState();
}

class _LocationSelectionPopupState
    extends ConsumerState<LocationSelectionPopup> {
  String? _selectedHallId;
  String? _selectedScreenId;
  final TextEditingController _seatController = TextEditingController();
  int _step = 0;
  String _seatRow = 'F';
  int _seatNumber = 9;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final halls = ref.watch(cinemaHallsProvider);
    final selectedHall = _resolveSelectedHall(halls);
    final screens = selectedHall?.screens ?? const <CinemaScreen>[];
    final selectedScreen = _resolveSelectedScreen(screens);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: () => setState(() => _step -= 1),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: colorScheme.onSurface),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          color: colorScheme.onSurface),
                    ),
                  ],
                ),
                _buildStepperHeader(
                  context: context,
                  step: _step,
                  hallName: selectedHall?.name,
                  screenName: selectedScreen?.name,
                  seat: _computedSeatLabel,
                ),
                const SizedBox(height: 32),
                if (_step == 0) ...[
                  _buildSectionTitle('1) SELECT CINEMA HALL'),
                  const SizedBox(height: 16),
                  if (halls.isEmpty)
                    _buildEmptyState(
                        context, 'No cinema halls added yet. Add one from the admin dashboard.')
                  else
                    ...halls.map((hall) => _buildHallCard(context, hall)).toList(),
                ] else if (_step == 1) ...[
                  _buildSectionTitle('2) SELECT SCREEN'),
                  const SizedBox(height: 16),
                  if (screens.isEmpty)
                    _buildEmptyState(context, 'This hall has no screens configured yet.')
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.4,
                      children: screens
                          .map((screen) => _buildScreenTile(context, screen))
                          .toList(),
                    ),
                ] else ...[
                  _buildSectionTitle('3) PICK ROW & SEAT'),
                  const SizedBox(height: 16),
                  _buildSeatPicker(context),
                  const SizedBox(height: 16),
                  _buildSectionTitle('OR TYPE YOUR SEAT'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _seatController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'e.g. G12',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.chair_alt_rounded,
                            color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tip: Use row+seat like G12. We deliver directly to you.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _primaryEnabled(selectedHall, selectedScreen)
                    ? () {
                        if (_step < 2) {
                          setState(() => _step += 1);
                          return;
                        }
                        final seatText = _seatController.text.trim().isEmpty
                            ? _computedSeatLabel
                            : _seatController.text.trim();
                        widget.onSelected(
                          selectedHall!.id,
                          selectedHall.name,
                          selectedScreen!.name,
                          seatText,
                        );
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  _step < 2 ? 'CONTINUE' : 'CONFIRM SEAT',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, color: colorScheme.onSurface.withOpacity(0.2), size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallCard(BuildContext context, CinemaHall hall) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedHallId == hall.id;
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedHallId = hall.id;
        _selectedScreenId =
            hall.screens.isNotEmpty ? hall.screens.first.id : null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeNetworkImage(
                imageUrl: hall.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hall.name, 
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(hall.location, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.8)))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
                                const SizedBox(width: 4),
                                Text(hall.rating,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    )),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenTile(BuildContext context, CinemaScreen screen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected = _selectedScreenId == screen.id;
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedScreenId = screen.id;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.1),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(screen.floor.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(screen.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isSelected ? colorScheme.primary : colorScheme.onSurface).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                screen.tag,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CinemaHall? _resolveSelectedHall(List<CinemaHall> halls) {
    if (halls.isEmpty) return null;
    final existing = halls.where((hall) => hall.id == _selectedHallId).toList();
    if (existing.isNotEmpty) return existing.first;
    final fallback = halls.first;
    _selectedHallId = fallback.id;
    _selectedScreenId =
        fallback.screens.isNotEmpty ? fallback.screens.first.id : null;
    return fallback;
  }

  CinemaScreen? _resolveSelectedScreen(List<CinemaScreen> screens) {
    if (screens.isEmpty) return null;
    final existing =
        screens.where((screen) => screen.id == _selectedScreenId).toList();
    if (existing.isNotEmpty) return existing.first;
    final fallback = screens.first;
    _selectedScreenId = fallback.id;
    return fallback;
  }

  bool _primaryEnabled(CinemaHall? hall, CinemaScreen? screen) {
    if (_step == 0) return hall != null;
    if (_step == 1) return hall != null && screen != null;
    return hall != null && screen != null;
  }

  String get _computedSeatLabel {
    final manual = _seatController.text.trim();
    if (manual.isNotEmpty) return manual;
    return '$_seatRow$_seatNumber';
  }

  Widget _buildStepperHeader({
    required BuildContext context,
    required int step,
    required String? hallName,
    required String? screenName,
    required String seat,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subtitle = step == 0
        ? 'Pick your cinema hall'
        : step == 1
            ? 'Pick your screen'
            : 'Select your seat number';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip(context, hallName ?? 'Hall', active: step >= 0),
              _buildSummaryChip(context, screenName ?? 'Screen', active: step >= 1),
              _buildSummaryChip(context, seat, active: step >= 2),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (step + 1) / 3,
                    minHeight: 8,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text('${step + 1}/3', 
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rows = List.generate(
        10, (idx) => String.fromCharCode('A'.codeUnitAt(0) + idx));
    final seatNumbers = List.generate(12, (idx) => idx + 1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Row',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _seatRow = row),
                      child: _buildSelectableChip(context, row, selected: _seatRow == row),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Seat Number',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final n in seatNumbers)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _seatNumber = n),
                      child: _buildSelectableChip(context, '$n', selected: _seatNumber == n),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(BuildContext context, String label, {required bool active}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? colorScheme.primary.withOpacity(0.1) : colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? colorScheme.primary.withOpacity(0.2) : colorScheme.outline.withOpacity(0.05)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: active ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSelectableChip(BuildContext context, String label, {required bool selected}) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
