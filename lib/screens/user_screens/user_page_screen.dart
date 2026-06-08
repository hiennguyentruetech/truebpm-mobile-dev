import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/user_screens/body/user_annual_leave_history_tab_body.dart';
import 'package:truebpm/screens/user_screens/body/user_dtls_tab_body.dart';
import 'package:truebpm/screens/user_screens/body/user_membership_tab_body.dart';
import 'package:truebpm/screens/user_screens/detail_user_screen.dart';

/// User Page
class UserPageScreen extends StatelessWidget {
  const UserPageScreen({super.key});

  static const String moduleCode = 'USER';
  static const String moduleName = 'User';
  static const String defaultTabCode = 'DTLS';

  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: UserDetailsTabBody.new,
    ),
    TabConfig(
      code: 'MBS',
      name: 'Membership',
      tabBodyBuilder: UserMembershipTabBody.new,
    ),
    TabConfig(
      code: 'ANNUALLEAVEHISTORY',
      name: 'Add/Subtract Annual Leave Days',
      tabBodyBuilder: UserAnnualLeaveHistoryTabBody.new,
    ),
    TabConfig(
      code: 'CMT',
      name: 'Comments',
      tabBodyBuilder: TabCmtCoreBodyScreen.new,
    ),
    TabConfig(
      code: 'DOC',
      name: 'Documents',
      tabBodyBuilder: TabDocCoreBodyScreen.new,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListCoreScreen(
      moduleCode: moduleCode,
      moduleName: moduleName,
      tabModuleCode: defaultTabCode,
      availableTabs: availableTabs,
      detailScreenBuilder: _createDetailScreen,
    );
  }

  Widget? _createDetailScreen(
    BuildContext context,
    Map<String, dynamic> listItem,
  ) {
    return DetailUserScreen(listItem: listItem, initialTabCode: defaultTabCode);
  }
}
