// lib/screens/melody_mind/scrolling_text.dart
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double width;
  final int pauseMilliseconds;
  final double velocity;

  const ScrollingText({
    Key? key,
    required this.text,
    required this.style,
    required this.width,
    this.pauseMilliseconds = 1000,
    this.velocity = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //create a text painter to measure the text width
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    //check if text fits within the available width
    final bool needsScrolling = textPainter.width > width;

    //if text fits, use regular Text widget with ellipsis
    if (!needsScrolling) {
      return SizedBox(
        width: width,
        child: Text(
          text,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    //if text doesn't fit, use Marquee for scrolling
    return SizedBox(
      width: width,
      height: (style.fontSize ?? 14.0) * 1.5,
      child: Marquee(
        text: text,
        style: style,
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        blankSpace: 30.0,
        velocity: velocity,
        pauseAfterRound: Duration(milliseconds: pauseMilliseconds),
        startPadding: 10.0,
        accelerationDuration: const Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}
