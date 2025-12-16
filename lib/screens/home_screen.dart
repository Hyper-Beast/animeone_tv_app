import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home/search_tab.dart';
import 'home/schedule_tab.dart';
import 'home/all_anime_tab.dart';
import 'home/favorites_tab.dart';
import 'home/history_tab.dart';
import '../widgets/tv_focusable_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 1; // 默认选中季度新番
  DateTime? _lastBackPressed;

  // 🔥 修改：使用SVG图标路径替代文字
  final List<String> _tabIcons = [
    "icon/search.svg", // 搜索
    "icon/home.svg", // 季度新番
    "icon/grid.svg", // 全部番剧
    "icon/f_main.svg", // 我的追番
    "icon/history.svg", // 观看历史
  ];

  late List<FocusNode> _sideBarFocusNodes;

  @override
  void initState() {
    super.initState();
    _sideBarFocusNodes = List.generate(
      _tabIcons.length,
      (index) => FocusNode(),
    );

    // 启动时聚焦到季度新番标签
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _sideBarFocusNodes[1].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var node in _sideBarFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleSideBarTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _sideBarFocusNodes[index].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          // 显示Toast提示
          Fluttertoast.showToast(
            msg: "再按一次返回键退出应用",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withOpacity(0.7),
            textColor: Colors.white,
            fontSize: 18.0,
          );

          return false; // 不退出
        }
        return true; // 退出
      },
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 15,
              child: Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(_tabIcons.length, (index) {
                    return TvFocusableItem(
                      iconPath: _tabIcons[index], // 🔥 使用SVG图标
                      isSelected: _selectedTabIndex == index,
                      focusNode: _sideBarFocusNodes[index],
                      onFocus: () {
                        setState(() => _selectedTabIndex = index);
                        _handleSideBarTap(index); // 🔥 焦点移动时自动加载
                      },
                      onTap: () => _handleSideBarTap(index),
                    );
                  }),
                ),
              ),
            ),
            Expanded(flex: 85, child: _buildRightContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildRightContent() {
    switch (_selectedTabIndex) {
      case 0:
        return SearchTab(sidebarFocusNode: _sideBarFocusNodes[0]);
      case 1:
        return ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: ScheduleTab(sidebarFocusNode: _sideBarFocusNodes[1]),
        );
      case 2:
        return AllAnimeTab(sidebarFocusNode: _sideBarFocusNodes[2]);
      case 3:
        return FavoritesTab(sidebarFocusNode: _sideBarFocusNodes[3]);
      case 4:
        return HistoryTab(sidebarFocusNode: _sideBarFocusNodes[4]);
      default:
        return ScheduleTab(sidebarFocusNode: _sideBarFocusNodes[1]);
    }
  }
}
