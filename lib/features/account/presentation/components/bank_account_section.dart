import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/utils/temp_localizations.dart';

// Define a custom AnimatedEmojiData for the locked emoji if not already defined elsewhere
final lockedEmoji = AnimatedEmojiData('1f512', name: 'locked');

class BankAccount {
  final String bankAccountId;
  final String accountName;
  final String accountType;
  final String accountSubtype;
  final String accountMask;
  final double availableBalance;
  final double currentBalance;
  final String currency;
  final DateTime createdAt;
  final String cursor;

  BankAccount({
    required this.bankAccountId,
    required this.accountName,
    required this.accountType,
    required this.accountSubtype,
    required this.accountMask,
    required this.availableBalance,
    required this.currentBalance,
    required this.currency,
    required this.createdAt,
    required this.cursor,
  });
}

class BankAccountSection extends StatelessWidget {
  final List<BankAccount>? bankAccounts;
  final bool isLoading;
  final VoidCallback? onConnectBankAccount;

  const BankAccountSection({
    Key? key,
    this.bankAccounts,
    this.isLoading = false,
    this.onConnectBankAccount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    if (isLoading) {
      return _buildLoadingState(context, isDarkMode);
    }

    final bankAccount = bankAccounts?.firstOrNull;

    if (bankAccount == null) {
      return _buildNoBankAccountState(context, isDarkMode, localizations);
    }

    return _buildBankAccountDetails(
        context, isDarkMode, localizations, bankAccount);
  }

  Widget _buildLoadingState(BuildContext context, bool isDarkMode) {
    // Get screen size to check for small devices
    final isSmallDevice = MediaQuery.of(context).size.height < 700;

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isSmallDevice ? 16 : 24,
            vertical: isSmallDevice ? 12 : 16),
        padding: EdgeInsets.all(isSmallDevice ? 20 : 24),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.white12 : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.white24 : Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2979FF).withOpacity(0.2)
                          : const Color(0xFF2979FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedEmoji(
                      lockedEmoji,
                      size: 40,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 16,
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 36,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 14,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBankAccountState(
      BuildContext context, bool isDarkMode, AppLocalizations localizations) {
    // Get screen size to check for small devices
    final isSmallDevice = MediaQuery.of(context).size.height < 700;

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isSmallDevice ? 16 : 24,
            vertical: isSmallDevice ? 12 : 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallDevice ? 20 : 24),
              child: Row(
                children: [
                  Container(
                    width: isSmallDevice ? 48 : 52,
                    height: isSmallDevice ? 48 : 52,
                    padding: EdgeInsets.all(isSmallDevice ? 5 : 6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2979FF).withOpacity(0.2)
                          : const Color(0xFF2979FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedEmoji(
                      lockedEmoji,
                      size: isSmallDevice ? 36 : 40,
                      repeat: true,
                    ),
                  ),
                  SizedBox(width: isSmallDevice ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.bankAccount,
                          style: TextStyle(
                            fontSize: isSmallDevice ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallDevice ? 3 : 4),
                        Text(
                          localizations.connectToGetStarted,
                          style: TextStyle(
                            fontSize: isSmallDevice ? 13 : 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFE0E0E0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.accountConnectionRequired,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF424242),
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.accountConnectionMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode ? Colors.white60 : const Color(0xFF757575),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    haptics.Haptics.vibrate(haptics.HapticsType.light);
                    if (onConnectBankAccount != null) {
                      onConnectBankAccount!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.connectBankAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountDetails(BuildContext context, bool isDarkMode,
      AppLocalizations localizations, BankAccount bankAccount) {
    // Get screen size to check for small devices
    final isSmallDevice = MediaQuery.of(context).size.height < 700;

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isSmallDevice ? 16 : 24,
            vertical: isSmallDevice ? 12 : 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isSmallDevice ? 20 : 24),
              child: Row(
                children: [
                  Container(
                    width: isSmallDevice ? 48 : 52,
                    height: isSmallDevice ? 48 : 52,
                    padding: EdgeInsets.all(isSmallDevice ? 5 : 6),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF2979FF).withOpacity(0.2)
                          : const Color(0xFF2979FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedEmoji(
                      lockedEmoji,
                      size: isSmallDevice ? 36 : 40,
                      repeat: true,
                    ),
                  ),
                  SizedBox(width: isSmallDevice ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankAccount.accountName,
                          style: TextStyle(
                            fontSize: isSmallDevice ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallDevice ? 3 : 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallDevice ? 6 : 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFEEF2F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                bankAccount.accountType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: isSmallDevice ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF546E7A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallDevice ? 6 : 8),
                            Text(
                              '**** ${bankAccount.accountMask}',
                              style: TextStyle(
                                fontSize: isSmallDevice ? 12 : 13,
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(isSmallDevice ? 20 : 24),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.availableBalance,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          isDarkMode ? Colors.white60 : const Color(0xFF78909C),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    '\$${bankAccount.availableBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? Colors.white
                                      : const Color(0xFF1E2832),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '.${bankAccount.availableBalance.toStringAsFixed(2).split('.')[1]}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF78909C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE0E0E0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: isDarkMode
                              ? Colors.white60
                              : const Color(0xFF546E7A),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            localizations.connectedOn(DateFormat('MMM d, yyyy')
                                .format(bankAccount.createdAt)),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode
                                  ? Colors.white60
                                  : const Color(0xFF546E7A),
                              letterSpacing: 0.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
