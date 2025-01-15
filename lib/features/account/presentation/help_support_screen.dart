import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final List<bool> _expandedStates = List.generate(5, (_) => false);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@blink.com',
      queryParameters: {
        'subject': 'Support Request',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Widget _buildSupportCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () {
          haptics.Haptics.vibrate(haptics.HapticsType.light);
          onTap();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDarkMode ? Colors.white : const Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required int index,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isExpanded = _expandedStates[index];

    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? (isDarkMode
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF2196F3).withOpacity(0.3))
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: isExpanded
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: isExpanded ? 0.25 : 0,
              child: Icon(
                Icons.arrow_forward_ios,
                color: isDarkMode ? Colors.white38 : Colors.black38,
                size: 16,
              ),
            ),
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedStates[index] = expanded;
              });
              haptics.Haptics.vibrate(haptics.HapticsType.light);
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
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
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF5F5F5),
        elevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
              child: Text(
                'How can we help you?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            _buildSupportCard(
              title: 'Contact Support',
              description: 'Get in touch with our support team',
              icon: Icons.support_agent,
              onTap: _launchEmail,
            ),
            _buildSupportCard(
              title: 'Documentation',
              description: 'Browse our help documentation',
              icon: Icons.description,
              onTap: () {
                // TODO: Implement documentation navigation
              },
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
              child: Text(
                'Frequently Asked Questions',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            _buildFAQItem(
              question: 'How do I link my bank account?',
              answer:
                  'To link your bank account, go to the Account screen and tap on "Link Bank Account". Follow the prompts to securely connect your bank using our trusted partner, Plaid.',
              index: 0,
            ),
            _buildFAQItem(
              question: 'Is my data secure?',
              answer:
                  'Yes, we take security seriously. All your data is encrypted using industry-standard protocols, and we never store sensitive banking credentials on our servers.',
              index: 1,
            ),
            _buildFAQItem(
              question: 'How do I change my password?',
              answer:
                  'You can change your password by going to the Security screen in your Account settings. You\'ll need to enter your current password and choose a new one.',
              index: 2,
            ),
            _buildFAQItem(
              question: 'What should I do if I forget my password?',
              answer:
                  'If you forget your password, tap on "Forgot Password" on the login screen. We\'ll send you a link to reset your password to your registered email address.',
              index: 3,
            ),
            _buildFAQItem(
              question: 'How do I enable two-factor authentication?',
              answer:
                  'Two-factor authentication can be enabled in the Security screen. Once enabled, you\'ll need to enter a verification code sent to your phone in addition to your password when logging in.',
              index: 4,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
