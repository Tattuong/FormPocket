import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/form/form_engine.dart';
import '../providers/form_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pocket_chrome.dart';

class EditorScreen extends StatefulWidget {
  final bool template;

  const EditorScreen.profile({super.key}) : template = false;
  const EditorScreen.template({super.key}) : template = true;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _name = TextEditingController();
  final _detail = TextEditingController();
  final _initials = TextEditingController();
  final _label = TextEditingController();
  final _value = TextEditingController();
  final List<PocketField> _fields = [];
  String? _profileId;
  final Set<String> _included = {};
  var _sensitive = false;
  var _primed = false;

  void _onType() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _detail, _initials, _label, _value]) {
      controller.addListener(_onType);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.template || _primed) return;
    final forms = context.read<FormProvider>();
    if (forms.profiles.isEmpty) return;
    _primed = true;
    _profileId = forms.profiles.first.id;
    _included.addAll(forms.profiles.first.fields.map((field) => field.id));
  }

  @override
  void dispose() {
    for (final controller in [_name, _detail, _initials, _label, _value]) {
      controller.removeListener(_onType);
    }
    _name.dispose();
    _detail.dispose();
    _initials.dispose();
    _label.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_name.text.trim().isEmpty) return false;
    if (widget.template) return _profileId != null && _included.isNotEmpty;
    return _fields.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final profile = _profileId == null ? null : forms.profileById(_profileId!);
    final scheme = Theme.of(context).colorScheme;
    return FtrScaffold(
      appBar: AppBar(
        title: Text(widget.template ? 'New template' : 'New profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: pocketField(
              context,
              widget.template ? 'Template name' : 'Profile name',
              hint: widget.template ? 'Shipping details' : 'Personal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detail,
            decoration: pocketField(
              context,
              widget.template ? 'Description' : 'Short detail',
              hint: widget.template ? 'Ready to paste' : 'Everyday details',
            ),
          ),
          if (!widget.template) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _initials,
              textCapitalization: TextCapitalization.characters,
              maxLength: 2,
              decoration: pocketField(context, 'Initials', hint: 'AM'),
            ),
            const SizedBox(height: 8),
            const Text('Fields', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            PocketSurface(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Column(
                children: [
                  TextField(
                    controller: _label,
                    decoration: pocketField(context, 'Label', hint: 'Tax ID'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _value,
                    minLines: 1,
                    maxLines: 3,
                    decoration: pocketField(context, 'Value'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sensitive'),
                    value: _sensitive,
                    onChanged: (value) => setState(() => _sensitive = value),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _label.text.trim().isEmpty ? null : _addDraft,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add field'),
                    ),
                  ),
                ],
              ),
            ),
            if (_fields.isNotEmpty) ...[
              const SizedBox(height: 12),
              PocketSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < _fields.length; i++)
                      ListTile(
                        title: Text(_fields[i].label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(_fields[i].sensitive
                            ? '${_fields[i].value} · sensitive'
                            : _fields[i].value),
                        trailing: IconButton(
                          onPressed: () => setState(() => _fields.removeAt(i)),
                          icon:
                              Icon(Icons.close, color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in forms.profiles)
                  ChoiceChip(
                    label: Text(item.name),
                    selected: _profileId == item.id,
                    onSelected: (_) => setState(() {
                      if (_profileId == item.id) return;
                      _profileId = item.id;
                      _included
                        ..clear()
                        ..addAll(item.fields.map((field) => field.id));
                    }),
                  ),
              ],
            ),
            if (profile != null) ...[
              const SizedBox(height: 12),
              PocketSurface(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final field in profile.fields)
                      CheckboxListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        value: _included.contains(field.id),
                        title: Text(field.label),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) => setState(() {
                          if (value ?? false) {
                            _included.add(field.id);
                          } else {
                            _included.remove(field.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          PocketButton(
            label: 'Save',
            icon: Icons.check_rounded,
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }

  void _addDraft() {
    setState(() {
      _fields.add(PocketField(
        id: 'field-${_fields.length}-${DateTime.now().microsecondsSinceEpoch}',
        label: _label.text.trim(),
        value: _value.text.trim(),
        sensitive: _sensitive,
      ));
      _label.clear();
      _value.clear();
      _sensitive = false;
    });
  }

  Future<void> _save() async {
    final forms = context.read<FormProvider>();
    final shop = context.read<ShopProvider>();
    if (widget.template) {
      final created = await forms.createTemplate(
        name: _name.text,
        blurb: _detail.text,
        profileId: _profileId!,
        fieldIds: _included.toList(),
        hasPro: shop.hasPro,
      );
      if (!mounted) return;
      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unlock FormPocket Pro to add more templates.')));
        return;
      }
      Navigator.pop(context);
      return;
    }
    final created = await forms.createProfile(
      name: _name.text,
      detail: _detail.text,
      initials: _initials.text,
      fields: List<PocketField>.from(_fields),
      hasPro: shop.hasPro,
    );
    if (!mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unlock FormPocket Pro to add more profiles.')));
      return;
    }
    Navigator.pop(context);
  }
}
