import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/anime.dart';
import '../../services/anime_service.dart';
import '../../widgets/tv_capsule_selector.dart';
import '../../widgets/tv_dropdown_button.dart';
import '../../widgets/tv_action_button.dart';
import '../../widgets/tv_poster_card.dart';
import '../detail_screen.dart';

class ScheduleTab extends StatefulWidget {
  final FocusNode? sidebarFocusNode;
  const ScheduleTab({super.key, this.sidebarFocusNode});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final ScrollController _scrollController = ScrollController();

  late int _selectedYear;
  late String _selectedSeason;
  final List<String> _seasons = ["春季", "夏季", "秋季", "冬季"];
  late List<int> _yearList;

  // 真实世界的当前时间
  late int _realCurrentYear;
  late String _realCurrentSeason;

  // 星期数据
  int _selectedWeekIndex = 0;
  List<String> _weekDays = [];
  final List<String> _rawWeekDays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];

  List<List<Anime>> _seasonSchedule = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDateData();
    _loadSeasonSchedule();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initDateData() {
    final now = DateTime.now();
    _realCurrentYear = now.year;
    int month = now.month;
    if (month >= 1 && month <= 3) {
      _realCurrentSeason = "冬季";
    } else if (month >= 4 && month <= 6)
      _realCurrentSeason = "春季";
    else if (month >= 7 && month <= 9)
      _realCurrentSeason = "夏季";
    else
      _realCurrentSeason = "秋季";

    _selectedYear = _realCurrentYear;
    _selectedSeason = _realCurrentSeason;

    _yearList = [];
    for (int y = now.year; y >= 2017; y--) {
      _yearList.add(y);
    }
    _recalculateWeekDays();
  }

  void _recalculateWeekDays() {
    bool isCurrentTimeSlot =
        (_selectedYear == _realCurrentYear &&
        _selectedSeason == _realCurrentSeason);

    int startIndex;
    if (isCurrentTimeSlot) {
      startIndex = DateTime.now().weekday % 7;
    } else {
      startIndex = 1;
    }

    List<String> firstPart = _rawWeekDays.sublist(startIndex);
    List<String> secondPart = _rawWeekDays.sublist(0, startIndex);
    _weekDays = [...firstPart, ...secondPart];
    _selectedWeekIndex = 0;
  }

  void _onFilterChanged() {
    setState(() {
      _recalculateWeekDays();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadSeasonSchedule();
  }

  Future<void> _loadSeasonSchedule() async {
    setState(() => _isLoading = true);
    try {
      final schedule = await AnimeService.getSeasonSchedule(
        _selectedYear.toString(),
        _selectedSeason,
      );
      if (!mounted) return;

      bool isCurrentTimeSlot =
          (_selectedYear == _realCurrentYear &&
          _selectedSeason == _realCurrentSeason);
      int startIndex;
      if (isCurrentTimeSlot) {
        startIndex = DateTime.now().weekday % 7;
      } else {
        startIndex = 1;
      }

      List<List<Anime>> firstPart = schedule.sublist(startIndex);
      List<List<Anime>> secondPart = schedule.sublist(0, startIndex);
      List<List<Anime>> rotatedSchedule = [...firstPart, ...secondPart];

      setState(() {
        _seasonSchedule = rotatedSchedule;
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
    // 🔥 修改：Header 高度减小，让内容更靠近星期按钮
    const double headerHeight = 165;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: FocusTraversalGroup(
            child: _isLoading && _seasonSchedule.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    controller: _scrollController,
                    clipBehavior: Clip.none,
                    // 🔥 修改：Padding Top 减小，让内容更靠近星期按钮
                    padding: const EdgeInsets.fromLTRB(40, 185, 40, 150),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 30,
                        ),
                    itemCount:
                        _seasonSchedule.isNotEmpty &&
                            _selectedWeekIndex < _seasonSchedule.length
                        ? _seasonSchedule[_selectedWeekIndex].length
                        : 0,
                    itemBuilder: (context, index) {
                      if (_seasonSchedule.isEmpty ||
                          _selectedWeekIndex >= _seasonSchedule.length) {
                        return const SizedBox();
                      }
                      final anime = _seasonSchedule[_selectedWeekIndex][index];
                      return TvPosterCard(
                        index: index,
                        anime: anime,
                        titlePrefix: _weekDays.isNotEmpty
                            ? _weekDays[_selectedWeekIndex]
                            : "",
                        onTap: () => _openAnimeDetail(anime),
                        onMoveLeft: (index % 4 == 0)
                            ? () => widget.sidebarFocusNode?.requestFocus()
                            : null,
                        onFocus: () {
                          if (index < 4) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: Container(
            color: const Color(0xFF121212),
            padding: const EdgeInsets.fromLTRB(40, 30, 40, 5),
            child: FocusTraversalGroup(
              child: Column(
                children: [
                  // 筛选行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 140,
                        child: TvDropdownButton<int>(
                          label: "$_selectedYear 年",
                          items: _yearList,
                          itemLabelBuilder: (item) => "$item 年",
                          onChanged: (value) {
                            _selectedYear = value;
                            _onFilterChanged();
                          },
                          onMoveLeft: () =>
                              widget.sidebarFocusNode?.requestFocus(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        width: 120,
                        child: TvDropdownButton<String>(
                          label: _selectedSeason,
                          items: _seasons,
                          itemLabelBuilder: (item) => item,
                          onChanged: (value) {
                            _selectedSeason = value;
                            _onFilterChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        width: 100,
                        child: TvActionButton(
                          label: "查看",
                          color: Colors.blueAccent,
                          onTap: () => _onFilterChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // 星期行 - 🔥 使用胶囊样式选择器
                  TvCapsuleSelector(
                    labels: _weekDays,
                    counts: _seasonSchedule.map((day) => day.length).toList(),
                    selectedIndex: _selectedWeekIndex,
                    onIndexChanged: (index) {
                      setState(() => _selectedWeekIndex = index);
                    },
                    onMoveLeft: () => widget.sidebarFocusNode?.requestFocus(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
