import '../models/anime.dart';
import '../models/episode.dart';
import 'api_client.dart';

class AnimeService {
  /// 获取番剧列表
  /// [page] 页码，从 1 开始
  /// [keyword] 搜索关键词
  /// 返回 Map: {'list': List<Anime>, 'total': int}
  static Future<Map<String, dynamic>> getAnimeList({
    int page = 1,
    String keyword = '',
  }) async {
    try {
      final response = await ApiClient.get(
        '/api/list',
        queryParams: {
          'page': page.toString(),
          if (keyword.isNotEmpty) 'q': keyword,
        },
      );

      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        final list = data
            .map((json) => Anime.fromJson(json as Map<String, dynamic>))
            .toList();
        final total = response['total'] as int? ?? 0;
        return {'list': list, 'total': total};
      } else {
        throw Exception(response['msg'] ?? 'Failed to load anime list');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取季度新番表
  /// 返回 7 天的数据，每天是一个 Anime 列表
  static Future<List<List<Anime>>> getSeasonSchedule(
    String year,
    String season,
  ) async {
    try {
      final response = await ApiClient.get(
        '/api/season_schedule',
        queryParams: {'year': year, 'season': season},
      );

      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data.map((dayData) {
          final List<dynamic> dayList = dayData as List<dynamic>;
          return dayList
              .map((json) => Anime.fromJson(json as Map<String, dynamic>))
              .toList();
        }).toList();
      } else {
        throw Exception(response['msg'] ?? 'Failed to load season schedule');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取番剧的集数列表
  static Future<List<Episode>> getEpisodes(String animeId) async {
    try {
      final response = await ApiClient.get(
        '/api/episodes',
        queryParams: {'id': animeId},
      );

      if (response['code'] == 200) {
        final List<dynamic> data = response['data'] as List<dynamic>;
        return data
            .map((json) => Episode.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(response['msg'] ?? 'Failed to load episodes');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取播放地址
  static Future<String> getPlayUrl(String token) async {
    try {
      final response = await ApiClient.get(
        '/api/play_info',
        queryParams: {'token': token},
      );

      if (response['code'] == 200) {
        final url = response['url'] as String;
        // 🔥 修复：如果是相对路径，添加 baseUrl
        if (url.startsWith('/')) {
          return '${ApiClient.baseUrl}$url';
        }
        return url;
      } else {
        throw Exception(response['msg'] ?? 'Failed to get play URL');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取封面图片 URL
  static String getCoverUrl(String? poster) {
    if (poster == null || poster.isEmpty) return '';
    if (poster.startsWith('http')) return poster;
    return '${ApiClient.baseUrl}$poster';
  }

  /// 获取番剧介绍
  /// [title] 番剧标题
  /// 返回介绍文本，如果没有则返回 null
  static Future<String?> getAnimeDescription(String title) async {
    try {
      final response = await ApiClient.get('/static/json/desc_map.json');
      // 直接从 JSON 对象中获取对应标题的介绍
      return response[title] as String?;
    } catch (e) {
      return null;
    }
  }
}
