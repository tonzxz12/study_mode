// This file was corrupted and has been removed.
// Use timer_screen.dart instead.

  void dispose() {  void dispose() {

    _timer?.cancel();    _timer?.cancel();

    super.dispose();    super.dispose();

  }  }



  void _startTimer() {  void _startTimer() {

    if (_timer != null) return;    if (_timer != null) return;

        

    setState(() => _isRunning = true);    setState(() => _isRunning = true);

        

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {

      setState(() {      setState(() {

        if (_currentSeconds > 0) {        if (_currentSeconds > 0) {

          _currentSeconds--;          _currentSeconds--;

        } else {        } else {

          _onTimerComplete();          _onTimerComplete();

        }        }

      });      });

    });    });

  }  }



  void _pauseTimer() {  void _pauseTimer() {

    _timer?.cancel();    _timer?.cancel();

    _timer = null;    _timer = null;

    setState(() => _isRunning = false);    setState(() => _isRunning = false);

  }  }



  void _resetTimer() {  void _resetTimer() {

    _timer?.cancel();    _timer?.cancel();

    _timer = null;    _timer = null;

    setState(() {    setState(() {

      _isRunning = false;      _isRunning = false;

      _currentSeconds = _initialSeconds;      _currentSeconds = _initialSeconds;

    });    });

  }  }



  void _onTimerComplete() {  void _onTimerComplete() {

    _timer?.cancel();    _timer?.cancel();

    _timer = null;    _timer = null;

        

    setState(() {    setState(() {

      _isRunning = false;      _isRunning = false;

      if (_isStudyTime) {      if (_isStudyTime) {

        _completedPomodoros++;        _completedPomodoros++;

        // Switch to break        // Switch to break

        _isStudyTime = false;        _isStudyTime = false;

        _currentSeconds = _completedPomodoros % 4 == 0         _currentSeconds = _completedPomodoros % 4 == 0 

            ? _longBreakDuration             ? _longBreakDuration 

            : _shortBreakDuration;            : _shortBreakDuration;

        _initialSeconds = _currentSeconds;        _initialSeconds = _currentSeconds;

      } else {      } else {

        // Switch to study        // Switch to study

        _isStudyTime = true;        _isStudyTime = true;

        _currentSeconds = _studyDuration;        _currentSeconds = _studyDuration;

        _initialSeconds = _studyDuration;        _initialSeconds = _studyDuration;

      }      }

    });    });

  }  }



  String _formatTime(int seconds) {  String _formatTime(int seconds) {

    int minutes = seconds ~/ 60;    int minutes = seconds ~/ 60;

    int remainingSeconds = seconds % 60;    int remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';

  }  }



  @override  @override

  Widget build(BuildContext context) {  Widget build(BuildContext context) {

    double progress = _initialSeconds > 0 ? (_initialSeconds - _currentSeconds) / _initialSeconds : 0;    double progress = _initialSeconds > 0 ? (_initialSeconds - _currentSeconds) / _initialSeconds : 0;

        

    return Scaffold(    return Container(

      backgroundColor: Colors.transparent,      decoration: BoxDecoration(

      body: Container(        gradient: LinearGradient(

        decoration: BoxDecoration(          begin: Alignment.topCenter,

          gradient: LinearGradient(          end: Alignment.bottomCenter,

            begin: Alignment.topLeft,          colors: [

            end: Alignment.bottomRight,            _isStudyTime 

            colors: [                ? AppStyles.primary.withOpacity(0.05)

              _isStudyTime                 : AppStyles.warning.withOpacity(0.05),

                  ? AppStyles.primary.withOpacity(0.08)            AppStyles.background,

                  : AppStyles.warning.withOpacity(0.08),          ],

              AppStyles.background,        ),

              _isStudyTime       ),

                  ? AppStyles.primary.withOpacity(0.02)      child: SafeArea(

                  : AppStyles.warning.withOpacity(0.02),        bottom: false,

            ],        child: Column(

          ),          children: [

        ),            // Modern Header - Shadcn Style

        child: SafeArea(            Container(

          bottom: false,              padding: const EdgeInsets.fromLTRB(

          child: Column(                AppStyles.spaceXL, 

            children: [                AppStyles.spaceLG, 

              // Enhanced Modern Header                AppStyles.spaceXL, 

              Container(                AppStyles.spaceLG

                padding: const EdgeInsets.fromLTRB(              ),

                  AppStyles.spaceXL,               decoration: BoxDecoration(

                  AppStyles.spaceLG,                 color: AppStyles.card,

                  AppStyles.spaceXL,                 border: Border(

                  AppStyles.spaceLG                  bottom: BorderSide(

                ),                    color: AppStyles.border,

                decoration: BoxDecoration(                    width: 1,

                  color: AppStyles.card.withOpacity(0.95),                  ),

                  border: Border(                ),

                    bottom: BorderSide(              ),

                      color: AppStyles.border.withOpacity(0.6),              child: Row(

                      width: 1,                children: [

                    ),                  // Back Button

                  ),                  Container(

                  boxShadow: [                    decoration: BoxDecoration(

                    BoxShadow(                      color: AppStyles.card,

                      color: AppStyles.black.withOpacity(0.06),                      borderRadius: BorderRadius.circular(AppStyles.radiusSM),

                      blurRadius: 12,                      border: Border.all(

                      offset: const Offset(0, 2),                        color: AppStyles.border,

                    ),                        width: 1,

                    BoxShadow(                      ),

                      color: AppStyles.black.withOpacity(0.02),                    ),

                      blurRadius: 4,                    child: IconButton(

                      offset: const Offset(0, 1),                      onPressed: () => Navigator.pop(context),

                    ),                      icon: Icon(

                  ],                        Icons.arrow_back_rounded,

                ),                        color: AppStyles.mutedForeground,

                child: Row(                        size: 18,

                  children: [                      ),

                    // Back Button                      constraints: const BoxConstraints(

                    Container(                        minWidth: 40,

                      decoration: BoxDecoration(                        minHeight: 40,

                        color: AppStyles.background,                      ),

                        borderRadius: BorderRadius.circular(AppStyles.radiusSM),                    ),

                        border: Border.all(                  ),

                          color: AppStyles.border,                  const SizedBox(width: AppStyles.spaceMD),

                          width: 1,                  Column(

                        ),                    crossAxisAlignment: CrossAxisAlignment.start,

                        boxShadow: [                    children: [

                          BoxShadow(                      Text(

                            color: AppStyles.black.withOpacity(0.02),                        _isStudyTime ? 'Focus Session' : 'Break Time',

                            blurRadius: 2,                        style: AppStyles.sectionHeader.copyWith(

                            offset: const Offset(0, 1),                          fontWeight: FontWeight.w600,

                          ),                        ),

                        ],                      ),

                      ),                      Text(

                      child: IconButton(                        'Pomodoro ${_completedPomodoros + 1}',

                        onPressed: () => Navigator.pop(context),                        style: AppStyles.bodySmall.copyWith(

                        icon: Icon(                          color: AppStyles.mutedForeground,

                          Icons.arrow_back_rounded,                        ),

                          color: AppStyles.foreground,                      ),

                          size: 18,                    ],

                        ),                  ),

                        constraints: const BoxConstraints(                  const Spacer(),

                          minWidth: 40,                  Container(

                          minHeight: 40,                    padding: const EdgeInsets.symmetric(

                        ),                      horizontal: AppStyles.spaceSM, 

                      ),                      vertical: AppStyles.spaceXS

                    ),                    ),

                    const SizedBox(width: AppStyles.spaceLG),                    decoration: BoxDecoration(

                    // Enhanced Logo/Icon                      color: _isStudyTime 

                    Container(                          ? AppStyles.primary.withOpacity(0.1) 

                      width: 44,                          : AppStyles.warning.withOpacity(0.1),

                      height: 44,                      borderRadius: BorderRadius.circular(AppStyles.radiusSM),

                      decoration: BoxDecoration(                      border: Border.all(

                        gradient: LinearGradient(                        color: _isStudyTime 

                          begin: Alignment.topLeft,                            ? AppStyles.primary.withOpacity(0.2)

                          end: Alignment.bottomRight,                            : AppStyles.warning.withOpacity(0.2),

                          colors: [                        width: 1,

                            _isStudyTime                       ),

                                ? AppStyles.primary.withOpacity(0.15)                    ),

                                : AppStyles.warning.withOpacity(0.15),                    child: Row(

                            _isStudyTime                       mainAxisSize: MainAxisSize.min,

                                ? AppStyles.primary.withOpacity(0.05)                      children: [

                                : AppStyles.warning.withOpacity(0.05),                        Icon(

                          ],                          _isStudyTime ? Icons.psychology_rounded : Icons.coffee_rounded,

                        ),                          size: 14,

                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),                          color: _isStudyTime ? AppStyles.primary : AppStyles.warning,

                        border: Border.all(                        ),

                          color: _isStudyTime                         const SizedBox(width: AppStyles.spaceXS),

                              ? AppStyles.primary.withOpacity(0.3)                        Text(

                              : AppStyles.warning.withOpacity(0.3),                          _isStudyTime ? 'Focus' : 'Break',

                          width: 1.5,                          style: AppStyles.bodySmall.copyWith(

                        ),                            fontWeight: FontWeight.w500,

                        boxShadow: [                            color: _isStudyTime ? AppStyles.primary : AppStyles.warning,

                          BoxShadow(                          ),

                            color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.1),                        ),

                            blurRadius: 8,                      ],

                            offset: const Offset(0, 2),                    ),

                          ),                  ),

                        ],                ],

                      ),              ),

                      child: Icon(            ),

                        _isStudyTime ? Icons.psychology_rounded : Icons.coffee_rounded,

                        color: _isStudyTime ? AppStyles.primary : AppStyles.warning,            // Timer Content

                        size: 22,            Expanded(

                      ),              child: SingleChildScrollView(

                    ),                padding: const EdgeInsets.all(AppStyles.spaceXL),

                    const SizedBox(width: AppStyles.spaceMD),                child: Column(

                    // Title Section                  children: [

                    Expanded(                    const SizedBox(height: AppStyles.spaceXL),

                      child: Column(                    

                        crossAxisAlignment: CrossAxisAlignment.start,                    // Progress Stats

                        children: [                    Row(

                          Text(                      children: [

                            _isStudyTime ? 'Focus Session' : 'Break Time',                        Expanded(

                            style: AppStyles.sectionHeader.copyWith(                          child: _buildStatCard(

                              fontWeight: FontWeight.w600,                            'Completed',

                              fontSize: 18,                            _completedPomodoros.toString(),

                            ),                            'Pomodoros',

                          ),                            Icons.check_circle_rounded,

                          Text(                          ),

                            'Pomodoro ${_completedPomodoros + 1} • ${_formatTime(_initialSeconds)} session',                        ),

                            style: AppStyles.bodySmall.copyWith(                        const SizedBox(width: AppStyles.spaceSM),

                              color: AppStyles.mutedForeground,                        Expanded(

                            ),                          child: _buildStatCard(

                          ),                            'Session',

                        ],                            _isStudyTime ? '${_studyDuration ~/ 60}m' : '${_initialSeconds ~/ 60}m',

                      ),                            'Duration',

                    ),                            Icons.schedule_rounded,

                    // Status Badge                          ),

                    Container(                        ),

                      padding: const EdgeInsets.symmetric(                      ],

                        horizontal: AppStyles.spaceSM,                     ),

                        vertical: AppStyles.spaceXS                    

                      ),                    const SizedBox(height: AppStyles.spaceXXL),

                      decoration: BoxDecoration(                    

                        color: _isRunning                     // Timer Circle - Shadcn Style

                            ? AppStyles.success.withOpacity(0.1)                    Container(

                            : AppStyles.muted.withOpacity(0.5),                      width: 280,

                        borderRadius: BorderRadius.circular(20),                      height: 280,

                        border: Border.all(                      decoration: BoxDecoration(

                          color: _isRunning                         shape: BoxShape.circle,

                              ? AppStyles.success.withOpacity(0.2)                        color: AppStyles.card,

                              : AppStyles.border,                        border: Border.all(

                          width: 1,                          color: AppStyles.border,

                        ),                          width: 1,

                      ),                        ),

                      child: Row(                        boxShadow: [

                        mainAxisSize: MainAxisSize.min,                          BoxShadow(

                        children: [                            color: AppStyles.black.withOpacity(0.05),

                          Container(                            blurRadius: 20,

                            width: 6,                            offset: const Offset(0, 8),

                            height: 6,                          ),

                            decoration: BoxDecoration(                        ],

                              color: _isRunning ? AppStyles.success : AppStyles.mutedForeground,                      ),

                              shape: BoxShape.circle,                      child: Stack(

                            ),                        alignment: Alignment.center,

                          ),                        children: [

                          const SizedBox(width: AppStyles.spaceXS),                          // Progress Ring

                          Text(                          SizedBox(

                            _isRunning ? 'Active' : 'Paused',                            width: 240,

                            style: AppStyles.bodySmall.copyWith(                            height: 240,

                              fontWeight: FontWeight.w500,                            child: CircularProgressIndicator(

                              color: _isRunning ? AppStyles.success : AppStyles.mutedForeground,                              value: progress,

                            ),                              strokeWidth: 6,

                          ),                              backgroundColor: AppStyles.muted,

                        ],                              valueColor: AlwaysStoppedAnimation<Color>(

                      ),                                _isStudyTime ? AppStyles.primary : AppStyles.warning,

                    ),                              ),

                  ],                            ),

                ),                          ),

              ),                          // Time Display

                          Column(

              // Timer Content                            mainAxisAlignment: MainAxisAlignment.center,

              Expanded(                            children: [

                child: SingleChildScrollView(                              Text(

                  padding: const EdgeInsets.all(AppStyles.spaceXL),                                _formatTime(_currentSeconds),

                  child: Column(                                style: AppStyles.screenTitle.copyWith(

                    children: [                                  fontSize: 48,

                      const SizedBox(height: AppStyles.spaceXL),                                  fontWeight: FontWeight.w700,

                                                        height: 1.0,

                      // Progress Stats                                ),

                      Row(                              ),

                        children: [                              const SizedBox(height: AppStyles.spaceXS),

                          Expanded(                              Text(

                            child: _buildStatCard(                                _isStudyTime ? 'Focus Time' : 'Break Time',

                              'Completed',                                style: AppStyles.bodyMedium.copyWith(

                              _completedPomodoros.toString(),                                  color: AppStyles.mutedForeground,

                              'Pomodoros',                                  fontWeight: FontWeight.w500,

                              Icons.check_circle_rounded,                                ),

                            ),                              ),

                          ),                            ],

                          const SizedBox(width: AppStyles.spaceSM),                          ),

                          Expanded(                        ],

                            child: _buildStatCard(                      ),

                              'Session',                    ),

                              _isStudyTime ? '${_studyDuration ~/ 60}m' : '${_initialSeconds ~/ 60}m',                    

                              'Duration',                    const SizedBox(height: AppStyles.spaceXXL),

                              Icons.schedule_rounded,                    

                            ),                    // Control Buttons - Shadcn Style

                          ),                    Row(

                        ],                      mainAxisAlignment: MainAxisAlignment.center,

                      ),                      children: [

                                              // Reset button

                      const SizedBox(height: AppStyles.spaceXXL),                        _buildControlButton(

                                                onPressed: _resetTimer,

                      // Enhanced Timer Circle                          icon: Icons.refresh_rounded,

                      Container(                          backgroundColor: AppStyles.card,

                        width: 320,                          foregroundColor: AppStyles.mutedForeground,

                        height: 320,                          borderColor: AppStyles.border,

                        decoration: BoxDecoration(                        ),

                          shape: BoxShape.circle,                        

                          gradient: LinearGradient(                        const SizedBox(width: AppStyles.spaceLG),

                            begin: Alignment.topLeft,                        

                            end: Alignment.bottomRight,                        // Play/Pause button

                            colors: [                        _buildControlButton(

                              AppStyles.card,                          onPressed: _isRunning ? _pauseTimer : _startTimer,

                              AppStyles.card.withOpacity(0.8),                          icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,

                            ],                          backgroundColor: _isStudyTime ? AppStyles.primary : AppStyles.warning,

                          ),                          foregroundColor: Colors.white,

                          border: Border.all(                          isLarge: true,

                            color: AppStyles.border.withOpacity(0.4),                        ),

                            width: 2,                        

                          ),                        const SizedBox(width: AppStyles.spaceLG),

                          boxShadow: [                        

                            BoxShadow(                        // Skip button

                              color: AppStyles.black.withOpacity(0.08),                        _buildControlButton(

                              blurRadius: 32,                          onPressed: _onTimerComplete,

                              offset: const Offset(0, 12),                          icon: Icons.skip_next_rounded,

                            ),                          backgroundColor: AppStyles.card,

                            BoxShadow(                          foregroundColor: AppStyles.mutedForeground,

                              color: AppStyles.black.withOpacity(0.04),                          borderColor: AppStyles.border,

                              blurRadius: 8,                        ),

                              offset: const Offset(0, 4),                      ],

                            ),                    ),

                            BoxShadow(                    

                              color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.1),                    const SizedBox(height: AppStyles.spaceXXL),

                              blurRadius: 24,                  ],

                              offset: const Offset(0, 0),                ),

                            ),              ),

                          ],            ),

                        ),          ],

                        child: Stack(        ),

                          alignment: Alignment.center,      ),

                          children: [    );

                            // Enhanced Progress Ring  }

                            SizedBox(

                              width: 280,  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {

                              height: 280,    return Container(

                              child: CircularProgressIndicator(      padding: const EdgeInsets.all(AppStyles.spaceLG),

                                value: progress,      decoration: BoxDecoration(

                                strokeWidth: 8,        color: AppStyles.card,

                                backgroundColor: AppStyles.muted.withOpacity(0.3),        borderRadius: BorderRadius.circular(AppStyles.radiusMD),

                                valueColor: AlwaysStoppedAnimation<Color>(        border: Border.all(

                                  _isStudyTime ? AppStyles.primary : AppStyles.warning,          color: AppStyles.border,

                                ),          width: 1,

                                strokeCap: StrokeCap.round,        ),

                              ),        boxShadow: [

                            ),          BoxShadow(

                            // Enhanced Time Display            color: AppStyles.black.withOpacity(0.02),

                            Column(            blurRadius: 4,

                              mainAxisAlignment: MainAxisAlignment.center,            offset: const Offset(0, 1),

                              children: [          ),

                                Text(        ],

                                  _formatTime(_currentSeconds),      ),

                                  style: AppStyles.screenTitle.copyWith(      child: Column(

                                    fontSize: 56,        crossAxisAlignment: CrossAxisAlignment.start,

                                    fontWeight: FontWeight.w800,        mainAxisSize: MainAxisSize.min,

                                    height: 1.0,        children: [

                                    letterSpacing: -2,          Row(

                                    color: AppStyles.foreground,            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                  ),            children: [

                                ),              Text(

                                const SizedBox(height: AppStyles.spaceSM),                title,

                                Container(                style: AppStyles.bodyMedium.copyWith(

                                  padding: const EdgeInsets.symmetric(                  fontWeight: FontWeight.w500,

                                    horizontal: AppStyles.spaceMD,                  color: AppStyles.mutedForeground,

                                    vertical: AppStyles.spaceXS,                ),

                                  ),              ),

                                  decoration: BoxDecoration(              Icon(

                                    color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.1),                icon,

                                    borderRadius: BorderRadius.circular(20),                color: AppStyles.mutedForeground,

                                    border: Border.all(                size: 18,

                                      color: (_isStudyTime ? AppStyles.primary : AppStyles.warning).withOpacity(0.2),              ),

                                      width: 1,            ],

                                    ),          ),

                                  ),          const SizedBox(height: AppStyles.spaceXS),

                                  child: Text(          Text(

                                    _isStudyTime ? 'Focus Mode' : 'Break Time',            value,

                                    style: AppStyles.bodyMedium.copyWith(            style: AppStyles.sectionHeader.copyWith(

                                      color: _isStudyTime ? AppStyles.primary : AppStyles.warning,              fontWeight: FontWeight.w700,

                                      fontWeight: FontWeight.w600,              height: 1.0,

                                      fontSize: 14,              fontSize: 22,

                                    ),            ),

                                  ),          ),

                                ),          Text(

                              ],            subtitle,

                            ),            style: AppStyles.bodySmall.copyWith(

                          ],              color: AppStyles.mutedForeground,

                        ),            ),

                      ),          ),

                              ],

                      const SizedBox(height: AppStyles.spaceXXL),      ),

                          );

                      // Control Buttons - Enhanced  }

                      Row(

                        mainAxisAlignment: MainAxisAlignment.center,  Widget _buildControlButton({

                        children: [    required VoidCallback onPressed,

                          // Reset button    required IconData icon,

                          _buildControlButton(    required Color backgroundColor,

                            onPressed: _resetTimer,    required Color foregroundColor,

                            icon: Icons.refresh_rounded,    Color? borderColor,

                            backgroundColor: AppStyles.card,    bool isLarge = false,

                            foregroundColor: AppStyles.mutedForeground,  }) {

                            borderColor: AppStyles.border,    return Container(

                          ),      width: isLarge ? 72 : 56,

                                height: isLarge ? 72 : 56,

                          const SizedBox(width: AppStyles.spaceLG),      decoration: BoxDecoration(

                                  color: backgroundColor,

                          // Play/Pause button        borderRadius: BorderRadius.circular(isLarge ? 36 : 28),

                          _buildControlButton(        border: borderColor != null ? Border.all(

                            onPressed: _isRunning ? _pauseTimer : _startTimer,          color: borderColor,

                            icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,          width: 1,

                            backgroundColor: _isStudyTime ? AppStyles.primary : AppStyles.warning,        ) : null,

                            foregroundColor: Colors.white,        boxShadow: [

                            isLarge: true,          BoxShadow(

                          ),            color: AppStyles.black.withOpacity(0.1),

                                      blurRadius: 8,

                          const SizedBox(width: AppStyles.spaceLG),            offset: const Offset(0, 2),

                                    ),

                          // Skip button        ],

                          _buildControlButton(      ),

                            onPressed: _onTimerComplete,      child: IconButton(

                            icon: Icons.skip_next_rounded,        onPressed: onPressed,

                            backgroundColor: AppStyles.card,        icon: Icon(

                            foregroundColor: AppStyles.mutedForeground,          icon,

                            borderColor: AppStyles.border,          color: foregroundColor,

                          ),          size: isLarge ? 32 : 24,

                        ],        ),

                      ),      ),

                          );

                      const SizedBox(height: AppStyles.spaceXXL),  }

                    ],}
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: AppStyles.card.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: AppStyles.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  fontWeight: FontWeight.w500,
                  color: AppStyles.mutedForeground,
                ),
              ),
              Icon(
                icon,
                color: AppStyles.mutedForeground,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceXS),
          Text(
            value,
            style: AppStyles.sectionHeader.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.0,
              fontSize: 22,
            ),
          ),
          Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppStyles.mutedForeground,
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
      width: isLarge ? 80 : 64,
      height: isLarge ? 80 : 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isLarge ? 40 : 32),
        border: borderColor != null ? Border.all(
          color: borderColor,
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: foregroundColor,
          size: isLarge ? 36 : 28,
        ),
      ),
    );
  }
}