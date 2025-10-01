import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_clipper.dart';
import 'package:bus_kahan_hay/screens/user/onBoardingFluid/fluid_edge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FluidCarousel extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback? onLastPageReached;

  const FluidCarousel({
    super.key,
    required this.children,
    this.onLastPageReached,
  });

  @override
  FluidCarouselState createState() => FluidCarouselState();
}

class FluidCarouselState extends State<FluidCarousel>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int? _dragIndex;
  Offset _dragOffset = Offset.zero;
  double _dragDirection = 0;
  bool _dragCompleted = false;

  FluidEdge edge = FluidEdge(count: 25);
  late Ticker _ticker;
  GlobalKey key = GlobalKey();

  @override
  void initState() {
    _ticker = createTicker(_tick)..start();
    super.initState();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration duration) {
    edge.tick(duration);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int l = widget.children.length;

    return Stack(
      children: [
        GestureDetector(
          key: key,
          onPanDown: (details) => _handlePanDown(details, _getSize()),
          onPanUpdate: (details) => _handlePanUpdate(details, _getSize()),
          onPanEnd: (details) => _handlePanEnd(details, _getSize()),
          child: Stack(
            children: <Widget>[
              widget.children[_index % l],
              _dragIndex == null
                  ? SizedBox()
                  : ClipPath(
                      clipBehavior: Clip.hardEdge,
                      clipper: FluidClipper(edge, margin: 10.0),
                      child: widget.children[_dragIndex! % l],
                    ),
            ],
          ),
        ),

        // Current page indicator at top
        Positioned(
          top: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(l, (dotIndex) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _index == dotIndex
                      ? Colors.white.withOpacity(0.0)
                      : Colors.white.withOpacity(0.0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Size _getSize() {
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? Size.zero;
  }

  void _handlePanDown(DragDownDetails details, Size size) {
    if (_dragIndex != null && _dragCompleted) {
      _index = _dragIndex!;
      if (_index >= widget.children.length - 1 &&
          widget.onLastPageReached != null) {
        widget.onLastPageReached!();
      }
    }
    _dragIndex = null;
    _dragOffset = details.localPosition;
    _dragCompleted = false;
    _dragDirection = 0;

    edge.farEdgeTension = 0.0;
    edge.edgeTension = 0.01;
    edge.reset();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    double dx = details.localPosition.dx - _dragOffset.dx;

    if (!_isSwipeActive(dx)) return;
    if (_isSwipeComplete(dx, size.width)) return;

    if (_dragDirection == -1) dx = size.width + dx;
    edge.applyTouchOffset(Offset(dx, details.localPosition.dy), size);
  }

  bool _isSwipeActive(double dx) {
    if (_dragDirection == 0.0 && dx.abs() > 20.0) {
      _dragDirection = dx.sign;
      edge.side = _dragDirection == 1.0 ? Side.left : Side.right;
      setState(() => _dragIndex = _index - _dragDirection.toInt());
    }
    return _dragDirection != 0.0;
  }

  bool _isSwipeComplete(double dx, double width) {
    if (_dragDirection == 0.0) return false;
    if (_dragCompleted) return true;

    double availW = _dragDirection == 1
        ? width - _dragOffset.dx
        : _dragOffset.dx;
    double ratio = dx * _dragDirection / availW;

    if (ratio > 0.8 && availW / width > 0.5) {
      _dragCompleted = true;
      edge.farEdgeTension = 0.01;
      edge.edgeTension = 0.0;
      edge.applyTouchOffset();
    }
    return _dragCompleted;
  }

  void _handlePanEnd(DragEndDetails details, Size size) {
    edge.applyTouchOffset();
  }
}
