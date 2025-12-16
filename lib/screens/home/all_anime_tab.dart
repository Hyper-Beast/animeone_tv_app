import 'package:flutter/material.dart';
import '../../models/anime.dart';
import '../../services/anime_service.dart';
import '../../widgets/tv_poster_card.dart';
import '../detail_screen.dart';
import 'package:flutter/rendering.dart';

class AllAnimeTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  const AllAnimeTab({super.key, this.sidebarFocusNode});

  @override
  State<AllAnimeTab> createState() => _AllAnimeTabState();
}

class _AllAnimeTabState extends State<AllAnimeTab> {
  final ScrollController _scrollController = ScrollController();

  List<Anime> _allAnimeList = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalCount = 0; // 🔥 新增：服务器返回的总数

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAllAnime();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 500) {
      if (_hasMore && !_isLoading) {
        _currentPage++;
        _loadAllAnime(loadMore: true);
      }
    }
  }

  Future<void> _loadAllAnime({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (!loadMore) {
        _currentPage = 1;
        _allAnimeList = [];
      }
      // 🔥 使用新的返回格式
      final result = await AnimeService.getAnimeList(
        page: _currentPage,
        keyword: '',
      );
      final animeList = result['list'] as List<Anime>;
      final total = result['total'] as int;

      if (!mounted) return;
      setState(() {
        if (loadMore) {
          _allAnimeList.addAll(animeList);
        } else {
          _allAnimeList = animeList;
        }
        _totalCount = total; // 保存总数
        _hasMore = animeList.length >= 24;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
      child: _isLoading && _allAnimeList.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                    itemCount: _allAnimeList.length,
                    itemBuilder: (context, index) {
                      final anime = _allAnimeList[index];
                      return Builder(
                        builder: (context) {
                          return TvPosterCard(
                            index: index,
                            anime: anime,
                            titlePrefix: "全部",
                            onTap: () => _openAnimeDetail(anime),
                            onMoveLeft: (index % 4 == 0)
                                ? () => widget.sidebarFocusNode?.requestFocus()
                                : null,
                            onFocus: () {
                              if (_scrollController.hasClients) {
                                final RenderObject? object = context
                                    .findRenderObject();
                                if (object != null && object is RenderBox) {
                                  // 获取item相对于viewport的位置
                                  // 注意：这就需要找到包括header的整个视口
                                  // 简单方法：获取全局坐标，减去GridView的全局坐标（或者近似值）

                                  // 更可靠的方法：使用ShowInViewport的变体，或者手动计算
                                  final viewport = RenderAbstractViewport.of(
                                    object,
                                  );
                                  // viewport 在此处不为空，因为我们在 ScrollView 内部
                                  final offsetToRevealTop = viewport
                                      .getOffsetToReveal(object, 0.0)
                                      .offset;
                                  // offsetToRevealTop 是让item顶部对齐viewport顶部的scrollOffset
                                  // 我们现在希望item顶部距离viewport顶部150px
                                  // 也就是说，我们不希望scrollOffset是offsetToRevealTop
                                  // 而是希望scrollOffset = offsetToRevealTop - 150

                                  final currentOffset =
                                      _scrollController.offset;
                                  final targetOffset = (offsetToRevealTop - 150)
                                      .clamp(
                                        0.0,
                                        _scrollController
                                            .position
                                            .maxScrollExtent,
                                      );

                                  // 只有当当前位置会导致被遮挡时才滚动（即 currentOffset > targetOffset）
                                  // 或者简单点：只要focus，就检查是否需要调整

                                  // 获取当前item距离viewport顶部的距离
                                  // itemTopInViewport = object.localToGlobal(Offset.zero).dy;
                                  // 这种方式受header影响。

                                  // 还是用offset比较稳：
                                  // 如果 currentOffset > offsetToRevealTop - 150，说明滚得太下面了，item被header遮挡了
                                  // 此时需要滚回去
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
                      '全部番剧 ($_totalCount)',
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
