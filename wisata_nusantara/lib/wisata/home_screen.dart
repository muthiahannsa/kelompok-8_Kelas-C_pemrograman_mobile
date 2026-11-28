import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../notifications/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_wisata_screen.dart';
import 'kategori.dart';
import 'wisata_model.dart';
import 'wisata_provider.dart';
import 'wisata_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _onlyFavorites = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : null,
      ),
    );
  }

  String _displayName(String? email) {
    if (email == null || email.isEmpty) return 'Traveler';
    final local = email.split('@').first;
    if (local.isEmpty) return 'Traveler';
    return local[0].toUpperCase() + local.substring(1);
  }

  /// Rekomendasi: destinasi yang ditandai "populer" oleh admin (maksimal 6).
  /// Bila belum ada yang ditandai, diambil dari seluruh destinasi. Urutan
  /// diacak dengan seed tanggal sehingga berganti tiap hari tapi stabil di
  /// hari yang sama.
  List<Wisata> _recommendations(List<Wisata> all) {
    var pool = all.where((w) => w.populer).toList();
    if (pool.isEmpty) pool = List<Wisata>.of(all);
    if (pool.isEmpty) return [];

    pool.sort((a, b) => a.id.compareTo(b.id));

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    pool.shuffle(Random(now.year * 1000 + dayOfYear));

    return pool.take(6).toList();
  }

  void _bukaEdit(Wisata wisata) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddWisataScreen(wisata: wisata)),
    );
  }

  Future<void> _pilihProvinsi(WisataProvider provider) async {
    final terpilih = provider.selectedProvinsi;

    final hasil = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        final daftar = provider.daftarProvinsi;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Pilih Provinsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                ListTile(
                  title: const Text('Semua Provinsi'),
                  trailing: (terpilih == null || terpilih.isEmpty)
                      ? const Icon(Icons.check_rounded, color: AppColors.teal)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, ''),
                ),
                for (final provinsi in daftar)
                  ListTile(
                    title: Text(provinsi),
                    trailing: terpilih == provinsi
                        ? const Icon(Icons.check_rounded, color: AppColors.teal)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, provinsi),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (hasil == null) return; // ditutup tanpa memilih
    provider.filterByProvinsi(hasil.isEmpty ? null : hasil);
  }

  Future<void> _toggleFavorite(WisataProvider provider, String id) async {
    try {
      await provider.toggleFavorite(id);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _confirmDelete(WisataProvider provider, Wisata wisata) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus destinasi?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('"${wisata.nama}" akan dihapus permanen dari database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await provider.deleteWisata(wisata.id);
      if (!mounted) return;
      _snack('Destinasi berhasil dihapus.');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _resetAll(WisataProvider provider) {
    _searchController.clear();
    setState(() => _onlyFavorites = false);
    provider.resetFilter();
  }

  Future<void> _salinFcmToken() async {
    final token = NotificationService().fcmToken;
    if (token == null || token.isEmpty) {
      _snack('FCM Token belum tersedia di perangkat ini.', isError: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    _snack('FCM Token berhasil disalin.');
  }

  Future<void> _bukaRiwayatNotifikasi() async {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final notifService = NotificationService();
    notifService.markAllAsRead();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        TextButton.icon(
                          onPressed: _salinFcmToken,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Salin Token'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => notifService.showTestNotification(),
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                          ),
                          label: const Text('Uji Notif'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ValueListenableBuilder<List<AppNotification>>(
                      valueListenable: notifService.historyNotifier,
                      builder: (context, items, _) {
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 44,
                                    color: AppColors.muted,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Belum ada notifikasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Push notification atau peringatan cuaca akan muncul di sini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _NotificationTile(
                              item: item,
                              onTap: item.wisataId == null
                                  ? null
                                  : () {
                                      Navigator.pop(sheetContext);
                                      notifService.openWisataById(
                                        item.wisataId,
                                      );
                                    },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddWisataScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Wisata',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: Consumer<WisataProvider>(
        builder: (context, provider, child) {
          final hasProvinceFilter = provider.selectedProvinsi != null &&
              provider.selectedProvinsi!.isNotEmpty;
          final hasCategoryFilter = provider.selectedKategori != null &&
              provider.selectedKategori!.isNotEmpty;
          final isFiltering = provider.searchQuery.isNotEmpty ||
              hasProvinceFilter ||
              hasCategoryFilter ||
              _onlyFavorites;

          var list = provider.filteredWisata;
          if (_onlyFavorites) {
            list = list.where((w) => provider.isFavorite(w.id)).toList();
          }

          final recommendations = _recommendations(provider.daftarWisata);
          final showRecommendations = !isFiltering &&
              !provider.isLoading &&
              recommendations.isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(auth, provider)),
              SliverToBoxAdapter(
                child: _buildFilterChips(
                  provider,
                  hasProvinceFilter,
                  hasCategoryFilter,
                ),
              ),
              if (showRecommendations) ...[
                const SliverToBoxAdapter(
                  child: _SectionTitle(
                    title: 'Rekomendasi untuk kamu',
                    trailing: 'Pilihan hari ini',
                  ),
                ),
                SliverToBoxAdapter(
                  child: RecommendationCarousel(
                    items: recommendations,
                    isFavorite: provider.isFavorite,
                    onToggleFavorite: (w) => _toggleFavorite(provider, w.id),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _SectionTitle(
                  title: _onlyFavorites ? 'Favoritmu' : 'Jelajahi Destinasi',
                  trailing: provider.isLoading ? null : '${list.length} tempat',
                ),
              ),
              ..._buildListSlivers(auth, provider, list, isFiltering),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- header

  Widget _buildHeader(AuthProvider auth, WisataProvider provider) {
    final name = _displayName(auth.user?.email);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $name 👋',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (auth.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PENGELOLA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Pengunjung',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<List<AppNotification>>(
                    valueListenable: NotificationService().historyNotifier,
                    builder: (context, items, _) {
                      final unread = items.where((e) => !e.isRead).length;
                      return IconButton.filledTonal(
                        tooltip: 'Notifikasi',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        onPressed: _bukaRiwayatNotifikasi,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Logout',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Mau jelajah ke\nmana hari ini?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: provider.searchWisata,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari pantai, gunung, candi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            provider.searchWisata('');
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- filter chips

  Widget _buildFilterChips(
    WisataProvider provider,
    bool hasProvinceFilter,
    bool hasCategoryFilter,
  ) {
    final kategoriTerpilih = provider.selectedKategori;

    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _FilterChip(
            label: 'Semua',
            selected: !_onlyFavorites && !hasProvinceFilter && !hasCategoryFilter,
            onTap: () => _resetAll(provider),
          ),
          for (final kategori in KategoriWisata.untukFilter) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: kategori,
              icon: KategoriWisata.ikon(kategori),
              selected: kategoriTerpilih == kategori,
              onTap: () => provider.filterByKategori(
                kategoriTerpilih == kategori ? null : kategori,
              ),
            ),
          ],
          const SizedBox(width: 8),
          _FilterChip(
            label: hasProvinceFilter ? provider.selectedProvinsi! : 'Provinsi',
            icon: Icons.map_outlined,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            selected: hasProvinceFilter,
            onTap: () => _pilihProvinsi(provider),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Favorit',
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
            selected: _onlyFavorites,
            onTap: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- list

  List<Widget> _buildListSlivers(
    AuthProvider auth,
    WisataProvider provider,
    List<Wisata> list,
    bool isFiltering,
  ) {
    if (provider.isLoading) {
      return [const SliverToBoxAdapter(child: WisataSkeleton())];
    }

    final error = provider.errorMessage;
    if (error != null && error.isNotEmpty && provider.daftarWisata.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Oops, terjadi kendala',
            subtitle: error,
          ),
        ),
      ];
    }

    if (list.isEmpty) {
      late final EmptyState empty;
      if (_onlyFavorites) {
        empty = const EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Belum ada favorit',
          subtitle: 'Ketuk ikon hati pada destinasi untuk menyimpannya di sini.',
        );
      } else if (isFiltering) {
        empty = EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Destinasi tidak ditemukan',
          subtitle: 'Coba kata kunci atau provinsi yang lain.',
          actionLabel: 'Reset filter',
          onAction: () => _resetAll(provider),
        );
      } else {
        empty = EmptyState(
          icon: Icons.travel_explore_rounded,
          title: 'Belum ada destinasi wisata',
          subtitle: auth.isAdmin
              ? 'Tekan tombol "Tambah Wisata" untuk menambahkan destinasi pertama.'
              : 'Destinasi akan muncul di sini setelah pengelola menambahkannya.',
        );
      }
      return [SliverToBoxAdapter(child: empty)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final wisata = list[index];
            return WisataTile(
              wisata: wisata,
              isFavorite: provider.isFavorite(wisata.id),
              onToggleFavorite: () => _toggleFavorite(provider, wisata.id),
              // FR-09: tombol edit & hapus hanya untuk Admin
              onEdit: auth.isAdmin ? () => _bukaEdit(wisata) : null,
              onDelete:
                  auth.isAdmin ? () => _confirmDelete(provider, wisata) : null,
            );
          },
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Widget pendukung (private)
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor = AppColors.teal,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color iconColor;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.ink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: ShapeDecoration(
        color: selected ? AppColors.teal : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.teal : AppColors.line,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : iconColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 2),
                  Icon(trailingIcon, size: 18, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (item.type) {
      'cuaca' => (Icons.thunderstorm_outlined, Colors.orange.shade700),
      'test' => (Icons.science_outlined, AppColors.teal),
      _ => (Icons.notifications_active_outlined, AppColors.teal),
    };

    final hh = item.timestamp.hour.toString().padLeft(2, '0');
    final mm = item.timestamp.minute.toString().padLeft(2, '0');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(
        item.body,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$hh:$mm',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}