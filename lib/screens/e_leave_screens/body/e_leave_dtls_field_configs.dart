class ELeaveDtlsFieldConfigs {
  const ELeaveDtlsFieldConfigs._();

  static List<Map<String, dynamic>> generalInfoPrimaryFields() {
    return [
      {
        'key': 'status',
        'widget': 'status',
        'showIcon': true,
        'visibleWhen': {'key': 'id', 'operator': 'ne', 'value': null},
      },
      {'key': 'code', 'label': 'Code', 'type': 'text', 'disabled': true},
      {
        'key': 'startDate',
        'widget': 'datetime',
        'label': 'Start Date - End Date',
        'datetimeType': 'daterange',
        'startDateKey': 'startDate',
        'endDateKey': 'endDate',
        'displayFormat': 'ddMMyyyy',
        'hintText': 'Select leave duration...',
        'required': true,
      },
      {
        'key': 'leaveTime',
        'widget': 'select',
        'selectType': 'dropdown',
        'label': 'Date Status',
        'hintText': 'Select leave time',
        'data': 'DROPDOWN.ELEAVE/LEAVETIME',
        'display': 'name',
        'required': true,
      },
      {
        'key': 'totalDays',
        'label': 'Total Days',
        'type': 'number',
        'decimalPlaces': 1,
        'disabled': true,
      },
      {
        'key': 'leaveType',
        'widget': 'select',
        'selectType': 'dropdown',
        'label': 'I wish to apply for',
        'hintText': 'Select leave type',
        'data': 'DROPDOWN.ELEAVE/LEAVETYPE',
        'display': 'name',
        'required': true,
      },
    ];
  }

  static List<Map<String, dynamic>> generalInfoSecondaryFields() {
    return [
      {
        'key': 'leaveReason',
        'label': 'Reason',
        'type': 'textarea',
        'required': true,
        'maxLines': 3,
        'hintText': 'Enter leave reason...',
      },
    ];
  }

  static List<Map<String, dynamic>> systemInfoFields() {
    return [
      {
        'key': 'createdBy',
        'label': 'Created By',
        'hintText': 'Created by user',
        'type': 'text',
        'disabled': true,
      },
      {
        'key': 'createdDate',
        'widget': 'datetime',
        'label': 'Created Date',
        'datetimeType': 'datetime',
        'displayFormat': 'ddMMyyyy',
        'hintText': 'Record creation date',
        'disabled': true,
      },
    ];
  }
}
