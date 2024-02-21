import 'package:personal_finance_tracker/data/database.dart';
import 'dart:async';


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
