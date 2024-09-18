import 'package:flutter/material.dart';
import 'package:flutter_client/constants/time_enums.dart';
import 'package:flutter_client/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});
  @override
  ReadingScreenState createState() => ReadingScreenState();
}

class ReadingScreenState extends State<ReadingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Score>> _scoresFuture;
  Score? _currentScore;
  TimeRange _range = TimeRange.day;

  @override
  void initState() {
    super.initState();
    _scoresFuture = loadScores();
  }

  Future<List<Score>> loadScores() async {
    List<Score> scores = await _firebaseService.getScores(
      getStartOfRange(_range),
      DateTime.now(),
    );
    setState(() {
      _currentScore = scores.isNotEmpty ? scores.last : null;
    });
    return aggregateData(scores, _range);
  }

  Future<void> onRefresh() async {
    setState(() {
      _scoresFuture = loadScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading Screen')),
      body: Column(
        children: [
          DropdownMenu(
            dropdownMenuEntries: TimeRange.values
                .map(
                  (e) => DropdownMenuEntry(
                    value: e,
                    label: e.toString().split('.').last,
                  ),
                )
                .toList(),
            onSelected: (value) {
              setState(() {
                _range = value!;
                _scoresFuture = loadScores();
              });
            },
            initialSelection: _range,
          ),
          Expanded(
            child: FutureBuilder<List<Score>>(
              future: _scoresFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No scores available'));
                } else {
                  List<Score> scores = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 400,
                              width: double.infinity,
                              child: SfCartesianChart(
                                primaryXAxis: DateTimeAxis(
                                  title: const AxisTitle(text: 'Time'),
                                  dateFormat: _getDateFormat(_range),
                                  minimum: getStartOfRange(_range),
                                  maximum: DateTime.now(),
                                ),
                                primaryYAxis: const NumericAxis(
                                  maximum: 100,
                                  minimum: 0,
                                  title: AxisTitle(text: 'Score'),
                                ),
                                series: <CartesianSeries>[
                                  LineSeries<Score, DateTime>(
                                    dataSource: scores,
                                    xValueMapper: (Score score, _) =>
                                        score.timestamp,
                                    yValueMapper: (Score score, _) =>
                                        score.score,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Latest Score: ${_currentScore?.score ?? 'N/A'}',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

DateTime getStartOfRange(TimeRange range) {
  DateTime now = DateTime.now();
  switch (range) {
    case TimeRange.hour:
      return DateTime(now.year, now.month, now.day, now.hour, 0, 0);
    case TimeRange.day:
      return DateTime(now.year, now.month, now.day, 0, 0, 0);
    case TimeRange.month:
      return DateTime(now.year, now.month, 1, 0, 0, 0);
    case TimeRange.year:
      return DateTime(now.year, 1, 1, 0, 0, 0);
    default:
      return DateTime(now.year, now.month, now.day);
  }
}

DateFormat _getDateFormat(TimeRange range) {
  switch (range) {
    case TimeRange.hour:
      return DateFormat.ms(); // Hour and minute
    case TimeRange.day:
      return DateFormat.Hm(); // Month and day
    case TimeRange.month:
      return DateFormat.MMMd(); // Month and day
    case TimeRange.year:
      return DateFormat.M(); // Year
    default:
      return DateFormat.MMMd(); // Default to month and day
  }
}

List<Score> aggregateData(List<Score> scores, TimeRange interval) {
  Map<DateTime, List<Score>> groupedScores = {};

  for (var score in scores) {
    DateTime key;
    switch (interval) {
      case TimeRange.hour:
        key = DateTime(score.timestamp.year, score.timestamp.month,
            score.timestamp.day, score.timestamp.hour, score.timestamp.minute);
        break;
      case TimeRange.day:
        // Group by 30-minute intervals within the day
        int minute = score.timestamp.minute;
        int roundedMinute =
            (minute ~/ 30) * 30; // Round down to nearest 30-minute mark
        key = DateTime(score.timestamp.year, score.timestamp.month,
            score.timestamp.day, score.timestamp.hour, roundedMinute);
        break;
      case TimeRange.month:
        // Aggregate data into daily intervals
        key = DateTime(
            score.timestamp.year, score.timestamp.month, score.timestamp.day);
        break;
      case TimeRange.year:
        // Aggregate data into monthly intervals
        key = DateTime(score.timestamp.year, score.timestamp.month);
        break;
      default:
        key = score.timestamp;
    }

    if (!groupedScores.containsKey(key)) {
      groupedScores[key] = [];
    }
    groupedScores[key]!.add(score);
  }

  return groupedScores.entries.map((entry) {
    DateTime time = entry.key;
    double avgScore;
    if (entry.value.isEmpty) {
      avgScore = 0;
    } else {
      avgScore = entry.value.map((s) => s.score).reduce((a, b) => a + b) /
          entry.value.length;
    }
    return Score(score: avgScore, timestamp: time);
  }).toList();
}
