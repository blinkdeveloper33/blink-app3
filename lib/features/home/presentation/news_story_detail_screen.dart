import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

class NewsStoryDetailScreen extends StatefulWidget {
  final Map<String, String> story;
  final int index;
  final List<Map<String, String>> allStories;

  const NewsStoryDetailScreen({
    Key? key,
    required this.story,
    required this.index,
    required this.allStories,
  }) : super(key: key);

  @override
  State<NewsStoryDetailScreen> createState() => _NewsStoryDetailScreenState();
}

class _NewsStoryDetailScreenState extends State<NewsStoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Map<int, ScrollController> _scrollControllers = {};
  double _scrollProgress = 0.0;
  bool _isDarkMode = false;
  bool _isBookmarked = false;
  bool _isLiked = false;
  int _likeCount = 0;
  double _imageHeight = 300;
  late String _cachedArticleContent;
  bool _isLoading = true;
  int _currentIndex = 0;

  ScrollController _getScrollController(int index) {
    if (!_scrollControllers.containsKey(index)) {
      _scrollControllers[index] = ScrollController()
        ..addListener(() {
          if (!mounted) return;
          setState(() {
            _scrollProgress =
                (_scrollControllers[index]!.offset / 300).clamp(0.0, 1.0);
          });
        });
    }
    return _scrollControllers[index]!;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _pageController = PageController(initialPage: widget.index);
    _getScrollController(widget.index); // Initialize first controller
    _likeCount = 120 + (DateTime.now().millisecond % 50);
    _loadContent();
  }

  void _handlePageChanged(int index) async {
    await HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
      _getScrollController(index).jumpTo(0);
      _loadContent();
    });
  }

  @override
  void dispose() {
    _scrollControllers.values.forEach((controller) {
      controller.dispose();
    });
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    _cachedArticleContent = _getFullArticleContent();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getFullArticleContent() {
    // This would typically come from your backend
    return '''
# ${widget.story['title']}

${widget.story['description']}

## Key Takeaways

* Understanding the basics is crucial for financial success
* Regular monitoring and adjustments help optimize your strategy
* Professional guidance can provide valuable insights
* Long-term perspective is essential for achieving your goals

## Detailed Analysis

The financial landscape is constantly evolving, requiring investors to stay informed and adaptable. This article explores key concepts and strategies that can help you make better financial decisions.

### Market Dynamics

Market conditions play a crucial role in determining investment outcomes. Understanding these dynamics helps you:

1. Make informed decisions
2. Manage risk effectively
3. Identify opportunities
4. Maintain a balanced portfolio

### Risk Management

Effective risk management is essential for long-term success. Consider these factors:

* Portfolio diversification
* Asset allocation
* Regular rebalancing
* Emergency fund maintenance

## Expert Insights

Financial experts recommend maintaining a disciplined approach to investing. This includes:

* Regular portfolio review
* Cost management
* Tax efficiency
* Long-term perspective

## Conclusion

Success in financial management requires knowledge, discipline, and patience. By following these principles and staying informed, you can work towards achieving your financial goals.

---

*This article is for informational purposes only and should not be considered financial advice. Always consult with a qualified financial advisor before making investment decisions.*
''';
  }

  Future<void> _handleShare(Map<String, String> story) async {
    try {
      final String shareText = '${story['title']}\n\n${story['description']}';
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not share the article'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          _isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF0A0F1E) : Colors.white,
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          itemCount: widget.allStories.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final story = widget.allStories[index];
            return Stack(
              children: [
                CustomScrollView(
                  controller: _getScrollController(index),
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: _imageHeight,
                      floating: false,
                      pinned: true,
                      stretch: true,
                      backgroundColor:
                          _isDarkMode ? const Color(0xFF0A0F1E) : Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                        ],
                        background: Hero(
                          tag: 'newsImage-$index',
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                story['imageUrl']!,
                                fit: BoxFit.cover,
                                cacheWidth: 1080,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.5, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      leading: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      actions: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isBookmarked = !_isBookmarked;
                            });
                          },
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => _handleShare(story),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    if (_isLoading)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'newsTitle-$index',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        story['title']!,
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 28,
                                          fontFamily: 'Onest',
                                          fontWeight: FontWeight.bold,
                                          height: 1.3,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isDarkMode
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Financial Tips',
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white
                                                : Colors.blue[700],
                                            fontSize: 14,
                                            fontFamily: 'Onest',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '5 min read',
                                        style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white60
                                              : Colors.black54,
                                          fontSize: 14,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildActionButton(
                                          icon: _isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          label: '$_likeCount Likes',
                                          onPressed: () {
                                            setState(() {
                                              _isLiked = !_isLiked;
                                              _likeCount += _isLiked ? 1 : -1;
                                            });
                                          },
                                          color: _isLiked
                                              ? Colors.red
                                              : (_isDarkMode
                                                  ? Colors.white70
                                                  : Colors.black54),
                                        ),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: _isDarkMode
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                        _buildActionButton(
                                          icon: Icons.bookmark,
                                          label: 'Save',
                                          onPressed: () {
                                            setState(() {
                                              _isBookmarked = !_isBookmarked;
                                            });
                                          },
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                        Container(
                                          height: 24,
                                          width: 1,
                                          color: _isDarkMode
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                        _buildActionButton(
                                          icon: Icons.share,
                                          label: 'Share',
                                          onPressed: () => _handleShare(story),
                                          color: _isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: MarkdownBody(
                                data: _cachedArticleContent,
                                styleSheet: MarkdownStyleSheet(
                                  h1: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 24,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  h2: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 20,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  h3: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 18,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  p: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                    fontFamily: 'Onest',
                                    height: 1.6,
                                  ),
                                  listBullet: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                    fontFamily: 'Onest',
                                    height: 1.6,
                                  ),
                                  blockquote: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white60
                                        : Colors.black45,
                                    fontSize: 16,
                                    fontFamily: 'Onest',
                                    height: 1.6,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  code: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'Onest',
                                    backgroundColor: _isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[200],
                                  ),
                                  em: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 16,
                                    fontFamily: 'Onest',
                                    fontStyle: FontStyle.italic,
                                  ),
                                  strong: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                  ],
                ),
                // Progress indicator
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _scrollProgress,
                    child: Container(
                      height: 1,
                      color: _isDarkMode ? Colors.white30 : Colors.black12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (_scrollProgress * 100).toInt(),
                            child: Container(
                              color: _isDarkMode ? Colors.white : Colors.blue,
                            ),
                          ),
                          Expanded(
                            flex: ((1 - _scrollProgress) * 100).toInt(),
                            child: const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
