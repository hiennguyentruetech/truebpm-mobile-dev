import 'package:truebpm/utils/global_store.dart';

class HostStrings {
  final String main;
  final String bonitaService;
  final String coreService;
  final String portalService;
  final String applicationId;

  final String bonitaUrl;
  final String systemUrl;
  final String bpmUrl;
  final String coreUrl;
  final String flexAPIUrl;

  HostStrings({
    this.main                           = 'https://truebpm.truetech.com.vn/',
    this.bonitaService                  = 'bonita/',
    this.coreService                    = 'bonita/apps/',
    this.portalService                  = 'bonita/portal/resource/app/',
    this.applicationId                  = '301', // TrueBPM application ID
  })  : bonitaUrl                       = '${main}bonita/',
        systemUrl                       = '$main$coreService${appConstants.appNameParams}/API/system/',
        bpmUrl                          = '$main$portalService${appConstants.appNameParams}/task-list/API/bpm/',
        coreUrl                         = '$main$coreService${appConstants.appNameParams}/API/extension/',
        flexAPIUrl                      = '${main}bonita/api/';
}
