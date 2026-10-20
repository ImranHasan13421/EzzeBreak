import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/native_app_service.dart';
import '../../../core/services/report_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/ezze_button.dart';
import '../../../shared/widgets/ezze_card.dart';
import '../../monitoring/providers/monitoring_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedType = 0; // 0: Today, 1: 7-Day
  bool _isGenerating = false;
  String? _lastExportedPath;

  void _generateAndDownload() async {
    setState(() {
      _isGenerating = true;
      _lastExportedPath = null;
    });

    final db = ref.read(databaseProvider);
    final reportService = ReportService(db);
    final now = DateTime.now();

    DateTime start;
    DateTime end = now;
    String title;

    if (_selectedType == 0) {
      start = now;
      title = 'Daily Report - ${EzzeDateUtils.formatPretty(now)}';
    } else {
      start = now.subtract(const Duration(days: 6));
      title = '7-Day Summary (${EzzeDateUtils.formatShort(start)} - ${EzzeDateUtils.formatShort(end)})';
    }

    try {
      final summary = await reportService.getAnalyticsForDateRange(start, end, title);
      final savedPath = await reportService.exportReport(summary);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _lastExportedPath = savedPath;
        });

        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report successfully saved to Downloads!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save PDF to Downloads.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  void _openPdf(String path) async {
    final success = await NativeAppService.openFile(path);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file. Ensure a PDF viewer is installed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Export Reports', style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl, vertical: Spacing.lg),
        children: [
          // Graphic motif
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.brandRed, size: 38),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Generate PDF Reports',
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Create offline wellbeing reports with detailed usage breakdowns and physical activity logs.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: secondaryText, height: 1.4),
          ),
          const SizedBox(height: Spacing.xxl),

          // Report Range Options
          Text('Report Type', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm, horizontal: Spacing.md),
            child: Column(
              children: [
                _buildReportOption(
                  value: 0,
                  title: 'Today\'s Report (${EzzeDateUtils.formatPretty(DateTime.now())})',
                  subtitle: 'Full daily usage, breaks triggered, and exercise activity.',
                ),
                const Divider(),
                _buildReportOption(
                  value: 1,
                  title: '7-Day Summary Report',
                  subtitle: 'Weekly aggregates, daily trends, and break compliance rates.',
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Contents Included Summary
          Text('Report Contents', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: Spacing.sm),
          EzzeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckItem('Total screen time and daily usage summary'),
                _buildCheckItem('Individual monitored application breakdown'),
                _buildCheckItem('Break compliance and adherence rates'),
                _buildCheckItem('Physical exercise repetitions and timer logs'),
                _buildCheckItem('Daily PIN override authorization audit'),
                _buildCheckItem('100% offline device-only privacy guarantee'),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xxl),

          // Export Button
          EzzeButton(
            text: _isGenerating ? 'Generating PDF Document...' : 'Generate & Download PDF',
            icon: Icons.download_rounded,
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _generateAndDownload,
          ),
          const SizedBox(height: Spacing.xl),

          // Download Confirmation Card
          if (_lastExportedPath != null) ...[
            EzzeCard.status(
              statusColor: AppColors.accentGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 22),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Report Ready in Downloads',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _lastExportedPath!,
                    style: AppTypography.bodySmall.copyWith(color: secondaryText),
                  ),
                  const SizedBox(height: Spacing.lg),
                  EzzeButton(
                    text: 'Open PDF Document',
                    icon: Icons.open_in_new_rounded,
                    variant: EzzeButtonVariant.secondary,
                    onPressed: () => _openPdf(_lastExportedPath!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildReportOption({
    required int value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedType == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.brandRed : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandRed,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: primaryText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodySmall.copyWith(color: secondaryText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.accentGreen),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
