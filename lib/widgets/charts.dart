import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/models/pet.dart';

class WeeklyNutrientGraph extends StatefulWidget {
  final double width;
  final double height;
  final Pet pet;

  const WeeklyNutrientGraph({required this.width, required this.height, required this.pet, super.key});

  @override
  State<StatefulWidget> createState() => _WeeklyNutrientGraphState();
}

class _WeeklyNutrientGraphState extends State<WeeklyNutrientGraph> {
  static const double barWidth = 30;
  static const double barSpacing = 15;
  bool showCalories = true;
  late Map<int, double> weeklyCalorieIntake;
  late Map<int, List<double>> macroIntake;

  @override
  void initState() {
    super.initState();

    print("🔍 Debugging Weekly Nutrients: ${widget.pet.weeklyNutrients}");

    weeklyCalorieIntake = {
      0: widget.pet.weeklyNutrients?["Sunday"]?["Calories"].toDouble(),
      1: widget.pet.weeklyNutrients?["Monday"]?["Calories"].toDouble(),
      2: widget.pet.weeklyNutrients?["Tuesday"]?["Calories"].toDouble(),
      3: widget.pet.weeklyNutrients?["Wednesday"]?["Calories"].toDouble(),
      4: widget.pet.weeklyNutrients?["Thursday"]?["Calories"].toDouble(),
      5: widget.pet.weeklyNutrients?["Friday"]?["Calories"].toDouble(),
      6: widget.pet.weeklyNutrients?["Saturday"]?["Calories"].toDouble(),
    };

    macroIntake = {
      0: extractMacros("Sunday"),
      1: extractMacros("Monday"),
      2: extractMacros("Tuesday"),
      3: extractMacros("Wednesday"),
      4: extractMacros("Thursday"),
      5: extractMacros("Friday"),
      6: extractMacros("Saturday"),
    };
  }

  List<double> extractMacros(String day) {
    final nutrients = widget.pet.weeklyNutrients?[day] ?? {};
    return [
      nutrients["Carbohydrates"].toDouble() ?? 0.0, // Carbohydrates
      nutrients["Crude Protein"].toDouble()?? 0.0, // Protein
      nutrients["Crude Fat"].toDouble() ?? 0.0,     // Fat
    ];
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold);
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Sun';
        break;
      case 1:
        text = 'Mon';
        break;
      case 2:
        text = 'Tue';
        break;
      case 3:
        text = 'Wed';
        break;
      case 4:
        text = 'Thu';
        break;
      case 5:
        text = 'Fri';
        break;
      case 6:
        text = 'Sat';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      meta: meta,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: style),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold);
    String text = value.toInt().toString(); // Convert the actual number without modification

    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }


  BarChartGroupData generateCaloriesGroup(int x, double calories) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: calories,
          width: barWidth,
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue,
        ),
      ],
    );
  }

  BarChartGroupData generateMacrosGroup(int x, double protein, double carbs, double fats) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: protein, width: 8, color: Colors.green),
        BarChartRodData(toY: carbs, width: 8, color: Colors.yellow),
        BarChartRodData(toY: fats, width: 8, color: Colors.pink),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.swap_horiz, color: Colors.white),
                onPressed: () {
                  setState(() {
                    showCalories = !showCalories;
                  });
                },
              ),
            ),
            SizedBox(
              width: widget.width,
              height: widget.height - 50,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: showCalories 
                    ? ((widget.pet.calorieRequirement / 100).round() * 100) + 100 
                    : (((widget.pet.nutritionalRequirements["Carbohydrates"] ?? 0) / 100).round() * 100) + 100,
                  minY: 0,
                  groupsSpace: barSpacing,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: bottomTitles,
                        reservedSize: 38
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: leftTitles,
                        interval: showCalories ? 100 : 20,
                        reservedSize: 38,
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    checkToShowHorizontalLine: (value) => true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey,
                        strokeWidth: value == 0 ? 3 : 0.8,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true, 
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.8),       // Hide the top border
                      right: BorderSide.none,     // Hide the right border
                      left: BorderSide.none,      // Hide the left border
                      bottom: BorderSide(color: Colors.grey, width: 1.5), // Show only bottom border
                    ),
                  ),
                  barGroups: showCalories
                      ? weeklyCalorieIntake.entries.map((e) => generateCaloriesGroup(e.key, e.value)).toList()
                      : macroIntake.entries.map((e) => generateMacrosGroup(e.key, e.value[0], e.value[1], e.value[2])).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChart extends StatefulWidget {
  final Pet pet;
  final int filterMonths;

  const _LineChart(this.pet, this.filterMonths);

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  List<Map<String, dynamic>> filteredStats = [];

  @override
  Widget build(BuildContext context) {
    return LineChart(
      sampleData1,
      duration: const Duration(milliseconds: 250),
    );
  }

  List<Map<String, dynamic>> get sortedVetStats {
    return List.from(widget.pet.vetStatistics!)..sort((a, b) {
      DateTime dateA = parseDate(a['date']);
      DateTime dateB = parseDate(b['date']);
      return dateA.compareTo(dateB);
    });
  }

  DateTime parseDate(String date) {
    List<String> parts = date.split('-');
    
    if (parts.length < 3) {
      throw FormatException("Invalid date format: $date");
    }

    int month = int.parse(parts[0]); // MM
    int day = int.parse(parts[1]);   // DD

    // Ensure the year is properly extracted
    String yearPart = parts[2].split(' ')[0]; // Take only the first part before any space
    int year = int.parse(yearPart) + 2000; // Convert YY to YYYY

    return DateTime(year, month, day);
  }

  LineChartData get sampleData1 {
    DateTime now = DateTime.now();
    DateTime cutoffDate = now.subtract(Duration(days: widget.filterMonths * 30)); // ✅ Correct date range

    // ✅ Filter to only include entries within the selected time frame
    filteredStats = sortedVetStats
        .where((entry) => parseDate(entry["date"]).isAfter(cutoffDate))
        .toList();
    print(filteredStats);

    if (filteredStats.isEmpty) {
      print("⚠️ No data found in range. Showing last 5 entries.");
      filteredStats = sortedVetStats.take(5).toList(); // ✅ Show last 5 as fallback
    }

    // ✅ Ensure at least 2 points to prevent minX == maxX issues
    if (filteredStats.length == 1) {
      print("⚠️ Only one data point found. Duplicating it.");
      DateTime duplicatedDate = parseDate(filteredStats.first["date"]);

      filteredStats.add({
        ...filteredStats.first,
        "date": "${duplicatedDate.month}-${duplicatedDate.day}-${duplicatedDate.year % 100}"
      });
    }

    // ✅ Calculate minX and maxX properly
    double maxX = filteredStats.length.toDouble() - 1;

    print("🔹 Showing ${filteredStats.length} data points for ${widget.filterMonths} months");

    return LineChartData(
      lineTouchData: lineTouchData1,
      gridData: gridData,
      titlesData: titlesData1,
      borderData: borderData,
      lineBarsData: lineBarsData1,
      minX: 0,  // ✅ Prevents ArgumentError (ensures valid range)
      maxX: maxX,
      maxY: 40,
      minY: 0,
    );
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Colors.blueGrey.withValues(alpha: 0.8),
        ),
      );

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  List<LineChartBarData> get lineBarsData1 => [
        weightData,
        heightData,
        bcsData,
      ];

  LineTouchData get lineTouchData2 => const LineTouchData(
        enabled: false,
      );

  FlTitlesData get titlesData2 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        value.toInt().toString(), // Show actual value
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

SideTitles leftTitles() => SideTitles(
  getTitlesWidget: leftTitleWidgets,
  showTitles: true,
  interval: 5, // Adjust interval dynamically if needed
  reservedSize: 40,
);

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    int index = value.toInt();
    if (index < 0 || index >= filteredStats.length) return Container();

    DateTime date = parseDate(filteredStats[index]["date"]);
    String formattedDate = "${date.month}/${date.day}"; // ✅ MM/DD format

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        formattedDate,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        getTitlesWidget: bottomTitleWidgets,
        interval: 30 * 24 * 60 * 60 * 1000.0, // Approx. 1 month in milliseconds
        reservedSize: 24,
      );

  FlGridData get gridData => const FlGridData(show: false);

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );

  /// ✅ Weight Data (sorted by date)
  LineChartBarData get weightData => LineChartBarData(
  isCurved: false,
  color: Colors.green,
  barWidth: 4,
  isStrokeCapRound: true,
  dotData: const FlDotData(show: true),
  belowBarData: BarAreaData(show: false),
  spots: filteredStats.asMap().entries
    .where((entry) => entry.value["weight"] != null) // Only keep valid data
    .map((entry) => FlSpot(
      entry.key.toDouble(),
      (entry.value["weight"] as num).toDouble(),
    ))
    .toList(),
  );

  /// ✅ Height Data (sorted by date)
  LineChartBarData get heightData => LineChartBarData(
    isCurved: false,
    color: Colors.pink,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: true),
    belowBarData: BarAreaData(show: false),
    spots: filteredStats.asMap().entries
      .where((entry) => entry.value["height"] != null)
      .map((entry) => FlSpot(
        entry.key.toDouble(),
        (entry.value["height"] as num).toDouble(),
      ))
      .toList(),
  );

  /// ✅ BCS Data (sorted by date)
  LineChartBarData get bcsData => LineChartBarData(
    isCurved: false,
    color: Colors.cyan,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: true),
    belowBarData: BarAreaData(show: false),
    spots: filteredStats.asMap().entries
    .where((entry) => entry.value["bcs"] != null)
    .map((entry) => FlSpot(
      entry.key.toDouble(),
      (entry.value["bcs"] as num).toDouble(),
    ))
    .toList(),
  );
}

class LineChartSample1 extends StatefulWidget {
  final double width;
  final double height;
  final Pet pet;
  const LineChartSample1({super.key, required this.width, required this.height, required this.pet});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  int filterMonths = 12;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            filterButton("1M", 1),
            filterButton("6M", 6),
            filterButton("12M", 12),
          ],),
        SizedBox(height:10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: theme.colorScheme.primary, // Background color of the graph
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: AspectRatio(
                aspectRatio: 1.23,
                child: Stack(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(
                          height: 37,
                        ),
                        const Text(
                          'Vet Visits',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 37,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16, left: 6),
                            child: _LineChart(widget.pet, filterMonths),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget filterButton(String text, int months) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            filterMonths = months;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: filterMonths == months ? Colors.blue : Colors.grey,
        ),
        child: Text(text),
      ),
    );
  }
}
