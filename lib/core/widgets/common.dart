import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/brain_theme.dart';
import '../config/app_config.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.tonal = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool tonal;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool hovered = false;
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.brain;
    final base =
        widget.color ?? (widget.tonal ? palette.surfaceHigh : palette.surface);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: widget.onTap != null,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => focused = value),
        onShowHoverHighlight: (value) => setState(() => hovered = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          duration: still ? Duration.zero : const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Color.lerp(base, palette.primary, hovered ? .035 : 0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: focused
                  ? palette.focus
                  : widget.tonal
                  ? Colors.transparent
                  : palette.outline.withValues(alpha: .38),
              width: focused ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              canRequestFocus: false,
              onTap: widget.onTap,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = color == null
        ? null
        : FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: context.onColor(color!),
          );
    final button = icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class PageEyebrow extends StatelessWidget {
  const PageEyebrow(this.title, {super.key, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    title,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: color ?? context.brain.primary,
      fontWeight: FontWeight.w800,
      letterSpacing: .2,
    ),
  );
}

class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.trailing,
  });

  final String label;
  final double value;
  final Color? color;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppText.percentSemantics(label, (value.clamp(0, 1) * 100).round()),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: TextStyle(color: context.brain.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value.clamp(0, 1),
          color: color ?? context.brain.primary,
        ),
      ],
    ),
  );
}

class SessionHud extends StatelessWidget {
  const SessionHud({
    super.key,
    required this.label,
    required this.progress,
    required this.primaryStat,
    required this.secondaryStat,
    required this.color,
    this.answerCorrect,
  });

  final String label;
  final double progress;
  final String primaryStat;
  final String secondaryStat;
  final Color color;
  final bool? answerCorrect;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${AppText.percentSemantics(label, (progress.clamp(0, 1) * 100).round())}, $primaryStat, $secondaryStat',
    child: Column(
      children: [
        Row(
          children: [
            if (answerCorrect != null) ...[
              Semantics(
                liveRegion: true,
                label: answerCorrect!
                    ? AppText.gameplay.correct
                    : AppText.gameplay.tryNext,
                child: Icon(
                  answerCorrect!
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  color: answerCorrect!
                      ? context.brain.success
                      : context.brain.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.brain.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              primaryStat,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 12),
            Text(
              secondaryStat,
              style: TextStyle(
                color: context.brain.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: progress.clamp(0, 1),
            color: color,
          ),
        ),
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? context.brain.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brain.outline.withValues(alpha: .72)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21, color: context.brain.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: context.brain.textMuted),
          ),
        ],
      ),
    ),
  );
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 840,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: AppText.focusMark(),
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          context.brain.primary,
          context.brain.secondary,
        ),
      ),
    ),
  );
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter(this.primary, this.secondary);

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, size.width * .055);
    for (final ring in <(double, Color)>[
      (.38, primary),
      (.25, secondary),
      (.12, primary),
    ]) {
      stroke.color = ring.$2;
      canvas.drawCircle(center, size.shortestSide * ring.$1, stroke);
    }
    final dot = Paint()..color = primary;
    canvas.drawCircle(center, size.shortestSide * .055, dot);
    canvas.drawCircle(
      Offset(size.width * .78, size.height * .28),
      size.shortestSide * .045,
      dot,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

class GamePageTitle extends StatelessWidget {
  const GamePageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: context.brain.textMuted),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
