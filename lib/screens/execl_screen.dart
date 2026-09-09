import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../controllers/excel_controller.dart';
import '../controllers/workbook_controller.dart';
import 'sheet_widget.dart';

class ExcelScreen extends StatelessWidget {
  final String? userName;
  final String? excelId;

  const ExcelScreen({super.key, required this.excelId, required this.userName});

  @override
  Widget build(BuildContext context) {
    // Initialize the workbook controller uniquely for each excelId
    final WorkbookController workbookController = Get.put(
      WorkbookController(userName: userName ?? '', workbookId: excelId ?? ''),
      tag: excelId, 
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("${userName ?? ''} - Workbook"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Toolbar
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    await Future.delayed(const Duration(milliseconds: 150));
                    final activeSheet = workbookController.activeSheet.value;
                    if (activeSheet.isNotEmpty) {
                      final ctrl = Get.find<ExcelController>(tag: '${excelId}_$activeSheet');
                      ctrl.saveData();
                    }
                  },
                ),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    await Future.delayed(const Duration(milliseconds: 150));
                    final activeSheet = workbookController.activeSheet.value;
                    if (activeSheet.isNotEmpty) {
                      final ctrl = Get.find<ExcelController>(tag: '${excelId}_$activeSheet');
                      ctrl.saveData();
                    }
                    workbookController.exportEntireWorkbook();
                  },
                ),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () {
                    final activeSheet = workbookController.activeSheet.value;
                    if (activeSheet.isNotEmpty) {
                      final ctrl = Get.find<ExcelController>(tag: '${excelId}_$activeSheet');
                      ctrl.importExcel();
                    }
                  },
                ),
                const SizedBox(width: 15),
                const Icon(Icons.copy),
                const SizedBox(width: 15),
                const Icon(Icons.paste),
                const SizedBox(width: 15),
                const Icon(Icons.undo),
                const SizedBox(width: 15),
                const Icon(Icons.redo),
              ],
            ),
          ),
          
          // Sheet content area
          Expanded(
            child: Obx(() {
              if (workbookController.sheets.isEmpty || workbookController.activeSheet.value.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final activeSheet = workbookController.activeSheet.value;
              return SheetWidget(
                key: ValueKey('${excelId}_$activeSheet'), // ensures rebuild on sheet change
                workbookId: excelId ?? '',
                sheetName: activeSheet,
                userName: userName ?? '',
              );
            }),
          ),

          // Bottom Tabs Bar
          SafeArea(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      // Access activeSheet here so Obx tracks it
                      final currentActive = workbookController.activeSheet.value;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: workbookController.sheets.length,
                        itemBuilder: (context, index) {
                          final sheet = workbookController.sheets[index];
                          final isActive = currentActive == sheet;
                          return GestureDetector(
                            onTap: () => workbookController.setActiveSheet(sheet),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.grey.shade200,
                                border: Border(
                                  right: BorderSide(color: Colors.grey.shade300),
                                  bottom: BorderSide(
                                    color: isActive ? Colors.transparent : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Text(
                                sheet,
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isActive ? Colors.green.shade700 : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      final nextIndex = workbookController.sheets.length + 1;
                      workbookController.addSheet('Sheet$nextIndex');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


