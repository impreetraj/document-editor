import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../controllers/excel_controller.dart';

class SheetWidget extends StatelessWidget {
  final String workbookId;
  final String sheetName;
  final String userName;

  const SheetWidget({
    super.key,
    required this.workbookId,
    required this.sheetName,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final String sheetId = '${workbookId}_$sheetName';
    
    final ExcelController controller = Get.put(
      ExcelController(userName: userName, excelId: sheetId),
      tag: sheetId,
    );

    return Listener(
      onPointerHover: (event) => controller.updateLocalMousePositionexcel(event.localPosition),
      onPointerMove: (event) => controller.updateLocalMousePositionexcel(event.localPosition),
      child: Stack(
        children: [
          SfDataGrid(
            key: controller.gridKey,
            source: controller.dataSource,
            allowEditing: true,
            navigationMode: GridNavigationMode.cell,
            selectionMode: SelectionMode.single,
            defaultColumnWidth: 100,
            gridLinesVisibility: GridLinesVisibility.both,
            headerGridLinesVisibility: GridLinesVisibility.both,
            frozenColumnsCount: 1,
            columns: [
              GridColumn(
                columnName: 'RowIndex',
                width: 50,
                allowEditing: false,
                label: Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Text(''),
                ),
              ),
              GridColumn(
                columnName: 'A',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'B',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'C',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('C', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'D',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('D', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'E',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('E', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'F',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'G',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('G', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'H',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('H', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              GridColumn(
                columnName: 'I',
                label: Container(
                  alignment: Alignment.center,
                  child: const Text('I', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: GetBuilder<ExcelController>(
              id: 'mice_layer',
              tag: sheetId,
              builder: (ctrl) {
                return Stack(
                  fit: StackFit.expand,
                  children: ctrl.activeMice.entries.map((entry) {
                    final data = entry.value;
                    final x = data['x'] as double? ?? 0.0;
                    final y = data['y'] as double? ?? 0.0;

                    return Positioned(
                      left: x,
                      top: y,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.pan_tool_alt,
                            color: Colors.redAccent,
                            size: 24,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.key.isNotEmpty ? entry.key.substring(0, 1) : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
