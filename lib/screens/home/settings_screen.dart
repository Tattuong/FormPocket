import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/navigation/app_navigator.dart';
import '../../providers/form_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/pocket_chrome.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final shop = context.watch<ShopProvider>();
    final forms = context.watch<FormProvider>();
    final scheme = Theme.of(context).colorScheme;
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        if (embedded)
          Text('Settings',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: scheme.onSurface)),
        if (embedded) const SizedBox(height: 16),
        Text('Privacy', style: AppTypography.title(context: context)),
        const SizedBox(height: 10),
        PocketSurface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Hide sensitive fields'),
                subtitle: const Text(
                    'Phone numbers and tax IDs stay masked until you reveal them.'),
                value: forms.hideSensitive,
                onChanged: forms.setHideSensitive,
              ),
              Divider(height: 1, color: scheme.outline.withValues(alpha: 0.4)),
              SwitchListTile(
                title: const Text('Lock app'),
                subtitle: Text(forms.lockEnabled
                    ? 'PIN is on'
                    : 'Ask for a PIN when you leave'),
                value: forms.lockEnabled,
                onChanged: (value) => _lock(context, value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(AppStrings.t(context, 'appearance'),
            style: AppTypography.title(context: context)),
        const SizedBox(height: 10),
        PocketSurface(
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(AppStrings.t(context, 'themeLight'))),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(AppStrings.t(context, 'themeDark'))),
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(AppStrings.t(context, 'themeSystem'))),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (v) => theme.setThemeMode(v.first),
          ),
        ),
        const SizedBox(height: 16),
        _SettingsTile(
          icon: Icons.replay_rounded,
          title: AppStrings.t(context, 'resetLook'),
          onTap: () async {
            await shop.resetLookToDefault();
            if (context.mounted) {
              AppToast.show(context,
                  title: AppStrings.t(context, 'defaultRestored'));
            }
          },
        ),
        _SettingsTile(
          icon: Icons.storefront_outlined,
          title: AppStrings.t(context, 'shop'),
          onTap: () => AppTabs.goShop(),
        ),
        if (!shop.isBillingDisabled)
          _SettingsTile(
            icon: Icons.restore_rounded,
            title: AppStrings.t(context, 'restorePurchases'),
            onTap: () {
              shop.restorePurchases();
              AppToast.show(context,
                  title: AppStrings.t(context, 'restoreStarted'));
            },
          ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: AppStrings.t(context, 'privacyPolicy'),
          onTap: () => Navigator.pushNamed(context, '/privacy'),
        ),
        const SizedBox(height: 16),
        Text(AppStrings.t(context, 'about'),
            style: AppTypography.title(context: context)),
        const SizedBox(height: 10),
        Text(AppStrings.t(context, 'aboutBody'),
            style: AppTypography.body(context: context)),
      ],
    );
    if (embedded) return list;
    return FtrScaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'settings'))),
      body: list,
    );
  }

  Future<void> _lock(BuildContext context, bool enable) async {
    final forms = context.read<FormProvider>();
    if (!enable) {
      await forms.clearLock();
      return;
    }
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _PinDialog(),
    );
    if (pin == null) return;
    await forms.setLock(pin);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: AppTypography.title(size: 16, context: context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set a PIN'),
      content: TextField(
        controller: _pin,
        autofocus: true,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        decoration: const InputDecoration(labelText: '4-digit PIN'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_pin.text.trim().length < 4) return;
            Navigator.pop(context, _pin.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
