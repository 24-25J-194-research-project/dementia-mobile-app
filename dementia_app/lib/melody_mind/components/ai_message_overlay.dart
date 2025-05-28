import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dementia_app/utils/appColors.dart';

class AIMessageOverlay extends StatefulWidget {
 
  final String message;

 
  final bool isVisible;

 
  final VoidCallback? onHide;

 
  final Duration displayDuration;

 
  final AIMessageStyle? customStyle;


  final bool enableAutoHide;

  const AIMessageOverlay({
    Key? key,
    required this.message,
    required this.isVisible,
    this.onHide,
    this.displayDuration = const Duration(seconds: 5),
    this.customStyle,
    this.enableAutoHide = true,
  }) : super(key: key);

  @override
  State<AIMessageOverlay> createState() => _AIMessageOverlayState();
}

class _AIMessageOverlayState extends State<AIMessageOverlay>
    with SingleTickerProviderStateMixin {
 
  late AnimationController _animationController;

  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AIMessageOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

   
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showMessage();
      } else {
        _hideMessage();
      }
    }

    
    if (widget.isVisible && widget.message != oldWidget.message) {
      _resetAutoHideTimer();
    }
  }

  
  void _showMessage() {
    _animationController.forward();
    if (widget.enableAutoHide) {
      _startAutoHideTimer();
    }
  }

  
  void _hideMessage() {
    _animationController.reverse();
    _cancelAutoHideTimer();
  }

  
  void _startAutoHideTimer() {
    _cancelAutoHideTimer();
    _autoHideTimer = Timer(widget.displayDuration, () {
      if (mounted && widget.onHide != null) {
        widget.onHide!();
      }
    });
  }

  
  void _resetAutoHideTimer() {
    if (widget.enableAutoHide) {
      _startAutoHideTimer();
    }
  }

  /// Cancel the auto-hide timer
  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cancelAutoHideTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (!widget.isVisible && _animationController.isDismissed) {
      return const SizedBox.shrink();
    }

    final style = widget.customStyle ?? AIMessageStyle.defaultStyle();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildMessageContainer(style),
          ),
        );
      },
    );
  }

 
  Widget _buildMessageContainer(AIMessageStyle style) {
    return Container(
      margin: style.margin,
      padding: style.padding,
      decoration: BoxDecoration(
        gradient: style.backgroundGradient,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        boxShadow: style.boxShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconContainer(style),
          SizedBox(width: style.contentSpacing),
          Expanded(
            child: _buildMessageContent(style),
          ),
        ],
      ),
    );
  }

  
  Widget _buildIconContainer(AIMessageStyle style) {
    return Container(
      padding: style.iconPadding,
      decoration: BoxDecoration(
        color: style.iconBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.iconData,
        color: style.iconColor,
        size: style.iconSize,
      ),
    );
  }

  
  Widget _buildMessageContent(AIMessageStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          style.title,
          style: GoogleFonts.inter(
            color: style.titleColor,
            fontSize: style.titleFontSize,
            fontWeight: style.titleFontWeight,
          ),
        ),
        SizedBox(height: style.titleMessageSpacing),
        Text(
          widget.message,
          style: GoogleFonts.inter(
            color: style.messageColor,
            fontSize: style.messageFontSize,
            fontWeight: style.messageFontWeight,
            height: style.messageLineHeight,
          ),
        ),
      ],
    );
  }
}

class AIMessageStyle {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final EdgeInsets iconPadding;
  final Gradient backgroundGradient;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow> boxShadow;
  final double contentSpacing;

  
  final IconData iconData;
  final Color iconColor;
  final Color iconBackgroundColor;
  final double iconSize;

  
  final String title;
  final Color titleColor;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color messageColor;
  final double messageFontSize;
  final FontWeight messageFontWeight;
  final double messageLineHeight;
  final double titleMessageSpacing;

  const AIMessageStyle({
    required this.margin,
    required this.padding,
    required this.iconPadding,
    required this.backgroundGradient,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.boxShadow,
    required this.contentSpacing,
    required this.iconData,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.iconSize,
    required this.title,
    required this.titleColor,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.messageColor,
    required this.messageFontSize,
    required this.messageFontWeight,
    required this.messageLineHeight,
    required this.titleMessageSpacing,
  });

  
  factory AIMessageStyle.defaultStyle() {
    return AIMessageStyle(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      iconPadding: const EdgeInsets.all(8),
      backgroundGradient: LinearGradient(
        colors: [
          Colors.amber.shade50.withOpacity(0.95),
          Colors.orange.shade50.withOpacity(0.95),
        ],
      ),
      borderColor: Colors.amber.shade200,
      borderWidth: 1,
      borderRadius: 16,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      contentSpacing: 12,
      iconData: Icons.psychology,
      iconColor: Colors.amber.shade700,
      iconBackgroundColor: Colors.amber.shade100,
      iconSize: 20,
      title: "AI Therapy Companion",
      titleColor: Colors.amber.shade800,
      titleFontSize: 12,
      titleFontWeight: FontWeight.w600,
      messageColor: Colors.amber.shade900,
      messageFontSize: 14,
      messageFontWeight: FontWeight.w500,
      messageLineHeight: 1.3,
      titleMessageSpacing: 4,
    );
  }

  ///create a style variant for different contexts
  factory AIMessageStyle.successStyle() {
    return AIMessageStyle.defaultStyle().copyWith(
      backgroundGradient: LinearGradient(
        colors: [
          Colors.green.shade50.withOpacity(0.95),
          Colors.greenAccent.withOpacity(0.95),
        ],
      ),
      borderColor: Colors.green.shade200,
      iconColor: Colors.green.shade700,
      iconBackgroundColor: Colors.green.shade100,
      titleColor: Colors.green.shade800,
      messageColor: Colors.green.shade900,
    );
  }

 
  AIMessageStyle copyWith({
    EdgeInsets? margin,
    EdgeInsets? padding,
    EdgeInsets? iconPadding,
    Gradient? backgroundGradient,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
    double? contentSpacing,
    IconData? iconData,
    Color? iconColor,
    Color? iconBackgroundColor,
    double? iconSize,
    String? title,
    Color? titleColor,
    double? titleFontSize,
    FontWeight? titleFontWeight,
    Color? messageColor,
    double? messageFontSize,
    FontWeight? messageFontWeight,
    double? messageLineHeight,
    double? titleMessageSpacing,
  }) {
    return AIMessageStyle(
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      iconPadding: iconPadding ?? this.iconPadding,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      iconSize: iconSize ?? this.iconSize,
      title: title ?? this.title,
      titleColor: titleColor ?? this.titleColor,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      messageColor: messageColor ?? this.messageColor,
      messageFontSize: messageFontSize ?? this.messageFontSize,
      messageFontWeight: messageFontWeight ?? this.messageFontWeight,
      messageLineHeight: messageLineHeight ?? this.messageLineHeight,
      titleMessageSpacing: titleMessageSpacing ?? this.titleMessageSpacing,
    );
  }
}
