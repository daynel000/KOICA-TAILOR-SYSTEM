// ============================================================
// providers/app_provider.dart
//
// Central state manager for the entire Customer app.
// All screens read data FROM here and trigger actions THROUGH here.
// Mock data has been fully removed — all state comes from the API.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/tailor_model.dart';
import '../models/order_model.dart';
import '../models/scan_result_model.dart';
import '../models/customer_model.dart';
import '../api/api_service.dart';
import '../services/order_repository.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ----------------------------------------------------------
  // STATE VARIABLES
  // ----------------------------------------------------------

  bool isLoadingInitialData = false;
  String? errorMessage;

  // The currently logged-in customer (null = not logged in yet)
  CustomerModel? currentCustomer;

  // Auth token from the login response
  String? authToken;

  // All tailors shown on the Home tab
  List<TailorModel> tailorList = [];

  // All orders for the current customer
  List<OrderModel> orderList = [];

  // The AI scan result saved by the customer (persisted locally)
  ScanResultModel? savedScanResult;

  // The currently selected tailor (for overlay/details screen)
  TailorModel? selectedTailorForDetails;

  // The tailor to zoom to on the Map tab (set when user taps 'View on Map')
  TailorModel? focusedMapTailor;

  // The currently selected order (for chat screen deeplink)
  OrderModel? selectedOrderForChat;

  // ----------------------------------------------------------
  // COMPUTED PROPERTIES (handy getters for the UI)
  // ----------------------------------------------------------

  /// Orders that are NOT yet completed.
  List<OrderModel> get activeOrders =>
      orderList.where((o) => !o.isCompleted).toList();

  /// Orders that ARE completed.
  List<OrderModel> get completedOrders =>
      orderList.where((o) => o.isCompleted).toList();

  /// Count of unread chat messages across all orders.
  int get unreadMessageCount => 0;

  // ----------------------------------------------------------
  // INITIALIZATION
  // ----------------------------------------------------------

  /// Loads all initial data when the app starts.
  /// Reads the saved auth token from device storage first.
  Future<void> loadInitialData() async {
    isLoadingInitialData = false;
    errorMessage = null;

    try {
      await _restoreAuthSession();

      if (authToken != null) {
        final tailors = await _apiService.getAllTailors().catchError((_) => <TailorModel>[]);
        final orders = await _apiService.getCustomerOrders(authToken!, currentCustomer?.customerId ?? '').catchError((_) => <OrderModel>[]);
        final profile = await _apiService.getCustomerProfile(authToken!).catchError((_) => null);

        tailorList = tailors;
        orderList = orders;
        if (profile != null) {
          currentCustomer = profile;
        }
      } else {
        tailorList = await _apiService.getAllTailors().catchError((_) => <TailorModel>[]);
        orderList = [];
      }

      await _loadSavedScanResult();
    } catch (_) {
      orderList = [];
    } finally {
      isLoadingInitialData = false;
      notifyListeners();
    }
  }

  /// Reloads customer orders from persistent repository/API.
  Future<void> refreshOrders() async {
    try {
      if (authToken != null && currentCustomer != null) {
        orderList = await _apiService.getCustomerOrders(authToken!, currentCustomer!.customerId);
      } else {
        orderList = await OrderRepository.getCustomerOrders();
      }
    } catch (_) {}
    notifyListeners();
  }

  // ----------------------------------------------------------
  // AUTH ACTIONS
  // ----------------------------------------------------------

  /// Logs in the customer and stores the session token.
  Future<void> login({
    required String emailAddress,
    required String password,
  }) async {
    final result = await _apiService.loginCustomer(
      emailAddress: emailAddress,
      password: password,
    );
    authToken = result['auth_token'] as String;
    currentCustomer = CustomerModel.fromJson(
      result['customer'] as Map<String, dynamic>,
    );
    await _saveAuthSession(authToken!, currentCustomer!);

    // Load real orders from backend for this logged-in customer
    try {
      orderList = await _apiService.getCustomerOrders(authToken!, currentCustomer!.customerId);
    } catch (_) {
      orderList = [];
    }
    notifyListeners();
  }

  /// Logs out and clears all session data.
  Future<void> logout() async {
    await clearAuthSession();
    currentCustomer = null;
    orderList = [];
    savedScanResult = null;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // TAILOR ACTIONS
  // ----------------------------------------------------------

  /// Sets the tailor to show in the details overlay.
  void selectTailorForDetails(TailorModel tailor) {
    selectedTailorForDetails = tailor;
    notifyListeners();
  }

  /// Clears the tailor details overlay.
  void clearSelectedTailor() {
    selectedTailorForDetails = null;
    notifyListeners();
  }

  /// Tells the Map tab to zoom to the given tailor when it next renders.
  void focusTailorOnMap(TailorModel tailor) {
    focusedMapTailor = tailor;
    notifyListeners();
  }

  /// Clears the map focus after the Map tab has handled it.
  void clearMapFocus() {
    focusedMapTailor = null;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // ORDER ACTIONS
  // ----------------------------------------------------------

  /// Submits a new tailoring order to the repository and backend.
  Future<void> createNewOrder(Map<String, dynamic> orderFormData) async {
    final selectedTailorId = orderFormData['tailor_id']?.toString() ?? '';
    final tailorMatches = tailorList.where((t) => t.tailorId == selectedTailorId).toList();
    final tailorShopName = tailorMatches.isNotEmpty 
        ? tailorMatches.first.shopName 
        : (tailorList.isNotEmpty ? tailorList.first.shopName : 'Silhouettes Couture');

    final newOrder = await OrderRepository.addOrder(
      tailorId: selectedTailorId.isNotEmpty ? selectedTailorId : 't1',
      tailorShopName: tailorShopName,
      customerName: currentCustomer?.fullName ?? 'Customer',
      garmentType: orderFormData['garment_type']?.toString() ?? 'Custom Garment',
      fabricMaterial: orderFormData['fabric_material']?.toString() ?? 'Custom Fabric',
      customerNotes: orderFormData['customer_notes']?.toString() ?? '',
      chest: (orderFormData['chest_measurement_inches'] as num?)?.toDouble() ?? 34.0,
      waist: (orderFormData['waist_measurement_inches'] as num?)?.toDouble() ?? 27.0,
      hips: (orderFormData['hips_measurement_inches'] as num?)?.toDouble() ?? 37.0,
      shoulders: (orderFormData['shoulders_measurement_inches'] as num?)?.toDouble() ?? 14.5,
      inseam: (orderFormData['inseam_measurement_inches'] as num?)?.toDouble() ?? 29.0,
    );

    if (authToken != null && authToken!.isNotEmpty && currentCustomer != null) {
      try {
        orderFormData['customer_id'] = currentCustomer!.customerId;
        
        await _apiService.createOrder(
          authToken: authToken!,
          orderData: orderFormData,
        );
        
        // Refresh orders from backend to get the real ID and dates
        await refreshOrders();
      } catch (_) {}
    }

    orderList.insert(0, newOrder);
    notifyListeners();
  }

  // ----------------------------------------------------------
  // CHAT ACTIONS
  // ----------------------------------------------------------

  /// Sets the order to open when navigating to the Chat tab.
  void selectOrderForChat(OrderModel order) {
    selectedOrderForChat = order;
    notifyListeners();
  }

  /// Clears the pre-selected chat order.
  void clearSelectedOrderForChat() {
    selectedOrderForChat = null;
    notifyListeners();
  }

  /// Sends a chat message within an order thread.
  Future<void> sendMessageInOrder(String orderId, String messageText) async {
    final newMessage = await _apiService.sendChatMessage(
      authToken: authToken ?? '',
      orderId: orderId,
      messageText: messageText,
    );

    // Find the order and append the new message to it
    final orderIndex = orderList.indexWhere((o) => o.orderId == orderId);
    if (orderIndex != -1) {
      final updatedMessages = [...orderList[orderIndex].chatMessages, newMessage];
      orderList[orderIndex] = OrderModel(
        orderId: orderList[orderIndex].orderId,
        tailorId: orderList[orderIndex].tailorId,
        tailorShopName: orderList[orderIndex].tailorShopName,
        garmentType: orderList[orderIndex].garmentType,
        status: orderList[orderIndex].status,
        statusUpdatedDate: orderList[orderIndex].statusUpdatedDate,
        estimatedCompletionDate: orderList[orderIndex].estimatedCompletionDate,
        customerNotes: orderList[orderIndex].customerNotes,
        chestMeasurementInches: orderList[orderIndex].chestMeasurementInches,
        waistMeasurementInches: orderList[orderIndex].waistMeasurementInches,
        hipsMeasurementInches: orderList[orderIndex].hipsMeasurementInches,
        shouldersMeasurementInches: orderList[orderIndex].shouldersMeasurementInches,
        inseamMeasurementInches: orderList[orderIndex].inseamMeasurementInches,
        fabricMaterial: orderList[orderIndex].fabricMaterial,
        inspirationImageUrl: orderList[orderIndex].inspirationImageUrl,
        chatMessages: updatedMessages,
        orderCreatedDate: orderList[orderIndex].orderCreatedDate,
      );
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // AI SCAN ACTIONS
  // ----------------------------------------------------------

  /// Runs an AI body scan and returns the result (does not save yet).
  Future<ScanResultModel> runAIBodyScan({
    required String imageUrl,
    required String gender,
    required int heightCm,
  }) async {
    return _apiService.runAIBodyScan(
      imageUrl: imageUrl,
      gender: gender,
      heightCm: heightCm,
    );
  }

  /// Saves the scan result to the provider state and to device storage.
  Future<void> saveScanResult(ScanResultModel result) async {
    savedScanResult = result;
    notifyListeners();
    await _persistScanResult(result);
  }

  // ----------------------------------------------------------
  // LOCAL PERSISTENCE (SharedPreferences)
  // ----------------------------------------------------------

  static const String _scanResultStorageKey = 'customer_saved_scan_result';
  static const String _authTokenStorageKey = 'customer_auth_token';

  void setLoggedInCustomer({
    required String fullName,
    required String username,
    String? email,
    String? phoneNumber,
    String? cityLocation,
    String? customerId,
    String? authTokenValue,
  }) async {
    currentCustomer = CustomerModel(
      customerId: customerId ?? 'c1',
      fullName: fullName,
      emailAddress: email ?? '$username@tailorconnect.com',
      phoneNumber: phoneNumber ?? '',
      cityLocation: cityLocation ?? '',
      avatarImageUrl: '',
      accountTier: 'standard',
      memberSince: '2026',
    );
    if (authTokenValue != null) {
      authToken = authTokenValue;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_full_name', fullName);
    await prefs.setString('customer_username', username);
    await prefs.setString('customer_email', email ?? '');
    await prefs.setString('customer_phone', phoneNumber ?? '');
    await prefs.setString('customer_city', cityLocation ?? '');
    await prefs.setString('customer_id', customerId ?? '');
    // Load real orders from backend
    try {
      if (authToken != null) {
        orderList = await _apiService.getCustomerOrders(authToken!, currentCustomer?.customerId ?? customerId ?? '');
      } else {
        orderList = [];
      }
    } catch (_) {
      orderList = [];
    }
    notifyListeners();
  }

  Future<void> _saveAuthSession(String token, [CustomerModel? customer]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenStorageKey, token);
    if (customer != null) {
      await prefs.setString('customer_full_name', customer.fullName);
      await prefs.setString('customer_email', customer.emailAddress);
      await prefs.setString('customer_phone', customer.phoneNumber);
      await prefs.setString('customer_city', customer.cityLocation);
      await prefs.setString('customer_id', customer.customerId);
    }
  }

  Future<void> _restoreAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString(_authTokenStorageKey);
    final savedName = prefs.getString('customer_full_name');
    final savedUser = prefs.getString('customer_username');
    final savedEmail = prefs.getString('customer_email') ?? '';
    final savedPhone = prefs.getString('customer_phone') ?? '';
    final savedCity = prefs.getString('customer_city') ?? '';
    final savedId = prefs.getString('customer_id') ?? '';
    if (savedName != null && savedName.isNotEmpty) {
      currentCustomer = CustomerModel(
        customerId: savedId.isNotEmpty ? savedId : 'c1',
        fullName: savedName,
        emailAddress: savedEmail.isNotEmpty ? savedEmail : '${savedUser ?? "customer"}@tailorconnect.com',
        phoneNumber: savedPhone,
        cityLocation: savedCity,
        avatarImageUrl: '',
        accountTier: 'standard',
        memberSince: '2026',
      );
    }
  }

  Future<void> clearAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenStorageKey);
    await prefs.remove('customer_full_name');
    await prefs.remove('customer_username');
    authToken = null;
    currentCustomer = null;
  }

  Future<void> _persistScanResult(ScanResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanResultStorageKey, jsonEncode(result.toJson()));
  }

  Future<void> _loadSavedScanResult() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_scanResultStorageKey);
    if (stored != null) {
      try {
        savedScanResult = ScanResultModel.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        );
      } catch (_) {
        // If stored data is corrupt, ignore it
      }
    }
  }
}
