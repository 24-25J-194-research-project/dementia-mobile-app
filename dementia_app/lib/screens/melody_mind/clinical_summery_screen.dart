import 'package:dementia_app/melody_mind/services/ai_clinical_summery.dart';
import 'package:dementia_app/melody_mind/services/clinical_tts_service.dart';
import 'package:dementia_app/utils/appColors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class ClinicalSummaryScreen extends StatefulWidget {
  final String patientId;

  const ClinicalSummaryScreen({
    Key? key,
    required this.patientId,
  }) : super(key: key);

  @override
  State<ClinicalSummaryScreen> createState() => _ClinicalSummaryScreenState();
}

class _ClinicalSummaryScreenState extends State<ClinicalSummaryScreen>
    with TickerProviderStateMixin {
  final AIClinicalSummaryService _summaryService = AIClinicalSummaryService();
  final ClinicalTTSService _ttsService = ClinicalTTSService();

  late TabController _tabController;
  ClinicalSummary? _clinicalSummary;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _errorMessage = '';

  //tts configs
  bool _isTTSInitialized = false;
  bool _isPlaying = false;
  String _currentlyPlayingSection = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeTTS();
    _generateSummary();
  }

  Future<void> _initializeTTS() async {
    final initialized = await _ttsService.initialize();
    setState(() {
      _isTTSInitialized = initialized;
    });

    _ttsService.onSpeakStart = () {
      print('TTS: Speech started - updating UI state');
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    };

    _ttsService.onSpeakComplete = () {
      print('TTS: Speech completed - updating UI state');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSection = '';
        });
      }
    };

    _ttsService.onError = (error) {
      print('TTS: Error occurred - $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech error: $error')),
      );
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSection = '';
        });
      }
    };
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isGenerating = true;
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final summary = await _summaryService.generateClinicalSummary(
        patientId: widget.patientId,
      );

      setState(() {
        _clinicalSummary = summary;
        _isLoading = false;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isGenerating = false;
      });
    }
  }

  //tts controls
  Future<void> _toggleFullSummaryPlayback() async {
    if (_clinicalSummary == null || !_isTTSInitialized) return;

    if (_isPlaying) {
      await _ttsService.stop();
      return;
    }

    final fullText = '''
    Executive Summary: ${_clinicalSummary!.executiveSummary}
    
    Clinical Assessment: ${_clinicalSummary!.cognitiveAssessment}
    ''';

    setState(() {
      _currentlyPlayingSection = 'Full Summary';
    });

    await _ttsService.speakClinicalSummary(fullText);
  }

  Future<void> _toggleSectionPlayback(String title, String content) async {
    if (!_isTTSInitialized) return;

    if (_isPlaying && _currentlyPlayingSection == title) {
      await _ttsService.stop();
      return;
    }

    setState(() {
      _currentlyPlayingSection = title;
    });

    await _ttsService.speakSection(title, content);
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
        ),
        child: SafeArea(
          child: Column(
            children: [
              //header
              _buildHeader(),

              //loading content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage.isNotEmpty
                        ? _buildErrorState()
                        : _buildSummaryContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clinical Summary',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          //regenerate button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isGenerating ? null : _generateSummary,
          ),
          //share button
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _clinicalSummary != null ? _shareSummary : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryBlue),
          const SizedBox(height: 24),
          Text(
            _isGenerating ? 'Generating Clinical Summary...' : 'Loading...',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take a few moments as we analyze the patient data',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Generating Summary',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: _generateSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent() {
    if (_clinicalSummary == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle:
                GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Executive'),
              Tab(text: 'Clinical'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildSectionTab(
                  'Executive Summary', _clinicalSummary!.executiveSummary),
              _buildSectionTab(
                  'Clinical Assessment', _clinicalSummary!.cognitiveAssessment),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //key metrics summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Metrics',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMetricRow('Total Sessions',
                    '${_clinicalSummary!.keyMetrics.totalSessions}'),
                _buildMetricRow('Average Accuracy',
                    '${_clinicalSummary!.keyMetrics.averageAccuracy.toStringAsFixed(1)}%'),
                _buildMetricRow('Generated At',
                    _formatDateTime(_clinicalSummary!.generatedAt)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //quick actions
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionChip(
                'Listen to Summary',
                _isPlaying && _currentlyPlayingSection == 'Full Summary'
                    ? Icons.stop
                    : Icons.volume_up,
                () => _toggleFullSummaryPlayback(),
              ),
              _buildActionChip(
                  'Share Summary', Icons.share, () => _shareSummary()),
              _buildActionChip('Copy Text', Icons.copy, () => _copySummary()),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This summary is AI-generated to support clinical decision-making. It should be used in conjunction with professional medical judgment.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab(String title, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //section header with TTS button
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isTTSInitialized)
                IconButton(
                  icon: Icon(
                    _isPlaying && _currentlyPlayingSection == title
                        ? Icons.stop
                        : Icons.volume_up,
                    color: AppColors.primaryBlue,
                  ),
                  onPressed: () => _toggleSectionPlayback(title, content),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareSummary() {
    if (_clinicalSummary == null) return;

    final summaryText = '''
Clinical Summary

Executive Summary:
${_clinicalSummary!.executiveSummary}

Clinical Assessment:
${_clinicalSummary!.cognitiveAssessment}

Generated: ${_formatDateTime(_clinicalSummary!.generatedAt)}
''';

    Share.share(summaryText, subject: 'Clinical Summary - MelodyMind');
  }

  void _copySummary() {
    if (_clinicalSummary == null) return;

    final summaryText = '''
${_clinicalSummary!.executiveSummary}

${_clinicalSummary!.cognitiveAssessment}
''';

    Clipboard.setData(ClipboardData(text: summaryText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
