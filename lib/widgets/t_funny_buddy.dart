import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import '../utils/config.dart';

Size androidOverlayWorldSize() {
  try {
    final displays = PlatformDispatcher.instance.displays;
    if (displays.isNotEmpty) {
      final d = displays.first;
      final dpr = d.devicePixelRatio == 0 ? 1.0 : d.devicePixelRatio;
      var logical = Size(d.size.width / dpr, d.size.height / dpr);
      if (logical.width < 250 || logical.height < 400) {
        logical = d.size;
      }
      if (logical.width > 250 && logical.height > 400) return logical;
    }
  } catch (_) {}
  return const Size(411, 891);
}

/// Physics world: size captured from the main activity, swapped on rotation.
Size overlayPhysicsSize() {
  final saved = AppConfig.instance.savedScreenSize();
  if (saved.width < 200 || saved.height < 200) {
    return androidOverlayWorldSize();
  }
  try {
    final displays = PlatformDispatcher.instance.displays;
    if (displays.isNotEmpty) {
      final d = displays.first;
      final dpr = d.devicePixelRatio == 0 ? 1.0 : d.devicePixelRatio;
      final dw = d.size.width / dpr;
      final dh = d.size.height / dpr;
      if (dw > 250 && dh > 400) {
        final savedLand = saved.width >= saved.height;
        final displayLand = dw >= dh;
        if (savedLand != displayLand) {
          return Size(saved.height, saved.width);
        }
      }
    }
  } catch (_) {}
  return saved;
}

class BuddyHitRegistry {
  static final Map<int, Rect> bounds = {};
  static int dragging = 0;
  static Offset overlayOrigin = Offset.zero;
  static Size? worldSize;

  static const double spriteW = 96;
  static const double spriteH = 148;
  static const double padX = 28;
  static const double padTop = 48;
  static const double padBottom = 24;

  static double overlayWidth(double scale) => spriteW * scale + padX * 2;
  static double overlayHeight(double scale) => spriteH * scale + padTop + padBottom;

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
  final bool preview;
  const TFunnyBuddy({super.key, required this.isOverlay, this.index = 0, this.preview = false});

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
  final Map<String, bool> _imgOk = {};

  @override
  void initState() {
    super.initState();
    isLeft = widget.index.isOdd;
    if (widget.preview) {
      mode = 'idle';
      posX = 0;
      posY = 0;
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..repeat();
    if (!widget.preview) {
      _timer = Timer.periodic(
        Duration(milliseconds: widget.isOverlay && Platform.isAndroid ? 50 : 33),
        (_) => _update(),
      );
      _brain();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screen = _worldSize(context);
    if (!_spawned && screen.width > 10) {
      _spawned = true;
      final scale = AppConfig.instance.sizeMultiplier;
      posX = 40 + (_rng.nextDouble() * max(40, screen.width - 140)) + widget.index * 28;
      posX = posX.clamp(0, max(0, screen.width - _spriteW * scale));
      // Android overlay window follows pos; start on-screen so the buddy is visible immediately.
      posY = _androidWindowed ? 96 : -_spriteH * scale;
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
  bool get _androidWindowed => widget.isOverlay && Platform.isAndroid;

  Size _worldSize(BuildContext context) {
    if (_androidWindowed) {
      final world = BuddyHitRegistry.worldSize;
      if (world != null && world.width > 200 && world.height > 200) return world;
      final sized = overlayPhysicsSize();
      BuddyHitRegistry.worldSize = sized;
      return sized;
    }
    return MediaQuery.sizeOf(context);
  }

  /// Keep the visible body a little inside the screen; do not hang off the edge.
  double get _edgeMargin => 8.0 * _scale;

  double _leftEdge() => _edgeMargin;
  double _rightEdge(Size s, double w) => max(_leftEdge(), s.width - w - _edgeMargin);

  void _reportHit() {
    BuddyHitRegistry.set(
      widget.index,
      Rect.fromLTWH(posX, posY, _spriteW * _scale, _spriteH * _scale),
    );
  }

  void _update() {
    if (!mounted || mode == 'drag' || widget.preview) return;
    final s = _worldSize(context);
    if (s.width < 10) return;

    final w = _spriteW * _scale;
    final h = _spriteH * _scale;
    final ground = s.height - h - _edgeMargin;
    final left = _leftEdge();
    final right = _rightEdge(s, w);
    final oldMode = mode;
    final oldLeft = isLeft;

    _ticks++;
    final onGround = posY >= ground - 0.5 && velY >= 0 && mode != 'climb';

    if (mode == 'climb') {
      velX = 0;
      velY = -2.0 * AppConfig.instance.speedMultiplier;
      posX = _wall < 0 ? left : right;
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
      if ((mode == 'walk' || mode == 'fall') && posY > 40) {
        _startClimb(-1);
      } else if (mode != 'climb') {
        isLeft = false;
        if (mode == 'walk') velX = _walkSpeed;
      }
    } else if (posX >= right) {
      posX = right;
      if ((mode == 'walk' || mode == 'fall') && posY > 40) {
        _startClimb(1);
      } else if (mode != 'climb') {
        isLeft = true;
        if (mode == 'walk') velX = -_walkSpeed;
      }
    }

    if (mode == 'climb' && posY <= _edgeMargin) {
      mode = 'fall';
      _wall = 0;
      velY = 0.4;
      velX = isLeft ? 2.2 : -2.2;
      posY = 0;
    }

    _reportHit();
    if (!_androidWindowed || oldMode != mode || oldLeft != isLeft) {
      setState(() {});
    }
  }

  bool _startClimb(int wall) {
    mode = 'climb';
    _wall = wall;
    velX = 0;
    velY = 0;
    isLeft = wall < 0;
    return true;
  }

  bool _grabEdgeIfClose() {
    final s = _worldSize(context);
    final w = _spriteW * _scale;
    final h = _spriteH * _scale;
    final left = _leftEdge();
    final right = _rightEdge(s, w);
    const edge = 64.0;
    if (posY <= 36 || posY >= s.height - h - 8) return false;
    if (posX <= left + edge) {
      posX = left;
      return _startClimb(-1);
    }
    if (posX >= right - edge) {
      posX = right;
      return _startClimb(1);
    }
    return false;
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
    final sprite = RepaintBoundary(
      child: Transform.scale(
        scale: widget.preview ? 0.82 : _scale,
        alignment: widget.preview ? Alignment.topCenter : Alignment.topLeft,
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, _) => _buildCharacter(),
        ),
      ),
    );
    if (widget.preview) {
      return IgnorePointer(child: sprite);
    }
    final clickThrough = widget.isOverlay && !Platform.isWindows && !Platform.isAndroid && AppConfig.instance.isClickThrough;
    // Android overlay is a small window that follows the buddy. Keep the sprite
    // pinned inside that window; world posX/posY only drive window movement.
    final left = _androidWindowed ? BuddyHitRegistry.padX : posX;
    final top = _androidWindowed ? BuddyHitRegistry.padTop : posY;
    return Positioned(
      left: left,
      top: top,
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
            if (_grabEdgeIfClose()) return;
            mode = 'fall';
            velX = (d.velocity.pixelsPerSecond.dx / 90).clamp(-18, 18);
            velY = (d.velocity.pixelsPerSecond.dy / 90).clamp(-18, 18);
          }),
          onPanCancel: () => setState(() {
            if (BuddyHitRegistry.dragging > 0) BuddyHitRegistry.dragging--;
            if (_grabEdgeIfClose()) return;
            mode = 'fall';
          }),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: sprite,
          ),
        ),
      ),
    );
  }

  Widget _buildCharacter() {
    final sec = widget.preview ? _animCtrl.value * 0.72 : _ticks * 0.05;
    final custom = AppConfig.instance.mode == 'custom' ? AppConfig.instance.getActiveCustom() : null;
    final headImg = custom?.headImg;
    final bodyImg = custom?.bodyImg;
    final armUpImg = custom?.armUpperImg;
    final armLowImg = custom?.armLowerImg;
    final handImg = custom?.handImg;
    final legUpImg = custom?.legUpperImg;
    final legLowImg = custom?.legLowerImg;
    final footImg = custom?.footImg;

    double fArmUp = 0.08, bArmUp = -0.08, fArmLow = -0.32, bArmLow = -0.32;
    double fHand = -0.08, bHand = -0.08;
    double fLegUp = 0.04, bLegUp = -0.04, fLegLow = 0.16, bLegLow = 0.16;
    double fFoot = 0, bFoot = 0;
    double bob = 0;
    double tilt = 0;
    double headTilt = 0;

    if (mode == 'walk') {
      final g = sec * 2 * pi * 1.3;
      final hipF = sin(g) * 0.38;
      final hipB = sin(g + pi) * 0.38;
      fLegUp = hipF;
      bLegUp = hipB;
      final kneeF = 0.16 + max(0.0, sin(g - 0.45)) * 0.42;
      final kneeB = 0.16 + max(0.0, sin(g + pi - 0.45)) * 0.42;
      fLegLow = kneeF;
      bLegLow = kneeB;
      fArmUp = sin(g) * 0.7;
      bArmUp = sin(g + pi) * 0.7;
      fArmLow = -0.42 - fArmUp.abs() * 0.06;
      bArmLow = -0.42 - bArmUp.abs() * 0.06;
      fHand = -0.1;
      bHand = -0.1;
      fFoot = 0;
      bFoot = 0;
      bob = (1 - cos(g * 2)) * -2.0;
      tilt = sin(g) * 0.03;
    } else if (mode == 'climb') {
      final g = sec * 2 * pi * 1.6;
      final reach = sin(g);
      fArmUp = -1.55 - reach * 0.4;
      bArmUp = -1.85 + reach * 0.4;
      fArmLow = -0.28;
      bArmLow = -0.28;
      fHand = -0.06;
      bHand = -0.06;
      fLegUp = -0.55 - reach * 0.28;
      bLegUp = -0.78 + reach * 0.28;
      fLegLow = 0.62;
      bLegLow = 0.62;
      fFoot = -0.15;
      bFoot = -0.15;
      bob = -reach.abs() * 1.2;
      tilt = 0.04;
      headTilt = 0.08;
    } else if (mode == 'drag' || mode == 'fall') {
      final g = sec * 2 * pi * 3.4;
      final flap = sin(g);
      fArmUp = 1.4 + sin(g) * 1.0;
      bArmUp = -1.4 + sin(g + 1.3) * 1.0;
      fArmLow = -0.48 - flap.abs() * 0.1;
      bArmLow = -0.48 - flap.abs() * 0.1;
      fHand = -0.1;
      bHand = -0.1;
      fLegUp = 0.45 + sin(g + 0.7) * 0.65;
      bLegUp = -0.45 + sin(g + 2.1) * 0.65;
      fLegLow = 0.5 + sin(g + 0.4).abs() * 0.2;
      bLegLow = 0.5 + sin(g + 1.6).abs() * 0.2;
      fFoot = 0.08;
      bFoot = 0.08;
      tilt = mode == 'fall' ? sin(g * 0.5) * 0.16 : 0.05;
    } else {
      final idle = sin(sec * 2 * pi * 0.45);
      fArmUp = 0.08 + idle * 0.03;
      bArmUp = -0.08 - idle * 0.03;
      fArmLow = -0.32;
      bArmLow = -0.32;
      fHand = -0.08;
      bHand = -0.08;
      fLegUp = 0.04;
      bLegUp = -0.04;
      fLegLow = 0.16;
      bLegLow = 0.16;
      fFoot = 0;
      bFoot = 0;
      bob = idle * 0.7;
      tilt = 0;
    }

    final blink = widget.preview
        ? (_animCtrl.value * 24).floor() % 28 == 0
        : (_ticks % (80 + widget.index * 9)) < 4;

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
                      _limb(false, bArmUp, bArmLow, bHand, armUpImg, armLowImg, handImg, dx: mode == 'climb' ? 4 : 0),
                      _leg(false, bLegUp, bLegLow, bFoot, legUpImg, legLowImg, footImg, dx: mode == 'climb' ? 8 : 0),
                      _part(
                        34,
                        52,
                        const Color(0xFF3B82F6),
                        bodyImg,
                        [
                          Positioned(
                            left: -7,
                            top: -42,
                            child: Transform.rotate(
                              angle: headTilt,
                              alignment: Alignment.bottomCenter,
                              child: _part(
                                48,
                                48,
                                const Color(0xFFF59E0B),
                                headImg,
                                (headImg != null && File(headImg).existsSync()) ? const [] : [_BuddyFace(blink: blink)],
                              ),
                            ),
                          ),
                        ],
                        radius: 16,
                      ),
                      _leg(true, fLegUp, fLegLow, fFoot, legUpImg, legLowImg, footImg, dx: mode == 'climb' ? 10 : 0),
                      _limb(true, fArmUp, fArmLow, fHand, armUpImg, armLowImg, handImg, dx: mode == 'climb' ? 18 : 0),
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

  Widget _limb(bool near, double upR, double lowR, double handR, String? up, String? low, String? hand, {double dx = 0}) {
    return Positioned(
      left: (near ? -10.0 : 28.0) + dx,
      top: 2,
      child: _joint(13, 28, const Color(0xFF64748B), upR, up, [
        Positioned(
          left: 1,
          top: 22,
          child: _joint(11, 24, const Color(0xFF94A3B8), lowR, low, [
            Positioned(
              left: -1,
              top: 19,
              child: _joint(12, 12, const Color(0xFFCBD5E1), handR, hand, const [], radius: 5),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _leg(bool near, double upR, double lowR, double footR, String? up, String? low, String? foot, {double dx = 0}) {
    return Positioned(
      left: (near ? 4.0 : 16.0) + dx,
      top: 44,
      child: _joint(14, 30, const Color(0xFF92400E), upR, up, [
        Positioned(
          left: 1,
          top: 24,
          child: _joint(12, 26, const Color(0xFFB45309), lowR, low, [
            Positioned(
              left: 3,
              top: 22,
              child: _joint(
                15,
                8,
                const Color(0xFFD97706),
                footR,
                foot,
                const [],
                radius: 4,
                alignment: Alignment.centerLeft,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _joint(
    double w,
    double h,
    Color c,
    double r,
    String? img,
    List<Widget> children, {
    double radius = 8,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Transform.rotate(
      angle: r,
      alignment: alignment,
      child: _part(w, h, c, img, children, radius: radius),
    );
  }

  bool _hasImg(String? img) {
    if (img == null || img.isEmpty) return false;
    return _imgOk.putIfAbsent(img, () => File(img).existsSync());
  }

  Widget _part(double w, double h, Color c, String? img, List<Widget> children, {double radius = 8}) {
    final fileOk = _hasImg(img);
    return Container(
      width: w,
      height: h,
      decoration: fileOk
          ? null
          : BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
            ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (fileOk)
            Positioned.fill(
              child: OverflowBox(
                maxWidth: 120,
                maxHeight: 120,
                child: Image.file(File(img!), fit: BoxFit.contain),
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
