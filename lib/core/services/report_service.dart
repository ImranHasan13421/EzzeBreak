import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../database/app_database.dart';
import '../platform/native_app_service.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';
import '../../shared/models/analytics_summary.dart';

class ReportService {
  final AppDatabase _db;

  ReportService([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  /// Builds AnalyticsSummary for a given date range
  Future<AnalyticsSummary> getAnalyticsForDateRange(DateTime start, DateTime end, String title) async {
    final startDay = EzzeDateUtils.startOfDay(start);
    final endDay = EzzeDateUtils.endOfDay(end);

    // Calculate all date keys in range
    final daysCount = endDay.difference(startDay).inDays + 1;
    final dateKeys = <String>[];
    for (int i = 0; i < daysCount; i++) {
      dateKeys.add(EzzeDateUtils.dateKey(startDay.add(Duration(days: i))));
    }

    final monitoredApps = await _db.getAllMonitoredApps();
    final dailyUsages = await _db.getDailyUsageForDateRange(dateKeys);
    final breakSessions = await _db.getBreakSessions(startDay, endDay);
    final exerciseLogs = await _db.getExerciseLogsForDateRange(startDay, endDay);
    final overrideLogs = await _db.getOverridesForDateRange(startDay, endDay);

    int totalUsageSec = 0;
    final Map<String, int> appUsageMap = {};
    for (final du in dailyUsages) {
      totalUsageSec += du.accumulatedSeconds;
      appUsageMap[du.packageName] = (appUsageMap[du.packageName] ?? 0) + du.accumulatedSeconds;
    }

    // Per app stats
    final appStats = <AppUsageStat>[];
    for (final app in monitoredApps) {
      final usageSec = appUsageMap[app.packageName] ?? 0;
      final rule = await _db.getRule(app.packageName);
      final sessionsCount = await _db.getSessionCountForApp(app.packageName, startDay, endDay);
      final appBreaks = breakSessions.where((b) => b.packageName == app.packageName).length;
      final appOverrides = overrideLogs.where((o) => o.packageName == app.packageName).length;

      appStats.add(AppUsageStat(
        packageName: app.packageName,
        appName: app.appName,
        iconBase64: app.iconBase64,
        usageSeconds: usageSec,
        budgetMinutes: rule?.dailyBudgetMinutes ?? 60,
        sessionsCount: sessionsCount,
        breaksCount: appBreaks,
        overridesCount: appOverrides,
      ));
    }
    appStats.sort((a, b) => b.usageSeconds.compareTo(a.usageSeconds));

    // Daily trends
    final dailyTrends = <DailyTrendItem>[];
    for (final dk in dateKeys) {
      final usagesOnDate = dailyUsages.where((u) => u.dateKey == dk);
      final sec = usagesOnDate.fold<int>(0, (sum, u) => sum + u.accumulatedSeconds);

      final dateObj = EzzeDateUtils.parseDateKey(dk);
      final s = EzzeDateUtils.startOfDay(dateObj);
      final e = EzzeDateUtils.endOfDay(dateObj);

      final breaksOnDate = breakSessions.where((b) => b.triggerTime.isAfter(s) && b.triggerTime.isBefore(e)).length;
      final exercisesOnDate = exerciseLogs.where((ex) => ex.completedAt.isAfter(s) && ex.completedAt.isBefore(e)).length;

      dailyTrends.add(DailyTrendItem(
        dateKey: dk,
        usageSeconds: sec,
        breaksCount: breaksOnDate,
        exercisesCount: exercisesOnDate,
      ));
    }

    // Exercises summary
    final Map<String, ExerciseSummaryItem> exMap = {};
    int totalReps = 0;
    int totalExSec = 0;
    for (final log in exerciseLogs) {
      totalReps += log.repetitions;
      totalExSec += log.durationSeconds;

      final existing = exMap[log.exerciseName];
      if (existing == null) {
        exMap[log.exerciseName] = ExerciseSummaryItem(
          exerciseName: log.exerciseName,
          type: log.repetitions > 0 ? 'repetitions' : 'duration_seconds',
          totalRepetitions: log.repetitions,
          totalDurationSeconds: log.durationSeconds,
          sessionCount: 1,
        );
      } else {
        exMap[log.exerciseName] = ExerciseSummaryItem(
          exerciseName: log.exerciseName,
          type: existing.type,
          totalRepetitions: existing.totalRepetitions + log.repetitions,
          totalDurationSeconds: existing.totalDurationSeconds + log.durationSeconds,
          sessionCount: existing.sessionCount + 1,
        );
      }
    }

    int totalOverrideMins = 0;
    for (final o in overrideLogs) {
      totalOverrideMins += o.extensionMinutes;
    }

    final completedBreaks = breakSessions.where((b) => b.completedTime != null).length;

    return AnalyticsSummary(
      periodTitle: title,
      totalUsageSeconds: totalUsageSec,
      monitoredAppsCount: monitoredApps.where((a) => a.isMonitored).length,
      breaksTriggered: breakSessions.length,
      breaksCompleted: completedBreaks,
      exercisesCompleted: exerciseLogs.length,
      totalRepetitions: totalReps,
      totalExerciseSeconds: totalExSec,
      overridesCount: overrideLogs.length,
      totalOverrideMinutes: totalOverrideMins,
      appStats: appStats,
      dailyTrends: dailyTrends,
      exerciseStats: exMap.values.toList(),
    );
  }

  /// Generates the PDF document for an AnalyticsSummary
  Future<Uint8List> generatePdfReport(AnalyticsSummary summary) async {
    final pdf = pw.Document();

    final red = PdfColor.fromHex('#D92D3E');
    final dark = PdfColor.fromHex('#111111');
    final gray = PdfColor.fromHex('#777777');
    final lightBg = PdfColor.fromHex('#F4F4F6');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EZZE BREAK',
                    style: pw.TextStyle(
                      color: red,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.Text(
                    'Digital Wellbeing & Break Analytics Report',
                    style: pw.TextStyle(color: gray, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    summary.periodTitle,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                  pw.Text(
                    'Generated: ${EzzeDateUtils.formatPretty(DateTime.now())}',
                    style: pw.TextStyle(color: gray, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 15),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Ezze Break - 100% Offline & Private', style: pw.TextStyle(color: gray, fontSize: 8)),
              pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(color: gray, fontSize: 8)),
            ],
          ),
        ),
        build: (context) => [
          // Summary Cards Grid
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfStatItem('Total Screen Time', EzzeFormatters.formatSeconds(summary.totalUsageSeconds), red),
                _buildPdfStatItem('Monitored Apps', '${summary.monitoredAppsCount}', dark),
                _buildPdfStatItem('Breaks Done', '${summary.breaksCompleted} / ${summary.breaksTriggered}', dark),
                _buildPdfStatItem('Exercises Done', '${summary.exercisesCompleted}', dark),
                _buildPdfStatItem('Overrides', '${summary.overridesCount}', red),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Monitored Apps Table
          pw.Text('App Usage Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: pw.BoxDecoration(color: dark),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            headers: ['Application', 'Package', 'Daily Budget', 'Usage', 'Status', 'Sessions'],
            data: summary.appStats.map((app) {
              final pct = EzzeFormatters.formatPercentage(app.budgetRatio);
              final isOver = app.budgetRatio >= 1.0 && app.usageSeconds > 0;
              return [
                app.appName,
                app.packageName,
                '${app.budgetMinutes}m',
                EzzeFormatters.formatSeconds(app.usageSeconds),
                isOver ? 'Exceeded ($pct)' : 'Within Budget ($pct)',
                '${app.sessionsCount}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          // Exercise Activity Table
          pw.Text('Physical Exercise Activity', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (summary.exerciseStats.isEmpty)
            pw.Text('No physical exercises logged in this period.', style: pw.TextStyle(color: gray, fontSize: 10))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: dark),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              headers: ['Exercise', 'Measurement Type', 'Total Activity', 'Completed Sessions'],
              data: summary.exerciseStats.map((ex) {
                final activityStr = ex.type == 'repetitions'
                    ? '${ex.totalRepetitions} repetitions'
                    : EzzeFormatters.formatSeconds(ex.totalDurationSeconds);
                return [
                  ex.exerciseName,
                  ex.type == 'repetitions' ? 'Repetition Count' : 'Timed Duration',
                  activityStr,
                  '${ex.sessionCount}',
                ];
              }).toList(),
            ),
          pw.SizedBox(height: 24),

          // Notice & Privacy Guarantee
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Data Accuracy & Privacy Notice', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'This report was compiled strictly from local device measurements by Ezze Break. No usage data, package names, or physical activity statistics were transmitted over the internet. The daily 8-digit PIN and override controls are local mindful self-discipline tools.',
                  style: pw.TextStyle(color: gray, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  pw.Widget _buildPdfStatItem(String label, String value, PdfColor valueColor) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(color: valueColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8)),
      ],
    );
  }

  /// Exports PDF to Downloads folder and returns the file path
  Future<String?> exportReport(AnalyticsSummary summary) async {
    final bytes = await generatePdfReport(summary);
    final fileName = 'EzzeBreak_Report_${EzzeDateUtils.todayKey()}.pdf';

    // Try Android MediaStore / Native save first
    if (!kIsWeb && Platform.isAndroid) {
      final path = await NativeAppService.savePdfToDownloads(fileName, bytes);
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }

    // Fallback: use path_provider
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Fallback PDF write error: $e');
      return null;
    }
  }
}
