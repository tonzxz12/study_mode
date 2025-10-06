import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/styles.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _currentSeconds = 1500; // 25 minutes default
  int _initialSeconds = 1500;
  bool _isRunning = false;
  bool _isStudyTime = true;
  int _completedPomodoros = 0;
  
  final int _studyDuration = 25 * 60; // 25 minutes
  final int _shortBreakDuration = 5 * 60; // 5 minutes
  final int _longBreakDuration = 15 * 60; // 15 minutes

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _currentSeconds = _initialSeconds;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _timer = null;
    
    setState(() {
      _isRunning = false;
      if (_isStudyTime) {
        _completedPomodoros++;
        // Switch to break
        _isStudyTime = false;
        _currentSeconds = _completedPomodoros % 4 == 0 
            ? _longBreakDuration 
            : _shortBreakDuration;
        _initialSeconds = _currentSeconds;
      } else {
        // Switch to study
        _isStudyTime = true;
        _currentSeconds = _studyDuration;
        _initialSeconds = _studyDuration;
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = _initialSeconds > 0 ? (_initialSeconds - _currentSeconds) / _initialSeconds : 0;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isStudyTime 
                  ? AppStyles.primary.withOpacity(0.08)
                  : AppStyles.warning.withOpacity(0.08),
              AppStyles.background,
              _isStudyTime 
                  ? AppStyles.primary.withOpacity(0.02)
                  : AppStyles.warning.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Timer Content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL + 60, // Add top padding for back button
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL
                ),
                child: Column(
                  children: [
                    // Enhanced Progress Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            _completedPomodoros.toString(),
                            'Sessions',
                            Icons.check_circle_rounded,
                            AppStyles.success,
                          ),
                        ),
                        const SizedBox(width: AppStyles.spaceMD),
                        Expanded(
                          child: _buildStatCard(
                            'Current',
                            _isStudyTime ? '${_studyDuration ~/ 60}min' : '${_initialSeconds ~/ 60}min',
                            'Duration',
                            Icons.timer_rounded,
                            _isStudyTime ? AppStyles.primary : AppStyles.warning,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXXL * 2),
                    
                    // Enhanced Timer Circle
                    Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppStyles.card,
                            AppStyles.card.withOpacity(0.7),
                          ],
                        ),
                        border: Border.all(
                          color: AppStyles.border.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: AppStyles.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Enhanced Progress Ring
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: AppStyles.muted.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isStudyTime ? AppStyles.primary : AppStyles.warning,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          // Enhanced Time Display
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_currentSeconds),
                                style: AppStyles.screenTitle.copyWith(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: -3,
                                  color: AppStyles.foreground,
                                ),
                              ),
                              const SizedBox(height: AppStyles.spaceMD),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppStyles.spaceLG,
                                  vertical: AppStyles.spaceSM,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.15),
                                      (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isStudyTime ? Icons.psychology_rounded : Icons.coffee_rounded,
                                      color: _isStudyTime ? AppStyles.primary : AppStyles.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      _isStudyTime ? 'Focus Mode' : 'Break Mode',
                                      style: AppStyles.bodyMedium.copyWith(
                                        color: _isStudyTime ? AppStyles.primary : AppStyles.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXXL * 2),
                    
                    // Enhanced Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reset button
                        _buildControlButton(
                          onPressed: _resetTimer,
                          icon: Icons.refresh_rounded,
                          backgroundColor: AppStyles.card,
                          foregroundColor: AppStyles.mutedForeground,
                          borderColor: AppStyles.border,
                        ),
                        
                        const SizedBox(width: AppStyles.spaceXL),
                        
                        // Play/Pause button
                        _buildControlButton(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          backgroundColor: _isStudyTime ? AppStyles.primary : AppStyles.warning,
                          foregroundColor: Colors.white,
                          isLarge: true,
                        ),
                        
                        const SizedBox(width: AppStyles.spaceXL),
                        
                        // Skip button
                        _buildControlButton(
                          onPressed: _onTimerComplete,
                          icon: Icons.skip_next_rounded,
                          backgroundColor: AppStyles.card,
                          foregroundColor: AppStyles.mutedForeground,
                          borderColor: AppStyles.border,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppStyles.spaceXXL),
                  ],
                ),
              ),
              
              // Floating Back Button
              Positioned(
                top: AppStyles.spaceLG,
                left: AppStyles.spaceXL,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppStyles.card.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    border: Border.all(
                      color: AppStyles.border.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: AppStyles.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: AppStyles.foreground,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.card,
            AppStyles.card.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusLG),
        border: Border.all(
          color: AppStyles.border.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppStyles.mutedForeground,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Text(
            value,
            style: AppStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.0,
              fontSize: 26,
              color: AppStyles.foreground,
            ),
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    bool isLarge = false,
  }) {
    return Container(
      width: isLarge ? 88 : 72,
      height: isLarge ? 88 : 72,
      decoration: BoxDecoration(
        gradient: isLarge ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
        ) : null,
        color: isLarge ? null : backgroundColor,
        borderRadius: BorderRadius.circular(isLarge ? 44 : 36),
        border: borderColor != null ? Border.all(
          color: borderColor,
          width: 1.5,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(isLarge ? 0.15 : 0.1),
            blurRadius: isLarge ? 20 : 12,
            offset: Offset(0, isLarge ? 8 : 4),
          ),
          if (isLarge) BoxShadow(
            color: backgroundColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isLarge ? 44 : 36),
          child: Center(
            child: Icon(
              icon,
              color: foregroundColor,
              size: isLarge ? 40 : 32,
            ),
          ),
        ),
      ),
    );
  }
}