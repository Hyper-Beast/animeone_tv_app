import '../models/playback_history.dart';
import '../services/api_client.dart';

class PlaybackHistoryService {
  /// 保存播放记录（仅服务器）
  static Future<void> savePlaybackHistory(
    String animeId,
    String episodeTitle, {
    int playbackPosition = 0,
  }) async {
    try {
      await ApiClient.post('/api/playback/save', {
        'anime_id': animeId,
        'episode_title': episodeTitle,
        'playback_position': playbackPosition,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 获取指定番剧的播放记录（仅服务器）
  static Future<PlaybackHistory?> getPlaybackHistory(String animeId) async {
    try {
      final response = await ApiClient.get('/api/playback/get/$animeId');

      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.isNotEmpty) {
          return PlaybackHistory(
            animeId: animeId,
            episodeTitle: data['episode_title'] as String,
            timestamp: DateTime.parse(data['timestamp'] as String),
            playbackPosition: data['playback_position'] as int? ?? 0,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 清除指定番剧的播放记录（仅服务器）
  static Future<void> clearPlaybackHistory(String animeId) async {
    try {
      await ApiClient.post('/api/playback/clear', {'anime_id': animeId});
    } catch (e) {
      rethrow;
    }
  }

  /// 获取所有播放记录（仅服务器）
  static Future<List<PlaybackHistory>> getAllPlaybackHistory() async {
    try {
      final response = await ApiClient.get('/api/playback/list');

      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'] as List;
        return data.map((item) {
          return PlaybackHistory(
            animeId: item['anime_id'] as String,
            episodeTitle: item['episode_title'] as String,
            timestamp: DateTime.parse(item['timestamp'] as String),
            playbackPosition: item['playback_position'] as int? ?? 0,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// 清除所有播放记录
  static Future<void> clearAll() async {
    try {
      await ApiClient.post('/api/playback/clear_all', {});
    } catch (e) {
      rethrow;
    }
  }
}
