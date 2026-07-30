import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GamificationOverlay extends StatefulWidget {
  final Widget child;
  final int? xpGained;
  final bool? levelUp;
  final int? newLevel;

  const GamificationOverlay({
    super.key,
    required this.child,
    this.xpGained,
    this.levelUp,
    this.newLevel,
  });

  @override
  State<GamificationOverlay> createState() => _GamificationOverlayState();
}

class _GamificationOverlayState extends State<GamificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _showAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );
  }

  @override
  void didUpdateWidget(GamificationOverlay old) {
    super.didUpdateWidget(old);
    if (widget.xpGained != null || widget.levelUp == true) {
      setState(() => _showAnimation = true);
      _controller.forward().then((_) {
        _controller.reset();
        if (mounted) setState(() => _showAnimation = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showAnimation) _buildAnimatedOverlay(),
      ],
    );
  }

  Widget _buildAnimatedOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            children: [
              // Floating XP particles
              ...List.generate(12, (i) {
                final rng = Random(i);
                final dx = 80 * cos(rng.nextDouble() * 2 * pi) * _controller.value;
                final dy = -100 * _controller.value + 50 * sin(rng.nextDouble() * 2 * pi) * _controller.value;
                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 + dx - 10,
                  top: MediaQuery.of(context).size.height / 2 + dy - 10,
                  child: Opacity(
                    opacity: (1 - _controller.value).clamp(0.0, 1.0),
                    child: Text(
                      ['+10XP', '+15XP', '+20XP', '🔥', '💪', '⭐'][i % 6],
                      style: TextStyle(
                        fontSize: 16 + rng.nextDouble() * 8,
                        color: [AppColors.primary, AppColors.accent, AppColors.accentYellow, AppColors.accentPurple][i % 4],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
              // Level-up badge or XP gained badge
              Center(
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: widget.levelUp == true
                            ? const LinearGradient(colors: [AppColors.accentYellow, AppColors.accent])
                            : const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.levelUp == true ? AppColors.accentYellow : AppColors.primary).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.levelUp == true ? Icons.emoji_events : Icons.stars,
                            color: AppColors.background,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.levelUp == true ? 'LEVEL UP!' : 'XP GAINED',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.background,
                              letterSpacing: 2,
                            ),
                          ),
                          if (widget.levelUp == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Level ${widget.newLevel ?? 0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              '+${widget.xpGained ?? 0} XP',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
