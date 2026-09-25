import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/brain_theme.dart';

enum GamePanelStyle { standard, raised, inset, purple, wood }

class BrainCard extends StatefulWidget {
  const BrainCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.style = GamePanelStyle.raised,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final GamePanelStyle style;
  @override
  State<BrainCard> createState() => _BrainCardState();
}

class _BrainCardState extends State<BrainCard> {
  bool hover = false, pressed = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final p = context.brain;
    final still = MediaQuery.disableAnimationsOf(context);
    final base =
        widget.color ??
        switch (widget.style) {
          GamePanelStyle.purple => p.primary,
          GamePanelStyle.wood => const Color(0xFFA94F2E),
          GamePanelStyle.inset => p.hud,
          _ => p.surface,
        };
    final ink = context.onColor(base);
    return Semantics(
      button: widget.onTap != null,
      child: Focus(
        canRequestFocus: widget.onTap != null,
        onFocusChange: (value) => setState(() => focused = value),
        onKeyEvent: (_, event) {
          if (widget.onTap != null &&
              event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: widget.onTap == null
              ? MouseCursor.defer
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() {
            hover = false;
            pressed = false;
          }),
          child: GestureDetector(
            onTapDown: widget.onTap == null
                ? null
                : (_) => setState(() => pressed = true),
            onTapCancel: widget.onTap == null
                ? null
                : () => setState(() => pressed = false),
            onTapUp: widget.onTap == null
                ? null
                : (_) => setState(() => pressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(
                0,
                still
                    ? 0
                    : pressed
                    ? 4
                    : hover
                    ? -2
                    : 0,
                0,
              ),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: Color.lerp(base, p.highlight, hover ? .06 : 0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: focused ? p.reward : p.outline,
                  width: focused ? 4 : 3,
                ),
                boxShadow: widget.style == GamePanelStyle.inset
                    ? [
                        BoxShadow(
                          color: p.shadow.withValues(alpha: .6),
                          offset: const Offset(0, 3),
                          blurRadius: 1,
                          spreadRadius: -1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: p.shadow.withValues(alpha: .85),
                          offset: Offset(0, pressed ? 2 : 7),
                        ),
                        BoxShadow(
                          color: p.highlight.withValues(alpha: .12),
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: ink),
                child: IconTheme.merge(
                  data: IconThemeData(color: ink),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
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
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool hover = false, down = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final p = context.brain, enabled = widget.onPressed != null;
    final still = MediaQuery.disableAnimationsOf(context);
    final buttonColor = widget.color ?? p.success;
    final foreground = context.onColor(buttonColor);
    final button = Focus(
      canRequestFocus: enabled,
      onFocusChange: (value) => setState(() => focused = value),
      onKeyEvent: (_, event) {
        if (enabled &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() {
          hover = false;
          down = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => down = true) : null,
          onTapCancel: enabled ? () => setState(() => down = false) : null,
          onTapUp: enabled ? (_) => setState(() => down = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: still ? Duration.zero : const Duration(milliseconds: 120),
            transform: Matrix4.translationValues(
              0,
              still
                  ? 0
                  : down
                  ? 5
                  : hover
                  ? -2
                  : 0,
              0,
            ),
            constraints: const BoxConstraints(minHeight: 54, minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? buttonColor : p.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: focused ? p.reward : p.outline,
                width: focused ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: enabled
                      ? Color.lerp(buttonColor, Colors.black, .28)!
                      : p.shadow,
                  offset: Offset(0, down ? 1 : 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.expanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: enabled ? foreground : p.text.withValues(alpha: .5),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: enabled
                          ? foreground
                          : p.text.withValues(alpha: .45),
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: widget.expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class TitlePlaque extends StatelessWidget {
  const TitlePlaque(this.title, {super.key, this.color});
  final String title;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final plaqueColor = color ?? context.brain.reward;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: plaqueColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.brain.outline, width: 3),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(plaqueColor, Colors.black, .25)!,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: context.onColor(plaqueColor),
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class ResourceBar extends StatelessWidget {
  const ResourceBar({
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
        ],
      ),
      const SizedBox(height: 5),
      Container(
        height: 16,
        decoration: BoxDecoration(
          color: context.brain.hud,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: context.brain.outline, width: 3),
        ),
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: color ?? context.brain.secondary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: context.brain.highlight.withValues(alpha: .35),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 24, 2, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    ),
  );
}

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  final IconData icon;
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 11),
      decoration: BoxDecoration(
        color: color ?? context.brain.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brain.outline, width: 3),
        boxShadow: [
          BoxShadow(color: context.brain.shadow, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: context.rewardInk),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
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
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) Text(subtitle!),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
