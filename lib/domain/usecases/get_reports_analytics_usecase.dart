import '../../core/utils/resource.dart';
import '../../models/report_model.dart';
import '../repositories/order_repository.dart';

class GetReportsAnalyticsUseCase {
  final OrderRepository repository;

  GetReportsAnalyticsUseCase(this.repository);

  Future<Resource<ReportData>> execute({String? userPin, String? startDate, String? endDate}) {
    return repository.getReportsAnalytics(userPin: userPin, startDate: startDate, endDate: endDate);
  }
}
