import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/app_logger.dart';

class AppStateProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  StreamSubscription<AuthState>? _authSubscription;

  ProfileModel? _currentProfile;
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];
  List<String> _watchlistIds = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'all';
  String _selectedSellingMode = 'ALL';
  String _searchQuery = '';
  LocationData? _userLocation;

  ProfileModel? get currentProfile => _currentProfile;
  List<ProductModel> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;
  List<String> get watchlistIds => _watchlistIds;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedSellingMode => _selectedSellingMode;
  String get searchQuery => _searchQuery;
  LocationData? get userLocation => _userLocation;

  bool get isAuthenticated => _service.currentUser != null;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Listen to Supabase Auth State Changes
    _authSubscription?.cancel();
    _authSubscription = _service.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      AppLogger.i('Auth event: $event, User: ${session?.user.email}');

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (session?.user != null) {
          await loadUserProfile(session!.user.id);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentProfile = null;
        _watchlistIds = [];
        _notifications = [];
        notifyListeners();
      }
    });

    // Check Current Auth User
    final currentUser = _service.currentUser;
    if (currentUser != null) {
      await loadUserProfile(currentUser.id);
    }

    // Load Database Categories
    _categories = await _service.getCategories();

    // Detect GPS Location
    await detectRealLocation();

    // Load Marketplace Data
    await refreshProducts();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> detectRealLocation() async {
    final location = await LocationService.getCurrentLocation();
    if (location != null) {
      _userLocation = location;
      if (_currentProfile != null) {
        _currentProfile = ProfileModel(
          id: _currentProfile!.id,
          name: _currentProfile!.name,
          phone: _currentProfile!.phone,
          email: _currentProfile!.email,
          profileImage: _currentProfile!.profileImage,
          verificationStatus: _currentProfile!.verificationStatus,
          rating: _currentProfile!.rating,
          completedTransactions: _currentProfile!.completedTransactions,
          bidReliability: _currentProfile!.bidReliability,
          locationName: location.locationName,
          createdAt: _currentProfile!.createdAt,
        );

        try {
          await _service.client.from('profiles').update({
            'location_name': location.locationName,
          }).eq('id', _currentProfile!.id);
        } catch (e) {
          AppLogger.w('Failed to update location name in DB: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> loadUserProfile(String userId) async {
    final res = await _service.getProfile(userId);
    if (res.isSuccess) {
      _currentProfile = res.data;
      await refreshWatchlist();
      await refreshNotifications();
    } else {
      AppLogger.w('User profile not found in DB for $userId');
    }
    notifyListeners();
  }

  Future<void> switchDemoUser(String userId) async {
    _isLoading = true;
    notifyListeners();

    await loadUserProfile(userId);
    await refreshWatchlist();
    await refreshNotifications();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    _errorMessage = null;
    final res = await _service.getProducts(
      categoryId: _selectedCategory,
      sellingMode: _selectedSellingMode,
      searchQuery: _searchQuery,
    );

    if (res.isSuccess) {
      _products = res.data ?? [];
    } else {
      _errorMessage = res.errorMessage;
    }
    notifyListeners();
  }

  void setCategory(String categoryId) {
    _selectedCategory = categoryId;
    refreshProducts();
  }

  void setSellingMode(String mode) {
    _selectedSellingMode = mode;
    refreshProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshProducts();
  }

  Future<void> refreshWatchlist() async {
    if (_currentProfile != null) {
      _watchlistIds =
          await _service.getWatchlistProductIds(_currentProfile!.id);
      notifyListeners();
    }
  }

  Future<void> toggleWatchlist(String productId) async {
    if (_currentProfile == null) return;
    final isAdded =
        await _service.toggleWatchlist(_currentProfile!.id, productId);
    if (isAdded) {
      _watchlistIds.add(productId);
    } else {
      _watchlistIds.remove(productId);
    }
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    if (_currentProfile != null) {
      _notifications =
          await _service.getUserNotifications(_currentProfile!.id);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _currentProfile = null;
    _watchlistIds = [];
    _notifications = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
