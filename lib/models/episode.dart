class Episode {
  final int index;
  final String title;
  final String fullTitle;
  final String token;

  Episode({
    required this.index,
    required this.title,
    required this.fullTitle,
    required this.token,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      index: json['index'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      fullTitle: json['full_title']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'title': title,
      'full_title': fullTitle,
      'token': token,
    };
  }
}
