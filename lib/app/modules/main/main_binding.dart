import 'package:get/get.dart';
import 'main_controller.dart';
import '../home/home_controller.dart';
import '../transactions/transactions_controller.dart';
import '../reports/reports_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(
      () => MainController(),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
    Get.lazyPut<ReportsController>(
      () => ReportsController(),
    );
    Get.lazyPut<TransactionsController>(() => TransactionsController());
  }
}
