import "package:flutter/material.dart";
import "package:marquee/marquee.dart";

class AutoScrollText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double velocity;

  const AutoScrollText({
    super.key,
    required this.text,
    this.style = const TextStyle(),
    this.velocity = 20.0
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final isOverflow = textPainter.width > constraints.maxWidth;

        return SizedBox(height: textPainter.height, child: isOverflow
            ? Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              velocity: velocity,
              blankSpace: 20,
              pauseAfterRound: Duration(seconds: 3),
              startAfter: Duration(seconds: 1),
              // fadingEdgeStartFraction: 0.1,
              // fadingEdgeEndFraction: 0.1,
            )
            : Text(text, style: style, overflow: TextOverflow.ellipsis));
      },
    );
  }
}
