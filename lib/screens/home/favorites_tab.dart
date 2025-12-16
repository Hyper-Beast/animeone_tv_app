import 'package:flutter/material.dart';
import '../../models/anime.dart';
import '../../services/anime_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/tv_poster_card.dart';
import '../detail_screen.dart';
import 'package:flutter/rendering.dart';

class FavoritesTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  const FavoritesTab({super.key, this.sidebarFocusNode});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final ScrollController _scrollController = ScrollController();
  List<String> _favoriteIds = [];
  List<Anime> _favoriteAnimes = [];
  bool _favoritesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 加载追番列表
  Future<void> _loadFavorites() async {
    setState(() {
      _favoritesLoading = true;
    });

    try {
      // 获取追番ID列表
      _favoriteIds = await FavoritesService.getFavorites();

      if (_favoriteIds.isEmpty) {
        setState(() {
          _favoriteAnimes = [];
          _favoritesLoading = false;
        });
        return;
      }

      // 获取所有番剧列表（分页加载）
      List<Anime> allAnimes = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore && page <= 50) {
        // 最多加载50页
        final result = await AnimeService.getAnimeList(page: page);
        final animes = result['list'] as List<Anime>;
        if (animes.isEmpty) {
          hasMore = false;
        } else {
          allAnimes.addAll(animes);
          page++;
        }
      }

      // 筛选出追番的番剧
      _favoriteAnimes = allAnimes
          .where((anime) => _favoriteIds.contains(anime.id))
          .toList();

      if (mounted) {
        setState(() {
          _favoritesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoritesLoading = false;
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
      child: _favoritesLoading && _favoriteAnimes.isEmpty
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
          : _favoriteAnimes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.white24),
                  SizedBox(height: 20),
                  Text(
                    '还没有追番哦',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '在番剧详情页点击"追番"按钮即可添加',
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
                    itemCount: _favoriteAnimes.length,
                    itemBuilder: (context, index) {
                      final anime = _favoriteAnimes[index];
                      return Builder(
                        builder: (context) {
                          return TvPosterCard(
                            index: index,
                            anime: anime,
                            titlePrefix: "追番",
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
                    child: Text(
                      '我的追番 (${_favoriteAnimes.length})',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
