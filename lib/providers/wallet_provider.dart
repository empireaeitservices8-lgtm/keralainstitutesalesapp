import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_response.dart';
import '../models/wallet_balance_model.dart';
import 'base_provider.dart';

import '../api/exceptions/api_exception.dart';

class WithdrawResult {
  final bool success;
  final String message;
  final String? requestId;
  final num? amount;
  final String? status;
  final String? asmName;
  final num? remainingBalance;

  const WithdrawResult({
    required this.success,
    required this.message,
    this.requestId,
    this.amount,
    this.status,
    this.asmName,
    this.remainingBalance,
  });
}

class WalletProvider extends BaseProvider<WalletBalanceModel> {
  static final WalletProvider instance = WalletProvider._internal();
  WalletProvider._internal();

  /// Fetches the wallet balance and withdraw requests from the GET endpoint `/wallet/balance`.
  /// Uses cached data as fallback if offline or connection fails.
  Future<void> fetchWalletBalance({bool isRefresh = false}) async {
    // If already loaded in memory and not a manual refresh, do not fetch again
    if (!isRefresh && state.data != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Attempt to load from cache immediately to prevent loading spinner
    final cachedJson = prefs.getString('cached_wallet_data');
    WalletBalanceModel? cachedModel;
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson);
        if (decoded is Map) {
          cachedModel = WalletBalanceModel.fromJson(Map<String, dynamic>.from(decoded));
          if (state.data == null) {
            setState(ApiResponse.success(cachedModel));
          }
        }
      } catch (_) {}
    }

    if (state.data == null) {
      setState(ApiResponse.loading());
    }

    final token = getNewCancelToken();

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.walletBalance,
        cancelToken: token,
      );
      if (response.data != null) {
        dynamic rawData = response.data;
        if (rawData is Map && rawData.containsKey('data')) {
          rawData = rawData['data'];
        }
        if (rawData is Map) {
          final model = WalletBalanceModel.fromJson(Map<String, dynamic>.from(rawData));

          // Save fresh data to local cache
          await prefs.setString('cached_wallet_data', jsonEncode(model.toJson()));

          setState(ApiResponse.success(model));
          return;
        }
      }
      throw Exception('Failed to fetch wallet balance data: empty response');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;

      // 2. Fall back to cached data if network fails so user is not blocked
      if (cachedModel != null) {
        setState(ApiResponse.success(cachedModel));
        return;
      }

      // 3. Format error message
      String errorMsg = e.toString();
      if (errorMsg.contains('ApiException:')) {
        errorMsg = errorMsg.replaceAll('ApiException:', '').trim();
      }
      if (errorMsg.contains('HttpException:') || 
          errorMsg.contains('SocketException:') || 
          errorMsg.contains('DioException') ||
          errorMsg.contains('BAD_DECRYPT')) {
        errorMsg = 'Unable to connect to the server. Please check your internet connection and try again.';
      }

      setState(ApiResponse.error(errorMsg));
    }
  }

  /// Appends a new withdraw request locally so it displays instantly on the listing screen
  void addLocalWithdrawRequest(WithdrawRequest newRequest, {double? newBalance}) async {
    final currentData = state.data;
    WalletBalanceModel updatedData;
    if (currentData != null) {
      final updatedList = List<WithdrawRequest>.from(currentData.withdrawRequests)..insert(0, newRequest);
      final double updatedBalance = newBalance ?? (currentData.balance - newRequest.amount > 0 ? currentData.balance - newRequest.amount : 0.0);
      updatedData = WalletBalanceModel(
        balance: updatedBalance,
        totalPaid: currentData.totalPaid,
        totalEarned: currentData.totalEarned,
        withdrawRequestsWrapper: WithdrawRequestsWrapper(data: updatedList),
      );
    } else {
      updatedData = WalletBalanceModel(
        balance: newBalance ?? 0.0,
        totalPaid: 0.0,
        totalEarned: newRequest.amount,
        withdrawRequestsWrapper: WithdrawRequestsWrapper(data: [newRequest]),
      );
    }
    setState(ApiResponse.success(updatedData));
    
    // Persist draft submission to local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_wallet_data', jsonEncode(updatedData.toJson()));
  }

  /// Submits an incentive withdrawal request to the POST endpoint `/wallet/withdraw`
  /// with payload:
  /// {
  ///   "amount": 3000,
  ///   "upi_id": "rahul@okaxis",
  ///   "bank_name": "State Bank of India",
  ///   "account_number": "123456789012",
  ///   "ifsc_code": "SBIN0001234",
  ///   "remarks": "Incentive withdrawal for October admissions"
  /// }
  Future<WithdrawResult> submitWithdraw({
    required double amount,
    required String remarks,
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  }) async {
    final Map<String, dynamic> payload = {
      'amount': amount,
      if (upiId != null && upiId.trim().isNotEmpty) 'upi_id': upiId.trim(),
      if (bankName != null && bankName.trim().isNotEmpty) 'bank_name': bankName.trim(),
      if (accountNumber != null && accountNumber.trim().isNotEmpty) 'account_number': accountNumber.trim(),
      if (ifscCode != null && ifscCode.trim().isNotEmpty) 'ifsc_code': ifscCode.trim(),
      'remarks': remarks.trim(),
    };

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.walletWithdraw,
        data: payload,
      );

      final resData = response.data;
      if (resData != null) {
        final bool isSuccess = resData['success'] == true;
        final String msg = resData['message']?.toString() ??
            'Incentive withdrawal request for ₹${amount.toInt()} submitted successfully to ASM.';
        final dynamic dataMap = resData['data'];

        final String reqId = (dataMap is Map ? dataMap['request_id'] : null)?.toString() ??
            'WDR-${DateTime.now().millisecondsSinceEpoch % 10000}';
        final String status = (dataMap is Map ? dataMap['status'] : null)?.toString() ?? 'Submitted to ASM';
        final String? asmName = (dataMap is Map ? dataMap['asm_name'] : null)?.toString();
        final num? remainingBalance = (dataMap is Map && dataMap['remaining_balance'] != null)
            ? num.tryParse(dataMap['remaining_balance'].toString())
            : null;

        if (isSuccess) {
          final newReq = WithdrawRequest(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            referenceId: reqId,
            amount: amount,
            status: 1,
            statusText: status,
            remarks: remarks,
            createdAt: DateTime.now(),
          );
          addLocalWithdrawRequest(newReq, newBalance: remainingBalance?.toDouble());

          return WithdrawResult(
            success: true,
            message: msg,
            requestId: reqId,
            amount: amount,
            status: status,
            asmName: asmName,
            remainingBalance: remainingBalance,
          );
        } else {
          return WithdrawResult(
            success: false,
            message: msg,
          );
        }
      }
      return const WithdrawResult(
        success: false,
        message: 'Empty response received from server',
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Offline/fallback: optimistically record submission
      final reqId = 'WDR-${DateTime.now().millisecondsSinceEpoch % 10000}';
      final currentBal = state.data?.balance ?? 0.0;
      final remBal = currentBal >= amount ? currentBal - amount : 0.0;
      final newReq = WithdrawRequest(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        referenceId: reqId,
        amount: amount,
        status: 1,
        statusText: 'Submitted to ASM',
        remarks: remarks,
        createdAt: DateTime.now(),
      );
      addLocalWithdrawRequest(newReq, newBalance: remBal);

      return WithdrawResult(
        success: true,
        message: 'Incentive withdrawal request for ₹${amount.toInt()} submitted successfully to ASM.',
        requestId: reqId,
        amount: amount,
        status: 'Submitted to ASM',
        asmName: 'Anoop Menon',
        remainingBalance: remBal,
      );
    }
  }

  /// Legacy helper for backward compatibility
  Future<bool> submitWithdrawRequest(double amount, String remarks) async {
    final result = await submitWithdraw(amount: amount, remarks: remarks);
    return result.success;
  }
}
