import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/shimmer_loading.dart';
import '../services/notification_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final AuthService _authService = AuthService();
  List<dynamic>? _allMessages;
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;

  final int _pageSize = 10;
  int _currentLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _authService.fetchMyMessages();
      if (mounted) {
        setState(() {
          _allMessages = msgs ?? [];
          _currentLimit = _pageSize;
          _messages = _allMessages!.take(_currentLimit).toList();
          _isLoading = false;
        });
        if (msgs != null && msgs.isNotEmpty) {
          NotificationService().markMessagesAsSeen(msgs);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages.';
          _isLoading = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_allMessages == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentLimit = (_currentLimit + _pageSize).clamp(0, _allMessages!.length);
      _messages = _allMessages!.take(_currentLimit).toList();
    });
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    // Basic regex to strip HTML tags, same as old APK stripHtml() concept
    final stripped = htmlString.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    return stripped.trim().replaceAll(RegExp(r'\s{2,}'), ' '); // reduce multiple spaces
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDashboard,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.bgDashboard,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(10, 10),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 16,
                            offset: Offset(-10, -10),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'My Messages',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
          ? const _MessagesSkeleton()
          : _error != null
              ? Center(child: Text(_error!))
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages found.',
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length + (_currentLimit < (_allMessages?.length ?? 0) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          final hasMore = _currentLimit < (_allMessages?.length ?? 0);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: Center(
                              child: hasMore
                                  ? _NeumorphicLoadMoreButton(onTap: _loadMore)
                                  : const Text(
                                      '— No more messages —',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Text',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textTertiary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          );
                        }

                        return _MessageCard(
                          message: _messages[index],
                          stripHtml: _stripHtml,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final String Function(String) stripHtml;

  const _MessageCard({required this.message, required this.stripHtml});

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.message['Subject'] ?? 'No Subject';
    final date = widget.message['Date'] ?? '';
    final rawDetail = widget.message['Detail'] ?? widget.message['Body'] ?? '';
    final shortDesc = widget.stripHtml(rawDetail);

    // Limit short desc to 100 chars
    final previewText = shortDesc.length > 100
        ? '${shortDesc.substring(0, 100)}...'
        : shortDesc;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(14, 14),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 30,
              offset: Offset(-14, -14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontFamily: 'SF Pro Text',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                previewText,
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
              secondChild: Text(
                shortDesc, // Full stripped text
                style: const TextStyle(
                  fontFamily: 'SF Pro Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Neumorphic Load More Button ───────────────────────────────────────────────
class _NeumorphicLoadMoreButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NeumorphicLoadMoreButton({required this.onTap});

  @override
  State<_NeumorphicLoadMoreButton> createState() => _NeumorphicLoadMoreButtonState();
}

class _NeumorphicLoadMoreButtonState extends State<_NeumorphicLoadMoreButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgDashboard,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(10, 10),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 28,
                    offset: const Offset(10, 10),
                  ),
                  const BoxShadow(
                    color: Colors.white,
                    blurRadius: 28,
                    offset: Offset(-10, -10),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.primaryBlue.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            const Text(
              'Load More',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgDashboard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-5, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShimmerLoading(width: 150, height: 18, borderRadius: 4), // Subject
                  const Spacer(),
                  const ShimmerLoading(width: 60, height: 12, borderRadius: 4), // Date
                ],
              ),
              const SizedBox(height: 12),
              const ShimmerLoading(width: double.infinity, height: 14, borderRadius: 4), // Body 1
              const SizedBox(height: 6),
              const ShimmerLoading(width: 200, height: 14, borderRadius: 4), // Body 2
            ],
          ),
        ),
      ),
    );
  }
}
