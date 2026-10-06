import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/form/form_engine.dart';
import '../providers/form_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/pocket_chrome.dart';

class TemplateScreen extends StatelessWidget {
  final String templateId;

  const TemplateScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final template = forms.templateById(templateId);
    if (template == null) {
      return const FtrScaffold(
          body: Center(child: Text('This template is gone.')));
    }
    final profile = forms.profileById(template.profileId);
    final included = FormEngine.included(profile, template.fieldIds);
    final preview = FormEngine.joinValues(included);
    final display = included
        .map((field) =>
            FormEngine.shown(field, hidden: forms.hidden(field)).trim())
        .where((value) => value.isNotEmpty)
        .join('\n');
    final scheme = Theme.of(context).colorScheme;
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
                      const Expanded(
                        child: Text('Templates',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'duplicate') {
                            _duplicate(context, template);
                          } else {
                            _delete(context, template);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                              value: 'duplicate', child: Text('Duplicate')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete template')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.description_outlined,
                          color: scheme.primary, size: 26),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(template.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: scheme.primary)),
                  const SizedBox(height: 6),
                  Text(template.blurb,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, height: 1.4)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Use profile',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _changeProfile(context, template),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  if (profile == null)
                    PocketSurface(
                      shadow: false,
                      color: scheme.primary.withValues(alpha: 0.08),
                      onTap: () => _changeProfile(context, template),
                      child: const Text('Choose a profile'),
                    )
                  else
                    PocketSurface(
                      shadow: false,
                      color: scheme.primary.withValues(alpha: 0.08),
                      onTap: () => _changeProfile(context, template),
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        children: [
                          InitialBadge(
                            initials: profile.initials,
                            solid: profile.tone == 0,
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                Text(profile.detail,
                                    style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.expand_more,
                              color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Includes',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('Choose fields',
                          style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (profile != null)
                    PocketSurface(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < profile.fields.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: scheme.outline.withValues(alpha: 0.4),
                              ),
                            _CheckRow(
                              label: profile.fields[i].label,
                              checked: template.fieldIds
                                  .contains(profile.fields[i].id),
                              onTap: () {
                                final ids = [...template.fieldIds];
                                final id = profile.fields[i].id;
                                if (!ids.remove(id)) ids.add(id);
                                forms.updateTemplate(
                                    template.copyWith(fieldIds: ids));
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('Preview',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text(
                        template.id == 'shipping'
                            ? 'Formatted for shipping'
                            : 'Ready to paste',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PocketSurface(
                    shadow: false,
                    color: scheme.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            display.isEmpty
                                ? 'Choose fields to preview.'
                                : display,
                            style: const TextStyle(
                                height: 1.45, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: preview.isEmpty
                              ? null
                              : () => copyPocketText(context, preview,
                                  title: template.name),
                          icon: Icon(Icons.copy_outlined,
                              size: 20, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: ReuseBar(
                fields: included,
                title: template.name,
                action: 'Copy message',
                caption: 'Paste it into a form, email, or chat.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicate(BuildContext context, PocketTemplate template) async {
    final forms = context.read<FormProvider>();
    final created = await forms.duplicateTemplate(
      template.id,
      hasPro: context.read<ShopProvider>().hasPro,
    );
    if (!context.mounted) return;
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unlock FormPocket Pro to add more templates.')));
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TemplateScreen(templateId: created.id)),
    );
  }

  Future<void> _delete(BuildContext context, PocketTemplate template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${template.name}?'),
        content: const Text('The profile behind it stays.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<FormProvider>().deleteTemplate(template.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _changeProfile(
      BuildContext context, PocketTemplate template) async {
    final forms = context.read<FormProvider>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Use profile',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final profile in forms.profiles)
              ListTile(
                leading: InitialBadge(
                  initials: profile.initials,
                  solid: profile.tone == 0,
                  size: 40,
                ),
                title: Text(profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(profile.detail),
                trailing: template.profileId == profile.id
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, profile.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == template.profileId) return;
    final profile = forms.profileById(picked);
    await forms.updateTemplate(template.copyWith(
      profileId: picked,
      fieldIds: [
        for (final field in profile?.fields ?? const <PocketField>[]) field.id,
      ],
    ));
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: checked ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? scheme.primary
                      : scheme.outline.withValues(alpha: 0.8),
                  width: 1.6,
                ),
              ),
              child: checked
                  ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
