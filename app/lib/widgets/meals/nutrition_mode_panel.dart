import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_data.dart';
import '../../providers/app_state.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../gradient_button.dart';
import '../premium_ui.dart';
import 'delivery_option_tile.dart';

class NutritionModePanel extends StatefulWidget {
  final UserData user;

  const NutritionModePanel({super.key, required this.user});

  @override
  State<NutritionModePanel> createState() => _NutritionModePanelState();
}

class _NutritionModePanelState extends State<NutritionModePanel> {
  bool _dineIn = false;
  bool _loading = false;
  bool _requestingLocation = false;
  String? _areaLabel;
  String? _error;
  String? _locationHint;

  @override
  void initState() {
    super.initState();
    _dineIn = widget.user.nutritionMode == 'eat_out';
    if (widget.user.weeklyPlan.deliveryOptions?.isNotEmpty == true) {
      _areaLabel = 'your area';
    }
  }

  Future<void> _persistMode(bool dineIn) async {
    final mode = dineIn ? 'eat_out' : 'home_delivery';
    if (widget.user.nutritionMode == mode) return;
    await context.read<AppState>().patchUser((u) => u.nutritionMode = mode);
  }

  Future<LocationResolveResult?> _resolveLocation() async {
    setState(() {
      _requestingLocation = true;
      _error = null;
    });
    final result = await LocationService.resolveLocation();
    if (!mounted) return null;
    setState(() {
      _requestingLocation = false;
      _locationHint = null;
      if (!result.ok) _error = result.message;
    });

    if (result.status == LocationAccessResult.deniedForever) {
      await LocationService.openAppSettings();
    } else if (result.status == LocationAccessResult.serviceDisabled) {
      await LocationService.openLocationSettings();
    }
    return result;
  }

  Future<void> _findOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loc = await _resolveLocation();
      if (loc == null || !loc.ok) return;

      await _persistMode(_dineIn);

      final state = context.read<AppState>();
      final result = await state
          .refreshDeliveryOptions(dineIn: _dineIn)
          .timeout(const Duration(seconds: 45));

      if (!mounted) return;
      setState(() {
        _areaLabel = result?.areaLabel ?? loc.location?.label ?? 'your area';
        if (result == null || result.options.isEmpty) {
          _error = result?.reply.replaceAll('**', '').replaceAll('📍 ', '') ??
              'No options found nearby.';
        } else {
          _error = null;
        }
      });

      if (result != null && result.options.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${result.options.length} ${_dineIn ? 'restaurants' : 'delivery'} options')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Search timed out. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onModeChanged(bool dineIn) {
    setState(() => _dineIn = dineIn);
    _persistMode(dineIn);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final options = context.watch<AppState>().user?.weeklyPlan.deliveryOptions ?? [];
    final showEnableLocation = _error != null && _areaLabel == null && _isLocationError(_error!);
    final showAllergyHint = _error != null && !_isLocationError(_error!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining_outlined, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Delivery & eat out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Find nearby takeaways or restaurants that fit your macros and allergies.',
            style: TextStyle(fontSize: 12, color: t.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeChip(
                  label: 'Deliver to me',
                  selected: !_dineIn,
                  onTap: () => _onModeChanged(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeChip(
                  label: 'Eat out',
                  selected: _dineIn,
                  onTap: () => _onModeChanged(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: t.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _areaLabel != null
                      ? 'Near $_areaLabel'
                      : _locationHint ?? 'Uses your GPS for nearby spots',
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 12, color: AppColors.ember, height: 1.4)),
          ],
          const SizedBox(height: 14),
          if (showEnableLocation) ...[
            GradientButton(
              label: _requestingLocation ? 'Requesting…' : 'Enable location',
              expanded: true,
              onPressed: (_requestingLocation || _loading)
                  ? null
                  : () async {
                      final result = await _resolveLocation();
                      if (result?.ok == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location ready — tap Find options')),
                        );
                      }
                    },
            ),
            const SizedBox(height: 8),
          ],
          if (showAllergyHint) ...[
            Text(
              'Adjust allergies in Profile → Nutrition if results look too strict.',
              style: TextStyle(fontSize: 11, color: t.textMuted, height: 1.35),
            ),
            const SizedBox(height: 8),
          ],
          GradientButton(
            label: _loading ? 'Searching…' : 'Find options',
            expanded: true,
            onPressed: (_loading || _requestingLocation) ? null : _findOptions,
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _dineIn ? 'Restaurants near you' : 'Delivery near you',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
            const SizedBox(height: 10),
            ...options.take(5).map((opt) => DeliveryOptionTile(option: opt)),
          ],
        ],
      ),
    );
  }

  static bool _isLocationError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('location') ||
        lower.contains('permission') ||
        lower.contains('gps') ||
        lower.contains('denied') ||
        lower.contains('settings');
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    return Material(
      color: selected ? AppColors.accent.withValues(alpha: 0.12) : t.elevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accent : t.borderSubtle),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.accent : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
