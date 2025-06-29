import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/bottombar_controller.dart';
import 'controllers/user_controller.dart';
import 'utilities/app_theme.dart';
import 'views/my_point_view.dart';
import 'views/mypage.dart';
import 'views/number_auth_view.dart';
import 'views/overall_ranking_view.dart';
import 'views/root_view.dart';
import 'views/schedule_view.dart';
import 'views/signin_view.dart';
import 'views/tos_view.dart';
import 'components/qr_scanner.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);

  Get.put(AuthController());
  Get.put(BottomBarController());
  UserController.init();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder:
          (context, child) => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.regularTheme,
            builder: (BuildContext context, Widget? child) {
              final data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(
                  textScaleFactor: data.textScaleFactor >= 1.4 ? 1.4 : 1.0,
                ),
                child: child!,
              );
            },
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const SignInView()),
              GetPage(name: '/tos', page: () => const TosView()),
              GetPage(name: '/numberauth', page: () => const NumberAuthView()),
              GetPage(name: '/mypoint', page: () => MyPointView()),
              GetPage(
                name: '/overallRanking',
                page: () => OverallRankingView(),
              ),
              GetPage(name: '/home', page: () => const RootView()),
              GetPage(name: '/mypage', page: () => const MyPage()),
              GetPage(
                name: '/qr',
                page: () => QRScan(),
                transition: Transition.downToUp,
              ),
              GetPage(name: '/schedule', page: () => SchedulerScreen()),
            ],
          ),
    );
  }
}
