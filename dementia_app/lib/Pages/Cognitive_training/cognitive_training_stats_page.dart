import 'package:dementia_app/Shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  final baseUrl = Constants.baseAPIUrl;
  final _supabase = Supabase.instance.client;
  
  // Activity selection
  final Map<int, String> _activities = {
    1: 'Cash Tally',
    3: 'Memory Card',
  };
  int _selectedActivityId = 1; // Default to Cash Tally
  
  // Tab controller
  late TabController _tabController;
  
  // Data storage
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _statsData = [];
  
  // Filtered data
  Map<String, List<dynamic>> _levelData = {
    'easy': [],
    'medium': [],
    'hard': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/cognitive-training-history?user_id=$userId&cognitive_training_id=$_selectedActivityId'),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _statsData = data;
          _processData();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _processData() {
    // Reset level data
    _levelData = {
      'easy': [],
      'medium': [],
      'hard': [],
    };
    
    // Group by level
    for (var item in _statsData) {
      final level = item['level'].toString().toLowerCase();
      if (_levelData.containsKey(level)) {
        _levelData[level]!.add(item);
      }
    }
    
    // Sort by date (newest first)
    for (var key in _levelData.keys) {
      _levelData[key]!.sort((a, b) {
        final dateA = DateTime.parse(a['created_at']);
        final dateB = DateTime.parse(b['created_at']);
        return dateB.compareTo(dateA);
      });
    }
  }

  void _onActivityChanged(int? value) {
    if (value != null && value != _selectedActivityId) {
      setState(() {
        _selectedActivityId = value;
      });
      _fetchStats();
    }
  }

  // Get stats summary for a level
  Map<String, dynamic> _getLevelSummary(String level) {
    final data = _levelData[level] ?? [];
    
    if (data.isEmpty) {
      return {
        'totalSessions': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'recentScore': 0,
      };
    }

    double totalScore = 0;
    int bestScore = 0;
    
    for (var item in data) {
      final score = item['score'] as int;
      totalScore += score;
      if (score > bestScore) {
        bestScore = score;
      }
    }

    return {
      'totalSessions': data.length,
      'averageScore': data.isEmpty ? 0.0 : (totalScore / data.length).toDouble(),
      'bestScore': bestScore,
      'recentScore': data.isNotEmpty ? data.first['score'] : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Performance Stats', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Activity selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue,
            child: Row(
              children: [
                const Text(
                  'Activity: ',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),

                SizedBox(
                  width: 220,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedActivityId,
                        onChanged: _onActivityChanged,
                        items: _activities.entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          );
                        }).toList(),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                        menuMaxHeight: 300,
                        itemHeight: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.bar_chart)),
                Tab(text: 'History', icon: Icon(Icons.history)),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Score chart
          _buildScoreChart(),
          const SizedBox(height: 24),
          
          // Level summaries
          const Text(
            'Level Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildLevelSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildScoreChart() {
    if (_statsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data available. Complete some activities to see your stats!'),
        ),
      );
    }
    
    // Get the last 10 sessions
    final recentData = [..._statsData];
    recentData.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateA.compareTo(dateB);
    });
    
    final chartData = recentData.length > 10 
      ? recentData.sublist(recentData.length - 10) 
      : recentData;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Progression',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                          final date = DateTime.parse(chartData[value.toInt()]['created_at']);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: chartData.length.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(chartData.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        chartData[index]['score'].toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSummaryCards() {
    final levels = ['easy', 'medium', 'hard'];
    final levelColors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
    };
    
    return Column(
      children: levels.map((level) {
        final summary = _getLevelSummary(level);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: levelColors[level]!.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColors[level]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      level.toUpperCase(),
                      style: TextStyle(
                        color: levelColors[level],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${summary['totalSessions']} ${summary['totalSessions'] == 1 ? 'session' : 'sessions'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Average',
                    '${summary['averageScore'].toStringAsFixed(1)}%',
                    Icons.analytics_outlined,
                  ),
                  _buildStatItem(
                    'Best',
                    '${summary['bestScore']}%',
                    Icons.emoji_events_outlined,
                  ),
                  _buildStatItem(
                    'Recent',
                    '${summary['recentScore']}%',
                    Icons.access_time,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_statsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No history available. Complete some activities to see your stats!'),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'EASY'),
                Tab(text: 'MEDIUM'),
                Tab(text: 'HARD'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryList('easy'),
                _buildHistoryList('medium'),
                _buildHistoryList('hard'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String level) {
    final data = _levelData[level] ?? [];
    
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No $level level sessions completed yet.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final date = DateTime.parse(item['created_at']);
        final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
        final score = item['score'] as int;
        final errorCount = item['error_count'] as int;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    '${score}%',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activities[_selectedActivityId] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Errors',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$errorCount',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}