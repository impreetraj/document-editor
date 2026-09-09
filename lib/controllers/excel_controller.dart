import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editing_file/datasource/datasource.dart';
import 'package:editing_file/model/Datasource.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import 'dart:convert';
import '../controllers/workbook_controller.dart';
class ExcelController extends GetxController {
  final String userName;
  final String excelId;

  late ExcelDataSource dataSource;
  final GlobalKey<SfDataGridState> gridKey = GlobalKey<SfDataGridState>();

  StreamSubscription<DocumentSnapshot>? _subscription;
  StreamSubscription? _mouseSubscription;
  
  Map<String, Map<String, dynamic>> activeMice = {};
  DateTime _lastMouseUpdate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExcelController({required this.userName, required this.excelId});

  @override
  void onInit() {
    super.onInit();
    dataSource = ExcelDataSource();
    dataSource.userName = userName;
    dataSource.excelId = excelId;
    
    _listenToFirebaseRealtime();
    _listenToMouseMovementsexcel();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _mouseSubscription?.cancel();
    super.onClose();
  }

  void _listenToMouseMovementsexcel() {
    _mouseSubscription = _firestore
        .collection('excel_sheets')
        .doc(excelId)
        .collection('mice')
        .snapshots()
        .listen((snapshot) {
      final mice = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        if (doc.id != userName) {
          mice[doc.id] = doc.data();
        }
      }
      activeMice = mice;
      update(['mice_layer']); // Only update widgets with ID 'mice_layer'
    });
  }

  void updateLocalMousePositionexcel(Offset localPosition) {
    if (DateTime.now().difference(_lastMouseUpdate).inMilliseconds > 100) {
      _lastMouseUpdate = DateTime.now();
      _firestore
          .collection('excel_sheets')
          .doc(excelId)
          .collection('mice')
          .doc(userName)
          .set({
        'x': localPosition.dx,
        'y': localPosition.dy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  bool isInitialLoad = true;

  void _listenToFirebaseRealtime() {
    _subscription = _firestore
        .collection('excel_sheets')
        .doc(excelId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null) {
          if (isInitialLoad || data['lastUpdatedBy'] != userName) {
            if (data['sheetData'] != null) {
              List<dynamic> rawData = data['sheetData'];
              List<DataSource> updatedRows = rawData
                  .map((e) => DataSource.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              dataSource.updateData(updatedRows);
            }
            isInitialLoad = false;
          }
        }
      }
    });
  }

  void saveData() async {
    Get.snackbar('Saving', 'Saving data....', snackPosition: SnackPosition.BOTTOM);

    try {
      List<Map<String, dynamic>> sheetData = dataSource.allEmployees
          .map((emp) => emp.toJson())
          .toList();

      await _firestore.collection('excel_sheets').doc(excelId).set({
        'sheetData': sheetData,
        'lastUpdatedBy': userName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar('Success', 'Data Saved', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Firebase Error: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        Get.snackbar('Importing', 'Reading file...', snackPosition: SnackPosition.BOTTOM);
        
        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        
        Archive archive = ZipDecoder().decodeBytes(bytes);
        
        List<String> sharedStrings = [];
        ArchiveFile? sstFile = archive.findFile('xl/sharedStrings.xml');
        if (sstFile != null) {
          final document = XmlDocument.parse(utf8.decode(sstFile.content as List<int>));
          final siElements = document.findAllElements('si');
          for (var si in siElements) {
            final t = si.findAllElements('t').map((e) => e.innerText).join();
            sharedStrings.add(t);
          }
        }
        
        // 1. Read xl/workbook.xml to find sheets
        ArchiveFile? workbookFile = archive.findFile('xl/workbook.xml');
        if (workbookFile == null) throw Exception("No workbook.xml found");
        final wbDoc = XmlDocument.parse(utf8.decode(workbookFile.content as List<int>));
        final sheetElements = wbDoc.findAllElements('sheet');
        
        List<Map<String, String>> sheetInfo = [];
        for (var s in sheetElements) {
          String name = s.getAttribute('name') ?? '';
          String rId = s.getAttribute('r:id') ?? '';
          if (name.isNotEmpty && rId.isNotEmpty) {
            sheetInfo.add({'name': name, 'rId': rId});
          }
        }

        // 2. Read rels to map rId to path
        ArchiveFile? relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
        if (relsFile == null) throw Exception("No workbook.xml.rels found");
        final relsDoc = XmlDocument.parse(utf8.decode(relsFile.content as List<int>));
        final relElements = relsDoc.findAllElements('Relationship');
        
        Map<String, String> rIdToTarget = {};
        for (var rel in relElements) {
          String id = rel.getAttribute('Id') ?? '';
          String target = rel.getAttribute('Target') ?? '';
          if (id.isNotEmpty && target.isNotEmpty) {
            rIdToTarget[id] = target;
          }
        }

        int lastUnderscore = excelId.lastIndexOf('_');
        String workbookId = lastUnderscore != -1 ? excelId.substring(0, lastUnderscore) : excelId;
        String currentSheetName = lastUnderscore != -1 ? excelId.substring(lastUnderscore + 1) : 'Sheet1';
        
        WorkbookController? workbookController;
        try {
           workbookController = Get.find<WorkbookController>(tag: workbookId);
        } catch (_) {}

        List<String> foundSheetNames = [];

        // 3. Process each sheet
        for (var info in sheetInfo) {
          String sheetName = info['name']!;
          String rId = info['rId']!;
          String? target = rIdToTarget[rId];
          
          if (target != null) {
            String pathInArchive = target.startsWith('xl/') ? target : 'xl/$target';
            ArchiveFile? sheetFile = archive.findFile(pathInArchive);
            
            if (sheetFile != null) {
              final document = XmlDocument.parse(utf8.decode(sheetFile.content as List<int>));
              final rowElements = document.findAllElements('row');
              
              List<DataSource> newRows = [];
              for (var row in rowElements) {
                if (newRows.length >= 100) break;
                
                var cElements = row.findAllElements('c');
                List<String> rowData = List.filled(9, '');
                
                for (var c in cElements) {
                  String r = c.getAttribute('r') ?? ''; 
                  String t = c.getAttribute('t') ?? 'n'; 
                  String v = '';
                  
                  var vElements = c.findElements('v');
                  if (vElements.isNotEmpty) {
                    v = vElements.first.innerText;
                    if (t == 's') {
                      int index = int.tryParse(v) ?? -1;
                      if (index >= 0 && index < sharedStrings.length) {
                        v = sharedStrings[index];
                      }
                    }
                  } else if (t == 'inlineStr') {
                    var isElements = c.findElements('is');
                    if (isElements.isNotEmpty) {
                      v = isElements.first.findAllElements('t').map((e) => e.innerText).join();
                    }
                  }
                  
                  if (r.isNotEmpty) {
                    String colLetter = r.replaceAll(RegExp(r'[0-9]'), '');
                    if (colLetter.isNotEmpty) {
                      int colIndex = colLetter.codeUnitAt(0) - 'A'.codeUnitAt(0);
                      if (colIndex >= 0 && colIndex < 9) {
                        rowData[colIndex] = v;
                      }
                    }
                  }
                }
                
                newRows.add(DataSource(
                  a: rowData[0], b: rowData[1], c: rowData[2], d: rowData[3],
                  e: rowData[4], f: rowData[5], g: rowData[6], h: rowData[7], i: rowData[8],
                ));
              }
              
              while (newRows.length < 100) {
                newRows.add(DataSource(a: '', b: '', c: '', d: '', e: '', f: '', g: '', h: '', i: ''));
              }

              foundSheetNames.add(sheetName);

              if (sheetName == currentSheetName) {
                dataSource.updateData(newRows);
                saveData();
              } else {
                List<Map<String, dynamic>> sheetData = newRows.map((emp) => emp.toJson()).toList();
                await _firestore.collection('excel_sheets').doc('${workbookId}_$sheetName').set({
                  'sheetData': sheetData,
                  'lastUpdatedBy': userName,
                  'lastUpdated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            }
          }
        }

        if (workbookController != null && foundSheetNames.isNotEmpty) {
          for (var name in foundSheetNames) {
            workbookController.addSheet(name);
          }
        }

        Get.snackbar('Success', 'File Imported Successfully', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to import: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
