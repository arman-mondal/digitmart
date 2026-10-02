import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';

class AppStateProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  ProfileModel? _currentProfile;
  List<ProductModel> _products = [];
  List<String> _watchlistIds = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';
  String _selectedSellingMode = 'ALL';
  String _searchQuery = '';
  LocationData? _userLocation;

  ProfileModel? get currentProfile => _currentProfile;
  List<ProductModel> get products => _products;
  List<String> get watchlistIds => _watchlistIds;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get selectedSellingMode => _selectedSellingMode;
  String get searchQuery => _searchQuery;
  LocationData? get userLocation => _userLocation;

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Check Real Supabase Auth Current User
    final currentUser = _service.currentUser;

    if (currentUser != null) {
      await loadUserProfile(currentUser.id);
    } else {
      // Auto Sign-In Anonymously or fallback to active walkthrough profile
      try {
        final res = await Supabase.instance.client.auth.signInAnonymously();
        if (res.user != null) {
          await loadUserProfile(res.user!.id);
        } else {
          await loadUserProfile(SupabaseService.demoUserId);
        }
      } catch (e) {
        await loadUserProfile(SupabaseService.demoUserId);
      }
    }

    // 2. Trigger Real GPS Location Detection
    await detectRealLocation();

    // 3. Load marketplace data
    await refreshProducts();
    await refreshWatchlist();
    await refreshNotifications();

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

        // Update real location name in Supabase profiles
        try {
          await _service.client.from('profiles').update({
            'location_name': location.locationName,
          }).eq('id', _currentProfile!.id);
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> loadUserProfile(String userId) async {
    _currentProfile = await _service.getProfile(userId);
    if (_currentProfile == null) {
      // Create fresh profile in public.profiles for real auth user
      final user = _service.currentUser;
      _currentProfile = ProfileModel(
        id: userId,
        name: user?.email?.split('@').first ?? 'User',
        email: user?.email,
        phone: user?.phone,
        locationName: _userLocation?.locationName ?? 'New Town, Kolkata',
        createdAt: DateTime.now(),
      );

      try {
        await _service.client.from('profiles').upsert({
          'id': userId,
          'name': _currentProfile!.name,
          'email': user?.email,
          'location_name': _currentProfile!.locationName,
        });
      } catch (_) {}
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
    _products = await _service.getProducts(
      categoryId: _selectedCategory,
      sellingMode: _selectedSellingMode,
      searchQuery: _searchQuery,
    );
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
}
