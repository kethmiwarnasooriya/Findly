import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/findly_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/item_category.dart';
import '../../models/item_report.dart';
import '../../models/report_draft.dart';
import '../../models/report_photo.dart';
import '../../models/report_type.dart';
import '../../state/reports_controller.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/feedback.dart';
import '../../widgets/report_badges.dart';
import '../../widgets/state_views.dart';
import 'photo_field.dart';

/// Creates a new report, or edits [existing] when given.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing, this.initialType});

  final ItemReport? existing;
  final ReportType? initialType;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late ReportType _type;
  ItemCategory? _category;
  DateTime? _eventDate;
  PhotoChange _photoChange = const KeepPhoto();
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title);
    _description = TextEditingController(text: existing?.description);
    _location = TextEditingController(text: existing?.location);
    _type = existing?.type ?? widget.initialType ?? ReportType.lost;
    _category = existing?.category;
    _eventDate = existing?.eventDate ?? dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = ReportDraft(
      type: _type,
      title: _title.text,
      description: _description.text,
      category: _category!,
      location: _location.text,
      eventDate: _eventDate!,
    );
    if (!draft.isValid()) return;

    setState(() => _saving = true);
    final controller = context.read<ReportsController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final existing = widget.existing;
      if (existing == null) {
        final photoChange = _photoChange;
        await controller.createReport(
          draft,
          photo: photoChange is ReplacePhoto ? photoChange.photo : null,
        );
      } else {
        await controller.updateReport(
          existing,
          draft,
          photoChange: _photoChange,
        );
      }
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Report updated' : 'Report posted. Thank you!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showError(context, error, onRetry: _submit);
    }
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: field.value ?? today,
      firstDate: ReportLimits.earliestEventDate,
      lastDate: today,
      helpText: _type == ReportType.lost
          ? 'When did you lose it?'
          : 'When did you find it?',
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
      field.didChange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLost = _type == ReportType.lost;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit report' : 'Report an item'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    for (final type in ReportType.values) ...[
                      if (type != ReportType.values.first)
                        const SizedBox(width: 12),
                      Expanded(
                        child: _TypeCard(
                          type: type,
                          selected: _type == type,
                          enabled: !_isEditing && !_saving,
                          onTap: () => setState(() => _type = type),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'The report type cannot be changed after posting.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  enabled: !_saving,
                  maxLength: ReportLimits.titleMax,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'What is it?',
                    hintText: isLost
                        ? 'e.g. Black laptop bag'
                        : 'e.g. Blue water bottle',
                  ),
                  validator: ReportDraft.validateTitle,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ItemCategory>(
                  initialValue: _category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in ItemCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 20),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                category.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) =>
                      value == null ? 'Choose a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: ReportLimits.descriptionMax,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Colour, brand, distinctive marks, what was inside…',
                    alignLabelWithHint: true,
                  ),
                  validator: ReportDraft.validateDescription,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _location,
                  enabled: !_saving,
                  maxLength: ReportLimits.locationMax,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: isLost
                        ? 'Where did you lose it?'
                        : 'Where did you find it?',
                    hintText: 'e.g. Main library, 2nd floor',
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                  validator: ReportDraft.validateLocation,
                ),
                const SizedBox(height: 8),
                FormField<DateTime>(
                  initialValue: _eventDate,
                  validator: (value) => ReportDraft.validateEventDate(value),
                  builder: (field) => InkWell(
                    onTap: _saving ? null : () => _pickDate(field),
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isLost ? 'Date lost' : 'Date found',
                        prefixIcon: const Icon(Icons.event_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        field.value == null
                            ? 'Choose a date'
                            : formatDisplayDate(field.value!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PhotoField(
                  existing: widget.existing,
                  change: _photoChange,
                  onChanged: (change) => setState(() => _photoChange = change),
                ),
                const SizedBox(height: 20),
                const _PrivacyNote(),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Post report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return NoticeCard(
      icon: Icons.shield_outlined,
      tone: context.findly.found,
      message:
          'Your report is visible to everyone signed in to Findly. '
          "Don't include phone numbers, emails, ID numbers or other "
          'personal details in the text or the photo.',
    );
  }
}

/// Large selectable card for choosing "I lost" / "I found".
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ReportType type;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = context.findly.forType(type);
    final label = type == ReportType.lost
        ? 'I lost something'
        : 'I found something';

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius + 2),
            border: Border.all(
              color: selected ? tone.foreground : Colors.transparent,
              width: 2,
            ),
          ),
          child: AppCard(
            onTap: enabled ? onTap : null,
            color: selected ? tone.background : null,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: reportTypeIcon(type),
                  background: selected ? tone.foreground : tone.background,
                  foreground: selected ? tone.background : tone.foreground,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? tone.foreground : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
