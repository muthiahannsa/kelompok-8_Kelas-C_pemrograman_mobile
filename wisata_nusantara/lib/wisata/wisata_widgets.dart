import 'package:flutter/material.dart';

import '../cuaca/weather_screen.dart';
import '../theme/app_theme.dart';
import 'kategori.dart';
import 'wisata_model.dart';

/// Navigasi ke halaman detail (WeatherScreen) membawa data wisata.
void openWisataDetail(BuildContext context, Wisata wisata) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WeatherScreen(
        wisataId: wisata.id,
        nama: wisata.nama,
        provinsi: wisata.provinsi,
        deskripsi: wisata.deskripsi,
        gambarUrl: wisata.gambarUrl,
        lat: wisata.lat,
        lon: wisata.lon,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Gambar dengan fade-in, placeholder loading, dan fallback error
// ---------------------------------------------------------------------------

class WisataImage extends StatelessWidget {
  const WisataImage({
    super.key,
    required this.url,
    this.kategori = KategoriWisata.lainnya,
  });

  final String url;

  /// Dipakai untuk tampilan cadangan (gradien + ikon) saat gambar kosong/gagal.
  final String kategori;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _ImageFallback(kategori: kategori);

    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _ImageFallback(kategori: kategori);
      },
      errorBuilder: (context, error, stackTrace) =>
          _ImageFallback(kategori: kategori),
    );
  }
}

/// Latar gradien berwarna sesuai kategori + ikon besar (saat belum ada gambar).
class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.kategori});

  final String kategori;

  @override
  Widget build(BuildContext context) {
    final warna = KategoriWisata.warna(kategori);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: warna,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final iconSize = side.isFinite ? (side * 0.42).clamp(28.0, 72.0) : 48.0;
          return Center(
            child: Icon(
              KategoriWisata.ikon(kategori),
              color: Colors.white.withValues(alpha: 0.85),
              size: iconSize,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tombol favorit (hati) dengan animasi pop
// ---------------------------------------------------------------------------

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = 40,
    this.backgroundColor,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite ? 'Hapus dari favorit' : 'Tambahkan ke favorit',
      child: Material(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  size: size * 0.52,
                  color: isFavorite ? Colors.redAccent : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carousel rekomendasi (PageView dengan efek skala)
// ---------------------------------------------------------------------------

class RecommendationCarousel extends StatefulWidget {
  const RecommendationCarousel({
    super.key,
    required this.items,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final List<Wisata> items;
  final bool Function(String wisataId) isFavorite;
  final void Function(Wisata wisata) onToggleFavorite;

  @override
  State<RecommendationCarousel> createState() => _RecommendationCarouselState();
}

class _RecommendationCarouselState extends State<RecommendationCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.82);
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (index) => setState(() => _current = index),
            itemBuilder: (context, index) {
              final wisata = items[index];

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double page = _current.toDouble();
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    page = _controller.page ?? page;
                  }
                  final delta = (page - index).abs().clamp(0.0, 1.0).toDouble();
                  return Transform.scale(
                    scale: 1 - (delta * 0.08),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _RecommendationCard(
                    wisata: wisata,
                    isFavorite: widget.isFavorite(wisata.id),
                    onToggleFavorite: () => widget.onToggleFavorite(wisata),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 22 : 6,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.teal
                    : AppColors.teal.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.wisata,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Wisata wisata;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WisataImage(url: wisata.gambarUrl, kategori: wisata.kategori),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wisata.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: AppColors.coral,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            wisata.provinsi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const _GlassChip(
                      icon: Icons.wb_cloudy_rounded,
                      label: 'Cek cuaca',
                    ),
                  ],
                ),
              ),
            ),
            // Lapisan ripple + tap (di atas teks, di bawah tombol favorit)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () => openWisataDetail(context, wisata)),
              ),
            ),
            const Positioned(
              top: 14,
              left: 14,
              child: IgnorePointer(
                child: _GlassChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Rekomendasi',
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: FavoriteButton(
                isFavorite: isFavorite,
                onTap: onToggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu daftar wisata (tile horizontal)
// ---------------------------------------------------------------------------

class WisataTile extends StatelessWidget {
  const WisataTile({
    super.key,
    required this.wisata,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
  });

  final Wisata wisata;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  /// Hanya diisi untuk Admin. Jika null, tombol edit tidak tampil.
  final VoidCallback? onEdit;

  /// Hanya diisi untuk Admin (FR-09). Jika null, tombol hapus tidak tampil.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openWisataDetail(context, wisata),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: WisataImage(
                      url: wisata.gambarUrl,
                      kategori: wisata.kategori,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 108,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          wisata.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                wisata.provinsi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            wisata.deskripsi,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 108,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FavoriteButton(
                        isFavorite: isFavorite,
                        onTap: onToggleFavorite,
                        size: 36,
                        backgroundColor: const Color(0xFFF4F7F6),
                      ),
                      if (onEdit != null || onDelete != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onEdit != null)
                              _MiniAction(
                                tooltip: 'Edit wisata',
                                icon: Icons.edit_outlined,
                                color: AppColors.teal,
                                onTap: onEdit!,
                              ),
                            if (onDelete != null)
                              _MiniAction(
                                tooltip: 'Hapus wisata',
                                icon: Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                onTap: onDelete!,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading (berkedip halus)
// ---------------------------------------------------------------------------

class WisataSkeleton extends StatefulWidget {
  const WisataSkeleton({super.key, this.count = 4});

  final int count;

  @override
  State<WisataSkeleton> createState() => _WisataSkeletonState();
}

class _WisataSkeletonState extends State<WisataSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = Color(0xFFEDE6DB);

    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: box,
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(widget.count, (_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: box,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(140, 16),
                        const SizedBox(height: 10),
                        bar(90, 12),
                        const SizedBox(height: 14),
                        bar(double.infinity, 10),
                        const SizedBox(height: 6),
                        bar(double.infinity, 10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.teal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}