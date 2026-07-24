import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../models/place_model.dart';
import '../../services/permission_service.dart';
import '../../core/app_exception.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  int _currentIndex = 0;

  static const Map<String, IconData> _placeTypeIcons = {
    'cafe': LucideIcons.coffee,
    'cinema': LucideIcons.film,
    'theatre': LucideIcons.film,
    'museum': LucideIcons.landmark,
    'historic': LucideIcons.landmark,
    'park': LucideIcons.treePine,
    'beach': LucideIcons.sun,
    'water_park': LucideIcons.waves,
    'mall': LucideIcons.shoppingBag,
    'restaurant': LucideIcons.utensils,
    'bar': LucideIcons.wine,
    'pub': LucideIcons.wine,
    'nightclub': LucideIcons.wine,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllAppPermissions();
      context.read<AppProvider>().fetchLocationAndPlaces();
    });
  }

  void _claimPlace(Place place) async {
    final provider = context.read<AppProvider>();
    try {
      await provider.claimPlace(place);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${place.name} berhasil diklaim!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e is AppException ? e.message : 'Gagal mengklaim tempat.')),
        );
      }
    }
  }

  IconData _getIconForPlaceType(String type) {
    return _placeTypeIcons[type.toLowerCase()] ?? LucideIcons.mapPin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JELO'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentPosition == null) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }

          final currentPos = provider.currentPosition;
          if (currentPos == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.mapPinOff,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ??
                          'Tidak dapat mengambil lokasi. Pastikan GPS aktif.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<AppProvider>().fetchLocationAndPlaces(),
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildMapTab(provider, currentPos),
              _buildDiscoverTab(provider, currentPos),
              _buildBadgesTab(provider),
              _buildStatisticsTab(provider),
              const ProfileScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.map),
            label: 'Peta',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.compass),
            label: 'Jelajah',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.award),
            label: 'Lencana',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(AppProvider provider, Position currentPos) {
    final claimedIds = provider.claimedBadges.map((b) => b.id).toSet();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(currentPos.latitude, currentPos.longitude),
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gamified_city',
            ),
            if (provider.currentRoute != null &&
                provider.currentRoute!.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: provider.currentRoute!,
                    color: Colors.orange,
                    strokeWidth: 5.0,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(currentPos.latitude, currentPos.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(LucideIcons.navigation,
                      color: Colors.blue, size: 40),
                ),
                if (provider.isPlacesVisibleOnMap)
                  ...provider.nearbyPlaces.where((place) {
                    try {
                      final bounds = _mapController.camera.visibleBounds;
                      return bounds.contains(LatLng(place.lat, place.lon));
                    } catch (_) {
                      return true;
                    }
                  }).map((place) {
                    final isClaimed = claimedIds.contains(place.id);
                    return Marker(
                      point: LatLng(place.lat, place.lon),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) =>
                                _buildPlaceDetails(ctx, place, isClaimed),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isClaimed
                                ? LucideIcons.checkCircle2
                                : _getIconForPlaceType(place.type),
                            color: isClaimed ? Colors.green : Colors.orange,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'map_toggle_places',
                onPressed: () {
                  provider.togglePlacesVisibility();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.isPlacesVisibleOnMap
                            ? 'Ikon tempat ditampilkan di peta'
                            : 'Ikon tempat disembunyikan dari peta',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                backgroundColor: provider.isPlacesVisibleOnMap
                    ? Colors.orange
                    : Colors.grey,
                child: Icon(
                  provider.isPlacesVisibleOnMap
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'map_refresh',
                onPressed: () {
                  context.read<AppProvider>().fetchLocationAndPlaces();
                  if (provider.currentPosition != null) {
                    _mapController.move(
                      LatLng(
                        provider.currentPosition!.latitude,
                        provider.currentPosition!.longitude,
                      ),
                      14.0,
                    );
                  }
                },
                backgroundColor: Colors.orange,
                child: const Icon(LucideIcons.refreshCw, color: Colors.white),
              ),
            ],
          ),
        ),
        if (provider.currentRoute != null &&
            provider.currentDestination != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.navigation, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Menuju',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            provider.currentDestination!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.red),
                      onPressed: () {
                        provider.clearRoute();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDiscoverTab(AppProvider provider, Position currentPos) {
    if (provider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.orange));
    }

    if (provider.nearbyPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  provider.errorMessage != null
                      ? LucideIcons.alertTriangle
                      : LucideIcons.searchX,
                  size: 60,
                  color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage ??
                    'Belum ada tempat ditemukan dalam radius 5KM.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<AppProvider>().fetchLocationAndPlaces(),
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Refresh'),
              )
            ],
          ),
        ),
      );
    }

    final claimedIds = provider.claimedBadges.map((b) => b.id).toSet();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.nearbyPlaces.length,
      itemBuilder: (context, index) {
        final place = provider.nearbyPlaces[index];
        final isClaimed = claimedIds.contains(place.id);

        final distance = const Distance().as(
            LengthUnit.Meter,
            LatLng(currentPos.latitude, currentPos.longitude),
            LatLng(place.lat, place.lon));

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => _buildPlaceDetails(ctx, place, isClaimed),
              );
            },
            leading: Icon(
              isClaimed
                  ? LucideIcons.checkCircle2
                  : _getIconForPlaceType(place.type),
              color: isClaimed ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(place.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Kategori: ${place.type}\nJarak: $distance meter'),
            isThreeLine: true,
            trailing: isClaimed
                ? const Text('Sudah Diklaim',
                    style: TextStyle(color: Colors.green, fontSize: 12))
                : TextButton(
                    onPressed: () => _claimPlace(place),
                    child: const Text('KLAIM',
                        style: TextStyle(color: Colors.orange)),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBadgesTab(AppProvider provider) {
    if (provider.claimedBadges.isEmpty) {
      return const Center(
        child: Text(
            'Belum ada lencana yang diklaim.\nJelajahi kota untuk mengumpulkan lencana!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.claimedBadges.length,
      itemBuilder: (context, index) {
        final badge = provider.claimedBadges[index];
        return Card(
          child: ListTile(
            leading:
                const Icon(LucideIcons.award, color: Colors.orange, size: 40),
            title: Text(badge.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Kategori: ${badge.type}'),
            trailing: const Icon(LucideIcons.check, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _buildPlaceDetails(BuildContext modalCtx, Place place, bool isClaimed) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Theme.of(modalCtx).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(_getIconForPlaceType(place.type),
                    color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(place.type.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (place.address != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.mapPin, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text(place.address!, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (place.openingHours != null) ...[
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(place.openingHours!,
                        style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (place.phone != null) ...[
            Row(
              children: [
                const Icon(LucideIcons.phone, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text(place.phone!, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (place.website != null) ...[
            Row(
              children: [
                const Icon(LucideIcons.globe, size: 20, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(place.website!,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.blue))),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 32),

          Center(
            child: isClaimed
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Lencana Berhasil Diklaim',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _claimPlace(place);
                      },
                      icon: const Icon(LucideIcons.award),
                      label: const Text('Klaim Lencana Lokasi',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ).copyWith(
                        backgroundColor:
                            WidgetStateProperty.all(Colors.orange),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(modalCtx);
                setState(() {
                  _currentIndex = 0;
                });
                final provider =
                    Provider.of<AppProvider>(context, listen: false);
                provider.getRouteToPlace(place);
              },
              icon: const Icon(LucideIcons.navigation, color: Colors.blue),
              label: const Text('Tampilkan Rute',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(AppProvider provider) {
    final badges = provider.claimedBadges;
    final total = badges.length;

    String level = 'Pemula';
    if (total >= 5 && total < 10) level = 'Petualang';
    if (total >= 10 && total < 20) level = 'Penjelajah Aktif';
    if (total >= 20) level = 'Master JELO';

    final Map<String, int> categoryCounts = {};
    for (final b in badges) {
      categoryCounts[b.type] = (categoryCounts[b.type] ?? 0) + 1;
    }

    final int maxCount = categoryCounts.isEmpty
        ? 1
        : categoryCounts.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Profil Penjelajah',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.medal, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(level.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Text('$total',
                    style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1)),
                const Text('Lencana Terkumpul',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('Kategori Favorit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: Theme.of(context).cardTheme.shadowColor != null
                  ? [
                      BoxShadow(
                          color: Theme.of(context).cardTheme.shadowColor!,
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: categoryCounts.isEmpty
                ? const Center(
                    child: Text('Belum ada data.\nKlaim lencana pertamamu!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: categoryCounts.entries.map((e) {
                      final heightRatio = e.value / maxCount;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${e.value}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: 32,
                            height: 100 * heightRatio,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(_getIconForPlaceType(e.key),
                              size: 20, color: Colors.grey),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
