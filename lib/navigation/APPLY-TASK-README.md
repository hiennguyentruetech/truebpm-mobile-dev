# Task Navigation System

## Overview

Hệ thống navigation cho task đã được refactor để dễ dàng khai báo và mở rộng các module types mới.

## Cấu trúc

```
lib/navigation/
├── index.dart                     # Export file
├── task_navigation_config.dart    # Config và factory classes
└── task_navigation_service.dart   # Navigation service
```

## Cách sử dụng

### 1. Basic Navigation (từ task data)

```dart
import 'package:truebpm/navigation/task_navigation_service.dart';

// Navigate từ task object
await TaskNavigationService.navigateToTaskDetail(
  context,
  task,
  onReturn: () {
    // Callback khi user quay lại
    print('User returned from task detail');
  },
);
```

### 2. Custom Navigation với Config

```dart
import 'package:truebpm/navigation/index.dart';

// Tạo custom config
final config = TaskNavigationConfig(
  moduleCode: 'OVTIME',
  listItemId: '123',
  taskId: '456',
  initialTabCode: 'DTLS',
  fromTaskScreen: true,
);

// Navigate với config
await TaskNavigationService.navigateWithConfig(
  context,
  config,
  onReturn: () => print('Done!'),
);
```

### 3. Quick Navigation (ví dụ từ notification)

```dart
// Direct navigation với parameters
await TaskNavigationService.quickNavigate(
  context,
  moduleCode: 'OVTIME',
  listItemId: '123',
  taskId: '456',
  onReturn: () => refreshData(),
);
```

## Thêm Module Type Mới

### 1. Thêm vào Enum

```dart
// Trong task_navigation_config.dart
enum TaskModuleType {
  overtime('OVTIME'),
  generic('GENERIC'),
  newModule('NEW_MODULE'), // Thêm module mới
}
```

### 2. Cập nhật fromCode method

```dart
static TaskModuleType fromCode(String moduleCode) {
  switch (moduleCode.toUpperCase()) {
    case 'OVTIME':
      return TaskModuleType.overtime;
    case 'NEW_MODULE':
      return TaskModuleType.newModule;
    default:
      return TaskModuleType.generic;
  }
}
```

### 3. Thêm vào TaskScreenFactory

```dart
static Widget createScreen(TaskNavigationConfig config) {
  final moduleType = TaskModuleType.fromCode(config.moduleCode);
  
  switch (moduleType) {
    case TaskModuleType.overtime:
      return DetailOTScreen(...);
    
    case TaskModuleType.newModule:
      return NewModuleDetailScreen(...); // Screen cho module mới
    
    case TaskModuleType.generic:
      return GenericDetailCoreScreen(...);
  }
}
```

### 4. Cập nhật Extension (optional)

```dart
extension TaskModuleTypeExtension on TaskModuleType {
  String get displayName {
    switch (this) {
      case TaskModuleType.overtime:
        return 'Overtime';
      case TaskModuleType.newModule:
        return 'New Module'; // Display name
      case TaskModuleType.generic:
        return 'General Task';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskModuleType.overtime:
        return Icons.access_time;
      case TaskModuleType.newModule:
        return Icons.new_releases; // Icon cho module mới
      case TaskModuleType.generic:
        return Icons.task_alt;
    }
  }
}
```

## Helper Methods

```dart
// Check xem module có được support không
bool isSupported = TaskNavigationService.isModuleSupported('OVTIME');

// Get module type từ task
TaskModuleType moduleType = TaskNavigationService.getModuleType(task);

// Get display name và icon
String displayName = moduleType.displayName;
IconData icon = moduleType.icon;
```

## Ví dụ Thực Tế

### Thêm Leave Request Module

1. **Thêm enum:**
```dart
enum TaskModuleType {
  overtime('OVTIME'),
  leaveRequest('LEAVE'),
  generic('GENERIC'),
}
```

2. **Cập nhật factory:**
```dart
case TaskModuleType.leaveRequest:
  return LeaveRequestDetailScreen(
    listItem: {'id': config.listItemId},
    initialTabCode: config.initialTabCode,
    fromTaskScreen: config.fromTaskScreen,
    taskId: config.taskId,
  );
```

3. **Sử dụng:**
```dart
// Tự động navigate dựa trên module code 'LEAVE'
await TaskNavigationService.navigateToTaskDetail(context, task);
```

## Lợi ích của cấu trúc mới

✅ **Dễ khai báo:** Chỉ cần thêm vào enum và switch case  
✅ **Type Safe:** Sử dụng enum thay vì magic strings  
✅ **Scalable:** Dễ dàng thêm module types mới  
✅ **Maintainable:** Code được tổ chức rõ ràng  
✅ **Reusable:** Có thể dùng từ nhiều nơi khác nhau  
✅ **Flexible:** Hỗ trợ cả basic và advanced navigation  
