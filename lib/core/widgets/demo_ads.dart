import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme/brain_theme.dart';
import 'common.dart';

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        border: Border.all(color: context.brain.outline, width: 3),
        borderRadius: BorderRadius.circular(14),
        color: context.brain.hud,
        boxShadow: [
          BoxShadow(color: context.brain.shadow, offset: const Offset(0, 3)),
        ],
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
    icon: const Icon(Icons.campaign_rounded, size: 44),
    title: const Center(child: TitlePlaque('Demo ad')),
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
      ArcadeButton(
        onPressed: seconds <= 0 ? () => Navigator.pop(context, true) : null,
        label: seconds <= 0 ? 'CONTINUE' : 'CONTINUE IN $seconds',
      ),
    ],
  );
}
