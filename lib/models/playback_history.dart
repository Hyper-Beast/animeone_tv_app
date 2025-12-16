class PlaybackHistory {
  final String animeId;
  final String episodeTitle;
  final DateTime timestamp;
  final int playbackPosition; // 播放位置（秒）

  PlaybackHistory({
    required this.animeId,
    required this.episodeTitle,
    required this.timestamp,
    this.playbackPosition = 0,
  });

  factory PlaybackHistory.fromJson(Map<String, dynamic> json) {
    return PlaybackHistory(
      animeId: json['animeId'] as String,
      episodeTitle: json['episodeTitle'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      playbackPosition: json['playbackPosition'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'episodeTitle': episodeTitle,
      'timestamp': timestamp.toIso8601String(),
      'playbackPosition': playbackPosition,
    };
  }
}
