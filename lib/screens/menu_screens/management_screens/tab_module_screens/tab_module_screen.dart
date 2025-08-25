import 'package:flutter/material.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';

class TabModuleScreen extends StatelessWidget {
  const TabModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListCoreScreen(
      moduleCode: 'TABMODULE',
      moduleName: 'Quản lý Tab Module',
      tabModuleCode: 'DTLS',
    );
  }
}
