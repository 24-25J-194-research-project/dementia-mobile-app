import 'package:dementia_app/melody_mind/components/scrolling_text.dart';
import 'package:dementia_app/melody_mind/services/analytics_service.dart';
import 'package:dementia_app/screens/melody_mind/clinical_summery_screen.dart';
import 'package:dementia_app/utils/appColors.dart';
import 'package:dementia_app/melody_mind/components/weekly_progress_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;

  bool _isLoading = true;
  bool _isGeneratingSummary = false;
  List<Map<String, dynamic>> _sessionData = [];
  Map<String, dynamic> _userStats = {};
  List<Map<String, dynamic>> _weeklyProgress = [];
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _analyticsService.getUserSessionData();
      final stats = await _analyticsService.getUserAggregatedStats();
      final progress = await _analyticsService.getWeeklyProgressData();
      final profile = await _analyticsService.getUserProfile();

      setState(() {
        _sessionData = sessions;
        _userStats = stats;
        _weeklyProgress = progress;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToClinicaSummary() async {
    //check if there is enogugh data for session data summery
    if (_sessionData.isEmpty) {
      _showInsufficientDataDialog();
      return;
    }

    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClinicalSummaryScreen(
            patientId: _analyticsService.userId,
          ),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingSummary = false;
      });
    }
  }

  void _showInsufficientDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.deepBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Insufficient Data',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To generate a meaningful clinical summary, the patient needs to complete at least 3 music therapy sessions.',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Current Progress',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sessions Completed:',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${_sessionData.length}',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sessions Needed:',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${3 - _sessionData.length}',
                          style: GoogleFonts.inter(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.7),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Understood'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                //navigate back to music library
                Navigator.of(context).pop();
              },
              child: const Text('Start Session'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepBlue, AppColors.black],
          ),
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryBlue))
              : Column(
                  children: [
                    // App bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Music Therapy Analytics',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    //patient profile summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.primaryBlue.withOpacity(0.2),
                              backgroundImage:
                                  _userProfile['avatar_url'] != null
                                      ? NetworkImage(_userProfile['avatar_url'])
                                      : null,
                              child: _userProfile['avatar_url'] == null
                                  ? Text(
                                      _userProfile['full_name']
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true
                                          ? _userProfile['full_name'][0]
                                              .toUpperCase()
                                          : 'P',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userProfile['full_name'] ?? 'Patient',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_userProfile['age'] != null &&
                                    _userProfile['age'] > 0)
                                  Text(
                                    'Age: ${_userProfile['age']}, Stage: ${_userProfile['dementia_stage'] ?? 'Unknown'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Sessions completed indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _sessionData.length >= 3
                                  ? Colors.green.withOpacity(0.2)
                                  : AppColors.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _sessionData.length >= 3
                                    ? Colors.green.withOpacity(0.3)
                                    : AppColors.primaryBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _sessionData.length >= 3
                                      ? Icons.check_circle
                                      : Icons.music_note,
                                  color: _sessionData.length >= 3
                                      ? Colors.green
                                      : Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_sessionData.length} sessions',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        labelStyle:
                            GoogleFonts.inter(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Sessions'),
                        ],
                      ),
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildSessionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),

      //summery action button
      floatingActionButton: _sessionData.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed:
                  _isGeneratingSummary ? null : _navigateToClinicaSummary,
              backgroundColor: _sessionData.length >= 3
                  ? AppColors.primaryBlue
                  : Colors.grey.withOpacity(0.7),
              foregroundColor: Colors.white,
              elevation: 8,
              icon: _isGeneratingSummary
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _sessionData.length >= 3
                          ? Icons.psychology
                          : Icons.info_outline,
                    ),
              label: Text(
                _isGeneratingSummary
                    ? 'Generating...'
                    : _sessionData.length >= 3
                        ? 'Clinical Summary'
                        : 'Need ${3 - _sessionData.length} more sessions',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadData,
      child: _sessionData.isEmpty
          ? _buildEmptyState('No session data available yet',
              'Complete a music therapy session to see your stats')
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Statistics summary
                  SessionStatisticsCard(
                    stats: _userStats,
                    title: 'Music Therapy Overview',
                    subtitle: 'Summary of all sessions',
                    icon: Icons.analytics,
                  ),

                  const SizedBox(height: 20),

                  // Weekly Progress Chart
                  if (_weeklyProgress.isNotEmpty)
                    WeeklyProgressChart(progressData: _weeklyProgress),

                  const SizedBox(height: 20),

                  // Preferences card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Preferences',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Most Played Song',
                          _userStats['most_played_song'],
                          Icons.favorite,
                        ),
                        const Divider(color: Colors.white24),
                        _buildStatRow(
                          'Preferred Rhythm Pace',
                          _userStats['preferred_pace'],
                          Icons.speed,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Preferences can inform therapy customization and indicate which music styles most effectively engage the patient.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Last session card
                  if (_sessionData.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Session Details',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showSessionDetails(_sessionData[0]),
                                child: Text(
                                  'View Details',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            'Song',
                            '${_sessionData[0]['song_name']} - ${_sessionData[0]['artist']}',
                            Icons.music_note,
                          ),
                          const Divider(color: Colors.white24),
                          _buildStatRow(
                            'Date',
                            DateFormat('dd MMM yyyy, HH:mm').format(
                                DateTime.parse(_sessionData[0]['timestamp'])),
                            Icons.calendar_today,
                          ),
                          const Divider(color: Colors.white24),
                          _buildStatRow(
                            'Rhythm Accuracy',
                            '${_sessionData[0]['rhythm_accuracy']}%',
                            Icons.auto_graph,
                          ),
                          const Divider(color: Colors.white24),
                          _buildStatRow(
                            'Consecutive Sync Beats',
                            _sessionData[0]['consecutive_sync_taps_max']
                                .toString(),
                            Icons.repeat,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  String _getTherapyAssessment() {
    if (_sessionData.isEmpty) {
      return "No sessions recorded yet to generate an assessment.";
    }

    final avgAccuracy = _userStats['avg_rhythm_accuracy'];
    final totalSessions = _userStats['total_sessions'];
    final highestAccuracy = _userStats['highest_accuracy'];

    if (totalSessions < 3) {
      return "Preliminary assessment (insufficient data): Patient has participated in $totalSessions music therapy sessions. "
          "Continue regular sessions to gather more data for a comprehensive assessment. Initial rhythm accuracy is ${avgAccuracy.toStringAsFixed(1)}%.";
    }

    String assessment = '';

    //cognitive assessment based on metrics
    if (avgAccuracy >= 70) {
      assessment =
          "Strong cognitive rhythm processing: Patient demonstrates excellent temporal processing abilities with an average accuracy of ${avgAccuracy.toStringAsFixed(1)}%. "
          "This suggests intact procedural memory and executive function. Recommend maintaining current therapy approach with potential to increase complexity.";
    } else if (avgAccuracy >= 50) {
      assessment =
          "Moderate cognitive rhythm processing: Patient shows adequate temporal processing with an average accuracy of ${avgAccuracy.toStringAsFixed(1)}%. "
          "Some inconsistency in rhythm maintenance suggests mild cognitive impairment affecting attention or procedural memory. "
          "Recommend continuing with current rhythm complexity but increasing frequency of sessions.";
    } else {
      assessment =
          "Developing cognitive rhythm processing: Patient demonstrates baseline temporal processing abilities with an average accuracy of ${avgAccuracy.toStringAsFixed(1)}%. "
          "Consistent difficulty maintaining rhythm may indicate moderate cognitive impairment affecting procedural memory or attention. "
          "Recommend simplifying rhythm patterns and using the 'Gentle' pace setting to improve engagement and success rate.";
    }

    // Add trend analysis if enough sessions
    if (totalSessions >= 5) {
      if (_weeklyProgress.isNotEmpty) {
        final recentAccuracyValues = _weeklyProgress
            .map((progress) =>
                double.tryParse(progress['accuracy'] ?? '0') ?? 0.0)
            .toList();

        if (recentAccuracyValues.length >= 2) {
          final firstHalf =
              recentAccuracyValues.sublist(0, recentAccuracyValues.length ~/ 2);
          final secondHalf =
              recentAccuracyValues.sublist(recentAccuracyValues.length ~/ 2);

          final firstHalfAvg =
              firstHalf.reduce((a, b) => a + b) / firstHalf.length;
          final secondHalfAvg =
              secondHalf.reduce((a, b) => a + b) / secondHalf.length;

          if (secondHalfAvg - firstHalfAvg > 5) {
            assessment +=
                "\n\nProgression trend: Patient shows significant improvement in rhythm accuracy over time, suggesting positive response to music therapy and potential cognitive benefits.";
          } else if (secondHalfAvg - firstHalfAvg < -5) {
            assessment +=
                "\n\nRegression trend: Patient shows decline in rhythm accuracy over time, which may indicate disease progression or need to adjust therapy approach.";
          } else {
            assessment +=
                "\n\nStable trend: Patient maintains consistent rhythm accuracy over time, suggesting stable cognitive function in areas related to temporal processing.";
          }
        }
      }
    }

    return assessment;
  }

  Widget _buildSessionsTab() {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadData,
      child: _sessionData.isEmpty
          ? _buildEmptyState('No sessions recorded',
              'Complete music therapy sessions to see your history')
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _sessionData.length,
              itemBuilder: (context, index) {
                final session = _sessionData[index];
                final timestamp = DateTime.parse(session['timestamp']);
                final formattedDate =
                    DateFormat('dd MMM yyyy, HH:mm').format(timestamp);

                return GestureDetector(
                  onTap: () => _showSessionDetails(session),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${session['song_name']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getAccuracyColor(double.parse(
                                      session['rhythm_accuracy'] ?? '0')),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${session['rhythm_accuracy']}%',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'by ${session['artist']}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDuration(session['total_duration']),
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    session['rhythm_pace'],
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProgressTab() {
    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadData,
      child: _weeklyProgress.isEmpty
          ? _buildEmptyState('No progress data available',
              'Complete more sessions to see your progress')
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Progress',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  //progress chart
                  WeeklyProgressChart(progressData: _weeklyProgress),

                  const SizedBox(height: 20),

                  //session counts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Sessions',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._weeklyProgress.map((data) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  data['day'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (data['sessions'] as int) /
                                        5, // Normalize to 5 sessions max
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    color: AppColors.primaryBlue,
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${data['sessions']} sessions',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //accuracy by day
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Average Accuracy',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._weeklyProgress.map((data) {
                          final accuracy = double.parse(data['accuracy']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  data['day'],
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: accuracy / 100,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    color: _getAccuracyColor(accuracy),
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${accuracy.toStringAsFixed(1)}%',
                                  style: GoogleFonts.inter(
                                    color: _getAccuracyColor(accuracy),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          ScrollingText(
            text: value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            width: MediaQuery.of(context).size.width * 0.4,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${session['song_name']}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(
              'by ${session['artist']}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Date and duration
            Row(
              children: [
                Expanded(
                  child: _buildSessionInfoCard(
                    'Date',
                    DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(session['timestamp'])),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSessionInfoCard(
                    'Time',
                    DateFormat('HH:mm')
                        .format(DateTime.parse(session['timestamp'])),
                    Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSessionInfoCard(
                    'Duration',
                    _formatDuration(session['total_duration']),
                    Icons.timer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSessionInfoCard(
                    'Rhythm Pace',
                    session['rhythm_pace'],
                    Icons.speed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            //performance metrics header
            Text(
              'Performance Metrics',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            //performance metrics
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    //rhythm accuracy
                    _buildPerformanceMetricCard(
                      'Rhythm Accuracy',
                      '${session['rhythm_accuracy']}%',
                      double.parse(session['rhythm_accuracy']) / 100,
                      _getAccuracyColor(
                          double.parse(session['rhythm_accuracy'])),
                      'How well you maintained rhythm during the session.',
                    ),

                    const SizedBox(height: 16),

                    //max consecutive syncs
                    _buildPerformanceMetricCard(
                      'Max Consecutive Syncs',
                      session['consecutive_sync_taps_max'].toString(),
                      session['consecutive_sync_taps_max'] /
                          20, // Normalize to expected max of 20
                      Colors.amber,
                      'Longest streak of rhythm-matched interactions.',
                    ),

                    const SizedBox(height: 16),

                    //interaction stats
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interaction Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            'Total Beats',
                            session['total_beats'].toString(),
                            Icons.graphic_eq,
                          ),
                          const Divider(color: Colors.white24),
                          _buildStatRow(
                            'Total Taps/Claps',
                            session['total_taps'].toString(),
                            Icons.touch_app,
                          ),
                          const Divider(color: Colors.white24),
                          _buildStatRow(
                            'Timing Tolerance',
                            '${session['time_tolerance']} ms',
                            Icons.timer,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    //assessment
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Therapeutic Assessment',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getAssessmentText(session),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricCard(
    String title,
    String value,
    double progress,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.1),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getAssessmentText(Map<String, dynamic> session) {
    final double accuracy = double.parse(session['rhythm_accuracy']);
    final int maxConsecutiveSync = session['consecutive_sync_taps_max'];
    final int totalTaps = session['total_taps'];

    if (totalTaps < 5) {
      return "Limited engagement detected. The patient may have been experiencing difficulty with attention, motivation, or physical ability to interact. Consider simplifying the rhythm or trying a different song for the next session.";
    } else if (accuracy >= 80 && maxConsecutiveSync >= 10) {
      return "Excellent rhythmic coordination and sustained attention demonstrated. The patient showed strong engagement and cognitive processing. This suggests preserved procedural memory and temporal processing abilities.";
    } else if (accuracy >= 60) {
      return "Good rhythmic coordination with some inconsistencies. The patient demonstrated adequate engagement and cognitive processing. Consider maintaining this difficulty level for future sessions to build confidence and consistency.";
    } else if (accuracy >= 40) {
      return "Moderate rhythmic coordination with frequent inconsistencies. The patient showed engagement but may benefit from a slower rhythm pace. This level of performance suggests some temporal processing challenges that could be addressed with continued therapy.";
    } else {
      return "Rhythmic coordination challenges detected. The patient showed interest but struggled with timing. Consider simplifying the rhythm pattern and using a 'Gentle' rhythm pace. Regular sessions may help improve procedural memory and temporal processing skills.";
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return Colors.green;
    } else if (accuracy >= 60) {
      return Colors.lightGreen;
    } else if (accuracy >= 40) {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.deepBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Export Analytics Data',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share patient data with healthcare team',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              title: 'Export as PDF Report',
              subtitle: 'Complete analytics with visualizations',
              onTap: () {
                Navigator.pop(context);
                _exportAsPdf();
              },
            ),
            _buildExportOption(
              icon: Icons.email_outlined,
              title: 'Email to Healthcare Provider',
              subtitle: 'Share data via email',
              onTap: () {
                Navigator.pop(context);
                _shareViaEmail();
              },
            ),
            _buildExportOption(
              icon: Icons.table_chart,
              title: 'Export Session Data as CSV',
              subtitle: 'Raw data for detailed analysis',
              onTap: () {
                Navigator.pop(context);
                _exportAsCSV();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsPdf() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Generating PDF report...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulated delay for PDF generation
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Close loading dialog
    Navigator.pop(context);

    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'PDF Report Ready',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Patient analytics report has been generated successfully.',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Report shared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Share PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaEmail() async {
    //create email content from analytics
    String patientName = _userProfile['full_name'] ?? 'Patient';
    String emailSubject = 'Music Therapy Analytics Report - $patientName';

    String emailBody = '''
Music Therapy Analytics Report for $patientName

SUMMARY:
Total Sessions: ${_userStats['total_sessions']}
Average Rhythm Accuracy: ${_userStats['avg_rhythm_accuracy'].toStringAsFixed(1)}%
Total Therapy Duration: ${_formatDuration(_userStats['total_duration'])}
Preferred Song: ${_userStats['most_played_song']}
Preferred Rhythm Pace: ${_userStats['preferred_pace']}

THERAPEUTIC ASSESSMENT:
${_getTherapyAssessment()}

Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}
''';

    //show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepBlue,
        title: Text(
          'Email Report',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An email will be drafted with the following information:',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subject: $emailSubject',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  emailBody,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Email drafted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Send Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsCSV() async {
    //show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Generating CSV data...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    //simulated delay for CSV generation
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    //close loading dialog
    Navigator.pop(context);

    //show success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session data exported as CSV'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'SHARE',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
