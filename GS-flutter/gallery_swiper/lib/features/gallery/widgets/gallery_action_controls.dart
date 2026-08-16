import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GalleryActionControls extends StatelessWidget {
  const GalleryActionControls({
    required this.canDecide,
    required this.canUndo,
    required this.deleteCount,
    required this.onUndo,
    required this.onUndoAll,
    required this.onDeleteDecision,
    required this.onKeepDecision,
    required this.onDeleteMarked,
    super.key,
  });

  final bool canDecide;
  final bool canUndo;
  final int deleteCount;
  final VoidCallback onUndo;
  final VoidCallback onUndoAll;
  final VoidCallback onDeleteDecision;
  final VoidCallback onKeepDecision;
  final VoidCallback onDeleteMarked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundAction(
              icon: Icons.undo_rounded,
              label: 'Undo',
              color: const Color(0xFF9AA1B3),
              onPressed: canUndo ? onUndo : null,
              small: true,
            ),
            const SizedBox(width: 12),
            _RoundAction(
              icon: Icons.settings_backup_restore_rounded,
              label: 'Undo all',
              color: const Color(0xFF9AA1B3),
              onPressed: canUndo ? onUndoAll : null,
              small: true,
            ),
            const SizedBox(width: 12),
            _RoundAction(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: AppColors.delete,
              onPressed: canDecide ? onDeleteDecision : null,
            ),
            const SizedBox(width: 12),
            _RoundAction(
              icon: Icons.favorite_rounded,
              label: 'Keep',
              color: AppColors.keep,
              onPressed: canDecide ? onKeepDecision : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
            key: ValueKey(deleteCount > 0),
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: deleteCount == 0 ? null : onDeleteMarked,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE54855),
                disabledBackgroundColor: const Color(0xFF181C25),
                disabledForegroundColor: const Color(0xFF626878),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              label: Text(
                deleteCount == 0
                    ? 'No photos marked for deletion'
                    : 'Delete $deleteCount marked photo${deleteCount == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: small ? 48 : 58,
          child: IconButton.filled(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: color.withValues(alpha: .14),
              foregroundColor: color,
              disabledBackgroundColor: Colors.white.withValues(alpha: .04),
              side: BorderSide(color: color.withValues(alpha: .25)),
            ),
            icon: Icon(icon, size: small ? 22 : 27),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: onPressed == null ? Colors.white24 : AppColors.textSoft,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
