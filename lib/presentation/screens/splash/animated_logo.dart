import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    this.size = 260,
    this.onAnimationComplete,
  });

  
  final double size;

  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _swooshFade;
  late final Animation<double> _swooshScale;

  late final Animation<double> _sproutFade;
  late final Animation<Offset> _sproutSlide;

  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  late final Animation<double> _finalCrossfade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _swooshFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _swooshScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _sproutFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _sproutSlide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.85, curve: Curves.easeOut),
    );
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOutCubic),
      ),
    );

  
    _finalCrossfade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 1.0 - _finalCrossfade.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    //big swoosh leaf 
                    FadeTransition(
                      opacity: _swooshFade,
                      child: ScaleTransition(
                        scale: _swooshScale,
                        child: Align(
                          alignment: const Alignment(0.12, 0.05),
                          child: Image.asset(
                            'assets/splash_screen/leaf_swoosh_medium.png',
                            width: s * 0.62,
                          ),
                        ),
                      ),
                    ),

                    //my leaflets
                    Align(
                      alignment: const Alignment(-0.62, -0.70),
                      child: FadeTransition(
                        opacity: _sproutFade,
                        child: SlideTransition(
                          position: _sproutSlide,
                          child: Image.asset(
                            'assets/splash_screen/leaf_sprout_dark.png',
                            width: s * 0.16,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.55, -0.76),
                      child: FadeTransition(
                        opacity: _sproutFade,
                        child: SlideTransition(
                          position: _sproutSlide,
                          child: Image.asset(
                            'assets/splash_screen/leaf_sprout_bright.png',
                            width: s * 0.16,
                          ),
                        ),
                      ),
                    ),

                    //text
                    Align(
                      alignment: const Alignment(0, 0.30),
                      child: FadeTransition(
                        opacity: _wordmarkFade,
                        child: SlideTransition(
                          position: _wordmarkSlide,
                          child: Image.asset(
                            'assets/splash_screen/wordmark_only.png',
                            width: s * 0.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

             //final combo
              Opacity(
                opacity: _finalCrossfade.value,
                child: Image.asset(
                  'assets/splash_screen/logo_full_combined.png',
                  width: s * 0.95,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
