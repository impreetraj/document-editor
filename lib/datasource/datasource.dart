import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editing_file/model/Datasource.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';


  class ExcelDataSource extends DataGridSource {
  late List<DataSource> _rows;
  List<DataGridRow> _dataGridRows = [];

  String? userName;
  String? excelId;

  List<DataSource> get allEmployees => _rows;

  ExcelDataSource() {
    _rows = List.generate(
      100,
      (index) => DataSource(a: '', b: '', c: '', d: '', e: '' , f: '', g:'' , h:'' , i :'' ),
    );

    _buildRows();
  }

  void updateData(List<DataSource> newRows) {
    _rows = newRows;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    int rowIndex = 1;
    _dataGridRows = _rows
        .map(
          (row) => DataGridRow(
            cells: [
              DataGridCell<int>(columnName: 'RowIndex', value: rowIndex++),
              DataGridCell<String>(columnName: 'A', value: row.a),
              DataGridCell<String>(columnName: 'B', value: row.b),
              DataGridCell<String>(columnName: 'C', value: row.c),
              DataGridCell<String>(columnName: 'D', value: row.d),
              DataGridCell<String>(columnName: 'E', value: row.e),
              DataGridCell<String>(columnName: 'F', value: row.f),
              DataGridCell<String>(columnName: 'G', value: row.g),
              DataGridCell<String>(columnName: 'H', value: row.h),
              DataGridCell<String>(columnName: 'I', value: row.i),
            ],
          ),
        )
        .toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'RowIndex') {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Text(
              cell.value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(cell.value.toString()),
        );
      }).toList(),
    );
  }

  @override
  Widget? buildEditWidget(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
    CellSubmit submitCell,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: _editingController,
        focusNode: _focusNode,
        onChanged: (value) {
          _newValue = value;
        },
        onSubmitted: (_) => submitCell(),
      ),
    );
  }

  dynamic _newValue;
  TextEditingController? _editingController;
  FocusNode? _focusNode;

  @override
  Future<void> onCellSubmit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) async {
    if (_newValue == null) return;

    final index = _dataGridRows.indexOf(dataGridRow);

    switch (column.columnName) {
      case 'A':
        _rows[index].a = _newValue;
        break;
      case 'B':
        _rows[index].b = _newValue;
        break;
      case 'C':
        _rows[index].c = _newValue;
        break;
      case 'D':
        _rows[index].d = _newValue;
        break;
      case 'E':
        _rows[index].e = _newValue;
        break;
      case 'F':
        _rows[index].f = _newValue;
        break;
      case 'G':
        _rows[index].g = _newValue;
        break;
      case 'H':
        _rows[index].h = _newValue;
        break;
      case 'I':
        _rows[index].i = _newValue;
        break;
    }

    _buildRows();
    notifyListeners();

    if (excelId != null && userName != null) {
      FirebaseFirestore.instance.collection('excel_sheets').doc(excelId).set({
        'sheetData': _rows.map((emp) => emp.toJson()).toList(),
        'lastUpdatedBy': userName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    _editingController?.dispose();
    _editingController = null;
    _focusNode?.dispose();
    _focusNode = null;
  }

  @override
  Future<bool> canSubmitCell(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) async {
    return true;
  }

  @override
  bool onCellBeginEdit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) {
    if (column.columnName == 'RowIndex') return false;
    
    _newValue = dataGridRow
        .getCells()
        .firstWhere((e) => e.columnName == column.columnName)
        .value;

    _editingController = TextEditingController(text: _newValue?.toString() ?? '');
    _focusNode = FocusNode();
    _focusNode?.requestFocus();
    
    return true;
  }

  @override
  void onCellCancelEdit(
    DataGridRow dataGridRow,
    RowColumnIndex rowColumnIndex,
    GridColumn column,
  ) {
    _newValue = null;
    _editingController?.dispose();
    _editingController = null;
    _focusNode?.dispose();
    _focusNode = null;
  }
}
