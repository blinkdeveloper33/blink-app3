import 'package:flutter/material.dart';
import 'package:blink_app/utils/temp_localizations.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/home/presentation/news_story_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoriesSection extends StatefulWidget {
  final bool isDarkMode;
  final Function(haptics.HapticsType) onHapticFeedback;
  final List<Map<String, String>> newsItems;

  const StoriesSection({
    Key? key,
    required this.isDarkMode,
    required this.onHapticFeedback,
    required this.newsItems,
  }) : super(key: key);

  @override
  State<StoriesSection> createState() => _StoriesSectionState();
}

class _StoriesSectionState extends State<StoriesSection> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.orange.shade400,
                          Colors.pink.shade400,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        localizations.stories,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      localizations.stories_subtitle,
                      style: TextStyle(
                        color:
                            widget.isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400.withOpacity(0.2),
                      Colors.orange.shade400.withOpacity(0.2),
                      Colors.pink.shade400.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.onHapticFeedback(haptics.HapticsType.light);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  FadeTransition(
                            opacity: animation,
                            child: NewsStoryDetailScreen(
                              story: widget.newsItems[0],
                              index: 0,
                              allStories: widget.newsItems,
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localizations.view_all,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.purple.shade700,
                              fontSize: 14,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.purple.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.newsItems.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 200 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: _buildEnhancedStoryCard(
                        widget.newsItems[index],
                        index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStoryCard(Map<String, String> newsItem, int index) {
    return GestureDetector(
      onTapDown: (_) => widget.onHapticFeedback(haptics.HapticsType.light),
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FadeTransition(
              opacity: animation,
              child: NewsStoryDetailScreen(
                story: newsItem,
                index: index,
                allStories: widget.newsItems,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? const Color(0xFF1A2942).withOpacity(0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'story-image-$index',
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: newsItem['imageUrl']!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: widget.isDarkMode
                              ? Colors.black12
                              : Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.blue[700]!,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: widget.isDarkMode
                              ? Colors.black12
                              : Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'story-title-$index',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          newsItem['title']!,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        newsItem['description']!,
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 12,
                          fontFamily: 'Onest',
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Financial Tips',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.blue[700],
                              fontSize: 10,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.blue[700],
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
