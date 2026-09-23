import 'dart:async';
import 'package:flutter/material.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .35),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 18),
          SizedBox(width: 8),
          Text(
            'DEMO AD · No tracking',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showRewardedDemo(
  BuildContext context, {
  required String reward,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _DemoAdDialog(reward: reward),
  );
  return result ?? false;
}

Future<void> showInterstitialDemo(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => const _DemoAdDialog(),
);

class _DemoAdDialog extends StatefulWidget {
  const _DemoAdDialog({this.reward});
  final String? reward;
  @override
  State<_DemoAdDialog> createState() => _DemoAdDialogState();
}

class _DemoAdDialogState extends State<_DemoAdDialog> {
  int seconds = 3;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.science, size: 44),
    title: const Text('Demo Ad'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'This is a local simulation. No network, advertiser, or tracking SDK is used.',
          textAlign: TextAlign.center,
        ),
        if (widget.reward != null) ...[
          const SizedBox(height: 16),
          Text(
            'Reward: ${widget.reward}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ],
    ),
    actions: [
      FilledButton(
        onPressed: seconds <= 0 ? () => Navigator.pop(context, true) : null,
        child: Text(seconds <= 0 ? 'Continue' : 'Continue in $seconds'),
      ),
    ],
  );
}
