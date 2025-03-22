import 'dart:convert';

class NewsItem {
  final String id;
  final String title;
  final String description;
  final dynamic content;
  final String imageUrl;
  final String contentType;
  final int priority;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    required this.contentType,
    required this.priority,
    required this.publishedAt,
    this.expiresAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to a map for JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'image_url': imageUrl,
      'content_type': contentType,
      'priority': priority,
      'published_at': publishedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert news to a Map to match the format used in the app
  Map<String, String> toDisplayMap() {
    String contentString = '';

    if (content is String) {
      contentString = content;
    } else if (content is Map) {
      // Extract content from blocks structure if available
      if (content['blocks'] != null && content['blocks'] is List) {
        final blocks = content['blocks'] as List;
        final paragraphs = blocks
            .where((block) =>
                block['type'] == 'paragraph' || block['text'] != null)
            .map((block) => block['text'])
            .join('\n\n');

        contentString = paragraphs;
      } else {
        contentString = jsonEncode(content);
      }
    }

    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'content': contentString,
    };
  }

  // Create a NewsItem from a JSON map
  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      content: map['content'],
      imageUrl: map['image_url'],
      contentType: map['content_type'],
      priority: map['priority'],
      publishedAt: DateTime.parse(map['published_at']),
      expiresAt:
          map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      isActive: map['is_active'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Create a news item from a JSON string
  factory NewsItem.fromJson(String source) =>
      NewsItem.fromMap(json.decode(source));
}
