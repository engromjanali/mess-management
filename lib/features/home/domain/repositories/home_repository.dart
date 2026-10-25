import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';

/// Home repository contract (abstraction in the domain layer).
abstract class HomeRepository {
  /// Loads the aggregated dashboard for the current mess/session.
  ResultFuture<DashboardEntity> getDashboard();
}
