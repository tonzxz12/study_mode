import 'package:flutter/material.dart';
import '../../core/services/enhanced_firestore_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';
import '../../data/models/study_session.dart';
import 'package:uuid/uuid.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal()}: $message');
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Database Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Firebase Firestore Database Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: const Text('Test Connection'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTestSubject,
                      child: const Text('Create Subject'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTestTask,
                      child: const Text('Create Task'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchAllData,
                      child: const Text('Fetch All Data'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _clearLogs,
                      child: const Text('Clear Logs'),
                    ),
                  ],
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Logs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black;
                if (log.contains('✅')) textColor = Colors.green;
                else if (log.contains('❌')) textColor = Colors.red;
                else if (log.contains('⚠️')) textColor = Colors.orange;
                else if (log.contains('🔍')) textColor = Colors.blue;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
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

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    _addLog("🔍 Testing Firestore connection...");
    
    try {
      final currentUserId = FirestoreService.currentUserId;
      _addLog("👤 Current User ID: $currentUserId");
      
      if (currentUserId == null) {
        _addLog("❌ No authenticated user found!");
        return;
      }
      
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

  Future<void> _createTestSubject() async {
    setState(() => _isLoading = true);
    _addLog("📚 Creating test subject...");
    
    try {
      final currentUserId = FirestoreService.currentUserId;
      if (currentUserId == null) {
        _addLog("❌ No authenticated user - cannot create subject");
        return;
      }

      final testSubject = Subject(
        id: const Uuid().v4(),
        name: "Mathematics ${DateTime.now().millisecondsSinceEpoch}",
        color: "#2196F3",
        description: "Test subject for mathematics learning",
        userId: currentUserId,
        createdAt: DateTime.now(),
      );

      // Save directly to Firestore
      final success = await EnhancedFirestoreService.saveSubject(testSubject);
      if (success) {
        _addLog("✅ Test subject created successfully: ${testSubject.name}");
        _addLog("📝 Subject ID: ${testSubject.id}");
      } else {
        _addLog("❌ Failed to create test subject");
      }
    } catch (e) {
      _addLog("❌ Error creating subject: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _createTestTask() async {
    setState(() => _isLoading = true);
    _addLog("📋 Creating test task...");
    
    try {
      final currentUserId = FirestoreService.currentUserId;
      if (currentUserId == null) {
        _addLog("❌ No authenticated user - cannot create task");
        return;
      }

      // Get subjects to link task to
      final subjects = await EnhancedFirestoreService.getAllSubjects();
      String subjectId = 'general';
      
      if (subjects.isNotEmpty) {
        subjectId = subjects.first.id;
        _addLog("📋 Using subject: ${subjects.first.name}");
      } else {
        _addLog("⚠️ No subjects found, using default ID");
      }

      final testTask = Task(
        id: const Uuid().v4(),
        title: "Complete Chapter 1 - ${DateTime.now().millisecondsSinceEpoch}",
        description: "Test task for homework completion",
        subjectId: subjectId,
        userId: currentUserId,
        priority: "High",
        dueDate: DateTime.now().add(const Duration(days: 7)),
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Save directly to Firestore
      final success = await EnhancedFirestoreService.saveTask(testTask);
      if (success) {
        _addLog("✅ Test task created successfully: ${testTask.title}");
        _addLog("📝 Task ID: ${testTask.id}");
      } else {
        _addLog("❌ Failed to create test task");
      }
    } catch (e) {
      _addLog("❌ Error creating task: $e");
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    _addLog("🔍 Fetching all data from Firestore...");
    
    try {
      final currentUserId = FirestoreService.currentUserId;
      if (currentUserId == null) {
        _addLog("❌ No authenticated user - cannot fetch data");
        return;
      }

      // Fetch subjects
      _addLog("📚 Fetching subjects...");
      final subjects = await EnhancedFirestoreService.getAllSubjects();
      _addLog("✅ Found ${subjects.length} subjects:");
      for (final subject in subjects) {
        _addLog("   - ${subject.name} (${subject.id}) - Color: ${subject.color}");
      }

      // Fetch tasks
      _addLog("📋 Fetching tasks...");
      final tasks = await EnhancedFirestoreService.getAllTasks();
      _addLog("✅ Found ${tasks.length} tasks:");
      for (final task in tasks) {
        _addLog("   - ${task.title} (${task.id}) - Subject: ${task.subjectId}");
      }

      // Fetch study sessions
      _addLog("📖 Fetching study sessions...");
      final sessions = await EnhancedFirestoreService.getAllStudySessions();
      _addLog("✅ Found ${sessions.length} study sessions:");
      for (final session in sessions.take(5)) {
        _addLog("   - Session ${session.id} - ${session.actualDuration.inMinutes}min");
      }

      _addLog("🎯 === SUMMARY ===");
      _addLog("📚 Total Subjects: ${subjects.length}");
      _addLog("📋 Total Tasks: ${tasks.length}");
      _addLog("📖 Total Sessions: ${sessions.length}");
      
    } catch (e) {
      _addLog("❌ Error fetching data: $e");
    }
    
    setState(() => _isLoading = false);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }
}