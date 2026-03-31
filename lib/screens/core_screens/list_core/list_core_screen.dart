import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/providers/core_list_provider.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/utils/core_constants.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/core/core_app_bar.dart';
import 'package:truebpm/widgets/core/core_empty_state.dart';
import 'package:truebpm/widgets/core/core_list_item_card.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';

part 'list_core_screen_main.dart';
part 'list_core_screen_actions.dart';
part 'list_core_screen_ui.dart';
