import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anime.dart';
import '../models/episode.dart';
import '../services/anime_service.dart';
import '../services/playback_history_service.dart';
import '../services/favorites_service.dart';
import 'player_screen.dart';

class DetailScreen extends StatefulWidget {
  final Anime anime;

  const DetailScreen({super.key, required this.anime});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Episode> _episodes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  int? _lastPlayedIndex; // 记录上次播放的集数索引
  bool _isFavorite = false; // 是否已追番
  bool _isFavoriteLoading = false; // 追番状态加载中
  String? _description; // 番剧介绍

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final episodes = await AnimeService.getEpisodes(widget.anime.id);

      // 🔥 加载播放记录
      final history = await PlaybackHistoryService.getPlaybackHistory(
        widget.anime.id,
      );

      int? lastPlayedIndex;
      if (history != null) {
        // 查找匹配的集数索引
        lastPlayedIndex = episodes.indexWhere(
          (ep) => ep.title == history.episodeTitle,
        );
        if (lastPlayedIndex == -1) {
          lastPlayedIndex = null; // 没找到匹配的集数
        }
      }

      setState(() {
        _episodes = episodes;
        _lastPlayedIndex = lastPlayedIndex;
        _isLoading = false;
      });

      // 🔥 加载番剧介绍
      _loadDescription();

      // 🔥 自动滚动并聚焦到上次播放的集数
      if (_lastPlayedIndex != null) {
        _scrollToLastPlayed();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDescription() async {
    final description = await AnimeService.getAnimeDescription(
      widget.anime.title,
    );
    if (mounted) {
      setState(() {
        _description = description;
      });
    }
  }

  void _scrollToLastPlayed() {
    if (_lastPlayedIndex == null) return;

    // 等待布局完成后再滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      // 计算目标位置
      // 每行8个，childAspectRatio: 2.0, crossAxisSpacing: 15, mainAxisSpacing: 15
      const crossAxisCount = 8;
      final row = _lastPlayedIndex! ~/ crossAxisCount;

      // 估算每行高度（根据 GridView 配置）
      // 假设每个按钮宽度约为 (屏幕宽度 - padding - spacing) / 8
      // childAspectRatio = 2.0，所以高度 = 宽度 / 2
      // 这里使用一个估算值，实际可能需要根据屏幕尺寸调整
      const estimatedRowHeight = 60.0; // 按钮高度 + spacing
      final targetOffset = row * estimatedRowHeight;

      // 滚动到目标位置
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadFavoriteStatus() async {
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      final isFavorite = await FavoritesService.isFavorite(widget.anime.id);
      setState(() {
        _isFavorite = isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      if (_isFavorite) {
        await FavoritesService.removeFavorite(widget.anime.id);
      } else {
        await FavoritesService.addFavorite(widget.anime.id);
      }

      setState(() {
        _isFavorite = !_isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (e) {
      setState(() {
        _isFavoriteLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  void _playEpisode(Episode episode) {
    // 🔥 查找当前集数的索引
    final currentIndex = _episodes.indexWhere(
      (ep) => ep.title == episode.title,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          anime: widget.anime,
          allEpisodes: _episodes, // 🔥 传递所有集数
          currentEpisodeIndex: currentIndex >= 0
              ? currentIndex
              : null, // 🔥 传递当前索引
        ),
      ),
    ).then((_) {
      // 🔥 从播放器返回后，重新加载集数列表（刷新播放记录标记）
      _loadEpisodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('返回'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：封面和追番按钮
                  Column(
                    children: [
                      // 封面海报
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.anime.poster.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: AnimeService.getCoverUrl(
                                  widget.anime.poster,
                                ),
                                width: 180,
                                height: 260,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 180,
                                  height: 260,
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blueAccent,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 180,
                                  height: 260,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white30,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Container(
                                width: 180,
                                height: 260,
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.movie,
                                  color: Colors.white30,
                                  size: 60,
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // 追番按钮
                      Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.select)) {
                            _toggleFavorite();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (ctx) {
                            final focused = Focus.of(ctx).hasFocus;
                            return InkWell(
                              onTap: _toggleFavorite,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 180,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: focused
                                      ? Colors.blueAccent
                                      : (_isFavorite
                                            ? Colors.orange
                                            : Colors.grey[700]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: focused
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: _isFavoriteLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isFavorite ? '已追番' : '追番',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 40),

                  // 右侧：标题、状态、选集
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题
                        Text(
                          widget.anime.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // 状态和年份季度
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: widget.anime.status.contains('连载')
                                    ? const Color(0xFF00B0FF)
                                    : Colors.grey[700],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.anime.status,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: widget.anime.status.contains('连载')
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              '${widget.anime.year} ${widget.anime.season}',
                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // 集数选择标题
                        Text(
                          '选集 (${_episodes.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 集数网格和介绍文字（使用CustomScrollView）
                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              // 集数网格
                              SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 8,
                                      childAspectRatio: 2.0,
                                      crossAxisSpacing: 15,
                                      mainAxisSpacing: 15,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final episode = _episodes[index];
                                  final isLastPlayed =
                                      index == _lastPlayedIndex;

                                  return Focus(
                                    autofocus:
                                        isLastPlayed ||
                                        (index == 0 &&
                                            _lastPlayedIndex == null),
                                    onKeyEvent: (node, event) {
                                      if (event is KeyDownEvent &&
                                          (event.logicalKey ==
                                                  LogicalKeyboardKey.enter ||
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.select)) {
                                        _playEpisode(episode);
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: Builder(
                                      builder: (ctx) {
                                        final focused = Focus.of(ctx).hasFocus;
                                        return InkWell(
                                          onTap: () => _playEpisode(episode),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            decoration: BoxDecoration(
                                              color: focused
                                                  ? Colors.blueAccent
                                                  : isLastPlayed
                                                  ? const Color(0xFF444444)
                                                  : const Color(0xFF333333),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: focused
                                                  ? Border.all(
                                                      color: Colors.white,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (isLastPlayed && !focused)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.play_circle_outline,
                                                      color: Colors.white70,
                                                      size: 16,
                                                    ),
                                                  ),
                                                Flexible(
                                                  child: Text(
                                                    episode.title,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          focused ||
                                                              isLastPlayed
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }, childCount: _episodes.length),
                              ),

                              // 番剧介绍（紧跟在集数网格下方）
                              if (_description != null &&
                                  _description!.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(
                                      // 删除只有换行的空行
                                      _description!
                                          .replaceAll('\r\n', '\n')
                                          .split('\n')
                                          .where(
                                            (line) => line.trim().isNotEmpty,
                                          )
                                          .join('\n'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white60,
                                        height: 1.6,
                                      ),
                                      maxLines: 8, // 增加到8行显示更多内容
                                      overflow:
                                          TextOverflow.ellipsis, // 最后一行显示省略号
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
