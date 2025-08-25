import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/navigation/app_pages.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/styles/theme.dart';
import 'package:truebpm/services/storage_service.dart';
import 'package:truebpm/di/service_locator.dart';
import 'package:truebpm/utils/global_store.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations to portrait only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // logger.i("App starting up...");
    
    // logger.i("Initializing storage service...");
    await StorageService.init();
    // logger.i("Storage service initialized successfully");
    
    // logger.i("Setting up dependencies...");
    await setupDependencies();
    // logger.i("Dependencies setup completed");
    
    // logger.i("Starting Flutter app...");
    runApp(Main());
  } catch (error, stackTrace) {
    logger.e("Error during app initialization: $error\n$stackTrace");

    // Fallback: start minimal app even if there are errors
    runApp(MaterialApp(
      title: '${appConstants.appName} - Error',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('${appConstants.appName} initialization failed'),
              SizedBox(height: 8),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    ));
  }
}

class Main extends StatelessWidget {
  const Main({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme, // Luôn dùng light theme cho cả dark mode
      themeMode: ThemeMode.light, // Chỉ dùng light mode, không theo hệ thống
      navigatorKey: NavigationService.navigatorKey,
      title: appConstants.appName,
      initialRoute: AppRoutes.splash,
      routes: AppPages.routes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // mm/dd/yyyy
        Locale('en', 'GB'), // dd/MM/yyyy
        Locale('vi', 'VN'), // dd/MM/yyyy (Tiếng Việt)
        Locale('ja', 'JP'), // yyyy/MM/dd
      ],
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) { // Wrap with error boundary
          // logger.e("Widget error: ${errorDetails.exception}\n${errorDetails.stack}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Something went wrong'),
                  SizedBox(height: 8),
                  Text('${errorDetails.exception}'),
                ],
              ),
            ),
          );
        };
        return widget ?? Container();
      },
    );
  }
}
