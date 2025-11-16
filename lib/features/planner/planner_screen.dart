import 'package:flutter/material.dart';
import '../../core/theme/styles.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/services/enhanced_firestore_service.dart';
import '../../core/services/firestore_service.dart';
import '../../data/models/subject.dart';
import '../../data/models/task.dart';


// Helper to convert color string to Color object
Color _colorFromString(String colorString) {
  try {
    final int colorValue = int.parse(colorString.replaceFirst('#', '0xff'));
    return Color(colorValue);
  } catch (e) {
    return Colors.blue; // Default color
  }
}

// Helper to convert Color object to string
String _colorToString(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late TabController _tabController;
  
  List<Subject> subjects = [];
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      print('🔍 === PLANNER SCREEN LOADING DATA ===');
      print('📱 Loading data directly from online database (Firestore)...');
      print('🆔 Current Firebase user ID: ${FirestoreService.currentUserId}');
      print('📧 Current Firebase user email: ${FirestoreService.currentUserId != null ? "User authenticated" : "No user"}');
      
      final loadedSubjects = await EnhancedFirestoreService.getAllSubjects();
      final loadedTasks = await EnhancedFirestoreService.getAllTasks();
      
      setState(() {
        subjects = loadedSubjects;
        tasks = loadedTasks;
      });
      
      print('✅ Loaded ${subjects.length} subjects and ${tasks.length} tasks from online database');
    } catch (e) {
      print('❌ Error loading data from online database: $e');
      setState(() {
        subjects = [];
        tasks = [];
      });
    }
  }
  
  Future<void> _updateTask(int index, Task updatedTask) async {
    try {
      final success = await EnhancedFirestoreService.saveTask(updatedTask);
      if (!success) throw Exception('Failed to save task to online database');
      setState(() {
        tasks[index] = updatedTask;
      });
      print('✅ Task updated and synced: ${updatedTask.title}');
    } catch (e) {
      print('❌ Error updating task: $e');
    }
  }

  void _editSubject(int index, Subject subject) {
    final nameController = TextEditingController(text: subject.name);
    Color selectedColor = _colorFromString(subject.color);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Color'),
              const SizedBox(height: 8),
              Container(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: Colors.primaries.map(
                      (color) => GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.white, width: 3)
                                : Border.all(color: Colors.grey.shade300, width: 1),
                            boxShadow: selectedColor == color
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updatedSubject = subject.copyWith(
                    name: nameController.text,
                    color: _colorToString(selectedColor),
                  );
                  
                  try {
                    final success = await EnhancedFirestoreService.saveSubject(updatedSubject);
                    if (!success) throw Exception('Failed to update subject in online database');
                    setState(() {
                      subjects[index] = updatedSubject;
                    });
                  } catch (e) {
                    print('❌ Error updating subject: $e');
                  }
                  Navigator.of(context).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated subject: ${nameController.text}')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSubject(int index, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"? This will also delete all associated tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Remove the subject
                final success = await EnhancedFirestoreService.deleteSubject(subject.id);
                if (!success) throw Exception('Failed to delete subject from online database');
                
                // Remove all tasks associated with this subject
                final tasksToDelete = tasks.where((task) => task.subjectId == subject.id).toList();
                for (final task in tasksToDelete) {
                  final taskDeleteSuccess = await EnhancedFirestoreService.deleteTask(task.id);
                  if (!taskDeleteSuccess) print('⚠️ Failed to delete task ${task.id} from online database');
                }
                
                // Update local state
                setState(() {
                  subjects.removeAt(index);
                  tasks.removeWhere((task) => task.subjectId == subject.id);
                });
                
                Navigator.of(context).pop();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted subject: ${subject.name}')),
                  );
                }
              } catch (e) {
                print('❌ Error deleting subject: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error deleting subject')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header Section with Planner Title and Planning Badge
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppStyles.spaceXL, 
                  AppStyles.spaceLG, 
                  AppStyles.spaceXL, 
                  AppStyles.spaceXL
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Planner Title with Icon
                    Expanded(
                      child: Row(
                        children: [
                          // Planner Icon
                          Container(
                            padding: const EdgeInsets.all(AppStyles.spaceXS),
                            decoration: BoxDecoration(
                              color: context.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              size: 32,
                              color: context.primary,
                            ),
                          ),
                          const SizedBox(width: AppStyles.spaceMD),
                          // Planner Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Planner',
                                  style: AppStyles.screenTitle.copyWith(
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                    color: context.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Study Organization',
                                  style: TextStyle(
                                    color: context.foreground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add Button
                    ElevatedButton(
                      onPressed: _showAddDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.primaryForeground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spaceLG,
                          vertical: AppStyles.spaceMD
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.radiusXL),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppStyles.spaceXL),

              // Dashboard Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tab Navigation - Modern Style
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.muted.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _currentIndex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppStyles.spaceSM,
                                  horizontal: AppStyles.spaceMD,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentIndex == 0 ? context.card : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                  boxShadow: _currentIndex == 0 ? context.shadowSM : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book_rounded,
                                      size: 18,
                                      color: _currentIndex == 0 ? context.primary : context.mutedForeground,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      'Subjects',
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                                        color: _currentIndex == 0 ? context.foreground : context.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _currentIndex = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppStyles.spaceSM,
                                  horizontal: AppStyles.spaceMD,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentIndex == 1 ? context.card : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                  boxShadow: _currentIndex == 1 ? context.shadowSM : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_rounded,
                                      size: 18,
                                      color: _currentIndex == 1 ? context.primary : context.mutedForeground,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      'Tasks',
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                                        color: _currentIndex == 1 ? context.foreground : context.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppStyles.spaceXL),

                    // Content based on selected tab
                    if (_currentIndex == 0) 
                      SubjectsTab(
                        subjects: subjects, 
                        onSubjectEdit: _editSubject,
                        onSubjectDelete: _deleteSubject,
                      ) 
                    else 
                      TasksTab(tasks: tasks, subjects: subjects, onTaskUpdate: _updateTask),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.width < 600 
                ? AppStyles.spaceXXL * 3 // Mobile - extra space for floating navbar
                : AppStyles.spaceXL), // Tablet/Desktop - less space needed
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    if (_currentIndex == 0) {
      _showAddSubjectDialog();
    } else {
      _showAddTaskDialog();
    }
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subject'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      hintText: 'e.g., Mathematics',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Color: '),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: Colors.primaries.map(
                              (color) => GestureDetector(
                                onTap: () => setState(() => selectedColor = color),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: selectedColor == color
                                        ? Border.all(color: Colors.white, width: 3)
                                        : Border.all(color: Colors.grey.shade300, width: 1),
                                    boxShadow: selectedColor == color
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newSubject = Subject(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    color: _colorToString(selectedColor),
                    userId: FirestoreService.currentUserId ?? 'anonymous',
                  );
                  
                  try {
                    final success = await EnhancedFirestoreService.saveSubject(newSubject);
                    if (!success) throw Exception('Failed to save subject to online database');
                    
                    // Update main widget state
                    setState(() {
                      subjects.add(newSubject);
                    });
                    
                    // Close dialog
                    Navigator.of(context).pop();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added subject: ${nameController.text}')),
                      );
                    }
                  } catch (e) {
                    print('❌ Error saving subject: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error adding subject')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedSubjectId = subjects.isNotEmpty ? subjects.first.id : '';
    String selectedPriority = 'Medium';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g., Complete Chapter 5',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional task description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (subjects.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: subjects
                      .map((subject) => DropdownMenuItem<String>(
                            value: subject.id,
                            child: Text(subject.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubjectId = value ?? subjects.first.id;
                    });
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Add subjects first to organize your tasks',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['High', 'Medium', 'Low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedPriority = value ?? 'Medium'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final newTask = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    subjectId: selectedSubjectId,
                    priority: selectedPriority,
                    dueDate: selectedDate,
                    isCompleted: false,
                    userId: FirestoreService.currentUserId ?? 'anonymous',
                  );

                  try {
                    final success = await EnhancedFirestoreService.saveTask(newTask);
                    if (!success) throw Exception('Failed to save task to online database');
                    
                    // Update the main widget state
                    setState(() {
                      tasks.add(newTask);
                    });

                    // Close the dialog
                    Navigator.of(context).pop();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added task: ${titleController.text}')),
                      );
                    }
                  } catch (e) {
                    print('❌ Error saving task: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error adding task')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectsTab extends StatelessWidget {
  final List<Subject> subjects;
  final Function(int, Subject)? onSubjectEdit;
  final Function(int, Subject)? onSubjectDelete;
  
  const SubjectsTab({
    super.key, 
    required this.subjects,
    required this.onSubjectEdit,
    required this.onSubjectDelete,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Stats
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Subjects',
                  value: '${subjects.length}',
                  subtitle: 'Active',
                  icon: Icons.book_rounded,
                  color: AppStyles.primary,
                ),
              ),
              const SizedBox(width: AppStyles.spaceSM),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Progress',
                  value: subjects.isEmpty ? '0%' : '75%', // TODO: Add progress field to Subject model
                  subtitle: 'Completed',
                  icon: Icons.trending_up_rounded,
                  color: AppStyles.success,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppStyles.spaceXL),
        
        // Subjects List
        Text(
          'Your Subjects',
          style: AppStyles.subsectionHeader.copyWith(
            fontWeight: FontWeight.w600,
            color: context.foreground,
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        
        if (subjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppStyles.spaceXXL),
            child: Column(
              children: [
                Icon(
                  Icons.book_rounded,
                  size: 48,
                  color: context.mutedForeground,
                ),
                const SizedBox(height: AppStyles.spaceLG),
                Text(
                  'No Subjects Yet',
                  style: AppStyles.subsectionHeader.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  'Add your first subject to start planning your studies',
                  style: AppStyles.bodyMedium.copyWith(
                    color: context.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...subjects.asMap().entries.map((entry) {
            final index = entry.key;
            final subject = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < subjects.length - 1 ? AppStyles.spaceSM : 0),
              child: _buildSubjectCard(context, subject),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: AppStyles.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
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

  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: context.border,
          width: 1,
        ),
        boxShadow: context.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceXS),
                decoration: BoxDecoration(
                  color: _colorFromString(subject.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  subject.name[0],
                  style: TextStyle(
                    color: _colorFromString(subject.color),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.foreground,
                      ),
                    ),
                    Text(
                      'Study sessions: ${subject.description.isEmpty ? 'None yet' : subject.description}',
                      style: AppStyles.bodySmall.copyWith(
                        color: context.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spaceSM,
                  vertical: AppStyles.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: _colorFromString(subject.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  'Active', // TODO: Add progress field to Subject model
                  style: AppStyles.bodySmall.copyWith(
                    color: _colorFromString(subject.color),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppStyles.spaceXS),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.mutedForeground,
                  size: 18,
                ),
                onSelected: (value) {
                  final index = subjects.indexWhere((s) => s.id == subject.id);
                  if (value == 'edit') {
                    onSubjectEdit?.call(index, subject);
                  } else if (value == 'delete') {
                    onSubjectDelete?.call(index, subject);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spaceMD),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: AppStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spaceXS),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: context.muted,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.65, // TODO: Add progress field to Subject model
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorFromString(subject.color),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TasksTab extends StatefulWidget {
  final List<Task> tasks;
  final List<Subject> subjects;
  final Function(int, Task) onTaskUpdate;
  
  const TasksTab({
    super.key, 
    required this.tasks, 
    required this.subjects, 
    required this.onTaskUpdate
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<Task> get tasks => widget.tasks;
  List<Subject> get subjects => widget.subjects;


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Stats
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Tasks',
                  value: '${tasks.length}',
                  subtitle: 'Created',
                  icon: Icons.assignment_rounded,
                  color: AppStyles.primary,
                ),
              ),
              const SizedBox(width: AppStyles.spaceSM),
              Expanded(
                child: _buildStatCard(
                  title: 'Completed',
                  value: '${tasks.where((t) => t.isCompleted).length}',
                  subtitle: 'Finished',
                  icon: Icons.check_circle_rounded,
                  color: AppStyles.success,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppStyles.spaceXL),
        
        // Tasks List
        Text(
          'Your Tasks',
          style: AppStyles.subsectionHeader.copyWith(
            fontWeight: FontWeight.w600,
            color: context.foreground,
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppStyles.spaceXXL),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_rounded,
                  size: 48,
                  color: context.mutedForeground,
                ),
                const SizedBox(height: AppStyles.spaceLG),
                Text(
                  'No Tasks Yet',
                  style: AppStyles.subsectionHeader.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  'Add your first task to start organizing your work',
                  style: AppStyles.bodyMedium.copyWith(
                    color: context.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < tasks.length - 1 ? AppStyles.spaceSM : 0),
              child: _buildTaskCard(context, task, index),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: AppStyles.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
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

  Widget _buildTaskCard(BuildContext context, Task task, int index) {
    final isOverdue = !task.isCompleted && DateTime.now().isAfter(task.dueDate);
    final priorityColor = _getPriorityColor(context, task.priority);
    final taskSubject = subjects.firstWhere(
      (s) => s.id == task.subjectId,
      orElse: () => Subject(id: '', name: 'Unknown', color: '#0066CC', userId: FirestoreService.currentUserId ?? 'anonymous'),
    );
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: isOverdue ? context.destructive.withOpacity(0.05) : context.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: isOverdue ? context.destructive.withOpacity(0.2) : context.border,
          width: 1,
        ),
        boxShadow: context.shadowSM,
      ),
      child: Row(
        children: [
          // Checkbox
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
            ),
            child: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                final updatedTask = task.copyWith(
                  isCompleted: value ?? false,
                );
                widget.onTaskUpdate(index, updatedTask);
              },
              activeColor: context.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppStyles.spaceSM),
          // Task Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: task.isCompleted ? context.mutedForeground : context.foreground,
                  ),
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.muted.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                      ),
                      child: Text(
                        taskSubject.name,
                        style: AppStyles.bodySmall.copyWith(
                          color: context.mutedForeground,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spaceXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spaceXS),
                Text(
                  'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: AppStyles.bodySmall.copyWith(
                    color: isOverdue ? context.destructive : context.mutedForeground,
                    fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.mutedForeground,
              size: 18,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteTask(index, task);
              } else if (value == 'edit') {
                _editTask(index, task);
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteTask(int index, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Remove the task using EnhancedFirestoreService
                final success = await EnhancedFirestoreService.deleteTask(task.id);
                if (!success) throw Exception('Failed to delete task from online database');
                
                Navigator.of(context).pop();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted task: ${task.title}')),
                  );
                }
              } catch (e) {
                print('❌ Error deleting task: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error deleting task')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.destructive,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editTask(int index, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    String selectedSubjectId = task.subjectId;
    String selectedPriority = task.priority;
    DateTime selectedDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (subjects.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: subjects
                      .map((subject) => DropdownMenuItem<String>(
                            value: subject.id,
                            child: Text(subject.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value ?? subjects.first.id),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['High', 'Medium', 'Low']
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedPriority = value ?? 'Medium'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final updatedTask = task.copyWith(
                    title: titleController.text,
                    description: descriptionController.text,
                    subjectId: selectedSubjectId,
                    priority: selectedPriority,
                    dueDate: selectedDate,
                  );

                  widget.onTaskUpdate(index, updatedTask);
                  Navigator.of(context).pop();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated task: ${titleController.text}')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'High':
        return context.destructive;
      case 'Medium':
        return context.warning;
      case 'Low':
        return context.success;
      default:
        return context.mutedForeground;
    }
  }
}
