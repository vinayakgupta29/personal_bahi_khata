import 'dart:async';
import 'package:personal_bahi_khata/data/database.dart';

// Define a simple notifier class
class ExpenseNotifier {
  final _controller = StreamController<List<Expense>>.broadcast();

  Stream<List<Expense>> get stream => _controller.stream;

  void update(List<Expense> value) {
    _controller.sink.add(value);
  }

  void dispose() {
    _controller.close();
  }
}
