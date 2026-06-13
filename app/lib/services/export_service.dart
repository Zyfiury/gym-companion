import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_data.dart';
import 'backend_config.dart';
import 'supabase_service.dart';

class ExportService {
  static Future<void> exportWeightCSV(UserData user) async {
    List<List<dynamic>> rows;
    if (BackendConfig.hasSupabase && SupabaseService.currentUser != null) {
      final history = await SupabaseService.getWeightHistory();
      rows = [
        ['Date', 'Weight (kg)'],
        ...history.map((e) => [e['date'], e['weight_kg']]),
      ];
    } else {
      rows = [
        ['Date', 'Weight (kg)'],
        ...user.weightHistory.map((e) => [e['date'], e['weight']]),
      ];
    }
    await _shareCsv(rows, 'weight_history.csv');
  }

  static Future<void> exportProgressPDF(UserData user, {String? displayName}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Gym Companion - Progress Report',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('${displayName ?? "Athlete"} | Goal: ${user.goal} | ${user.weight}kg | Level ${user.gamification['level'] ?? 1}'),
            pw.SizedBox(height: 20),
            pw.Text('Weight History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Date', 'Weight (kg)'],
              data: user.weightHistory.map((e) => [e['date'], '${e['weight']}']).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Personal Records', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (user.personalRecords.isNotEmpty)
              pw.Table.fromTextArray(
                headers: ['Lift', 'Value', 'Date'],
                data: user.personalRecords.map((e) => [e['lift'], e['value'], e['date']]).toList(),
              ),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gym_companion_progress.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'My progress report from Gym Companion');
  }

  static Future<void> _shareCsv(List<List<dynamic>> rows, String filename) async {
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported from Gym Companion');
  }
}
