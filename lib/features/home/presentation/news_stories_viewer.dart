import 'package:flutter/material.dart';

class NewsStoriesViewer extends StatefulWidget {
  final List<Map<String, String>> newsItems;
  final int initialIndex;

  const NewsStoriesViewer({
    super.key,
    required this.newsItems,
    required this.initialIndex,
  });

  @override
  State<NewsStoriesViewer> createState() => _NewsStoriesViewerState();
}

class _NewsStoriesViewerState extends State<NewsStoriesViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.newsItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            if (_currentIndex > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _progressController.reset();
                  _progressController.forward();
                });
              },
              itemCount: widget.newsItems.length,
              itemBuilder: (context, index) {
                return _StoryPage(newsItem: widget.newsItems[index]);
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: List.generate(
                    widget.newsItems.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: LinearProgressIndicator(
                          value: index == _currentIndex
                              ? _progressController.value
                              : index < _currentIndex
                                  ? 1.0
                                  : 0.0,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final Map<String, String> newsItem;

  const _StoryPage({required this.newsItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            newsItem['imageUrl']!,
            fit: BoxFit.cover,
            height: 300,
          ),
          const SizedBox(height: 20),
          Text(
            newsItem['title']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            newsItem['description']!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
