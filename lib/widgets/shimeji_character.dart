import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/config.dart';

class ShimejiCharacter extends StatefulWidget {
  const ShimejiCharacter({super.key});
  @override
  State<ShimejiCharacter> createState() => _ShimejiCharacterState();
}

class _ShimejiCharacterState extends State<ShimejiCharacter> with TickerProviderStateMixin {
  double posX = 0, posY = 0, velX = 0, velY = 0;
  bool isLeft = false;
  String mode = 'fall';
  late AnimationController _animCtrl;
  late Timer _logicTimer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    posX = _rng.nextDouble() * 200 + 50;
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    _logicTimer = Timer.periodic(const Duration(milliseconds: 16), (t) => _update());
    _brain();
  }

  void _brain() {
    Future.delayed(Duration(seconds: _rng.nextInt(AppConfig.instance.actionFrequency) + 1), () {
      if (!mounted) return;
      if (mode != 'fall' && mode != 'drag' && mode != 'climb') {
        int r = _rng.nextInt(10);
        if (r < 3) { mode = 'idle'; velX = 0; }
        else if (r < 7) { mode = 'walk'; velX = (isLeft ? -2.5 : 2.5) * AppConfig.instance.speedMultiplier; }
        else { mode = 'jump'; velY = -12 * AppConfig.instance.speedMultiplier; mode = 'fall'; }
      }
      _brain();
    });
  }

  void _update() {
    if (!mounted || mode == 'drag') return;
    Size s = MediaQuery.of(context).size;
    double scale = AppConfig.instance.sizeMultiplier;
    double charW = 100 * scale;
    double charH = 150 * scale;

    setState(() {
      if (mode != 'climb') velY += 0.8 * AppConfig.instance.speedMultiplier;
      posX += velX;
      posY += velY;

      if (posY >= s.height - charH) {
        posY = s.height - charH;
        velY = 0;
        if (mode == 'fall') mode = 'idle';
      }

      if (posX <= 0) {
        posX = 0;
        if (mode == 'walk') { isLeft = false; velX = 2.5 * AppConfig.instance.speedMultiplier; }
        else if (mode == 'climb') { isLeft = true; }
        if (mode != 'fall' && mode != 'drag' && _rng.nextBool() && posY > 0) {
          mode = 'climb'; velY = -2 * AppConfig.instance.speedMultiplier; velX = 0; isLeft = true;
        }
      } else if (posX >= s.width - charW && s.width > 0) {
        posX = s.width - charW;
        if (mode == 'walk') { isLeft = true; velX = -2.5 * AppConfig.instance.speedMultiplier; }
        else if (mode == 'climb') { isLeft = false; }
        if (mode != 'fall' && mode != 'drag' && _rng.nextBool() && posY > 0) {
          mode = 'climb'; velY = -2 * AppConfig.instance.speedMultiplier; velX = 0; isLeft = false;
        }
      } else {
        if (mode == 'climb') { mode = 'fall'; velY = 0; }
      }

      if (posY <= 0 && mode == 'climb') {
        mode = 'fall'; velY = 2 * AppConfig.instance.speedMultiplier; velX = isLeft ? 2 : -2;
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _logicTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() {
          mode = 'drag';
          posX += d.delta.dx;
          posY += d.delta.dy;
        }),
        onPanEnd: (d) => setState(() {
          mode = 'fall';
          velX = d.velocity.pixelsPerSecond.dx / 100;
          velY = d.velocity.pixelsPerSecond.dy / 100;
        }),
        child: Transform.scale(
          scale: AppConfig.instance.sizeMultiplier,
          alignment: Alignment.topLeft,
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(isLeft ? pi : 0),
              child: _buildSkeleton(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    double speedMult = AppConfig.instance.speedMultiplier;
    double t = _animCtrl.value * (speedMult > 0 ? speedMult : 1);
    double walkPhase = sin(t * pi * 2);
    double climbPhase = sin(t * pi * 4);

    double headRot = mode == 'idle' ? sin(t * pi) * 0.1 : 0;
    double bodyTilt = mode == 'walk' ? 0.1 : 0;
    
    double armRot = 0;
    double legRot = 0;

    if (mode == 'walk') {
      armRot = walkPhase * 0.5;
      legRot = walkPhase * 0.6;
    } else if (mode == 'fall') {
      armRot = pi - 0.5;
      legRot = 0.2;
    } else if (mode == 'climb') {
      armRot = pi + climbPhase * 0.2;
      legRot = climbPhase * 0.3;
    } else if (mode == 'drag') {
      armRot = pi;
      legRot = 0.5;
    }
    
    final cfg = AppConfig.instance;

    return SizedBox(
      width: 100,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 35, top: 50, child: _joint(25, 50, cfg.bodyColor, bodyTilt, Alignment.bottomCenter, cfg.bodyIcon, [
            Positioned(left: -5, top: -35, child: _joint(35, 35, cfg.headColor, headRot, Alignment.bottomCenter, cfg.headIcon, [
              if (cfg.headIcon == null) Positioned(left: 5, top: 5, child: Container(width: 5, height: 5, color: Colors.white, child: Center(child: Container(width: 2, height: 2, color: Colors.black)))),
              if (cfg.headIcon == null) Positioned(left: 20, top: 5, child: Container(width: 5, height: 5, color: Colors.white, child: Center(child: Container(width: 2, height: 2, color: Colors.black)))),
            ])),
            Positioned(left: -10, top: 0, child: _joint(12, 35, cfg.armColor, -armRot, Alignment.topCenter, cfg.armIcon, [
              Positioned(left: 0, top: 30, child: _joint(10, 30, cfg.armColor, -0.2, Alignment.topCenter, cfg.armIcon, [])),
            ])),
            Positioned(left: 25, top: 0, child: _joint(12, 35, cfg.armColor, armRot, Alignment.topCenter, cfg.armIcon, [
              Positioned(left: 0, top: 30, child: _joint(10, 30, cfg.armColor, 0.2, Alignment.topCenter, cfg.armIcon, [])),
            ])),
            Positioned(left: 0, top: 45, child: _joint(12, 35, cfg.legColor, legRot, Alignment.topCenter, cfg.legIcon, [
              Positioned(left: 0, top: 30, child: _joint(11, 30, cfg.legColor, legRot.abs(), Alignment.topCenter, cfg.legIcon, [])),
            ])),
            Positioned(left: 15, top: 45, child: _joint(12, 35, cfg.legColor, -legRot, Alignment.topCenter, cfg.legIcon, [
              Positioned(left: 0, top: 30, child: _joint(11, 30, cfg.legColor, legRot.abs(), Alignment.topCenter, cfg.legIcon, [])),
            ])),
          ])),
        ],
      ),
    );
  }

  Widget _joint(double w, double h, Color c, double r, Alignment a, IconData? icon, List<Widget> children) {
    return Transform.rotate(
      angle: r,
      alignment: a,
      child: Container(
        width: w,
        height: h,
        decoration: icon == null ? BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)) : null,
        child: Stack(
          clipBehavior: Clip.none, 
          children: [
            if (icon != null) Positioned.fill(child: FittedBox(child: Icon(icon, color: Colors.black87))),
            ...children
          ]
        ),
      ),
    );
  }
}
