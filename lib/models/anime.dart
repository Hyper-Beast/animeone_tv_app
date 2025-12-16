class Anime {
  final String id;
  final String title;
  final String status;
  final String year;
  final String season;
  final String poster;

  // 🔥 新增：追番状态和播放记录
  final bool isFavorite;
  final PlaybackInfo? playback;

  Anime({
    required this.id,
    required this.title,
    required this.status,
    required this.year,
    required this.season,
    this.poster = '',
    this.isFavorite = false,
    this.playback,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    PlaybackInfo? playbackInfo;
    if (json['playback'] != null) {
      final playbackData = json['playback'] as Map<String, dynamic>;
      playbackInfo = PlaybackInfo(
        episodeTitle: playbackData['episode_title']?.toString() ?? '',
        position: playbackData['position'] as int? ?? 0,
      );
    }

    return Anime(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '完结',
      year: json['year']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      isFavorite: json['is_favorite'] as bool? ?? false,
      playback: playbackInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'year': year,
      'season': season,
      'poster': poster,
      'is_favorite': isFavorite,
      'playback': playback?.toJson(),
    };
  }

  Anime copyWith({
    String? id,
    String? title,
    String? status,
    String? year,
    String? season,
    String? poster,
    bool? isFavorite,
    PlaybackInfo? playback,
  }) {
    return Anime(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      year: year ?? this.year,
      season: season ?? this.season,
      poster: poster ?? this.poster,
      isFavorite: isFavorite ?? this.isFavorite,
      playback: playback ?? this.playback,
    );
  }
}

// 🔥 新增：播放信息类
class PlaybackInfo {
  final String episodeTitle;
  final int position;

  PlaybackInfo({required this.episodeTitle, required this.position});

  Map<String, dynamic> toJson() {
    return {'episode_title': episodeTitle, 'position': position};
  }
}
