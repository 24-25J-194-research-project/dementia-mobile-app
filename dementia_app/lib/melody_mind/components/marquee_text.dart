import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double width;
  final Duration animationDuration;
  final Duration pauseDuration;
  final double velocity;
  final Curve curve;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    required this.width,
    this.animationDuration = const Duration(seconds: 3),
    this.pauseDuration = const Duration(milliseconds: 800),
    this.velocity = 50.0,
    this.curve = Curves.linear,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  bool _isScrolling = false;
  bool _needsScroll = false;
  GlobalKey _textKey = GlobalKey();
  double _textWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTextWidth();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateTextWidth() {
    if (_textKey.currentContext != null) {
      final RenderBox box =
          _textKey.currentContext!.findRenderObject() as RenderBox;
      _textWidth = box.size.width;

      setState(() {
        _needsScroll = _textWidth > widget.width;
      });

      if (_needsScroll) {
        _startScrolling();
      }
    }
  }

  void _startScrolling() async {
    if (!_needsScroll || _isScrolling) {
      return;
    }

    _isScrolling = true;

    while (_needsScroll && mounted) {
      await Future.delayed(widget.pauseDuration);
      if (!mounted) return;

      final double scrollExtent = _textWidth - widget.width;
      final duration = Duration(
        milliseconds: (scrollExtent / widget.velocity * 1000).round(),
      );

      //scroll to the end
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          scrollExtent,
          duration: duration,
          curve: widget.curve,
        );
        if (!mounted) return;
      }

      await Future.delayed(widget.pauseDuration);
      if (!mounted) return;

      //scroll back to the start
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: Duration.zero,
          curve: widget.curve,
        );
        if (!mounted) return;
      }
    }

    _isScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    //cecking if the text needs scrolling
    if (!_needsScroll) {
      return SizedBox(
        width: widget.width,
        child: Text(
          widget.text,
          key: _textKey,
          style: widget.style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: (widget.style.fontSize ?? 14) * 1.2,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
        ),
      ),
    );
  }
}
