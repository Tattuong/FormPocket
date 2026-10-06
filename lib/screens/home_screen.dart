import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/form/form_engine.dart';
import '../providers/form_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/coin_balance_chip.dart';
import '../widgets/pocket_chrome.dart';
import 'editor_screen.dart';
import 'home/settings_screen.dart';
import 'profile_screen.dart';
import 'template_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FtrScaffold(
      extendBody: false,
      body: SafeArea(
        child: Column(
          children: [
            if (_tab == 0) _BrandBar(onGear: () => setState(() => _tab = 2)),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _ProfilesPage(),
                  _TemplatesPage(),
                  SettingsScreen(embedded: true),
                ],
              ),
            ),
            _PocketNav(
              index: _tab,
              onSelect: (index) => setState(() => _tab = index),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  final VoidCallback onGear;

  const _BrandBar({required this.onGear});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 10, 0),
      child: Row(
        children: [
          Text('FormPocket',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.2,
                  color: scheme.onSurface)),
          const Spacer(),
          const CoinBalanceChip(variant: CoinChipVariant.header),
          IconButton(
            onPressed: onGear,
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
        ],
      ),
    );
  }
}

class _PocketNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _PocketNav({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profiles',
            selected: index == 0,
            color: scheme.primary,
            muted: scheme.onSurfaceVariant,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.description_outlined,
            selectedIcon: Icons.description,
            label: 'Templates',
            selected: index == 1,
            color: scheme.primary,
            muted: scheme.onSurfaceVariant,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            selected: index == 2,
            color: scheme.primary,
            muted: scheme.onSurfaceVariant,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final Color color;
  final Color muted;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.color,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? color : muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? selectedIcon : icon, color: ink, size: 24),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: ink, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 18 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilesPage extends StatelessWidget {
  const _ProfilesPage();

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text('Your details.\nReady.',
            style: TextStyle(
                fontSize: 36,
                height: 1.02,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
                color: scheme.onSurface)),
        const SizedBox(height: 12),
        Text(
          'Keep your information organized and ready when you need it.',
          style: TextStyle(
              color: scheme.onSurfaceVariant, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 20),
        if (forms.profiles.isEmpty)
          const _EmptyNote(
            icon: Icons.person_outline,
            title: 'No profiles yet',
            body: 'Add a personal, work, or family set.',
          ),
        for (var i = 0; i < forms.profiles.length; i++) ...[
          _ProfileCard(profile: forms.profiles[i], tinted: i == 0),
          const SizedBox(height: 12),
        ],
        _AddRow(label: 'New profile', onTap: () => _openEditor(context)),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final forms = context.read<FormProvider>();
    final shop = context.read<ShopProvider>();
    if (!forms.canAddProfile(shop.hasPro)) {
      _proSnack(context, 'Unlock FormPocket Pro to add more profiles.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditorScreen.profile()),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PocketProfile profile;
  final bool tinted;

  const _ProfileCard({required this.profile, required this.tinted});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = tinted
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10), scheme.surface)
        : scheme.surface;
    return PocketSurface(
      color: fill,
      shadow: !tinted,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(profileId: profile.id)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Row(
        children: [
          InitialBadge(initials: profile.initials, solid: profile.tone == 0),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 1),
                Text(profile.detail,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 6),
                const OnDeviceMark(),
              ],
            ),
          ),
          IconButton(
            onPressed: () => copyPocketText(
              context,
              FormEngine.joinValues(profile.fields.take(3)),
              title: profile.name,
            ),
            icon: Icon(Icons.copy_outlined,
                size: 20, color: scheme.onSurfaceVariant),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _TemplatesPage extends StatelessWidget {
  const _TemplatesPage();

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      children: [
        Text('Templates',
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: scheme.onSurface)),
        const SizedBox(height: 8),
        Text('Filled messages you can copy in one tap.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35)),
        const SizedBox(height: 18),
        if (forms.clips.isNotEmpty) ...[
          const Text('Use again',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          for (final clip in forms.clips) ...[
            PocketSurface(
              onTap: () =>
                  copyPocketText(context, clip.text, title: clip.title),
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clip.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          clip.text.replaceAll('\n', ' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => forms.forgetClip(clip.text),
                    icon: Icon(Icons.close,
                        size: 18, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
        ],
        if (forms.templates.isEmpty)
          const _EmptyNote(
            icon: Icons.description_outlined,
            title: 'No templates yet',
            body: 'Combine fields into a message you paste often.',
          ),
        for (final template in forms.templates) ...[
          PocketSurface(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TemplateScreen(templateId: template.id),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.description_outlined, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(template.blurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final profile = forms.profileById(template.profileId);
                    copyPocketText(
                      context,
                      FormEngine.joinValues(
                        FormEngine.included(profile, template.fieldIds),
                      ),
                      title: template.name,
                    );
                  },
                  icon: Icon(Icons.copy_outlined,
                      size: 20, color: scheme.onSurfaceVariant),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _AddRow(
          label: 'New template',
          onTap: forms.profiles.isEmpty ? null : () => _openEditor(context),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final forms = context.read<FormProvider>();
    final shop = context.read<ShopProvider>();
    if (!forms.canAddTemplate(shop.hasPro)) {
      _proSnack(context, 'Unlock FormPocket Pro to add more templates.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditorScreen.template()),
    );
  }
}

class _AddRow extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AddRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyNote(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PocketSurface(
        shadow: false,
        color: scheme.primary.withValues(alpha: 0.06),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(body,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _proSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
