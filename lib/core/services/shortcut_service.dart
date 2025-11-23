import 'package:quick_actions/quick_actions.dart';

class ShortcutService {
  static final QuickActions _quickActions = const QuickActions();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set up shortcut actions
      await _quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'action_start_timer',
          localizedTitle: 'Start Study Timer',
          icon: 'ic_timer',
        ),
        const ShortcutItem(
          type: 'action_quick_break',
          localizedTitle: 'Quick Break',
          icon: 'ic_break',
        ),
        const ShortcutItem(
          type: 'action_pomodoro',
          localizedTitle: 'Pomodoro Session',
          icon: 'ic_pomodoro',
        ),
        const ShortcutItem(
          type: 'action_settings',
          localizedTitle: 'Settings',
          icon: 'ic_settings',
        ),
      ]);
      
      _isInitialized = true;
      print('✅ Home screen shortcuts initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize shortcuts: $e');
    }
  }

  static void handleShortcut(String shortcutType) {
    print('🚀 Handling shortcut: $shortcutType');
    
    switch (shortcutType) {
      case 'action_start_timer':
        print('📱 Timer shortcut activated');
        // The shortcut will be handled by the main app when it receives the action
        break;
        
      case 'action_quick_break':
        print('📱 Quick break shortcut activated');
        break;
        
      case 'action_pomodoro':
        print('📱 Pomodoro shortcut activated');
        break;
        
      case 'action_settings':
        print('📱 Settings shortcut activated');
        break;
        
      default:
        print('⚠️ Unknown shortcut type: $shortcutType');
    }
  }

  static Future<bool> areShortcutsSupported() async {
    try {
      // Try to set shortcuts and check if it succeeds
      await _quickActions.setShortcutItems(<ShortcutItem>[]);
      return true;
    } catch (e) {
      print('❌ Shortcuts not supported: $e');
      return false;
    }
  }

  static Future<void> removeShortcuts() async {
    try {
      await _quickActions.clearShortcutItems();
      _isInitialized = false;
      print('✅ Home screen shortcuts removed');
    } catch (e) {
      print('❌ Failed to remove shortcuts: $e');
    }
  }

  static void setShortcutHandler(Function(String) handler) {
    _quickActions.initialize(handler);
  }
}