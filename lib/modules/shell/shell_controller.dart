import 'package:get/get.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) => currentIndex.value = index;
}
