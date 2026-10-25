import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/home/domain/entities/dashboard_entity.dart';

/// Home repository contract (abstraction in the domain layer).
abstract class HomeRepository {
  /// Loads the aggregated dashboard for the current mess/session.
  ResultFuture<DashboardEntity> getDashboard();
}
