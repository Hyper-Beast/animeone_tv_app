import '../services/api_client.dart';

class FavoritesService {
  /// 添加追番
  static Future<bool> addFavorite(String animeId) async {
    try {
      final response = await ApiClient.post('/api/favorites/add', {
        'anime_id': animeId,
      });

      return response['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  /// 取消追番
  static Future<bool> removeFavorite(String animeId) async {
    try {
      final response = await ApiClient.post('/api/favorites/remove', {
        'anime_id': animeId,
      });

      return response['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  /// 获取追番列表（倒序：最新追的在前）
  static Future<List<String>> getFavorites() async {
    try {
      final response = await ApiClient.get('/api/favorites/list');

      if (response['code'] == 200) {
        final data = response['data'] as List;
        final favorites = data.map((e) => e.toString()).toList();

        // 🔥 倒序：最新追的番剧排在前面
        return favorites.reversed.toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 检查是否已追番
  static Future<bool> isFavorite(String animeId) async {
    try {
      final favorites = await getFavorites();
      return favorites.contains(animeId);
    } catch (e) {
      return false;
    }
  }

  /// 切换追番状态
  static Future<bool> toggleFavorite(String animeId) async {
    final isFav = await isFavorite(animeId);
    if (isFav) {
      return await removeFavorite(animeId);
    } else {
      return await addFavorite(animeId);
    }
  }

  /// 获取追番列表（包含完整番剧信息）
  static Future<List<Map<String, dynamic>>> getFavoritesWithDetails() async {
    try {
      final response = await ApiClient.get('/api/favorites/list_with_details');

      if (response['code'] == 200) {
        final data = response['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
