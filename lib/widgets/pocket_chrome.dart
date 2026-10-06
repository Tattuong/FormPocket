import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/form/form_engine.dart';
import '../providers/form_provider.dart';

class PocketChrome {
  PocketChrome._();

  static const green = Color(0xFF22C55E);
  static const radius = 22.0;

  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: const Color(0xFF142033).withValues(alpha: 0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

class PocketSurface extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;

  const PocketSurface({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(14),
    this.radius = PocketChrome.radius,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.surface;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadow ? PocketChrome.shadow : null,
      ),
      child: Material(
        color: fill,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

class PocketButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const PocketButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        style: FilledButton.styleFrom(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class InitialBadge extends StatelessWidget {
  final String initials;
  final bool solid;
  final double size;

  const InitialBadge({
    super.key,
    required this.initials,
    required this.solid,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: solid ? scheme.primary : scheme.primary.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: solid ? scheme.onPrimary : scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class OnDeviceMark extends StatelessWidget {
  const OnDeviceMark({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: PocketChrome.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text('On this device', style: TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}

Future<void> copyPocketText(
  BuildContext context,
  String text, {
  String title = 'Copied',
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: trimmed));
  await HapticFeedback.lightImpact();
  if (!context.mounted) return;
  await context.read<FormProvider>().rememberClip(title, trimmed);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final ink = Theme.of(context).colorScheme.onInverseSurface;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1400),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(Icons.check_rounded, color: ink, size: 18),
          const SizedBox(width: 8),
          const Text('Copied'),
        ],
      ),
    ),
  );
}

class ReuseBar extends StatefulWidget {
  final List<PocketField> fields;
  final String title;
  final String action;
  final String caption;
  final VoidCallback? onSave;

  const ReuseBar({
    super.key,
    required this.fields,
    required this.title,
    required this.action,
    required this.caption,
    this.onSave,
  });

  @override
  State<ReuseBar> createState() => _ReuseBarState();
}

class _ReuseBarState extends State<ReuseBar> {
  var _shape = CopyShape.plain;

  String get _text => FormEngine.format(widget.fields, _shape);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = _text.isNotEmpty;
    return Column(
      children: [
        Row(
          children: [
            for (final shape in CopyShape.values) ...[
              if (shape != CopyShape.plain) const SizedBox(width: 8),
              Expanded(
                child: _ShapeChip(
                  label: switch (shape) {
                    CopyShape.plain => 'Values',
                    CopyShape.labels => 'Labels',
                    CopyShape.line => 'One line',
                  },
                  selected: _shape == shape,
                  onTap: () => setState(() => _shape = shape),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        PocketButton(
          label: widget.action,
          icon: Icons.copy_rounded,
          onPressed: ready
              ? () => copyPocketText(context, _text, title: widget.title)
              : null,
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: ready
                  ? () => Share.share(_text, subject: widget.title)
                  : null,
              icon: const Icon(Icons.ios_share, size: 18),
              label: const Text('Share'),
            ),
            if (widget.onSave != null)
              TextButton.icon(
                onPressed: ready ? widget.onSave : null,
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                label: const Text('Save template'),
              ),
          ],
        ),
        Text(widget.caption,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }
}

class _ShapeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ShapeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration pocketField(BuildContext context, String label,
    {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
