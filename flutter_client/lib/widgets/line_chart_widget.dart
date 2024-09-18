import 'package:flutter/material.dart';
import 'package:flutter_client/constants/time_enums.dart';
import 'package:flutter_client/services/firebase_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({super.key, required this.scores, required this.range});
  final List<Score> scores;
  final TimeRange range;

  @override
  Widget build(BuildContext context) {
    List<Score> processedScores = scores; //_processScores(scores, range);

    return SfCartesianChart(
      title: const ChartTitle(text: 'Scores Over Time'),
      primaryXAxis: const DateTimeAxis(),
      primaryYAxis: const NumericAxis(
        maximum: 300,
        minimum: 0,
      ),
      series: <CartesianSeries>[
        LineSeries<Score, DateTime>(
          dataSource: processedScores,
          xValueMapper: (Score score, _) => score.timestamp,
          yValueMapper: (Score score, _) => score.score,
        )
      ],
    );
  }

  // List<Score> _processScores(List<Score> scores, TimeRange range) {}
}
