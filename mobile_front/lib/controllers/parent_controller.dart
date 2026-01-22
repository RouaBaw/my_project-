import 'package:get/get.dart';
import '../models/child_model.dart';

class ParentController extends GetxController {
  var children = <Child>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Add sample data
    children.addAll([
      Child(
        id: '1',
        name: 'Mohamed Ali',
        nickname: 'Momo',
        age: '6',
        interests: ['Reading', 'Drawing', 'Math'],
      ),
      Child(
        id: '2',
        name: 'Sarah Ahmed',
        nickname: 'Soso',
        age: '8',
        interests: ['Music', 'Art', 'Dancing'],
      ),
      Child(
        id: '3',
        name: 'Omar Hassan',
        nickname: 'Omo',
        age: '5',
        interests: ['Sports', 'Animals'],
      ),
    ]);
  }

  void addChild(Child child) {
    children.add(child);
  }

  void updateChild(String id, Child updatedChild) {
    final index = children.indexWhere((child) => child.id == id);
    if (index != -1) {
      children[index] = updatedChild;
    }
  }

  void deleteChild(String id) {
    children.removeWhere((child) => child.id == id);
  }

  Child? getChildById(String id) {
    try {
      return children.firstWhere((child) => child.id == id);
    } catch (e) {
      return null;
    }
  }
}