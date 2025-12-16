import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:fluttertoast/fluttertoast.dart';

// 假设你的模型和服务路径如下，请根据实际情况调整引用
import '../models/anime.dart';
import '../models/episode.dart';
import '../services/anime_service.dart';
import '../services/playback_history_service.dart';

class PlayerScreen extends StatefulWidget {
  final Anime anime;
  final Episode episode;

  const PlayerScreen({super.key, required this.anime, required this.episode});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _lastBackPressed; // 双击返回退出

  // 控制 UI 显示的状态
  bool _showControls = false;
  Timer? _hideTimer;

  // 定期保存播放位置的定时器
  Timer? _savePositionTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final playUrl = await AnimeService.getPlayUrl(widget.episode.token);
      if (!mounted) return;

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(playUrl),
      );

      await _videoPlayerController!.initialize();
      if (!mounted) return;

      // 🔥 恢复上次播放位置
      final history = await PlaybackHistoryService.getPlaybackHistory(
        widget.anime.id,
      );
      int startPosition = 0;
      if (history != null && history.episodeTitle == widget.episode.title) {
        startPosition = history.playbackPosition;
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: false, // 我们自己画 UI
        allowedScreenSleep: false,
        routePageBuilder: null,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        ),
      );

      // 如果有保存的位置，跳转到该位置
      if (startPosition > 0) {
        await _videoPlayerController!.seekTo(Duration(seconds: startPosition));

        // 显示跳转提示
        if (mounted) {
          Fluttertoast.showToast(
            msg: "已跳转至 ${_formatDuration(Duration(seconds: startPosition))}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withOpacity(0.7),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        }
      }

      // 保存初始播放记录
      await PlaybackHistoryService.savePlaybackHistory(
        widget.anime.id,
        widget.episode.title,
        playbackPosition: startPosition,
      );

      // 🔥 启动定期保存定时器（每10秒保存一次）
      _startSavePositionTimer();

      setState(() {
        _isLoading = false;
        _showControls = true;
      });
      // 初始加载也是播放状态，启动倒计时
      _startHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  // --- UI 控制逻辑 ---

  // 每次按键调用此方法：显示 UI
  void _toggleControls() {
    setState(() {
      _showControls = true;
    });
    // 调用倒计时逻辑，内部会判断是否需要倒计时
    _startHideTimer();
  }

  // 🔥【修改点 1】修改倒计时逻辑：只有在“播放中”才启动倒计时
  // 如果是暂停状态，直接取消计时器，保持 UI 常亮
  void _startHideTimer() {
    _hideTimer?.cancel();

    // 如果控制器没初始化，或者当前是暂停状态，就不启动自动隐藏
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isPlaying) {
      return;
    }

    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // 🔥 启动定期保存播放位置的定时器
  void _startSavePositionTimer() {
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _saveCurrentPosition();
    });
  }

  // 🔥 保存当前播放位置
  Future<void> _saveCurrentPosition() async {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      final position = _videoPlayerController!.value.position.inSeconds;
      await PlaybackHistoryService.savePlaybackHistory(
        widget.anime.id,
        widget.episode.title,
        playbackPosition: position,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    // 🔥 退出前保存最终播放位置
    _saveCurrentPosition();

    _hideTimer?.cancel();
    _savePositionTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          Fluttertoast.showToast(
            msg: "再按一次返回键退出播放",
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
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;

            if (_videoPlayerController == null ||
                !_videoPlayerController!.value.isInitialized) {
              // 检查多种可能的返回键 - 返回ignored让WillPopScope处理
              if (event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.browserBack) {
                return KeyEventResult.ignored; // 让WillPopScope处理
              }
              return KeyEventResult.ignored;
            }

            bool interacted = false;

            // 1. 确认键 -> 暂停/播放
            if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              if (_videoPlayerController!.value.isPlaying) {
                // 🔥【修改点 2】暂停逻辑：暂停视频，显示 UI，并强制取消倒计时
                _videoPlayerController!.pause();
                setState(() {
                  _showControls = true;
                });
                _hideTimer?.cancel();
              } else {
                // 🔥【修改点 3】播放逻辑：开始播放，显示 UI，启动倒计时
                _videoPlayerController!.play();
                _toggleControls();
              }
              interacted = true;
            }
            // 2. 左/右键 -> 快退/快进
            else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              final current = _videoPlayerController!.value.position;
              final total = _videoPlayerController!.value.duration;
              final newPos = current + const Duration(seconds: 10);
              _videoPlayerController!.seekTo(newPos < total ? newPos : total);
              interacted = true;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              final current = _videoPlayerController!.value.position;
              final newPos = current - const Duration(seconds: 10);
              _videoPlayerController!.seekTo(
                newPos > Duration.zero ? newPos : Duration.zero,
              );
              interacted = true;
            }
            // 3. 上/下键 -> 音量
            else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              final newVol = (_videoPlayerController!.value.volume + 0.1).clamp(
                0.0,
                1.0,
              );
              _videoPlayerController!.setVolume(newVol);
              interacted = true;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              final newVol = (_videoPlayerController!.value.volume - 0.1).clamp(
                0.0,
                1.0,
              );
              _videoPlayerController!.setVolume(newVol);
              interacted = true;
            }

            if (interacted) {
              // 如果刚刚按的是方向键而不是回车，这里会统一处理。
              // 只有当视频正在播放时，_toggleControls 才会启动倒计时。
              // 如果视频是暂停的，_toggleControls 里的 _startHideTimer 会发现处于暂停状态从而不启动计时。
              // 这样就保证了：暂停状态下调整进度/音量，UI 依然常亮。
              if (event.logicalKey != LogicalKeyboardKey.select &&
                  event.logicalKey != LogicalKeyboardKey.enter &&
                  event.logicalKey != LogicalKeyboardKey.numpadEnter) {
                _toggleControls();
              }
              return KeyEventResult.handled;
            }

            // 检查多种可能的返回键 - 返回ignored让WillPopScope处理
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack ||
                event.logicalKey == LogicalKeyboardKey.browserBack) {
              return KeyEventResult.ignored; // 让WillPopScope处理
            }

            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // 层级 1: 视频画面
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.blueAccent)
                    : _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      )
                    : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
              ),

              // 🔥【修改点 4】新增：屏幕中间的状态图标 (独立于 UI 遮罩层)
              // 无论 _showControls 是 true 还是 false，只要暂停了，这个就显示
              if (!_isLoading && _videoPlayerController != null)
                Center(
                  child: ValueListenableBuilder(
                    valueListenable: _videoPlayerController!,
                    builder: (context, VideoPlayerValue value, child) {
                      // 如果正在缓冲，优先显示缓冲圈（或者什么都不显示，交给底层的CircularProgressIndicator）
                      if (value.isBuffering) {
                        return const SizedBox.shrink();
                      }
                      // 如果暂停了，显示大图标
                      if (!value.isPlaying) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Icon(
                            Icons.pause,
                            color: Colors.white,
                            size: 64,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

              // 层级 3: 自定义 UI 覆盖层 (标题 & 进度条)
              if (!_isLoading &&
                  _errorMessage == null &&
                  _videoPlayerController != null)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Stack(
                      children: [
                        // ... 保持原有的阴影遮罩代码不变 ...
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.8),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        // --- 顶部标题栏 ---
                        Positioned(
                          top: 30,
                          left: 40,
                          right: 40,
                          child: Row(
                            children: [
                              // 这里的左上角图标也可以跟着变
                              ValueListenableBuilder(
                                valueListenable: _videoPlayerController!,
                                builder:
                                    (context, VideoPlayerValue value, child) {
                                      return Icon(
                                        value.isPlaying
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        color: Colors.white,
                                        size: 28,
                                      );
                                    },
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.anime.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 2,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      widget.episode.title,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- 底部进度条 ---
                        Positioned(
                          bottom: 30,
                          left: 40,
                          right: 40,
                          child: ValueListenableBuilder(
                            valueListenable: _videoPlayerController!,
                            builder: (context, VideoPlayerValue value, child) {
                              final position = value.position;
                              final duration = value.duration;
                              return Row(
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: VideoProgressIndicator(
                                      _videoPlayerController!,
                                      allowScrubbing: false,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      colors: VideoProgressColors(
                                        playedColor: Colors.blueAccent,
                                        bufferedColor: Colors.white24,
                                        backgroundColor: Colors.grey
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
