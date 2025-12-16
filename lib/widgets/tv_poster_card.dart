import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anime.dart';
import '../services/anime_service.dart';
import '../services/favorites_service.dart';
import '../services/playback_history_service.dart';

class TvPosterCard extends StatefulWidget {
  final int index;
  final String titlePrefix;
  final VoidCallback onFocus;
  final Anime? anime;
  final VoidCallback? onTap;
  final VoidCallback? onMoveLeft;
  const TvPosterCard({
    super.key,
    required this.index,
    this.titlePrefix = "番剧",
    required this.onFocus,
    this.anime,
    this.onTap,
    this.onMoveLeft,
  });
  @override
  State<TvPosterCard> createState() => _TvPosterCardState();
}

class _TvPosterCardState extends State<TvPosterCard> {
  bool _isFocused = false;
  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (f) {
      setState(() => _isFocused = f);
      if (f) widget.onFocus();
    },
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
            widget.onMoveLeft != null) {
          widget.onMoveLeft!();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedScale(
            scale: _isFocused ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
                border: _isFocused
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child:
                        widget.anime?.poster != null &&
                            widget.anime!.poster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AnimeService.getCoverUrl(
                              widget.anime!.poster,
                            ),
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            memCacheHeight: 400,
                            maxHeightDiskCache: 400,
                            maxWidthDiskCache: 300,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[800]),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                size: 50,
                                color: Colors.white24,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[700],
                            child: const Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.white24,
                            ),
                          ),
                  ),
                  if (_isFocused)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  // 追番图标（左上角）
                  if (widget.anime != null)
                    FutureBuilder<bool>(
                      future: FavoritesService.isFavorite(widget.anime!.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            widget.anime?.title ?? "${widget.titlePrefix} ${widget.index + 1}",
            style: TextStyle(
              color: _isFocused ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        // 状态和观看进度徽章（单行显示）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              // 状态/年份徽章
              Builder(
                builder: (context) {
                  final status = widget.anime?.status ?? "";
                  final year = widget.anime?.year ?? "";

                  // 判断是否为连载中
                  final isOngoing =
                      status.contains("连载") || status.contains("Live");

                  // 🔥 统一规则：连载显示状态，完结显示年份
                  final displayText = isOngoing ? status : year;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOngoing
                          ? const Color(0xFF00B0FF)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayText.isNotEmpty ? displayText : "未知",
                      style: TextStyle(
                        color: isOngoing ? Colors.black : Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              // 观看进度徽章
              if (widget.anime != null)
                FutureBuilder<String?>(
                  future: _getPlaybackProgress(widget.anime!.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), // 绿色
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '观看至: ${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10, // 从11减小到10
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ],
    ),
  );

  // 获取播放进度
  Future<String?> _getPlaybackProgress(String animeId) async {
    try {
      final history = await PlaybackHistoryService.getPlaybackHistory(animeId);
      return history?.episodeTitle;
    } catch (e) {
      return null;
    }
  }
}
