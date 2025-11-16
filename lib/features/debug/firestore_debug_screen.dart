import 'package:flutter/material.dart';
import '../../core/services/enhanced_firestore_service.dart';
import '../../data/services/data_sync_service.dart';
import '../../data/models/subject.dart';
import '../../data/models/study_session.dart';
import '../../data/models/task.dart';
import 'package:uuid/uuid.dart';

class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({Key? key}) : super(key: key);

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, "${DateTime.now().toIso8601String()}: $message");
    });
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    _addLog("🧪 Testing Firestore connection...");
    
    try {
      final canConnect = await EnhancedFirestoreService.testConnection();
      if (canConnect) {
        _addLog("✅ Firestore connection successful!");
      } else {
        _addLog("❌ Firestore connection failed!");
      }
    } catch (e) {
      _addLog("❌ Connection test error: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testCreateSubject() async {
    setState(() => _isLoading = true);
    _addLog("📚 Creating test subject...");
    
    try {
      final testSubject = Subject(
        id: const Uuid().v4(),
        name: "Test Subject ${DateTime.now().millisecondsSinceEpoch}",
        color: "2196F3",
        description: "This is a test subject created from debug screen",
        userId: 'current_user',
      );

      await DataSyncService.saveSubject(testSubject);
      _addLog("✅ Test subject created: ${testSubject.name}");
    } catch (e) {
      _addLog("❌ Error creating subject: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testCreateStudySession() async {
    setState(() => _isLoading = true);
    _addLog("📖 Creating test study session...");
    
    try {
      // Get available subjects first
      final subjects = await DataSyncService.getAllSubjects();
      String subjectId = 'general';
      
      if (subjects.isNotEmpty) {
        subjectId = subjects.first.id;
        _addLog("📋 Using subject: ${subjects.first.name}");
      } else {
        _addLog("⚠️ No subjects available, using general ID");
      }

      final testSession = StudySession(
        id: const Uuid().v4(),
        subjectId: subjectId,
        userId: 'current_user',
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now(),
        targetDuration: const Duration(hours: 1),
        notes: "Test study session from debug screen",
        isCompleted: true,
        focusScore: 85.5,
      );

      await DataSyncService.saveStudySession(testSession);
      _addLog("✅ Test study session created: ${testSession.id}");
    } catch (e) {
      _addLog("❌ Error creating study session: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testCreateTask() async {
    setState(() => _isLoading = true);
    _addLog("✅ Creating test task...");
    
    try {
      // Get available subjects first
      final subjects = await DataSyncService.getAllSubjects();
      String subjectId = 'general';
      
      if (subjects.isNotEmpty) {
        subjectId = subjects.first.id;
        _addLog("📋 Using subject: ${subjects.first.name}");
      }

      final testTask = Task(
        id: const Uuid().v4(),
        title: "Test Task ${DateTime.now().millisecondsSinceEpoch}",
        description: "This is a test task created from debug screen",
        subjectId: subjectId,
        userId: 'current_user',
        priority: "High",
        dueDate: DateTime.now().add(const Duration(days: 7)),
        isCompleted: false,
      );

      await DataSyncService.saveTask(testTask);
      _addLog("✅ Test task created: ${testTask.title}");
    } catch (e) {
      _addLog("❌ Error creating task: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _listAllData() async {
    setState(() => _isLoading = true);
    _addLog("🔍 Listing all data from Firestore...");
    
    try {
      await EnhancedFirestoreService.debugListAllUserData();
      _addLog("✅ Check console logs for detailed data listing");
    } catch (e) {
      _addLog("❌ Error listing data: $e");
    }
    
    setState(() => _isLoading = false);
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testConnection,
                        icon: const Icon(Icons.wifi),
                        label: const Text('Test Connection'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _listAllData,
                        icon: const Icon(Icons.list),
                        label: const Text('List All Data'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testCreateSubject,
                        icon: const Icon(Icons.book),
                        label: const Text('Create Subject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testCreateStudySession,
                        icon: const Icon(Icons.schedule),
                        label: const Text('Create Session'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCreateTask,
                    icon: const Icon(Icons.task),
                    label: const Text('Create Task'),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          
          // Logs section
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Tap buttons above to test Firestore functionality.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color textColor = Colors.black87;
                      
                      if (log.contains('✅')) {
                        textColor = Colors.green;
                      } else if (log.contains('❌')) {
                        textColor = Colors.red;
                      } else if (log.contains('⚠️')) {
                        textColor = Colors.orange;
                      } else if (log.contains('🧪') || log.contains('🔍')) {
                        textColor = Colors.blue;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}