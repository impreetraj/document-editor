import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Alignment, Stack;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WorkbookController extends GetxController {
  final String workbookId;
  final String userName;

  WorkbookController({required this.workbookId, required this.userName});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  RxList<String> sheets = <String>[].obs;
  RxString activeSheet = ''.obs;

  StreamSubscription? _workbookSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToWorkbook();
  }

  @override
  void onClose() {
    _workbookSubscription?.cancel();
    super.onClose();
  }

  void _listenToWorkbook() {
    _workbookSubscription = _firestore
        .collection('excel_sheets_metadata')
        .doc(workbookId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data['sheets'] != null) {
          List<String> loadedSheets = List<String>.from(data['sheets']);
          sheets.value = loadedSheets;
          if (activeSheet.value.isEmpty && loadedSheets.isNotEmpty) {
            activeSheet.value = loadedSheets.first;
          }
        }
      } else {
        
        addSheet('Sheet1');
      }
    });
  }

  void addSheet(String sheetName) {
    List<String> updatedSheets = List.from(sheets);
    if (!updatedSheets.contains(sheetName)) {
      updatedSheets.add(sheetName);
      
      _firestore.collection('excel_sheets_metadata').doc(workbookId).set({
        'sheets': updatedSheets,
      }, SetOptions(merge: true));
      
      
      sheets.value = updatedSheets;
      activeSheet.value = sheetName;
    }
  }

  void setActiveSheet(String sheetName) {
    if (sheets.contains(sheetName)) {
      activeSheet.value = sheetName;
    }
  }

  Future<void> exportEntireWorkbook() async {
    try {
      Get.snackbar('Exporting', 'Gathering data for all sheets...', snackPosition: SnackPosition.BOTTOM);

      final Workbook workbook = Workbook();
      
      if (sheets.isEmpty) {
        workbook.dispose();
        return;
      }

      for (int i = 0; i < sheets.length; i++) {
        String sheetName = sheets[i];
        Worksheet worksheet;
        if (i == 0) {
          worksheet = workbook.worksheets[0];
          worksheet.name = sheetName;
        } else {
          worksheet = workbook.worksheets.addWithName(sheetName);
        }

        var snapshot = await _firestore.collection('excel_sheets').doc('${workbookId}_$sheetName').get();
        if (snapshot.exists) {
          var data = snapshot.data();
          if (data != null && data['sheetData'] != null) {
            List<dynamic> rawData = data['sheetData'];
            
            worksheet.getRangeByName('A1').setText('A');
            worksheet.getRangeByName('B1').setText('B');
            worksheet.getRangeByName('C1').setText('C');
            worksheet.getRangeByName('D1').setText('D');
            worksheet.getRangeByName('E1').setText('E');
            worksheet.getRangeByName('F1').setText('F');
            worksheet.getRangeByName('G1').setText('G');
            worksheet.getRangeByName('H1').setText('H');
            worksheet.getRangeByName('I1').setText('I');
            
            worksheet.getRangeByName('A1:I1').cellStyle.bold = true;

            for (int r = 0; r < rawData.length; r++) {
               var row = rawData[r];
               int rowIndex = r + 2;
               worksheet.getRangeByIndex(rowIndex, 1).setText(row['A']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 2).setText(row['B']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 3).setText(row['C']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 4).setText(row['D']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 5).setText(row['E']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 6).setText(row['F']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 7).setText(row['G']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 8).setText(row['H']?.toString() ?? '');
               worksheet.getRangeByIndex(rowIndex, 9).setText(row['I']?.toString() ?? '');
            }
          }
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      Uint8List uint8List = Uint8List.fromList(bytes);
      
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/${userName}_$workbookId.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(uint8List);

      await Share.shareXFiles([XFile(filePath)], text: 'My Full Workbook Data');

    } catch (e) {
      Get.snackbar('Error', 'Export Error: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
