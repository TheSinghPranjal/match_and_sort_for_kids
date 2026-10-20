import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/clay.dart';

/// Grown-ups only: a randomised multiplication question answered on a
/// number pad. Returns true when answered correctly.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _ParentGateDialog(),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _rnd = Random();
  late int _a, _b;
  String _entry = '';
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 3 + _rnd.nextInt(7);
    _b = 4 + _rnd.nextInt(6);
    _entry = '';
  }

  void _key(String k) {
    setState(() {
      _wrong = false;
      if (k == '⌫') {
        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
      } else if (_entry.length < 3) {
        _entry += k;
      }
    });
  }

  void _submit() {
    if (int.tryParse(_entry) == _a * _b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _wrong = true;
        _newQuestion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: ClayContainer(
          color: AppColors.cream,
          radius: 36,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Grown-ups only', style: AppText.display(26)),
              const SizedBox(height: 4),
              Text(
                'Please answer to continue',
                style: AppText.body(15, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              Text(
                '$_a × $_b = ?',
                style: AppText.display(36, color: AppColors.lavenderDeep),
              ),
              const SizedBox(height: 10),
              Container(
                width: 160,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _wrong ? AppColors.coral : AppColors.lavender,
                    width: 3,
                  ),
                ),
                child: Text(
                  _entry.isEmpty ? ' ' : _entry,
                  style: AppText.display(30),
                ),
              ),
              if (_wrong)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Try this one instead',
                    style: AppText.body(14, color: AppColors.inkSoft),
                  ),
                ),
              const SizedBox(height: 14),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['⌫', '0', '✓'],
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final k in row)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Squishy(
                            semanticLabel: k == '⌫'
                                ? 'Delete'
                                : (k == '✓' ? 'Submit' : k),
                            onTap: () => k == '✓' ? _submit() : _key(k),
                            child: ClayContainer(
                              color: k == '✓' ? AppColors.mint : Colors.white,
                              radius: 20,
                              width: 64,
                              height: 56,
                              depth: 0.7,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(k, style: AppText.title(24)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: AppText.title(18, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
