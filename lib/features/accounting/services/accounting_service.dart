import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/paginated_response.dart';
import '../models/account_model.dart';
import '../models/voucher_model.dart';

class AccountingService {
  AccountingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaginatedResponse<AccountModel>> getAccounts({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<AccountModel>(
      ApiEndpoints.accounts,
      queryParameters: filters,
      itemFromJson: AccountModel.fromJson,
    );
  }

  Future<PaginatedResponse<VoucherModel>> getVouchers({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<VoucherModel>(
      ApiEndpoints.vouchers,
      queryParameters: filters,
      itemFromJson: VoucherModel.fromJson,
    );
  }

  Future<ApiResponse<VoucherModel>> getVoucher(int id) {
    return _apiClient.get<VoucherModel>(
      '${ApiEndpoints.vouchers}/$id',
      fromData: (json) => VoucherModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
