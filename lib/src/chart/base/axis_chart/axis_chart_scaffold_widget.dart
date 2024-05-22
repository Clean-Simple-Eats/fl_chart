import 'package:fl_chart/fl_chart.dart';
import 'package:fl_chart/src/chart/base/axis_chart/side_titles/side_titles_widget.dart';
import 'package:fl_chart/src/extensions/fl_titles_data_extension.dart';
import 'package:fl_chart/src/extensions/side_titles_extension.dart';
import 'package:flutter/material.dart';

/// A scaffold to show an axis-based chart
///
/// It contains some placeholders to represent an axis-based chart.
///
/// It's something like the below graph:
/// |----------------------|
/// |      |  top  |       |
/// |------|-------|-------|
/// | left | chart | right |
/// |------|-------|-------|
/// |      | bottom|       |
/// |----------------------|
///
/// `left`, `top`, `right`, `bottom` are some place holders to show titles
/// provided by [AxisChartData.titlesData] around the chart
/// `chart` is a centered place holder to show a raw chart.
class AxisChartScaffoldWidget extends StatefulWidget {
  const AxisChartScaffoldWidget({
    super.key,
    required this.chart,
    required this.data,
  });

  final Widget chart;
  final AxisChartData data;

  @override
  State<AxisChartScaffoldWidget> createState() =>
      _AxisChartScaffoldWidgetState();
}

class _AxisChartScaffoldWidgetState extends State<AxisChartScaffoldWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController =
        widget.data.horizontalZoomConfig.scrollController ?? ScrollController();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AxisChartScaffoldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data == oldWidget.data) {
      return;
    }

    if (!scrollController.hasClients) {
      return;
    }

    scrollController.jumpTo(scrollController.offset);
  }

  @override
  void dispose() {
    if (widget.data.horizontalZoomConfig.scrollController == null) {
      scrollController.dispose();
    }
    super.dispose();
  }

  bool get showLeftTitles {
    if (!widget.data.titlesData.show) {
      return false;
    }
    final showAxisTitles = widget.data.titlesData.leftTitles.showAxisTitles;
    final showSideTitles = widget.data.titlesData.leftTitles.showSideTitles;
    return showAxisTitles || showSideTitles;
  }

  bool get showRightTitles {
    if (!widget.data.titlesData.show) {
      return false;
    }
    final showAxisTitles = widget.data.titlesData.rightTitles.showAxisTitles;
    final showSideTitles = widget.data.titlesData.rightTitles.showSideTitles;
    return showAxisTitles || showSideTitles;
  }

  bool get showTopTitles {
    if (!widget.data.titlesData.show) {
      return false;
    }
    final showAxisTitles = widget.data.titlesData.topTitles.showAxisTitles;
    final showSideTitles = widget.data.titlesData.topTitles.showSideTitles;
    return showAxisTitles || showSideTitles;
  }

  bool get showBottomTitles {
    if (!widget.data.titlesData.show) {
      return false;
    }
    final showAxisTitles = widget.data.titlesData.bottomTitles.showAxisTitles;
    final showSideTitles = widget.data.titlesData.bottomTitles.showSideTitles;
    return showAxisTitles || showSideTitles;
  }

  List<Widget> stackWidgets(BoxConstraints constraints) {
    final chartWidth = constraints.maxWidth -
        widget.data.titlesData.allSidesPadding.horizontal;

    final xDelta = widget.data.maxX - widget.data.minX;
    final largeChartWidth = xDelta * widget.data.horizontalZoomConfig.amount;

    final widgets = <Widget>[
      Container(
        margin: widget.data.titlesData.allSidesPadding,
        decoration: BoxDecoration(
          border: widget.data.borderData.isVisible()
              ? widget.data.borderData.border
              : null,
        ),
        child: switch (widget.data.horizontalZoomConfig.enabled) {
          true => SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: largeChartWidth,
                height: constraints.maxHeight,
                child: widget.chart,
              ),
            ),
          false => SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: widget.chart,
            ),
        },
      ),
    ];

    int insertIndex(bool drawBelow) => drawBelow ? 0 : widgets.length;

    double? axisMinXOverride;
    double? axisMaxXOverride;
    if (scrollController.hasClients) {
      final xAmount = widget.data.horizontalZoomConfig.amount;
      final showingXDelta = chartWidth / xAmount;
      axisMinXOverride = scrollController.offset / xAmount;
      axisMaxXOverride = axisMinXOverride + showingXDelta;
    }

    if (showLeftTitles) {
      widgets.insert(
        insertIndex(widget.data.titlesData.leftTitles.drawBelowEverything),
        SideTitlesWidget(
          side: AxisSide.left,
          axisChartData: widget.data,
          parentSize: constraints.biggest,
        ),
      );
    }

    if (showTopTitles) {
      widgets.insert(
        insertIndex(widget.data.titlesData.topTitles.drawBelowEverything),
        SideTitlesWidget(
          side: AxisSide.top,
          axisChartData: widget.data,
          parentSize: constraints.biggest,
          axisMinOverride: axisMinXOverride,
          axisMaxOverride: axisMaxXOverride,
        ),
      );
    }

    if (showRightTitles) {
      widgets.insert(
        insertIndex(widget.data.titlesData.rightTitles.drawBelowEverything),
        SideTitlesWidget(
          side: AxisSide.right,
          axisChartData: widget.data,
          parentSize: constraints.biggest,
        ),
      );
    }

    if (showBottomTitles) {
      widgets.insert(
        insertIndex(widget.data.titlesData.bottomTitles.drawBelowEverything),
        ClipRect(
          clipper: _AxisChartHorizontalClipper(
            axisChartData: widget.data,
            axisSide: AxisSide.bottom,
          ),
          child: Transform.translate(
            offset: Offset((axisMinXOverride ?? 0) * -1, 0),
            child: SideTitlesWidget(
              side: AxisSide.bottom,
              axisChartData: widget.data,
              parentSize: constraints.biggest,
              axisMinOverride: axisMinXOverride,
              axisMaxOverride: axisMaxXOverride,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scrollController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: stackWidgets(constraints),
            );
          },
        );
      },
    );
  }
}

class _AxisChartHorizontalClipper extends CustomClipper<Rect> {
  _AxisChartHorizontalClipper({
    required this.axisChartData,
    required this.axisSide,
  });

  final AxisChartData axisChartData;
  final AxisSide axisSide;

  @override
  Rect getClip(Size size) {
    final bottomAxisTitle = axisChartData.titlesData.bottomTitles;
    final leftAxisTitle = axisChartData.titlesData.leftTitles;
    final rightAxisTitle = axisChartData.titlesData.rightTitles;
    final axisViewSize = axisSide == AxisSide.bottom || axisSide == AxisSide.top
        ? size.width
        : size.height;
    final thisSidePaddingTotal = bottomAxisTitle.showAxisTitles
        ? axisChartData.titlesData.allSidesPadding.horizontal
        : 0.0;

    var horizontalPadding = 0.0;

    if (leftAxisTitle.showSideTitles) {
      horizontalPadding += leftAxisTitle.totalReservedSize - 8;
    }
    if (rightAxisTitle.showSideTitles) {
      horizontalPadding += rightAxisTitle.totalReservedSize - 8;
    }

    return Rect.fromLTWH(
      horizontalPadding,
      0,
      axisViewSize - thisSidePaddingTotal - horizontalPadding,
      axisViewSize,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}
