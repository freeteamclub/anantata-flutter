import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'xela_color.dart';
import 'xela_text_style.dart';
import 'models/xela_chart_models.dart';
import 'dart:math' as math;

class XelaChart extends StatefulWidget {

  final XelaChartType type;
  final List<String>? labels;
  final List<XelaLineChartDataset>? datasetsLineChart;
  final List<XelaBarChartDataset>? datasetsBarChart;
  final XelaPieChartDataset? datasetPieChart;
  final List<XelaDoughnutDataset>? datasetsDoughnutChart;
  final Color labelsColor;
  final Color chartBorderColor;
  final Color pieBackgroundColor;
  final double dataStep;
  final double doughnutStrokeWidth;
  final intl.NumberFormat? dataLabelFormat;
  final double height;
  final String beforeData;
  final String afterData;


  XelaChart({
    required this.height,
    required this.type,
    this.labels,
    this.datasetsLineChart,
    this.datasetsBarChart,
    this.datasetPieChart,
    this.datasetsDoughnutChart,
    this.labelsColor = XelaColor.Gray6,
    this.chartBorderColor = XelaColor.Gray12,
    this.pieBackgroundColor = XelaColor.Gray11,
    this.dataStep = 10,
    this.doughnutStrokeWidth = 12,
    this.dataLabelFormat,
    this.afterData = "",
    this.beforeData = ""
  });

  @override
  _XelaChartState createState() => _XelaChartState();
}

class _XelaChartState extends State<XelaChart> {
  _XelaChartState();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {

    // Clean up the focus nodes
    // when the form is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    double minData = double.nan;
    double maxData = double.nan;

    if(widget.datasetsLineChart != null) {
      for(var dataset in widget.datasetsLineChart!) {
        for(var data in dataset.data) {
          if(minData.isNaN) {
            minData = data;
          }
          else {
            if(minData > data) {
              minData = data;
            }
          }

          if(maxData.isNaN) {
            maxData = data;
          }
          else {
            if(maxData < data) {
              maxData = data;
            }
          }
        }
      }
    }

    if(widget.datasetsBarChart != null) {
      for(var dataset in widget.datasetsBarChart!) {
        for(var data in dataset.data) {
          if(minData.isNaN) {
            minData = data;
          }
          else {
            if(minData > data) {
              minData = data;
            }
          }

          if(maxData.isNaN) {
            maxData = data;
          }
          else {
            if(maxData < data) {
              maxData = data;
            }
          }
        }
      }
    }



    if(widget.datasetsLineChart != null && widget.labels != null && widget.type == XelaChartType.LINE) {
      double fromStep = maxData +
          (widget.dataStep - (maxData % widget.dataStep));
      double toStep = minData - (widget.dataStep - (minData % widget.dataStep));
      double stepsCountDouble = (fromStep - toStep) / widget.dataStep;
      int stepsCount = stepsCountDouble.toInt();
      if ((stepsCountDouble - stepsCount.toDouble()) > 0) {
        stepsCount += 1;
      }
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: CustomPaint(
          painter: XelaLineChartPainter(
              labels: widget.labels!,
              step: widget.dataStep,
              fromStep: fromStep,
              toStep: toStep,
              stepsCount: stepsCount,
              labelsColor: widget.labelsColor,
              borderColor: widget.chartBorderColor,
              datasets: widget.datasetsLineChart!,
              minData: minData,
            beforeData: widget.beforeData,
            afterData: widget.afterData
          ),
        ),
      );
    }
    else if(widget.datasetsBarChart != null && widget.labels != null && widget.type == XelaChartType.BAR) {
      double fromStep = maxData +
          (widget.dataStep - (maxData % widget.dataStep));
      double toStep = minData - (widget.dataStep - (minData % widget.dataStep));
      double stepsCountDouble = (fromStep - toStep) / widget.dataStep;
      int stepsCount = stepsCountDouble.toInt();
      if ((stepsCountDouble - stepsCount.toDouble()) > 0) {
        stepsCount += 1;
      }
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: CustomPaint(
          painter: XelaBarChartPainter(
              labels: widget.labels!,
              step: widget.dataStep,
              fromStep: fromStep,
              toStep: toStep,
              stepsCount: stepsCount,
              labelsColor: widget.labelsColor,
              borderColor: widget.chartBorderColor,
              datasets: widget.datasetsBarChart!,
              minData: minData,
              beforeData: widget.beforeData,
              afterData: widget.afterData
          ),
        ),
      );
    }
    else if(widget.datasetPieChart != null && widget.type == XelaChartType.PIE) {
      return AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: CustomPaint(
                painter: XelaPieChartPainter(
                    dataset: widget.datasetPieChart!,
                    background: widget.pieBackgroundColor
                )
            )
        ),
      );
    }
    else if(widget.datasetsDoughnutChart != null && widget.type == XelaChartType.DOUGHNUT) {
      return AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: CustomPaint(
                painter: XelaDoughnutChartPainter(
                    datasets: widget.datasetsDoughnutChart!,
                    strokeWidth: widget.doughnutStrokeWidth
                )
            )
        ),
      );
    }
    else {
      return Container();
    }


  }
}

class XelaDoughnutChartPainter extends CustomPainter {
  final List<XelaDoughnutDataset> datasets;
  final double strokeWidth;
  XelaDoughnutChartPainter({
    required this.datasets,
    required this.strokeWidth
  });

  @override
  void paint(Canvas canvas, Size size) {



    for(var j = 0; j < datasets.length; j++) {
      var dataset = datasets[j];
      double sum = 0;
      for(var data in dataset.data) {
        sum += data;
      }

      var center = Offset(size.width/2, size.height/2);

      var circleSize = size.height - strokeWidth*4*j;

      double tempEndDegrees = -90;
      for(var i = 0; i < dataset.data.length; i++) {
        var data = dataset.data[i];
        var paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..color = dataset.fillColors[i];

        double temp = data * 360 / sum;
        double startDegrees = tempEndDegrees;
        tempEndDegrees += temp;

        canvas.drawArc(Rect.fromCenter(center: center, width: circleSize, height: circleSize), startDegrees * math.pi / 180, (tempEndDegrees - startDegrees) * math.pi / 180, false, paint);
      }

    }





  }

  @override
  bool shouldRepaint(XelaDoughnutChartPainter oldDelegate) {
    return true;
  }

}

class XelaPieChartPainter extends CustomPainter {
  final XelaPieChartDataset dataset;
  final Color background;
  XelaPieChartPainter({
    required this.dataset,
    required this.background
  });

  @override
  void paint(Canvas canvas, Size size) {

    double sum = 0;
    for(var data in dataset.data) {
      sum += data;
    }

    var paintBg = Paint()
      ..style = PaintingStyle.fill
      ..color = background;

    var center = Offset(size.width/2, size.height/2);

    canvas.drawCircle(center, size.height/2, paintBg);
    double tempEndDegrees = -90;
    for(var i = 0; i < dataset.data.length; i++) {
      var data = dataset.data[i];
      var paint = Paint()
        ..style = PaintingStyle.fill
        ..color = dataset.fillColors[i];

      double temp = data * 360 / sum;
      double startDegrees = tempEndDegrees;
      tempEndDegrees += temp;
      canvas.drawArc(Rect.fromCenter(center: center, width: size.height, height: size.height), startDegrees * math.pi / 180, (tempEndDegrees - startDegrees) * math.pi / 180, true, paint);
    }

  }


  @override
  bool shouldRepaint(XelaPieChartPainter oldDelegate) {
    return true;
  }


}

class XelaBarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<XelaBarChartDataset> datasets;
  final Color labelsColor;
  final Color borderColor;
  final double step;
  final double fromStep;
  final double toStep;
  final int stepsCount;
  intl.NumberFormat? numberFormat;
  final double minData;
  final String beforeData;
  final String afterData;

  XelaBarChartPainter({
    required this.labels,
    required this.datasets,
    required this.labelsColor,
    required this.borderColor,
    required this.step,
    required this.fromStep,
    required this.toStep,
    required this.stepsCount,
    required this.minData,
    this.numberFormat,
    required this.beforeData,
    required this.afterData
  });

  Paint borderLinePaint = Paint()
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    borderLinePaint.color = borderColor;

    numberFormat ??= intl.NumberFormat("0", "en");

    var leftOffset = 32;
    var bottomOffset = 24;
    var rowWidth = (size.width - leftOffset)/labels.length.toDouble();

    double firstStep = fromStep - step*stepsCount;

    var rowHeight = (size.height - bottomOffset)/((stepsCount)+((firstStep + step) >= minData ? 1 : 0) - 1).toDouble();

    for(var i = 0; i < labels.length; i++) {
      var labelSpan = TextSpan(
          text: labels[i],
          style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
      );
      var labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center
      );
      labelPainter.layout(
          minWidth: rowWidth,
          maxWidth: rowWidth
      );
      var labelOffset = Offset(rowWidth*i+leftOffset, size.height - bottomOffset);
      labelPainter.paint(canvas, labelOffset);



      for(var j = 0; j < datasets.length; j++) {
        var data = datasets[j].data[i];

        borderLinePaint.strokeWidth = rowWidth - 8;

        borderLinePaint.strokeWidth = borderLinePaint.strokeWidth/datasets.length;

        borderLinePaint.color = borderColor;

        var lineX = rowWidth*i+leftOffset + 4;

        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(Offset(lineX+2+((borderLinePaint.strokeWidth)*j), 0), Offset(lineX+(borderLinePaint.strokeWidth*(j+1)), size.height - bottomOffset)), Radius.circular(datasets.length > 2 ? 4 : (14 - datasets.length*4))), borderLinePaint);

        borderLinePaint.color = datasets[j].fillColor;
        var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - (minData <= 0 ? 0 : 1)*rowHeight*(-firstStep/step - ((firstStep + step) >= minData ? 0 : 1));

        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromPoints(Offset(lineX+2+((borderLinePaint.strokeWidth)*j), yLine), Offset(lineX+(borderLinePaint.strokeWidth*(j+1)), size.height - bottomOffset)), Radius.circular(datasets.length > 2 ? 4 : (14 - datasets.length*4))), borderLinePaint);
      }


    }




    for(var j = 0; j < stepsCount + (((firstStep + step) >= minData ? 1 : 0)); j++) {

      var labelSpan = TextSpan(
          text: beforeData+numberFormat!.format(fromStep - step*j).toString()+afterData,
          style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
      );
      var labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right
      );
      labelPainter.layout(
        minWidth: leftOffset.toDouble()-4,
        maxWidth: leftOffset.toDouble()-4,
      );

      var lineY = rowHeight*j;

      borderLinePaint.strokeWidth = 1;

      var labelOffset = Offset(0, lineY - (j == 0 ? 0 : j == (stepsCount + (((firstStep + step) >= minData ? 1 : 0))-1) ? labelSpan.style!.fontSize! : labelSpan.style!.fontSize!/2) - 1);
      labelPainter.paint(canvas, labelOffset);

      // var linePath = Path();
      // linePath.moveTo(leftOffset.toDouble()+6, lineY);
      // linePath.lineTo(size.width - leftOffset*0.5 + 6, lineY);
      // canvas.drawPath(linePath, borderLinePaint);
    }
  }

  @override
  bool shouldRepaint(XelaBarChartPainter oldDelegate) {
    return true;
  }

}


class XelaLineChartPainter extends CustomPainter {

  final List<String> labels;
  final double step;
  final double fromStep;
  final double toStep;
  final int stepsCount;
  final Color labelsColor;
  final Color borderColor;
  intl.NumberFormat? numberFormat;
  final List<XelaLineChartDataset> datasets;
  final double minData;
  final String beforeData;
  final String afterData;

  XelaLineChartPainter({
    required this.labels,
    required this.step,
    required this.fromStep,
    required this.toStep,
    required this.stepsCount,
    required this.labelsColor,
    required this.borderColor,
    this.numberFormat,
    required this.datasets,
    required this.minData,
    required this.beforeData,
    required this.afterData
  });

  Paint borderLinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  Paint linePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  Paint fillPaint = Paint()
    ..style = PaintingStyle.fill;

  Paint pointBgPaint = Paint()
    ..style = PaintingStyle.fill;

  Paint pointStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {

    borderLinePaint.color = borderColor;

    numberFormat ??= intl.NumberFormat("0", "en");

      var leftOffset = 32;
      var bottomOffset = 24;
      var rowWidth = (size.width - leftOffset*1.5)/(labels.length.toDouble()-1);

      for(var i = 0; i < labels.length; i++) {
        var labelSpan = TextSpan(
          text: labels[i],
          style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
        );
        var labelPainter = TextPainter(
          text: labelSpan,
            textDirection: TextDirection.ltr,
          //textAlign: i == 0 ? TextAlign.right : i == labels.length - 1 ? TextAlign.left : TextAlign.center
          textAlign: TextAlign.center
        );
        labelPainter.layout(
          minWidth: rowWidth,
          maxWidth: rowWidth
        );

        var lineX = (rowWidth)*i+leftOffset + borderLinePaint.strokeWidth*6;

        var labelOffset = Offset(lineX - rowWidth/2, size.height - bottomOffset + 6);
        labelPainter.paint(canvas, labelOffset);

        //var lineX = (rowWidth)*i+leftOffset + borderLinePaint.strokeWidth*5;
        var linePath = Path();
        linePath.moveTo(lineX, 0);
        linePath.lineTo(lineX, size.height - bottomOffset);
        canvas.drawPath(linePath, borderLinePaint);

      }

      double firstStep = fromStep - step*stepsCount;

      var rowHeight = (size.height - bottomOffset)/((stepsCount)+((firstStep + step) >= minData ? 1 : 0) - 1).toDouble();


      for(var j = 0; j < stepsCount + (((firstStep + step) >= minData ? 1 : 0)); j++) {

        var labelSpan = TextSpan(
            text: beforeData+numberFormat!.format(fromStep - step*j).toString()+afterData,
            style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
        );
        var labelPainter = TextPainter(
            text: labelSpan,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right
        );
        labelPainter.layout(
            minWidth: leftOffset.toDouble()-4,
            maxWidth: leftOffset.toDouble()-4,
        );

        var lineY = rowHeight*j;

        var labelOffset = Offset(0, lineY - (j == 0 ? 0 : j == (stepsCount + (((firstStep + step) >= minData ? 1 : 0))-1) ? labelSpan.style!.fontSize! : labelSpan.style!.fontSize!/2) - 1);
        labelPainter.paint(canvas, labelOffset);

        var linePath = Path();
        linePath.moveTo(leftOffset.toDouble()+6, lineY);
        linePath.lineTo(size.width - leftOffset*0.5 + 6, lineY);
        canvas.drawPath(linePath, borderLinePaint);
      }


      for(var i = 0; i < datasets.length; i++) {
        var dataset = datasets[i];
        linePaint.color = dataset.lineColor;
        fillPaint.color = dataset.fillColor != Colors.transparent ? dataset.fillColor.withOpacity(0.24) : Colors.transparent;
        var prevOffset = const Offset(0, 0);
        var pathLine = Path();
        var path = Path();
        for(var j = 0; j < dataset.data.length; j++) {
          var data = dataset.data[j];
          var xLine = rowWidth*j+leftOffset+6;
          var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - (minData <= 0 ? 1 : 0)*rowHeight*(-firstStep/step - ((firstStep + step) >= minData ? 0 : 1));
          var offset = Offset(xLine, yLine);

          if(j == 0) {
            path.moveTo(offset.dx, size.height - bottomOffset);
            path.lineTo(offset.dx, offset.dy);
            pathLine.moveTo(offset.dx, offset.dy);
            prevOffset = offset;
          }
          else {
            var deltaX = offset.dx - prevOffset.dx;
            var curveXOffset = deltaX * dataset.tension;
            pathLine.cubicTo(prevOffset.dx + curveXOffset, prevOffset.dy, offset.dx - curveXOffset, offset.dy, offset.dx, offset.dy);
            path.cubicTo(prevOffset.dx + curveXOffset, prevOffset.dy, offset.dx - curveXOffset, offset.dy, offset.dx, offset.dy);
            prevOffset = offset;

          }

          if(j == (dataset.data.length - 1)) {
            path.lineTo(offset.dx, size.height - bottomOffset);
          }
        }

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(pathLine, linePaint);

        if(dataset.pointColor != Colors.transparent) {

          pointBgPaint.color = dataset.pointColorBackground;
          pointStrokePaint.color = dataset.pointColor;

          for(var j = 0; j < dataset.data.length; j++) {
            var data = dataset.data[j];
            var xLine = rowWidth*j+leftOffset+6;
            var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - (minData <= 0 ? 1 : 0)*rowHeight*(-firstStep/step - ((firstStep + step) >= minData ? 0 : 1));

            var offset = Offset(xLine, yLine);
            canvas.drawCircle(offset, 4, pointBgPaint);
            canvas.drawCircle(offset, 4, pointStrokePaint);
          }
        }
      }
  }

  @override
  bool shouldRepaint(XelaLineChartPainter oldDelegate) {
    return true;
  }


}

class XelaLineChartOLDPainter extends CustomPainter {

  final List<String> labels;
  final double step;
  final double fromStep;
  final double toStep;
  final int stepsCount;
  final Color labelsColor;
  final Color borderColor;
  intl.NumberFormat? numberFormat;
  final List<XelaLineChartDataset> datasets;
  final double minData;

  XelaLineChartOLDPainter({
    required this.labels,
    required this.step,
    required this.fromStep,
    required this.toStep,
    required this.stepsCount,
    required this.labelsColor,
    required this.borderColor,
    this.numberFormat,
    required this.datasets,
    required this.minData
  });

  Paint borderLinePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  Paint linePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;

  Paint fillPaint = Paint()
    ..style = PaintingStyle.fill;

  Paint pointBgPaint = Paint()
    ..style = PaintingStyle.fill;

  Paint pointStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {

    borderLinePaint.color = borderColor;

    numberFormat ??= intl.NumberFormat("0", "en");

    var leftOffset = 32;
    var bottomOffset = 24;
    var rowWidth = (size.width - leftOffset)/labels.length.toDouble();

    for(var i = 0; i < labels.length; i++) {
      var labelSpan = TextSpan(
          text: labels[i],
          style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
      );
      var labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center
      );
      labelPainter.layout(
          minWidth: rowWidth,
          maxWidth: rowWidth
      );
      var labelOffset = Offset(rowWidth*i+leftOffset, size.height - bottomOffset);
      labelPainter.paint(canvas, labelOffset);

      var lineX = rowWidth*i+leftOffset + rowWidth/2 - borderLinePaint.strokeWidth + 1;
      var linePath = Path();
      linePath.moveTo(lineX, 0);
      linePath.lineTo(lineX, size.height - bottomOffset);
      canvas.drawPath(linePath, borderLinePaint);
    }

    double firstStep = fromStep - step*stepsCount;

    var rowHeight = (size.height - bottomOffset)/(stepsCount+((firstStep + step) >= minData ? 1 : 0)).toDouble();


    for(var j = 0; j < stepsCount + (((firstStep + step) >= minData ? 1 : 0)); j++) {

      var labelSpan = TextSpan(
          text: numberFormat!.format(fromStep - step*j).toString(),
          style: XelaTextStyle.XelaCaption.apply(color: labelsColor)
      );
      var labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right
      );
      labelPainter.layout(
        minWidth: leftOffset.toDouble(),
        maxWidth: leftOffset.toDouble(),
      );

      var lineY = rowHeight*j + rowHeight/2;

      var labelOffset = Offset(0, lineY - labelSpan.style!.fontSize!/2 - 1);
      labelPainter.paint(canvas, labelOffset);

      var linePath = Path();
      linePath.moveTo(leftOffset.toDouble()+6, lineY);
      linePath.lineTo(size.width, lineY);
      canvas.drawPath(linePath, borderLinePaint);
    }


    for(var i = 0; i < datasets.length; i++) {
      var dataset = datasets[i];
      linePaint.color = dataset.lineColor;
      fillPaint.color = dataset.fillColor.withOpacity(0.24);
      var prevOffset = const Offset(0, 0);
      var pathLine = Path();
      var path = Path();
      for(var j = 0; j < dataset.data.length; j++) {
        var data = dataset.data[j];
        var xLine = rowWidth*j+leftOffset + rowWidth/2;
        var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - rowHeight/2 - (minData <= 0 ? 1 : 0)*rowHeight*(-firstStep/step - ((firstStep + step) >= minData ? 0 : 1));
        //var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - rowHeight/2;
        var offset = Offset(xLine, yLine);

        if(j == 0) {
          path.moveTo(offset.dx, size.height - bottomOffset);
          path.lineTo(offset.dx, offset.dy);
          pathLine.moveTo(offset.dx, offset.dy);
          prevOffset = offset;
        }
        else {
          var deltaX = offset.dx - prevOffset.dx;
          var curveXOffset = deltaX * dataset.tension;
          pathLine.cubicTo(prevOffset.dx + curveXOffset, prevOffset.dy, offset.dx - curveXOffset, offset.dy, offset.dx, offset.dy);
          path.cubicTo(prevOffset.dx + curveXOffset, prevOffset.dy, offset.dx - curveXOffset, offset.dy, offset.dx, offset.dy);
          prevOffset = offset;

        }

        if(j == (dataset.data.length - 1)) {
          path.lineTo(offset.dx, size.height - bottomOffset);
        }
      }

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(pathLine, linePaint);

      if(dataset.pointColor != Colors.transparent) {

        pointBgPaint.color = dataset.pointColorBackground;
        pointStrokePaint.color = dataset.pointColor;

        for(var j = 0; j < dataset.data.length; j++) {
          var data = dataset.data[j];
          var xLine = rowWidth*j+leftOffset + rowWidth/2;
          var yLine = (size.height - bottomOffset) - ((data)*(rowHeight/step)) - rowHeight/2 - (minData <= 0 ? 1 : 0)*rowHeight*(-firstStep/step - ((firstStep + step) >= minData ? 0 : 1));

          var offset = Offset(xLine, yLine);
          canvas.drawCircle(offset, 4, pointBgPaint);
          canvas.drawCircle(offset, 4, pointStrokePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(XelaLineChartPainter oldDelegate) {
    return true;
  }


}