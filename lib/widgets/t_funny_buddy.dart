import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/config.dart';

class BuddyHitRegistry {
  static final Map<int, Rect> bounds = {};
  static int dragging = 0;

  static void set(int index, Rect rect) => bounds[index] = rect;
  static void remove(int index) => bounds.remove(index);

  static bool hit(Offset p, {required bool wasOver}) {
    if (dragging > 0) return true;
    final pad = wasOver ? 22.0 : 10.0;
    return bounds.values.any((r) => r.inflate(pad).contains(p));
  }
}

class TFunnyBuddy extends StatefulWidget {
  final bool isOverlay;
  final int index;
  const TFunnyBuddy({super.key, required this.isOverlay, this.index = 0});

  @override
  State<TFunnyBuddy> createState() => _TFunnyBuddyState();
}

class _TFunnyBuddyState extends State<TFunnyBuddy> with TickerProviderStateMixin {
  static const double _spriteW = 96;
  static const double _spriteH = 148;

  double posX = 80;
  double posY = -40;
  double velX = 0;
  double velY = 0;
  bool isLeft = false;
  String mode = 'fall';
  int _wall = 0;
  bool _spawned = false;
  int _ticks = 0;

  late AnimationController _animCtrl;
  Timer? _timer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    isLeft = widget.index.isOdd;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
    _brain();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = MediaQuery.sizeOf(context);
    if (!_spawned && screen.width > 10) {
      _spawned = true;
      final scale = AppConfig.instance.sizeMultiplier;
      posX = 40 + (_rng.nextDouble() * max(40, screen.width - 140)) + widget.index * 28;
      posX = posX.clamp(0, max(0, screen.width - _spriteW * scale));
      posY = -_spriteH * scale;
    }
  }

  void _brain() {
    final freq = max(1, AppConfig.instance.actionFrequency);
    Future.delayed(Duration(milliseconds: 1400 + _rng.nextInt(freq * 900)), () {
      if (!mounted) return;
      if (mode == 'idle' || mode == 'walk') {
        if (_rng.nextInt(100) < 38) {
          mode = 'idle';
          velX = 0;
        } else {
          mode = 'walk';
          isLeft = _rng.nextBool();
          velX = (isLeft ? -1 : 1) * _walkSpeed;
        }
      }
      _brain();
    });
  }

  double get _walkSpeed => 2.4 * AppConfig.instance.speedMultiplier;
  double get _scale => AppConfig.instance.sizeMultiplier;

  void _reportHit() {
    BuddyHitRegistry.set(
      widget.index,
      Rect.fromLTWH(posX, posY, _spriteW * _scale, _spriteH * _scale),
    );
  }

  void _update() {
    if (!mounted || mode == 'drag') return;
    final s = MediaQuery.sizeOf(context);
    if (s.width < 10) return;

    final w = _spriteW * _scale;
    final h = _spriteH * _scale;
    final ground = s.height - h;
    final left = 0.0;
    final right = max(0.0, s.width - w);

    setState(() {
      _ticks++;
      final onGround = posY >= ground - 0.5 && velY >= 0 && mode != 'climb';

      if (mode == 'climb') {
        velX = 0;
        velY = -2.8 * AppConfig.instance.speedMultiplier;
        posX = _wall < 0 ? left : (right + 18 * _scale);
      } else if (!onGround) {
        velY = min(velY + 0.55, 16);
        if (mode != 'fall' && mode != 'drag') mode = 'fall';
      } else {
        posY = ground;
        if (velY > 0) velY = 0;
        if (mode == 'fall') {
          mode = 'idle';
          _wall = 0;
          velX = 0;
        }
        if (mode == 'walk') {
          velX = (isLeft ? -1 : 1) * _walkSpeed;
        } else {
          velX = 0;
        }
      }

      posX += velX;
      posY += velY;

      if (posY >= ground && mode != 'climb') {
        posY = ground;
        velY = 0;
        if (mode == 'fall') mode = 'idle';
      }

      if (posX <= left) {
        posX = left;
        if (mode == 'walk' && posY > 48) {
          mode = 'climb';
          _wall = -1;
          velX = 0;
          isLeft = true;
        } else if (mode != 'climb') {
          isLeft = false;
          if (mode == 'walk') velX = _walkSpeed;
        }
      } else if (posX >= right) {
        posX = right;
        if (mode == 'walk' && posY > 48) {
          mode = 'climb';
          _wall = 1;
          velX = 0;
          isLeft = false;
        } else if (mode != 'climb') {
          isLeft = true;
          if (mode == 'walk') velX = -_walkSpeed;
        }
      }

      if (mode == 'climb' && posY <= 0) {
        mode = 'fall';
        _wall = 0;
        velY = 0.4;
        velX = isLeft ? 2.2 : -2.2;
        posY = 0;
      }

      _reportHit();
    });
  }

  @override
  void dispose() {
    BuddyHitRegistry.remove(widget.index);
    _animCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clickThrough = widget.isOverlay && !Platform.isWindows && AppConfig.instance.isClickThrough;
    return Positioned(
      left: posX,
      top: posY,
      child: IgnorePointer(
        ignoring: clickThrough,
        child: GestureDetector(
          onPanStart: (_) => setState(() {
            mode = 'drag';
            _wall = 0;
            BuddyHitRegistry.dragging++;
            velX = 0;
            velY = 0;
          }),
          onPanUpdate: (d) => setState(() {
            mode = 'drag';
            posX += d.delta.dx;
            posY += d.delta.dy;
            _reportHit();
          }),
          onPanEnd: (d) => setState(() {
            if (BuddyHitRegistry.dragging > 0) BuddyHitRegistry.dragging--;
            mode = 'fall';
            velX = (d.velocity.pixelsPerSecond.dx / 90).clamp(-18, 18);
            velY = (d.velocity.pixelsPerSecond.dy / 90).clamp(-18, 18);
          }),
          onPanCancel: () => setState(() {
            if (BuddyHitRegistry.dragging > 0) BuddyHitRegistry.dragging--;
            mode = 'fall';
          }),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topLeft,
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, _) => _buildCharacter(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacter() {
    final t = _animCtrl.value;
    final walk = sin(t * pi * 2);
    final climb = sin(t * pi * 4);
    final idle = sin(t * pi * 2);
    final custom = AppConfig.instance.mode == 'custom' ? AppConfig.instance.getActiveCustom() : null;
    final headImg = custom?.headImg;
    final bodyImg = custom?.bodyImg;
    final armUpImg = custom?.armUpperImg;
    final armLowImg = custom?.armLowerImg;
    final handImg = custom?.handImg;
    final legUpImg = custom?.legUpperImg;
    final legLowImg = custom?.legLowerImg;
    final footImg = custom?.footImg;

    double fArmUp = 0.04, bArmUp = -0.04, fArmLow = 0.1, bArmLow = 0.1;
    double fHand = 0.08, bHand = 0.08;
    double fLegUp = 0.02, bLegUp = -0.02, fLegLow = 0.08, bLegLow = 0.08;
    double fFoot = 1.05, bFoot = 1.05;
    double bob = 0;
    double tilt = 0;

    if (mode == 'walk') {
      fArmUp = -walk * 0.9;
      bArmUp = walk * 0.9;
      fArmLow = -0.45 - walk.abs() * 0.25;
      bArmLow = -0.45 - walk.abs() * 0.25;
      fHand = 0.18 + walk.abs() * 0.12;
      bHand = 0.18 + walk.abs() * 0.12;
      fLegUp = -walk * 0.7;
      bLegUp = walk * 0.7;
      fLegLow = fLegUp < 0 ? 0.55 : 0.12;
      bLegLow = bLegUp < 0 ? 0.55 : 0.12;
      fFoot = fLegUp < 0 ? 0.55 : 1.15;
      bFoot = bLegUp < 0 ? 0.55 : 1.15;
      bob = -walk.abs() * 5;
      tilt = walk * 0.05;
    } else if (mode == 'climb') {
      fArmUp = -1.7 + climb * 0.75;
      bArmUp = -1.7 - climb * 0.75;
      fArmLow = fArmUp < -1.8 ? 0.55 : -0.2;
      bArmLow = bArmUp < -1.8 ? 0.55 : -0.2;
      fHand = 0.55;
      bHand = 0.55;
      fLegUp = -0.7 - climb * 0.65;
      bLegUp = -0.7 + climb * 0.65;
      fLegLow = fLegUp < -0.9 ? 1.05 : 0.5;
      bLegLow = bLegUp < -0.9 ? 1.05 : 0.5;
      fFoot = 0.85;
      bFoot = 0.85;
      bob = -climb.abs() * 2;
      tilt = 0.1;
    } else if (mode == 'drag' || mode == 'fall') {
      final flap = sin(t * pi * 6);
      fArmUp = pi - 0.35 + flap * 0.25;
      bArmUp = pi + 0.35 - flap * 0.25;
      fArmLow = 0.35;
      bArmLow = 0.35;
      fHand = 0.25;
      bHand = 0.25;
      fLegUp = 0.45 + flap * 0.2;
      bLegUp = -0.45 - flap * 0.2;
      fLegLow = 0.25;
      bLegLow = 0.25;
      fFoot = 0.7;
      bFoot = 0.7;
      tilt = mode == 'fall' ? flap * 0.12 : 0.08;
    } else {
      fArmUp = 0.05;
      bArmUp = -0.05;
      fArmLow = 0.1;
      bArmLow = 0.1;
      fHand = 0.08;
      bHand = 0.08;
      fLegUp = 0.02;
      bLegUp = -0.02;
      fLegLow = 0.08;
      bLegLow = 0.08;
      fFoot = 1.05;
      bFoot = 1.05;
      bob = idle * 1.4;
      tilt = 0;
    }

    final blink = (_ticks % (160 + widget.index * 17)) < 8;

    return SizedBox(
      width: _spriteW,
      height: _spriteH,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(isLeft ? -1.0 : 1.0, 1.0, 1.0),
        child: Transform.translate(
          offset: Offset(mode == 'climb' ? 8 : 0, bob),
          child: Transform.rotate(
            angle: tilt,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (mode != 'climb')
                  Positioned(
                    left: 22,
                    bottom: 6,
                    child: IgnorePointer(
                      child: Container(
                        width: 52,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 28,
                  top: 38,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _limb(false, bArmUp, bArmLow, bHand, armUpImg, armLowImg, handImg),
                      _leg(false, bLegUp, bLegLow, bFoot, legUpImg, legLowImg, footImg),
                      _part(
                        34,
                        52,
                        const Color(0xFF3B82F6),
                        bodyImg,
                        [
                          Positioned(
                            left: -7,
                            top: -42,
                            child: _part(
                              48,
                              48,
                              const Color(0xFFF59E0B),
                              headImg,
                              headImg != null ? const [] : [_BuddyFace(blink: blink)],
                            ),
                          ),
                        ],
                        radius: 16,
                      ),
                      _leg(true, fLegUp, fLegLow, fFoot, legUpImg, legLowImg, footImg),
                      _limb(true, fArmUp, fArmLow, fHand, armUpImg, armLowImg, handImg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _limb(bool near, double upR, double lowR, double handR, String? up, String? low, String? hand) {
    return Positioned(
      left: near ? -10 : 28,
      top: 2,
      child: _joint(13, 28, const Color(0xFF64748B), upR, up, [
        Positioned(
          left: 1,
          top: 22,
          child: _joint(11, 24, const Color(0xFF94A3B8), lowR, low, [
            Positioned(
              left: -1,
              top: 19,
              child: _joint(13, 14, const Color(0xFFCBD5E1), handR, hand, const [], radius: 5),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _leg(bool near, double upR, double lowR, double footR, String? up, String? low, String? foot) {
    return Positioned(
      left: near ? 4 : 16,
      top: 44,
      child: _joint(14, 30, const Color(0xFF92400E), upR, up, [
        Positioned(
          left: 1,
          top: 24,
          child: _joint(12, 26, const Color(0xFFB45309), lowR, low, [
            Positioned(
              left: -2,
              top: 20,
              child: _joint(18, 10, const Color(0xFFD97706), footR, foot, const [], radius: 4),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _joint(double w, double h, Color c, double r, String? img, List<Widget> children, {double radius = 8}) {
    return Transform.rotate(
      angle: r,
      alignment: Alignment.topCenter,
      child: _part(w, h, c, img, children, radius: radius),
    );
  }

  Widget _part(double w, double h, Color c, String? img, List<Widget> children, {double radius = 8}) {
    return Container(
      width: w,
      height: h,
      decoration: img == null
          ? BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
            )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (img != null)
            Positioned.fill(
              child: OverflowBox(
                maxWidth: 120,
                maxHeight: 120,
                child: Image.file(File(img), fit: BoxFit.contain),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}

class _BuddyFace extends StatelessWidget {
  final bool blink;
  const _BuddyFace({required this.blink});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: _FacePainter(blink: blink),
    );
  }
}

class _FacePainter extends CustomPainter {
  final bool blink;
  _FacePainter({required this.blink});

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    final blush = Paint()..color = const Color(0x55F43F5E);
    canvas.drawCircle(const Offset(12, 32), 5, blush);
    canvas.drawCircle(const Offset(36, 32), 5, blush);
    if (blink) {
      final lid = Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(14, 20), const Offset(20, 20), lid);
      canvas.drawLine(const Offset(28, 20), const Offset(34, 20), lid);
    } else {
      canvas.drawCircle(const Offset(17, 20), 3.2, eyePaint);
      canvas.drawCircle(const Offset(31, 20), 3.2, eyePaint);
      final shine = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(16, 19), 1.1, shine);
      canvas.drawCircle(const Offset(30, 19), 1.1, shine);
    }
    final smile = Paint()
      ..color = const Color(0xFF9F1239)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(18, 30)
      ..quadraticBezierTo(24, 35, 30, 30);
    canvas.drawPath(path, smile);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) => oldDelegate.blink != blink;
}
