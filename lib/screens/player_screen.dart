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
  final List<Episode>? allEpisodes; // 🔥 所有集数列表
  final int? currentEpisodeIndex; // 🔥 当前集数索引

  const PlayerScreen({
    super.key,
    required this.anime,
    this.allEpisodes,
    this.currentEpisodeIndex,
  });

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

  // 🔥 当前播放的集数和索引（可变）
  late Episode _currentEpisode;
  late int _currentEpisodeIndex;

  // 🔥 控制标志
  bool _hasTriggeredCompletion = false; // 防止重复触发
  bool _shouldSave = true; // 控制是否允许保存

  @override
  void initState() {
    super.initState();
    // 🔥 初始化当前集数信息
    _currentEpisodeIndex = widget.currentEpisodeIndex ?? 0;
    if (widget.allEpisodes != null &&
        _currentEpisodeIndex < widget.allEpisodes!.length) {
      _currentEpisode = widget.allEpisodes![_currentEpisodeIndex];
    } else {
      // 如果没有提供 allEpisodes，则无法自动播放下一集
      _currentEpisode = Episode(
        index: 0,
        title: 'Unknown',
        fullTitle: 'Unknown',
        token: '',
      );
    }
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final playUrl = await AnimeService.getPlayUrl(_currentEpisode.token);
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
      if (history != null && history.episodeTitle == _currentEpisode.title) {
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
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        }
      }

      // 保存初始播放记录
      await PlaybackHistoryService.savePlaybackHistory(
        widget.anime.id,
        _currentEpisode.title,
        playbackPosition: startPosition,
      );

      // 🔥 启动定期保存定时器（每10秒保存一次）
      _startSavePositionTimer();

      // 🔥 监听播放完成事件
      _videoPlayerController!.addListener(_videoListener);

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

  // 🔥 监听视频播放状态
  void _videoListener() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    // 🔥 检查是否即将播放完成（剩余时间少于10秒）
    // 因为每10秒上传一次，用10秒作为阈值确保最后一次上传后就触发
    if (duration.inSeconds > 0 &&
        (duration.inSeconds - position.inSeconds) <= 10 &&
        !_hasTriggeredCompletion) {
      // 🔥 防止重复触发
      _hasTriggeredCompletion = true;
      _onVideoCompleted();
    }
  }

  // 🔥 视频播放完成处理
  Future<void> _onVideoCompleted() async {
    // 移除监听器，避免重复触发
    _videoPlayerController?.removeListener(_videoListener);

    // 🔥 禁止继续保存，避免 clear 后又 save
    _shouldSave = false;

    // 清除播放记录（表示已看完）
    await PlaybackHistoryService.clearPlaybackHistory(widget.anime.id);

    // 检查是否有下一集
    if (widget.allEpisodes != null) {
      // 🔥 注意：列表是倒序的（最新集在前），所以下一集是 index - 1
      final nextIndex = _currentEpisodeIndex - 1;

      if (nextIndex >= 0 && nextIndex < widget.allEpisodes!.length) {
        final nextEpisode = widget.allEpisodes![nextIndex];

        // 🔥 立即显示提示（而不是等播完才显示）
        if (mounted) {
          Fluttertoast.showToast(
            msg: "即将播放下一集: ${nextEpisode.title}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        }

        // 🔥 等待视频播完（最多5秒）
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isPlaying) {
          // 如果还在播放，等待播完
          await Future.any([
            _videoPlayerController!.position.then((pos) {
              // 等待播放到结束
              return Future.doWhile(() async {
                if (!mounted || _videoPlayerController == null) return false;
                final remaining =
                    _videoPlayerController!.value.duration.inSeconds -
                    _videoPlayerController!.value.position.inSeconds;
                if (remaining <= 0) return false;
                await Future.delayed(const Duration(milliseconds: 100));
                return true;
              });
            }),
            Future.delayed(const Duration(seconds: 5)), // 最多等5秒
          ]);
        }

        if (mounted) {
          // 🔥 关键修复：在当前页面重新初始化播放器，而不是跳转
          _currentEpisode = nextEpisode;
          _currentEpisodeIndex = nextIndex;

          // 清理旧资源
          _savePositionTimer?.cancel();
          _hideTimer?.cancel();
          _videoPlayerController?.removeListener(_videoListener);
          _chewieController?.dispose();
          _videoPlayerController?.dispose();

          // 重新初始化
          _shouldSave = true; // 🔥 重置保存标志
          _hasTriggeredCompletion = false; // 🔥 重置完成标志
          await _initializePlayer();
        }
      } else {
        // 没有下一集了
        if (mounted) {
          Fluttertoast.showToast(
            msg: "已播放完所有集数",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        }
      }
    }
  }

  // 🔥 保存当前播放位置
  Future<void> _saveCurrentPosition() async {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        _shouldSave) {
      // 🔥 检查是否允许保存
      final position = _videoPlayerController!.value.position.inSeconds;

      // 🔥 只保存，不清除（清除由 _onVideoCompleted 处理）
      await PlaybackHistoryService.savePlaybackHistory(
        widget.anime.id,
        _currentEpisode.title,
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
    // 🔥 移除监听器
    _videoPlayerController?.removeListener(_videoListener);

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          Fluttertoast.showToast(
            msg: "再按一次返回键退出播放",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            textColor: Colors.white,
            fontSize: 18.0,
          );
        } else {
          Navigator.of(context).pop();
        }
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
                            color: Colors.black.withValues(alpha: 0.5),
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
                                  Colors.black.withValues(alpha: 0.8),
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
                                  Colors.black.withValues(alpha: 0.8),
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
                                      _currentEpisode.title,
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
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
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
