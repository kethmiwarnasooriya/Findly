import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item_report.dart';
import '../../models/report_photo.dart';
import '../../widgets/feedback.dart';
import '../../widgets/report_photo.dart';

/// Lets the user add, preview, replace or remove one photo.
///
/// Uses the system photo picker, which needs no storage permission on
/// current Android versions. Images are downscaled before upload.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.change,
    required this.onChanged,
    this.existing,
  });

  /// The report being edited, if any, to show its current photo.
  final ItemReport? existing;
  final PhotoChange change;
  final ValueChanged<PhotoChange> onChanged;

  bool get _showsExisting =>
      change is KeepPhoto && (existing?.hasPhoto ?? false);

  Future<void> _pick(BuildContext context) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final photo = PickedPhoto.fromBytes(await file.readAsBytes());
      onChanged(ReplacePhoto(photo));
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }

  void _remove() {
    onChanged(
      existing?.hasPhoto ?? false ? const RemovePhoto() : const KeepPhoto(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget? preview = switch (change) {
      ReplacePhoto(:final photo) => Image.memory(
        photo.bytes,
        fit: BoxFit.cover,
        semanticLabel: 'Selected photo',
      ),
      _ when _showsExisting => ReportPhoto(report: existing!, borderRadius: 0),
      _ => null,
    };

    if (preview == null) {
      return OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add a photo (optional)'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            preview,
            Positioned(
              right: 8,
              top: 8,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Choose a different photo',
                    onPressed: () => _pick(context),
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Remove photo',
                    onPressed: _remove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
            if (change is ReplacePhoto)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Uploads when you save',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
