import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:blink_app/config/api_config.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/features/home/domain/models/news_item.dart';

class NewsService {
  final Logger _logger = Logger();
  final AuthService _authService;

  NewsService(this._authService);

  /// Fetches news items from the server
  Future<List<NewsItem>> getNewsItems() async {
    try {
      final token = await _authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/news'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> newsData = responseData['data'];
          return newsData.map((item) => NewsItem.fromMap(item)).toList();
        } else {
          _logger.w('Failed to fetch news: ${responseData['message']}');
          return _getFallbackNewsItems();
        }
      } else {
        _logger.w('Failed to fetch news: HTTP ${response.statusCode}');
        return _getFallbackNewsItems();
      }
    } catch (e) {
      _logger.e('Error fetching news: $e');
      return _getFallbackNewsItems();
    }
  }

  /// Provides fallback news items if the API call fails
  List<NewsItem> _getFallbackNewsItems() {
    // Fallback to hardcoded news items using the same structure as the database
    return [
      NewsItem(
        id: '1',
        title:
            'The Cascading Effects of Late Debt Payments on Creditworthiness and Purchasing Power',
        description:
            'The failure to meet debt obligations punctually initiates a complex chain of financial consequences that extend far beyond immediate penalties.',
        content: {
          'blocks': [
            {
              'type': 'paragraph',
              'text':
                  'This analysis synthesizes empirical evidence from credit industry studies, legal frameworks, and economic research to elucidate how payment delays degrade credit standing, erode purchasing capacity, and alter long-term financial trajectories.'
            }
          ]
        },
        imageUrl:
            'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/news_images/pexels-shvets-production-7544453.jpg?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJuZXdzX2ltYWdlcy9wZXhlbHMtc2h2ZXRzLXByb2R1Y3Rpb24tNzU0NDQ1My5qcGciLCJpYXQiOjE3NDI0MDM3NTQsImV4cCI6MjA1Nzc2Mzc1NH0.8ZrGfbG15vrdBKK5qVl45XJXQYITc7Jq2d1jx6zJ6M8',
        contentType: 'article',
        priority: 10,
        publishedAt: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewsItem(
        id: '2',
        title: 'Roth IRA vs. 401(k): What\'s the Difference?',
        description:
            'Both Roth IRAs and 401(k)s are popular tax-advantaged retirement savings accounts that allow your savings to grow tax-free.',
        content: {
          'blocks': [
            {
              'type': 'paragraph',
              'text':
                  'Understanding the differences can help you choose the best option for your financial goals.'
            }
          ]
        },
        imageUrl:
            'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/news_images/roth_ira_vs_401k.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJuZXdzX2ltYWdlcy9yb3RoX2lyYV92c180MDFrLnBuZyIsImlhdCI6MTc0MjQwMzc1NCwiZXhwIjoyMDU3NzYzNzU0fQ.LqEOZjNMvnrdBKK5qVl45XJXQYITc7Jq2d1jx6zJ6M8',
        contentType: 'article',
        priority: 8,
        publishedAt: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewsItem(
        id: '3',
        title: 'The Basics of Budgeting: A Step-by-Step Guide',
        description:
            'Creating and sticking to a budget is a fundamental step in managing your finances.',
        content: {
          'blocks': [
            {
              'type': 'paragraph',
              'text':
                  'This guide walks you through the process of setting up a budget that works for your lifestyle and financial goals.'
            }
          ]
        },
        imageUrl:
            'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/news_images/budgeting_basics.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJuZXdzX2ltYWdlcy9idWRnZXRpbmdfYmFzaWNzLnBuZyIsImlhdCI6MTc0MjQwMzc1NCwiZXhwIjoyMDU3NzYzNzU0fQ.MG0VY0Pz9okTlZ32dikjuxCO8r8X1R59KBBkSS7EhNQ',
        contentType: 'article',
        priority: 6,
        publishedAt: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewsItem(
        id: '4',
        title: 'Understanding Credit Scores: What You Need to Know',
        description:
            'Your credit score plays a crucial role in your financial life.',
        content: {
          'blocks': [
            {
              'type': 'paragraph',
              'text':
                  'Learn what factors influence your credit score, how to check it, and steps you can take to improve it over time.'
            }
          ]
        },
        imageUrl:
            'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/news_images/credit_scores.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJuZXdzX2ltYWdlcy9jcmVkaXRfc2NvcmVzLnBuZyIsImlhdCI6MTc0MjQwMzc1NCwiZXhwIjoyMDU3NzYzNzU0fQ.Qk4Aw9JqrZ32dikjuxCO8r8X1R59KBBkSS7EhNQ',
        contentType: 'article',
        priority: 5,
        publishedAt: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NewsItem(
        id: '5',
        title: 'Investing for Beginners: Getting Started in the Stock Market',
        description: 'Thinking about investing in stocks?',
        content: {
          'blocks': [
            {
              'type': 'paragraph',
              'text':
                  'This article covers the basics of stock market investing, including how to open a brokerage account, understanding stock types, and strategies for beginners.'
            }
          ]
        },
        imageUrl:
            'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/news_images/investing_beginners.png?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1cmwiOiJuZXdzX2ltYWdlcy9pbnZlc3RpbmdfYmVnaW5uZXJzLnBuZyIsImlhdCI6MTc0MjQwMzc1NCwiZXhwIjoyMDU3NzYzNzU0fQ.PxGbL2mrvrdBKK5qVl45XJXQYITc7Jq2d1jx6zJ6M8',
        contentType: 'article',
        priority: 4,
        publishedAt: DateTime.now(),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
