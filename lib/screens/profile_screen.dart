import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/form/form_engine.dart';
import '../providers/form_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pocket_chrome.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Set<String> _selected = {};
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final profile = context.read<FormProvider>().profileById(widget.profileId);
    if (profile == null) return;
    _ready = true;
    _selected.addAll(profile.fields.take(3).map((field) => field.id));
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final profile = forms.profileById(widget.profileId);
    if (profile == null) {
      return const FtrScaffold(
          body: Center(child: Text('This profile is gone.')));
    }
    final scheme = Theme.of(context).colorScheme;
    final chosen = [
      for (final field in profile.fields)
        if (_selected.contains(field.id)) field,
    ];
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) => _menu(context, value, profile),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'field', child: Text('Add field')),
                          PopupMenuItem(value: 'rename', child: Text('Rename')),
                          PopupMenuItem(
                              value: 'duplicate', child: Text('Duplicate')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete profile')),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InitialBadge(
                        initials: profile.initials,
                        solid: profile.tone == 0,
                        size: 64,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6)),
                            const SizedBox(height: 2),
                            Text(profile.detail,
                                style:
                                    TextStyle(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            const OnDeviceMark(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (profile.fields.isEmpty)
                    Text('Add a field to start copying.',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  if (profile.fields.isNotEmpty)
                    PocketSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < profile.fields.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                color: scheme.outline.withValues(alpha: 0.45),
                              ),
                            _FieldRow(
                              field: profile.fields[i],
                              selected:
                                  _selected.contains(profile.fields[i].id),
                              hidden: forms.hidden(profile.fields[i]),
                              onSelect: () => setState(() {
                                final id = profile.fields[i].id;
                                if (!_selected.add(id)) {
                                  _selected.remove(id);
                                }
                              }),
                              onCopy: () => copyPocketText(
                                context,
                                profile.fields[i].value,
                                title: profile.fields[i].label,
                              ),
                              onReveal: profile.fields[i].sensitive
                                  ? () =>
                                      forms.toggleReveal(profile.fields[i].id)
                                  : null,
                              onEdit: () => _editField(
                                  context, profile, profile.fields[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text('Hold a field to edit or remove it.',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: profile.fields.isEmpty
                          ? null
                          : () => setState(() {
                                if (_selected.length == profile.fields.length) {
                                  _selected.clear();
                                } else {
                                  _selected
                                    ..clear()
                                    ..addAll(profile.fields
                                        .map((field) => field.id));
                                }
                              }),
                      child: Text(_selected.length == profile.fields.length
                          ? 'Clear'
                          : 'Select all'),
                    ),
                  ),
                  ReuseBar(
                    fields: chosen,
                    title: profile.name,
                    action: 'Copy selected (${chosen.length})',
                    caption: 'Choose the fields you want to copy.',
                    onSave: chosen.isEmpty
                        ? null
                        : () => _saveTemplate(context, profile, chosen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTemplate(BuildContext context, PocketProfile profile,
      List<PocketField> fields) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(initial: '${profile.name} message'),
    );
    if (name == null || !context.mounted) return;
    final forms = context.read<FormProvider>();
    final created = await forms.createTemplate(
      name: name,
      blurb: 'Saved from ${profile.name}.',
      profileId: profile.id,
      fieldIds: [for (final field in fields) field.id],
      hasPro: context.read<ShopProvider>().hasPro,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(created == null
          ? 'Unlock FormPocket Pro to add more templates.'
          : 'Saved as a template.'),
    ));
  }

  Future<void> _menu(
      BuildContext context, String value, PocketProfile profile) async {
    final forms = context.read<FormProvider>();
    if (value == 'delete') {
      final ok = await _confirm(
        context,
        title: 'Delete ${profile.name}?',
        body: 'Templates that use this profile are removed too.',
        action: 'Delete',
      );
      if (!ok || !context.mounted) return;
      await forms.deleteProfile(profile.id);
      if (context.mounted) Navigator.pop(context);
      return;
    }
    if (value == 'duplicate') {
      final created = await forms.duplicateProfile(
        profile.id,
        hasPro: context.read<ShopProvider>().hasPro,
      );
      if (!context.mounted) return;
      if (created == null) {
        _pro(context, 'Unlock FormPocket Pro to add more profiles.');
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProfileScreen(profileId: created.id)),
      );
      return;
    }
    if (value == 'rename') {
      final next = await showDialog<PocketProfile>(
        context: context,
        builder: (context) => _RenameDialog(profile: profile),
      );
      if (next == null) return;
      await forms.updateProfile(next);
      return;
    }
    final result = await showModalBottomSheet<_FieldResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _FieldSheet(),
    );
    final field = result?.field;
    if (field == null) return;
    await forms.addField(profile.id, field);
    if (mounted) setState(() => _selected.add(field.id));
  }

  Future<void> _editField(
      BuildContext context, PocketProfile profile, PocketField field) async {
    final forms = context.read<FormProvider>();
    final result = await showModalBottomSheet<_FieldResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _FieldSheet(existing: field),
    );
    if (result == null) return;
    if (result.deleted) {
      _selected.remove(field.id);
      await forms.deleteField(profile.id, field.id);
      return;
    }
    if (result.field != null) {
      await forms.updateField(profile.id, result.field!);
    }
  }
}

class _FieldRow extends StatelessWidget {
  final PocketField field;
  final bool selected;
  final bool hidden;
  final VoidCallback onSelect;
  final VoidCallback onCopy;
  final VoidCallback? onReveal;
  final VoidCallback onEdit;

  const _FieldRow({
    required this.field,
    required this.selected,
    required this.hidden,
    required this.onSelect,
    required this.onCopy,
    required this.onReveal,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = FormEngine.shown(field, hidden: hidden);
    return Material(
      color: selected ? scheme.primary.withValues(alpha: 0.06) : scheme.surface,
      child: InkWell(
        onTap: onSelect,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.label,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 3),
                    Text(shown,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1.3)),
                  ],
                ),
              ),
              if (field.sensitive)
                IconButton(
                  onPressed: onReveal,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              IconButton(
                onPressed: onCopy,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.copy_outlined,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldResult {
  final PocketField? field;
  final bool deleted;

  const _FieldResult.save(this.field) : deleted = false;
  const _FieldResult.delete()
      : field = null,
        deleted = true;
}

class _FieldSheet extends StatefulWidget {
  final PocketField? existing;

  const _FieldSheet({this.existing});

  @override
  State<_FieldSheet> createState() => _FieldSheetState();
}

class _FieldSheetState extends State<_FieldSheet> {
  late final TextEditingController _label;
  late final TextEditingController _value;
  late var _sensitive = widget.existing?.sensitive ?? false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.existing?.label ?? '');
    _value = TextEditingController(text: widget.existing?.value ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(editing ? 'Edit field' : 'Add field',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: pocketField(context, 'Label'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _value,
            minLines: 1,
            maxLines: 4,
            decoration: pocketField(context, 'Value'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sensitive'),
            subtitle: const Text('Masked until you reveal it'),
            value: _sensitive,
            onChanged: (value) => setState(() => _sensitive = value),
          ),
          const SizedBox(height: 8),
          PocketButton(
            label: editing ? 'Save field' : 'Add field',
            icon: Icons.check_rounded,
            onPressed: () {
              if (_label.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                _FieldResult.save(
                  PocketField(
                    id: widget.existing?.id ??
                        'field-${DateTime.now().microsecondsSinceEpoch}',
                    label: _label.text.trim(),
                    value: _value.text.trim(),
                    sensitive: _sensitive,
                  ),
                ),
              );
            },
          ),
          if (editing)
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const _FieldResult.delete()),
              child: const Text('Delete field'),
            ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  final PocketProfile profile;

  const _RenameDialog({required this.profile});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _detail = TextEditingController(text: widget.profile.detail);
  late final _initials = TextEditingController(text: widget.profile.initials);

  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    _initials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: pocketField(context, 'Name')),
          const SizedBox(height: 10),
          TextField(
              controller: _detail, decoration: pocketField(context, 'Detail')),
          const SizedBox(height: 10),
          TextField(
            controller: _initials,
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            decoration: pocketField(context, 'Initials'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            final raw = _initials.text.trim().toUpperCase();
            final initials = raw.isEmpty
                ? widget.profile.initials
                : (raw.length <= 2 ? raw : raw.substring(0, 2));
            Navigator.pop(
              context,
              widget.profile.copyWith(
                name: _name.text.trim(),
                detail: _detail.text.trim(),
                initials: initials,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

void _pro(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _NameDialog extends StatefulWidget {
  final String initial;

  const _NameDialog({required this.initial});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save template'),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: pocketField(context, 'Template name'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(context, _name.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
