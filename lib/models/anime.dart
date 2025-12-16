class Anime {
  final String id;
  final String title;
  final String status;
  final String year;
  final String season;
  final String poster;

  Anime({
    required this.id,
    required this.title,
    required this.status,
    required this.year,
    required this.season,
    this.poster = '',
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '完结',
      year: json['year']?.toString() ?? '',
      season: json['season']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
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
    };
  }

  Anime copyWith({
    String? id,
    String? title,
    String? status,
    String? year,
    String? season,
    String? poster,
  }) {
    return Anime(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      year: year ?? this.year,
      season: season ?? this.season,
      poster: poster ?? this.poster,
    );
  }
}
