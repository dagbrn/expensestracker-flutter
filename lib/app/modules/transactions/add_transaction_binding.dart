import 'package:get/get.dart';
import 'add_transaction_controller.dart';

class AddTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddTransactionController>(
      () => AddTransactionController(),
    );
  }
}
