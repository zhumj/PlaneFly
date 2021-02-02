import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plane_fly/res.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  AnimationController _animationController;
  Animation _animation;

  // 飞机尺寸
  Size planeSize;
  // 二阶贝塞尔曲线 p0：开始点、p1：控制点、p2：结束点
  Offset p0, p1, p2;
  // 矩阵
  Matrix4 _matrix4 = Matrix4.identity();
  // 移动轨迹点，即移动物的中心点
  Offset bezierCenter;
  // 当前移动距离
  Offset transSize = Offset(0.0, 0.0);

  /// 初始化动画
  _initAnim() {
    _animationController = AnimationController(duration: Duration(seconds: 3), vsync: this);
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    _animation.addListener(() {
      // t 动态变化的值
      var t = _animation.value;
      if (mounted) {
        setState(() {
          _matrix4 = Matrix4.identity();
          // 根据二阶贝塞尔曲线计算移动轨迹点
          double _left = pow(1 - t, 2) * p0.dx + 2 * t * (1 - t) * p1.dx + pow(t, 2) * p2.dx;
          double _top = pow(1 - t, 2) * p0.dy + 2 * t * (1 - t) * p1.dy + pow(t, 2) * p2.dy;
          // 设置移动
          if (bezierCenter == null) {
            transSize = Offset(0.0, 0.0);
          } else {
            transSize = Offset(transSize.dx - (bezierCenter.dx - _left),
                transSize.dy - (bezierCenter.dy - _top));
          }
          _matrix4..translate(transSize.dx, transSize.dy, 0.0);
          bezierCenter = Offset(_left, _top);
          // 设置缩小倍数
          _matrix4..scale((1-t) < 0.4 ? 0.4 : (1-t));
          // 设置旋转角度
          double rotate = pi/2*t;
          _matrix4..rotateX(rotate > rotate*0.8 ? rotate*0.8 : rotate);
          _matrix4..rotateY(rotate > rotate*0.8 ? -rotate*0.8 : -rotate);
          _matrix4..rotateZ(rotate > rotate*0.8 ? -rotate*0.8 : -rotate);
        });
      }
    });

  }

  // 初始化数值
  _calculateInitialValue(BuildContext context) {
    Size _size = MediaQuery.of(context).size;
    if (planeSize == null) {
      planeSize = Size(_size.width/4, _size.width/4);
    }
    if (p0 == null) {
      p0 = Offset(_size.width/2, _size.height/2);
      p1 = Offset(_size.width+_size.width/4, _size.height/4);
      p2 = Offset(_size.width*2/3, 0);
    }
  }

  @override
  void initState() {
    _initAnim();
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    _calculateInitialValue(context);

    return Stack(
      children: [
        Opacity(
          opacity: 0.4,
          child: Container(
            color: Colors.black,
          ),
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: BezierPainter(p0, p1, p2,),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              if (_animation.isCompleted || _animation.isDismissed) {
                _animationController.forward();
              }
            },
            child: Transform(
              transform: _matrix4,
              child: SvgPicture.asset(Res.svg_paper_plane, width: planeSize.width, height: planeSize.height,),
            ),
          ),
        ),
      ],
    );
  }
}

class BezierPainter extends CustomPainter {

  BezierPainter(this.p0, this.p1, this.p2,);

  Offset p0, p1, p2;

  @override
  void paint(Canvas canvas, Size size) {
    ///创建画笔
    var paint = Paint();
    ///设置画笔的颜色
    paint.color = Colors.red;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;

    if (p0 != null && p1 != null && p2 != null) {
      var path = Path();
      path.moveTo(p0.dx, p0.dy);
      path.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BezierPainter oldDelegate) {
    return p0 != oldDelegate.p0 || p1 != oldDelegate.p1 || p2 != oldDelegate.p2;
  }

}