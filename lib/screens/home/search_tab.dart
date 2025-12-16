import 'package:flutter/material.dart';
import '../../models/anime.dart';
import '../../services/anime_service.dart';
import '../../widgets/tv_keyboard_button.dart';
import '../../widgets/tv_action_button.dart';
import '../../widgets/tv_poster_card.dart';
import '../detail_screen.dart';
import 'package:flutter/rendering.dart';

class SearchTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  const SearchTab({super.key, this.sidebarFocusNode});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String _searchText = "";
  final List<String> _gridKeys = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
  ];

  List<Anime> _searchResults = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleKeyboardTap(String key) {
    setState(() {
      if (key == '后退') {
        if (_searchText.isNotEmpty) {
          _searchText = _searchText.substring(0, _searchText.length - 1);
        }
      } else if (key == '清空') {
        _searchText = "";
        _searchResults = [];
      } else if (key == '搜索') {
        // 搜索按钮现在不需要了，因为自动搜索
        _searchAnime();
      } else {
        _searchText += key;
      }
    });

    // 🔥 自动搜索：每次输入变化后自动触发搜索
    if (key != '搜索') {
      _searchAnime();
    }
  }

  Future<void> _searchAnime() async {
    if (_searchText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AnimeService.getAnimeList(
        page: 1,
        keyword: _searchText,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = result['list'] as List<Anime>;
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 键盘
        Expanded(
          flex: 35,
          child: Container(
            color: const Color(0xFF252525),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _searchText.isEmpty ? "输入拼音首字母..." : _searchText,
                            style: TextStyle(
                              fontSize: 18,
                              color: _searchText.isEmpty
                                  ? Colors.white24
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(1.0),
                            child: TvKeyboardButton(
                              label: '清空',
                              onTap: () => _handleKeyboardTap('清空'),
                              onMoveLeft: () =>
                                  widget.sidebarFocusNode?.requestFocus(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FocusTraversalOrder(
                            order: const NumericFocusOrder(1.1),
                            child: TvKeyboardButton(
                              label: '后退',
                              onTap: () => _handleKeyboardTap('后退'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _gridKeys.length,
                    itemBuilder: (context, index) => FocusTraversalOrder(
                      order: NumericFocusOrder(2.0 + (index * 0.001)),
                      child: TvKeyboardButton(
                        label: _gridKeys[index],
                        onTap: () => _handleKeyboardTap(_gridKeys[index]),
                        onMoveLeft: (index % 6 == 0)
                            ? () => widget.sidebarFocusNode?.requestFocus()
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3.0),
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: TvActionButton(
                        // Need to check TvActionButton
                        label: '搜索',
                        color: const Color(0xFF354898),
                        onTap: () => _handleKeyboardTap('搜索'),
                        onMoveLeft: () =>
                            widget.sidebarFocusNode?.requestFocus(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 结果
        Expanded(
          flex: 65,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  clipBehavior: Clip.none, // 避免海报放大时被裁剪
                  children: [
                    // 搜索结果网格
                    Positioned.fill(
                      child: GridView.builder(
                        controller: _scrollController,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.fromLTRB(30, 100, 30, 80),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.55,
                              crossAxisSpacing: 30,
                              mainAxisSpacing: 30,
                            ),
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, idx) {
                          final anime = _searchResults[idx];
                          return Builder(
                            builder: (context) {
                              return TvPosterCard(
                                index: idx,
                                anime: anime,
                                titlePrefix: "结果",
                                onTap: () => _openAnimeDetail(anime),
                                onFocus: () {
                                  if (_scrollController.hasClients) {
                                    final RenderObject? object = context
                                        .findRenderObject();
                                    if (object != null && object is RenderBox) {
                                      final viewport =
                                          RenderAbstractViewport.of(object);
                                      final offsetToRevealTop = viewport
                                          .getOffsetToReveal(object, 0.0)
                                          .offset;
                                      final currentOffset =
                                          _scrollController.offset;
                                      final targetOffset =
                                          (offsetToRevealTop - 150).clamp(
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
                    // 固定的header遮挡层
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFF121212),
                        padding: const EdgeInsets.fromLTRB(30, 20, 30, 20),
                        child: Text(
                          _searchText.isEmpty ? "" : "搜索结果: $_searchText",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
