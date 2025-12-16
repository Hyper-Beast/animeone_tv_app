class PlaybackHistory {
  final String animeId;
  final String episodeTitle;
  final DateTime timestamp;
  final int playbackPosition; // 播放位置（秒）

  // 🔥 新增：完整番剧信息（来自增强的 API）
  final String? title;
  final String? status;
  final String? year;
  final String? season;
  final String? poster;

  PlaybackHistory({
    required this.animeId,
    required this.episodeTitle,
    required this.timestamp,
    this.playbackPosition = 0,
    this.title,
    this.status,
    this.year,
    this.season,
    this.poster,
  });

  factory PlaybackHistory.fromJson(Map<String, dynamic> json) {
    return PlaybackHistory(
      animeId: json['animeId'] as String,
      episodeTitle: json['episodeTitle'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      playbackPosition: json['playbackPosition'] as int? ?? 0,
      title: json['title'] as String?,
      status: json['status'] as String?,
      year: json['year'] as String?,
      season: json['season'] as String?,
      poster: json['poster'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'episodeTitle': episodeTitle,
      'timestamp': timestamp.toIso8601String(),
      'playbackPosition': playbackPosition,
      'title': title,
      'status': status,
      'year': year,
      'season': season,
      'poster': poster,
    };
  }
}
