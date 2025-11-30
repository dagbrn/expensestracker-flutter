import 'package:get/get.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/transactions/add_transaction_binding.dart';
import '../modules/transactions/add_transaction_view.dart';
import '../modules/reports/reports_binding.dart';
import '../modules/reports/reports_view.dart';
import '../modules/main/main_binding.dart';
import '../modules/main/main_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.MAIN;

  static final routes = [
    GetPage(
      name: Routes.MAIN,
      page: () => MainView(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.ADD_TRANSACTION,
      page: () => AddTransactionView(),
      binding: AddTransactionBinding(),
    ),
    GetPage(
      name: Routes.REPORTS,
      page: () => ReportsView(),
      binding: ReportsBinding(),
    ),
  ];
}
