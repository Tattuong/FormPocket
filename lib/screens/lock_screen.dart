import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/form_provider.dart';
import '../widgets/app_scaffold.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  var _pin = '';
  var _wrong = false;

  void _press(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _wrong = false;
    });
    if (_pin.length < 4) return;
    final forms = context.read<FormProvider>();
    if (forms.checkPin(_pin)) {
      forms.unlock();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _pin = '';
      _wrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FtrScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text('FormPocket',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: scheme.onSurface)),
            const SizedBox(height: 18),
            const Text('Enter your PIN',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 28,
              child: _wrong
                  ? Text('Wrong PIN', style: TextStyle(color: scheme.error))
                  : null,
            ),
            const Spacer(),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', 'del'],
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final key in row)
                      _Key(
                        label: key,
                        onTap: key.isEmpty
                            ? null
                            : () {
                                if (key == 'del') {
                                  if (_pin.isEmpty) return;
                                  setState(() => _pin =
                                      _pin.substring(0, _pin.length - 1));
                                  return;
                                }
                                _press(key);
                              },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: label.isEmpty ? Colors.transparent : scheme.surface,
      shape: const CircleBorder(),
      elevation: label.isEmpty ? 0 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 74,
          height: 74,
          child: Center(
            child: label == 'del'
                ? Icon(Icons.backspace_outlined, color: scheme.onSurface)
                : Text(label,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
