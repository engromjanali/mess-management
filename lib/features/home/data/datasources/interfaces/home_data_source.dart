import 'package:clean_boilerplate/features/home/data/models/dashboard_model.dart';

/// Contract for any source that can provide dashboard data.
abstract class HomeDataSource {
  Future<DashboardModel> getDashboard();
}
