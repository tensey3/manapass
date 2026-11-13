import 'package:flutter/foundation.dart';

import 'review_data_source.dart';

class ReviewController extends ChangeNotifier {
  ReviewController(this._source);
  final ReviewDataSource _source;

  ReviewData? data;
  Object? error;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await _source.load();
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
