import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/config.dart';

class TFunnyBuddy extends StatefulWidget {
  final bool isOverlay;
  const TFunnyBuddy({super.key, required this.isOverlay});
  @override
  State<TFunnyBuddy> createState() => _TFunnyBuddyState();
}

class _TFunnyBuddyState extends State<TFunnyBuddy> with TickerProviderStateMixin, WidgetsBindingObserver {
  double posX = 100, posY = 100, velX = 0, velY = 0;
  bool isLeft = false; String mode = 'fall';
  late AnimationController _animCtrl; Timer? _timer; final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) => _update());
    _brain();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppConfig.instance.pauseOnScreenOff) {
      if (state == AppLifecycleState.paused) { _timer?.cancel(); _animCtrl.stop(); }
      else if (state == AppLifecycleState.resumed) { 
        _timer = Timer.periodic(const Duration(milliseconds: 16), (t) => _update());
        _animCtrl.repeat();
      }
    }
  }

  void _brain() {
    Future.delayed(Duration(seconds: _rng.nextInt(AppConfig.instance.actionFrequency) + 2), () {
      if (!mounted) return;
      if (mode != 'fall' && mode != 'drag' && mode != 'climb') {
        int r = _rng.nextInt(100);
        if (r < 20) { mode = 'idle'; velX = 0; }
        else if (r < 80) { mode = 'walk'; velX = (isLeft ? -2.0 : 2.0) * AppConfig.instance.speedMultiplier; }
        else { mode = 'jump'; velY = -12; mode = 'fall'; }
      }
      _brain();
    });
  }

  void _update() {
    if (!mounted || mode == 'drag') return;
    Size s = MediaQuery.of(context).size;
    double scale = AppConfig.instance.sizeMultiplier;
    double w = 100 * scale; double h = 150 * scale;

    setState(() {
      if (mode != 'climb') velY += 0.8;
      posX += velX; posY += velY;

      if (posY >= s.height - h) { posY = s.height - h; velY = 0; if(mode == 'fall') mode = 'idle'; }

      if (posX <= 0) {
        posX = 0;
        if (mode == 'walk') { isLeft = false; velX = 2.0; }
        if (posY > 50 && _rng.nextInt(10) < 3) { mode = 'climb'; velY = -2; velX = 0; isLeft = true; }
      } else if (posX >= s.width - w) {
        posX = s.width - w;
        if (mode == 'walk') { isLeft = true; velX = -2.0; }
        if (posY > 50 && _rng.nextInt(10) < 3) { mode = 'climb'; velY = -2; velX = 0; isLeft = false; }
      }

      if (mode == 'climb' && (posY <= 0 || (posX > 5 && posX < s.width - w - 5))) {
        mode = 'fall'; velY = 0; velX = isLeft ? 2 : -2;
      }
    });
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _animCtrl.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: posX, top: posY,
      child: IgnorePointer(
        ignoring: widget.isOverlay && AppConfig.instance.isClickThrough,
        child: GestureDetector(
          onPanUpdate: (d) => setState(() { mode = 'drag'; posX += d.delta.dx; posY += d.delta.dy; }),
          onPanEnd: (d) => setState(() { mode = 'fall'; velX = d.velocity.pixelsPerSecond.dx / 100; velY = d.velocity.pixelsPerSecond.dy / 100; }),
          child: Transform.scale(
            scale: AppConfig.instance.sizeMultiplier,
            alignment: Alignment.topLeft,
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (c, _) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(isLeft ? pi : 0),
                child: _buildSkeleton(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    double t = _animCtrl.value;
    double walk = sin(t * pi * 2);
    double climb = sin(t * pi * 4);
    CustomPreset? cp = AppConfig.instance.getActiveCustom();
    bool isCus = AppConfig.instance.mode == 'custom';

    double armUpRot = mode == 'walk' ? walk * 0.5 : (mode == 'climb' ? pi + climb * 0.3 : 0.2);
    double armLowRot = mode == 'walk' ? walk.abs() * 0.4 : 0.2;
    double legUpRot = mode == 'walk' ? -walk * 0.5 : (mode == 'climb' ? climb * 0.3 : 0);
    double legLowRot = mode == 'walk' ? walk.abs() * 0.3 : 0;

    return SizedBox(
      width: 100, height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 35, top: 50, child: _part(30, 50, Colors.blue, isCus ? cp?.bodyImg : null, [
            Positioned(left: -5, top: -35, child: _part(40, 40, Colors.orange, isCus ? cp?.headImg : null, [])),
            _limb(true, armUpRot, armLowRot, isCus ? cp?.armUpperImg : null, isCus ? cp?.armLowerImg : null),
            _limb(false, -armUpRot, armLowRot, isCus ? cp?.armUpperImg : null, isCus ? cp?.armLowerImg : null),
            _leg(true, legUpRot, legLowRot, isCus ? cp?.legUpperImg : null, isCus ? cp?.legLowerImg : null),
            _leg(false, -legUpRot, legLowRot, isCus ? cp?.legUpperImg : null, isCus ? cp?.legLowerImg : null),
          ])),
        ],
      ),
    );
  }

  Widget _limb(bool left, double upRot, double lowRot, String? up, String? low) {
    return Positioned(
      left: left ? -5 : 20, top: 0,
      child: _joint(15, 30, Colors.grey, upRot, up, [
        Positioned(left: 0, top: 25, child: _joint(12, 25, Colors.grey, lowRot, low, [])),
      ]),
    );
  }

  Widget _leg(bool left, double upRot, double lowRot, String? up, String? low) {
    return Positioned(
      left: left ? 2 : 13, top: 45,
      child: _joint(15, 30, Colors.brown, upRot, up, [
        Positioned(left: 0, top: 25, child: _joint(13, 25, Colors.brown, lowRot, low, [])),
      ]),
    );
  }

  Widget _joint(double w, double h, Color c, double r, String? img, List<Widget> children) {
    return Transform.rotate(angle: r, alignment: Alignment.topCenter, child: _part(w, h, c, img, children));
  }

  Widget _part(double w, double h, Color c, String? img, List<Widget> children) {
    return Container(
      width: w, height: h,
      decoration: img == null ? BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)) : null,
      child: Stack(clipBehavior: Clip.none, children: [
        if (img != null) Positioned.fill(child: OverflowBox(maxWidth: 100, maxHeight: 100, child: Image.file(File(img), fit: BoxFit.contain))),
        ...children
      ]),
    );
  }
}
