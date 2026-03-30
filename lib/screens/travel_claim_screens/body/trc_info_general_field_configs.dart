List<Map<String, dynamic>> buildTrcInfoGeneralFieldConfigs({
  required String encodedParentId,
  required bool hiddenDeductible,
}) {
  final fieldConfigs = [
    {
      'key': 'generalExpense',
      'widget': 'collection',
      'label': 'General Expense',
      // Dynamic header: show travel request code if available, else fallback index
      'titleTemplate': '{travelRequest.code}',
      'addButtonText': 'Add Expense',
      'hintText': 'No expense added yet. Click Add to create one.',
      'allowAdd': true,
      'allowRemove': true,
      'editMode': 'modal',
      'useFloatingAddButton': true,
      'useAddFirstList': true,
      'totalSummary': {
        'key': 'totalAfterTax',
        'label': 'Total After Tax',
        'format': '#,##0',
        'suffix': ' VND',
        'bgColor': '#E8F5E8',
        'borderColor': '#A5D6A7',
        'labelColor': '#2E7D32',
        'valueColor': '#1B5E20',
      },
      'summary': {
        'fields': [
          {
            'key': 'date',
            'label': 'Date',
            'type': 'date',
            'format': 'dd/MM/yyyy',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          {
            'key': 'expenseType',
            'display': 'name',
            'label': 'Type',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          {
            'key': 'locationObject',
            'display': 'name',
            'label': 'Location',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          {
            'key': 'purpose',
            'label': 'Purpose',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          // Deductible summary field will be conditionally removed below
          {
            'key': 'deductible',
            'label': 'Deductible',
            'type': 'number',
            'decimalPlaces': 0,
            'format': '#,##0',
            'suffix': ' %',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          {
            'key': 'total',
            'label': 'Total',
            'type': 'number',
            'decimalPlaces': 0,
            'format': '#,##0',
            'suffix': ' VND',
            'bgColor': '#E8F5E8',
            'borderColor': '#A5D6A7',
            'labelColor': '#2E7D32',
            'valueColor': '#1B5E20',
          },
          {
            'key': 'totalAfterTax',
            'label': 'Total After Tax',
            'type': 'number',
            'decimalPlaces': 0,
            'format': '#,##0',
            'suffix': ' VND',
            'bgColor': '#FFF4E6',
            'borderColor': '#FFCC99',
            'labelColor': '#C15700',
            'valueColor': '#A14400',
          },
        ],
      },
      'children': [
        {
          'key': 'travelRequest',
          'widget': 'select',
          'selectType': 'dropdown',
          'label': 'Travel Request',
          'data': 'DROPDOWN.TRACLA/TR.BYCLAIM?id=$encodedParentId',
          'display': 'code',
          'required': true,
          'hintText': 'Select travel request...',
          'clearOnChange': ['date'],
        },
        {
          'key': 'date',
          'widget': 'datetime',
          'label': 'Date',
          'datetimeType': 'date',
          'displayFormat': 'ddMMyyyy',
          'required': true,
          // Use dynamic paths for min/max constraints resolved at runtime
          'minDatePath': 'travelRequest.startDate',
          'maxDatePath': 'travelRequest.endDate',
          'requiredKeys': ['travelRequest.id'],
          // Provide default date when opening picker (startDate of travelRequest)
          'defaultDatePath': '_defaultDate_date',
          // Allow user to open even before picking travelRequest (will default today)
        },
        {
          'key': 'expenseType',
          'widget': 'select',
          'selectType': 'dropdown',
          'label': 'Expense Type',
          'data': 'DROPDOWN.TRACLA/EXP.TYPE.GENERAL',
          'display': 'name',
          'required': true,
        },
        {
          'key': 'locationObject',
          'widget': 'select',
          'selectType': 'dropdown',
          'label': 'Location',
          'data': 'DROPDOWN.TRACLA/LOC.BYCLAIM?id=$encodedParentId',
          'display': 'name',
          'required': true,
        },
        {
          'key': 'purpose',
          'label': 'Purpose',
          'type': 'textarea',
          'maxLines': 3,
          'required': true,
        },
        // Deductible child field (conditionally removed below)
        {
          'key': 'deductible',
          'label': 'Deductible (%)',
          'type': 'number',
          'suffix': ' %',
          'decimalPlaces': 0,
          'required': false,
        },
        {
          'key': 'total',
          'label': 'Total',
          'type': 'number',
          'suffix': ' VND',
          'decimalPlaces': 0,
          'required': true,
        },
        {
          'key': 'totalAfterTax',
          'label': 'Total After Tax',
          'type': 'number',
          'suffix': ' VND',
          'decimalPlaces': 0,
          'required': false,
          'disabled': true,
        },
      ],
    },
  ];

  if (hiddenDeductible) {
    // Remove deductible from summary fields
    final generalConfig = fieldConfigs.firstWhere(
      (e) => e['key'] == 'generalExpense',
    );
    final summary = generalConfig['summary'];
    if (summary is Map && summary['fields'] is List) {
      (summary['fields'] as List).removeWhere(
        (f) => f is Map && f['key'] == 'deductible',
      );
    }

    // Remove deductible from children
    if (generalConfig['children'] is List) {
      (generalConfig['children'] as List).removeWhere(
        (f) => f is Map && f['key'] == 'deductible',
      );
    }
  }

  return fieldConfigs;
}
