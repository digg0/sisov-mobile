import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'location_service.dart';

class LocationCaptureField extends StatefulWidget {
  const LocationCaptureField({
    super.key,
    required this.onChanged,
    this.title = 'Localização em tempo real',
  });

  final ValueChanged<LocationSnapshot?> onChanged;
  final String title;

  @override
  State<LocationCaptureField> createState() => _LocationCaptureFieldState();
}

class _LocationCaptureFieldState extends State<LocationCaptureField> {
  LocationSnapshot? _snapshot;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await LocationService.instance.capture();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
      widget.onChanged(snapshot);
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _snapshot = null;
        _error = error.message;
      });
      widget.onChanged(null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _error == null ? AppColors.border : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          if (_loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _snapshot == null ? Icons.location_searching : Icons.gps_fixed,
              color: _error == null ? AppColors.primary : AppColors.danger,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  _loading
                      ? 'Obtendo posição atual...'
                      : _error ??
                            _snapshot?.label ??
                            'Localização ainda não capturada',
                  style: TextStyle(
                    fontSize: 12,
                    color: _error == null
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar localização',
            onPressed: _loading ? null : _capture,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
