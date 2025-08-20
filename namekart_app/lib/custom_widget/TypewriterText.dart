import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration speed;
  final Duration fadeDuration;
  final Duration restartDelay;
  final bool loop;
  final bool reverse;

  const TypewriterText({
    Key? key,
    required this.text,
    this.textStyle,
    this.speed = const Duration(milliseconds: 150),
    this.fadeDuration = const Duration(milliseconds: 0),
    this.restartDelay = const Duration(milliseconds: 1000),
    this.loop = true,
    this.reverse = false,
  }) : super(key: key);

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  int _charIndex = 0;
  String _displayText = '';
  Timer? _typingTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isReversing = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    _startTyping();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(widget.speed, (timer) {
      setState(() {
        if (!_isReversing) {
          if (_charIndex < widget.text.length) {
            _charIndex++;
            _displayText = widget.text.substring(0, _charIndex);
          } else {
            // Finished typing full word
            timer.cancel();
            Future.delayed(widget.restartDelay, () {
              if (widget.reverse) {
                _isReversing = true;
                _startTyping();
              } else if (widget.loop) {
                _fadeOutAndRestart();
              }
            });
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
            _displayText = widget.text.substring(0, _charIndex);
          } else {
            // Finished reversing
            timer.cancel();
            if (widget.loop) {
              _fadeOutAndRestart();
            }
          }
        }
      });
    });
  }

  void _fadeOutAndRestart() async {
    await _fadeController.reverse();
    setState(() {
      _charIndex = 0;
      _displayText = '';
      _isReversing = false;
    });
    await _fadeController.forward();
    _startTyping();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        _displayText,
        style: widget.textStyle,
      ),
    );
  }
}
