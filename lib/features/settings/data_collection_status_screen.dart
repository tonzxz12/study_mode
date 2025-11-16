import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../data/services/data_sync_service.dart';

class DataCollectionStatusScreen extends StatefulWidget {
  const DataCollectionStatusScreen({super.key});

  @override
  State<DataCollectionStatusScreen> createState() => _DataCollectionStatusScreenState();
}

class _DataCollectionStatusScreenState extends State<DataCollectionStatusScreen> {
  Map<String, dynamic>? _syncStatus;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    
    try {
      final syncStatus = await DataSyncService.getSyncStatus();
      final userData = await FirestoreService.getUserData();
      
      setState(() {
        _syncStatus = syncStatus;
        _userData = userData;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Collection Status'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildUserSection(),
                  const SizedBox(height: 20),
                  _buildSyncStatusSection(),
                  const SizedBox(height: 20),
                  _buildDataSummarySection(),
                  const SizedBox(height: 20),
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final isFirestoreConnected = _syncStatus?['firestore']?['connected'] == true;
    
    return Card(
      color: isFirestoreConnected ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFirestoreConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isFirestoreConnected ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Data Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFirestoreConnected ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        isFirestoreConnected 
                            ? '✅ Active - Data is being saved to Firebase'
                            : '⚠️ Local Only - Firestore API needs to be enabled',
                        style: TextStyle(
                          color: isFirestoreConnected ? Colors.green.shade600 : Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isFirestoreConnected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Action Required:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Go to Firebase Console (console.firebase.google.com)\n'
                      '2. Select project: study-mode-78bf6\n'
                      '3. Click "Firestore Database" → "Create database"\n'
                      '4. Choose "Start in test mode" → Select location → Done',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 Current User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (user != null) ...[
              _buildInfoRow('Email', user.email ?? 'N/A'),
              _buildInfoRow('User ID', user.uid),
              _buildInfoRow('Display Name', user.displayName ?? 'Not set'),
              _buildInfoRow('Account Created', user.metadata.creationTime?.toString() ?? 'N/A'),
            ] else
              const Text('No user logged in', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔄 Data Sync Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Local Storage
            _buildSyncStatusTile(
              'Local Storage (Hive)',
              _syncStatus?['local']?['connected'] == true,
              'Device storage for offline functionality',
            ),
            
            const Divider(),
            
            // Firebase Auth
            _buildSyncStatusTile(
              'Firebase Authentication',
              FirebaseAuth.instance.currentUser != null,
              'User account management',
            ),
            
            const Divider(),
            
            // Firestore
            _buildSyncStatusTile(
              'Cloud Firestore',
              _syncStatus?['firestore']?['connected'] == true,
              'Cloud database for research data collection',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusTile(String title, bool isConnected, String description) {
    return Row(
      children: [
        Icon(
          isConnected ? Icons.check_circle : Icons.error,
          color: isConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: isConnected ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDataSummarySection() {
    final localData = _syncStatus?['local']?['data'];
    final firestoreData = _syncStatus?['firestore']?['data'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Data Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Local data summary
            Text(
              'Local Data:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 4),
            if (localData != null) ...[
              _buildInfoRow('Total Sessions', '${localData['totalSessions'] ?? 0}'),
              _buildInfoRow('Total Subjects', '${localData['totalSubjects'] ?? 0}'),
              _buildInfoRow('Study Minutes', '${localData['totalMinutes'] ?? 0}'),
              _buildInfoRow('Weekly Sessions', '${localData['weeklySessionCount'] ?? 0}'),
            ],
            
            const SizedBox(height: 8),
            
            // Cloud data summary
            Text(
              'Cloud Data (Firestore):',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
            ),
            const SizedBox(height: 4),
            if (firestoreData != null) ...[
              _buildInfoRow('Weekly Sessions', '${firestoreData['weeklySessionCount'] ?? 0}'),
              _buildInfoRow('Monthly Sessions', '${firestoreData['monthlySessionCount'] ?? 0}'),
              _buildInfoRow('Weekly Minutes', '${firestoreData['weeklyMinutes'] ?? 0}'),
              _buildInfoRow('Average Focus', '${(firestoreData['averageFocusThisWeek'] ?? 0.0).toStringAsFixed(1)}%'),
            ] else
              const Text('No Firestore data available (API not enabled)', 
                  style: TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Data'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (_syncStatus?['firestore']?['connected'] == true) 
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _forceSyncToCloud,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Force Sync to Cloud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Enable Firestore API to sync data to cloud for research',
                  style: TextStyle(color: Colors.orange.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = await DataSyncService.exportAllData();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Export'),
            content: SingleChildScrollView(
              child: Text(
                'Export completed!\n\n'
                'Summary:\n'
                '• Subjects: ${data['summary']?['totalSubjects'] ?? 0}\n'
                '• Sessions: ${data['summary']?['totalSessions'] ?? 0}\n'
                '• Completed: ${data['summary']?['completedSessions'] ?? 0}\n'
                '• Total Minutes: ${data['summary']?['totalStudyMinutes'] ?? 0}\n\n'
                'Data source: ${data['dataSource'] ?? 'unknown'}\n'
                'Exported at: ${data['exportedAt'] ?? 'unknown'}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _forceSyncToCloud() async {
    try {
      await DataSyncService.forceSyncToFirestore();
      await _loadStatus(); // Refresh status
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data synced to cloud successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}