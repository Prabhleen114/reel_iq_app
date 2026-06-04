class ContentCalendarDay {
  final int day;
  final String title;
  final String idea;
  final String hook;
  final String caption;
  final String cta;
  final String postingTime;
  final String difficulty;

  ContentCalendarDay({
    required this.day,
    required this.title,
    required this.idea,
    required this.hook,
    required this.caption,
    required this.cta,
    required this.postingTime,
    required this.difficulty,
  });

  factory ContentCalendarDay.fromJson(Map<String, dynamic> json) {
    return ContentCalendarDay(
      day: json['day'] ?? 0,
      title: json['title'] ?? '',
      idea: json['idea'] ?? '',
      hook: json['hook'] ?? '',
      caption: json['caption'] ?? '',
      cta: json['cta'] ?? '',
      postingTime: json['posting_time'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'idea': idea,
      'hook': hook,
      'caption': caption,
      'cta': cta,
      'posting_time': postingTime,
      'difficulty': difficulty,
    };
  }
}

class ContentCalendarModel {
  final String id;
  final String niche;
  final String audience;
  final String goal;
  final String frequency;
  final DateTime createdAt;
  final List<ContentCalendarDay> days;

  ContentCalendarModel({
    required this.id,
    required this.niche,
    required this.audience,
    required this.goal,
    required this.frequency,
    required this.createdAt,
    required this.days,
  });

  factory ContentCalendarModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawDate = json['createdAt'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else {
      parsedDate = DateTime.now();
    }

    return ContentCalendarModel(
      id: docId ?? json['id'] ?? '',
      niche: json['niche'] ?? '',
      audience: json['audience'] ?? '',
      goal: json['goal'] ?? '',
      frequency: json['frequency'] ?? '',
      createdAt: parsedDate,
      days: (json['days'] as List?)
              ?.map((item) => ContentCalendarDay.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'niche': niche,
      'audience': audience,
      'goal': goal,
      'frequency': frequency,
      'createdAt': createdAt.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }
}
