import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../core/database_helper.dart';
import '../core/constants.dart';
import '../core/app_exception.dart';

class AppProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _isNotificationsEnabled = false;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  List<Place> _nearbyPlaces = [];
  List<Place> get nearbyPlaces => _nearbyPlaces;

  bool _isPlacesVisibleOnMap = true;
  bool get isPlacesVisibleOnMap => _isPlacesVisibleOnMap;

  void togglePlacesVisibility() {
    _isPlacesVisibleOnMap = !_isPlacesVisibleOnMap;
    notifyListeners();
  }

  List<Place> _claimedBadges = [];
  List<Place> get claimedBadges => _claimedBadges;

  List<LatLng>? _currentRoute;
  List<LatLng>? get currentRoute => _currentRoute;

  Place? _currentDestination;
  Place? get currentDestination => _currentDestination;

  // --- USER PROFILE ---
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  AppProvider() {
    _loadClaimedBadges();
    _loadAlarmSettings();
    _loadUserProfile();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> userMaps =
          await db.query('user_profile', limit: 1);

      if (userMaps.isNotEmpty) {
        _userProfile = UserProfile.fromMap(userMaps.first);
        // Migrasi legacy ID jika ada
        if (_userProfile!.uniqueId == 'USR-8392') {
          final newUniqueId = DatabaseHelper.instance.generateRandomUniqueId();
          _userProfile = _userProfile!.copyWith();
          await db.update(
            'user_profile',
            {'unique_id': newUniqueId},
            where: 'id = ?',
            whereArgs: [_userProfile!.id],
          );
        }
      } else {
        final newUniqueId = DatabaseHelper.instance.generateRandomUniqueId();
        _userProfile = UserProfile(
          id: 'my_user_id',
          uniqueId: newUniqueId,
          name: 'Petualang Kota',
          avatar: 'avatar1',
          bio: 'Suka menjelajah tempat nongkrong & wisata unik.',
          lat: AppConstants.defaultLat,
          lon: AppConstants.defaultLon,
        );
        await db.insert('user_profile', _userProfile!.toMap());
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppProvider] _loadUserProfile error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    required String avatar,
    String? bio,
  }) async {
    if (_userProfile == null) return;
    final previousProfile = _userProfile;
    _userProfile = _userProfile!.copyWith(
      name: name,
      avatar: avatar,
      bio: bio,
    );

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_profile',
        _userProfile!.toMap(),
        where: 'id = ?',
        whereArgs: [_userProfile!.id],
      );
    } catch (e) {
      _userProfile = previousProfile;
      if (kDebugMode) {
        debugPrint('[AppProvider] updateUserProfile DB error: $e');
      }
      throw const DatabaseException('Gagal memperbarui profil di penyimpanan lokal.');
    }
    notifyListeners();
  }

  Future<void> togglePrivacy(bool isPrivate) async {
    if (_userProfile == null) return;
    final previousPrivacy = _userProfile!.isPrivate;
    _userProfile = _userProfile!.copyWith(isPrivate: isPrivate);

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_profile',
        _userProfile!.toMap(),
        where: 'id = ?',
        whereArgs: [_userProfile!.id],
      );
    } catch (e) {
      _userProfile = _userProfile!.copyWith(isPrivate: previousPrivacy);
      if (kDebugMode) {
        debugPrint('[AppProvider] togglePrivacy DB error: $e');
      }
      throw const DatabaseException('Gagal mengubah pengaturan privasi.');
    }
    notifyListeners();
  }

  // --- AUTH (Lokal via flutter_secure_storage) ---

  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    if (_userProfile == null) return;
    try {
      await _authService.saveCredentials(email, password);
      _userProfile = _userProfile!.copyWith(name: name, email: email);
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_profile',
        _userProfile!.toMap(),
        where: 'id = ?',
        whereArgs: [_userProfile!.id],
      );
    } catch (e) {
      throw const AuthException('Gagal mendaftarkan akun email. Coba lagi.');
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final valid = await _authService.validateCredentials(email, password);
    if (!valid) {
      throw const AuthException('Email atau kata sandi salah.');
    }
    await _loadUserProfile();
    notifyListeners();
  }

  Future<void> linkAccountWithEmail(String email, String password) async {
    if (_userProfile == null) return;
    try {
      await _authService.saveCredentials(email, password);
      _userProfile = _userProfile!.copyWith(email: email);
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_profile',
        _userProfile!.toMap(),
        where: 'id = ?',
        whereArgs: [_userProfile!.id],
      );
    } catch (e) {
      throw const AuthException('Gagal menghubungkan akun dengan email.');
    }
    notifyListeners();
  }

  // --- LOCATION & PLACES ---

  Future<void> fetchLocationAndPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPosition = await _locationService.getCurrentPosition();

      if (_userProfile != null && _currentPosition != null) {
        _userProfile = _userProfile!.copyWith(
          lat: _currentPosition!.latitude,
          lon: _currentPosition!.longitude,
        );
      }

      _nearbyPlaces = await _apiService.fetchNearbyPlaces(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      if (e is LocationException || e is NetworkException) {
        _errorMessage = e.toString();
      } else {
        _errorMessage = 'Terjadi kesalahan tak terduga saat memuat lokasi.';
        if (kDebugMode) {
          debugPrint('[AppProvider] fetchLocationAndPlaces error: $e');
        }
      }
      _nearbyPlaces = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> getRouteToPlace(Place destination) async {
    if (_currentPosition == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final route = await _apiService.fetchRoute(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        destination.lat,
        destination.lon,
      );
      if (route.isNotEmpty) {
        _currentRoute = route;
        _currentDestination = destination;
      } else {
        _errorMessage = 'Gagal menemukan rute ke lokasi tujuan.';
      }
    } catch (e) {
      _errorMessage = e is NetworkException
          ? e.message
          : 'Gagal memuat rute. Periksa koneksi internet Anda.';
      if (kDebugMode) {
        debugPrint('[AppProvider] getRouteToPlace error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearRoute() {
    _currentRoute = null;
    _currentDestination = null;
    notifyListeners();
  }

  // --- BADGES ---

  Future<void> claimPlace(Place place) async {
    if (_currentPosition == null) {
      throw const LocationException('Lokasi Anda tidak terdeteksi.');
    }

    final distance = _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.lat,
      place.lon,
    );

    if (distance <= AppConstants.claimRadiusMeters) {
      final claimedPlace = Place(
        id: place.id,
        name: place.name,
        type: place.type,
        lat: place.lat,
        lon: place.lon,
        claimDate: DateTime.now(),
      );

      try {
        final db = await DatabaseHelper.instance.database;
        await db.insert('badges', claimedPlace.toMap());
        await _loadClaimedBadges();
      } catch (e) {
        throw const DatabaseException('Gagal menyimpan lencana ke database.');
      }
    } else {
      throw LocationException(
        'Anda terlalu jauh dari lokasi ini (${distance.toStringAsFixed(0)} meter). '
        'Mendekat dalam radius ${AppConstants.claimRadiusMeters.toInt()} meter untuk klaim.',
      );
    }
  }

  Future<void> _loadClaimedBadges() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('badges');
      _claimedBadges = maps.map((map) => Place.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppProvider] _loadClaimedBadges error: $e');
      }
    }
    notifyListeners();
  }

  // --- ALARM SETTINGS ---
  int _reminderDay = DateTime.saturday;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  int get reminderDay => _reminderDay;
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> _loadAlarmSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _reminderDay = prefs.getInt('reminder_day') ?? DateTime.saturday;
      final hour = prefs.getInt('reminder_hour') ?? 9;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppProvider] _loadAlarmSettings error: $e');
      }
    }
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService().requestRequiredPermissions();
      if (!granted) {
        _isNotificationsEnabled = false;
        notifyListeners();
        return;
      }
    }

    _isNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    _updateNotificationService();
    notifyListeners();
  }

  Future<void> setAlarmSchedule(int day, TimeOfDay time) async {
    _reminderDay = day;
    _reminderTime = time;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_day', day);
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);

    if (_isNotificationsEnabled) {
      _updateNotificationService();
    }
    notifyListeners();
  }

  void _updateNotificationService() {
    NotificationService().scheduleCustomReminder(
      _isNotificationsEnabled,
      _reminderDay,
      _reminderTime.hour,
      _reminderTime.minute,
    );
  }
}
