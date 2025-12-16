import 'package:flutter/material.dart';
import '../../models/anime.dart';
import '../../models/playback_history.dart';
import '../../services/playback_history_service.dart';
import '../../widgets/tv_poster_card.dart';
import '../detail_screen.dart';
import 'package:flutter/rendering.dart';

class HistoryTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  const HistoryTab({super.key, this.sidebarFocusNode});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ScrollController _scrollController = ScrollController();
  List<PlaybackHistory> _historyList = [];
  List<Anime> _historyAnimes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 优化：获取所有播放记录（现在包含完整番剧信息）
      _historyList = await PlaybackHistoryService.getAllPlaybackHistory();

      if (_historyList.isEmpty) {
        setState(() {
          _historyAnimes = [];
          _isLoading = false;
        });
        return;
      }

      // 🔥 优化：直接使用 PlaybackHistory 中的完整信息，无需额外请求
      _historyAnimes = _historyList
          .where((history) => history.title != null) // 只保留有标题的（说明后端找到了）
          .map(
            (history) => Anime(
              id: history.animeId,
              title: history.title!,
              status: history.status ?? '完结',
              year: history.year ?? '',
              season: history.season ?? '',
              poster: history.poster ?? '',
              isFavorite: false, // 历史记录页面不需要显示追番状态
              playback: PlaybackInfo(
                episodeTitle: history.episodeTitle,
                position: history.playbackPosition,
              ),
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openAnimeDetail(Anime anime) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(anime: anime)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: _isLoading && _historyAnimes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text(
                    '加载中...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : _historyAnimes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.white24),
                  SizedBox(height: 20),
                  Text(
                    '还没有观看记录哦',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '开始观看番剧后会自动记录',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          : Stack(
              clipBehavior: Clip.none, // 避免海报放大时被裁剪
              children: [
                // 番剧网格 - 添加顶部padding为标题留空间
                Positioned.fill(
                  child: GridView.builder(
                    controller: _scrollController,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(40, 100, 40, 150),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 30,
                        ),
                    itemCount: _historyAnimes.length,
                    itemBuilder: (context, index) {
                      final anime = _historyAnimes[index];
                      return Builder(
                        builder: (context) {
                          return TvPosterCard(
                            index: index,
                            anime: anime,
                            titlePrefix: "历史",
                            onTap: () => _openAnimeDetail(anime),
                            onMoveLeft: (index % 4 == 0)
                                ? () => widget.sidebarFocusNode?.requestFocus()
                                : null,
                            onFocus: () {
                              if (_scrollController.hasClients) {
                                final RenderObject? object = context
                                    .findRenderObject();
                                if (object != null && object is RenderBox) {
                                  final viewport = RenderAbstractViewport.of(
                                    object,
                                  );
                                  final offsetToRevealTop = viewport
                                      .getOffsetToReveal(object, 0.0)
                                      .offset;
                                  final currentOffset =
                                      _scrollController.offset;
                                  final targetOffset = (offsetToRevealTop - 150)
                                      .clamp(
                                        0.0,
                                        _scrollController
                                            .position
                                            .maxScrollExtent,
                                      );

                                  if (currentOffset > targetOffset) {
                                    _scrollController.animateTo(
                                      targetOffset,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                }
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // 固定标题
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xFF121212),
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '观看历史 (${_historyAnimes.length})',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '按观看时间排序',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
