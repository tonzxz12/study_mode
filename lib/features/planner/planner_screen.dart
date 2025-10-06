import 'package:flutter/material.dart';
import '../../core/theme/styles.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppStyles.primary.withOpacity(0.05),
            AppStyles.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
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
                              color: AppStyles.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              size: 32,
                              color: AppStyles.primary,
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
                                    color: AppStyles.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Study Organization',
                                  style: TextStyle(
                                    color: AppStyles.foreground,
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
                        backgroundColor: AppStyles.primary,
                        foregroundColor: Colors.white,
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
                        color: AppStyles.muted.withOpacity(0.5),
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
                                  color: _currentIndex == 0 ? AppStyles.card : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                  boxShadow: _currentIndex == 0 ? [
                                    BoxShadow(
                                      color: AppStyles.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ] : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book_rounded,
                                      size: 18,
                                      color: _currentIndex == 0 ? AppStyles.primary : AppStyles.mutedForeground,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      'Subjects',
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                                        color: _currentIndex == 0 ? AppStyles.foreground : AppStyles.mutedForeground,
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
                                  color: _currentIndex == 1 ? AppStyles.card : Colors.transparent,
                                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                                  boxShadow: _currentIndex == 1 ? [
                                    BoxShadow(
                                      color: AppStyles.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ] : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_rounded,
                                      size: 18,
                                      color: _currentIndex == 1 ? AppStyles.primary : AppStyles.mutedForeground,
                                    ),
                                    const SizedBox(width: AppStyles.spaceXS),
                                    Text(
                                      'Tasks',
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                                        color: _currentIndex == 1 ? AppStyles.foreground : AppStyles.mutedForeground,
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
                    if (_currentIndex == 0) const SubjectsTab() else const TasksTab(),
                  ],
                ),
              ),

              const SizedBox(height: AppStyles.spaceXXL * 2), // Extra space for navbar
            ],
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
          content: Column(
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
              Row(
                children: [
                  const Text('Color: '),
                  ...Colors.primaries.take(6).map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  // Use a post frame callback to ensure Scaffold context is available
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added subject: ${nameController.text}')),
                      );
                    }
                  });
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
    String selectedSubject = 'Mathematics';
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
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English']
                    .map((subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedSubject = value!),
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
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  // Use a post frame callback to ensure Scaffold context is available
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added task: ${titleController.text}')),
                      );
                    }
                  });
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
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {'name': 'Mathematics', 'color': AppStyles.primary, 'progress': 0.75, 'sessions': 12},
      {'name': 'Physics', 'color': AppStyles.success, 'progress': 0.60, 'sessions': 8},
      {'name': 'Chemistry', 'color': AppStyles.warning, 'progress': 0.45, 'sessions': 6},
      {'name': 'Biology', 'color': AppStyles.info, 'progress': 0.80, 'sessions': 15},
      {'name': 'English', 'color': AppStyles.destructive, 'progress': 0.90, 'sessions': 20},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Stats
        Row(
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
                value: '${((subjects.fold<double>(0, (sum, s) => sum + (s['progress'] as double)) / subjects.length) * 100).toInt()}%',
                subtitle: 'Completed',
                icon: Icons.trending_up_rounded,
                color: AppStyles.success,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppStyles.spaceXL),
        
        // Subjects List
        Text(
          'Your Subjects',
          style: AppStyles.subsectionHeader.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        
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

  Widget _buildSubjectCard(BuildContext context, Map<String, dynamic> subject) {
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spaceXS),
                decoration: BoxDecoration(
                  color: (subject['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  (subject['name'] as String)[0],
                  style: TextStyle(
                    color: subject['color'] as Color,
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
                      subject['name'] as String,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${subject['sessions']} study sessions completed',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppStyles.mutedForeground,
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
                  color: (subject['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                ),
                child: Text(
                  '${((subject['progress'] as double) * 100).toInt()}%',
                  style: AppStyles.bodySmall.copyWith(
                    color: subject['color'] as Color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                      color: AppStyles.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.spaceXS),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppStyles.muted,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: subject['progress'] as double,
                  child: Container(
                    decoration: BoxDecoration(
                      color: subject['color'] as Color,
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
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final List<Map<String, dynamic>> tasks = [
    {
      'title': 'Complete Chapter 5 - Algebra',
      'subject': 'Mathematics',
      'dueDate': DateTime.now().add(const Duration(days: 2)),
      'completed': false,
      'priority': 'High',
    },
    {
      'title': 'Physics Lab Report',
      'subject': 'Physics',
      'dueDate': DateTime.now().add(const Duration(days: 5)),
      'completed': false,
      'priority': 'Medium',
    },
    {
      'title': 'Essay on Shakespeare',
      'subject': 'English',
      'dueDate': DateTime.now().add(const Duration(days: 1)),
      'completed': true,
      'priority': 'High',
    },
    {
      'title': 'Chemistry Worksheet',
      'subject': 'Chemistry',
      'dueDate': DateTime.now().add(const Duration(days: 7)),
      'completed': false,
      'priority': 'Low',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Stats
        Row(
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
                value: '${tasks.where((t) => t['completed']).length}',
                subtitle: 'Finished',
                icon: Icons.check_circle_rounded,
                color: AppStyles.success,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppStyles.spaceXL),
        
        // Tasks List
        Text(
          'Your Tasks',
          style: AppStyles.subsectionHeader.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppStyles.spaceMD),
        
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

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task, int index) {
    final isOverdue = !task['completed'] && DateTime.now().isAfter(task['dueDate']);
    final priorityColor = _getPriorityColor(task['priority']);
    
    return Container(
      padding: const EdgeInsets.all(AppStyles.spaceLG),
      decoration: BoxDecoration(
        color: isOverdue ? AppStyles.destructive.withOpacity(0.05) : AppStyles.card,
        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
        border: Border.all(
          color: isOverdue ? AppStyles.destructive.withOpacity(0.2) : AppStyles.border,
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
      child: Row(
        children: [
          // Checkbox
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.radiusSM),
            ),
            child: Checkbox(
              value: task['completed'],
              onChanged: (value) {
                setState(() {
                  task['completed'] = value ?? false;
                });
              },
              activeColor: AppStyles.success,
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
                  task['title'],
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: task['completed'] ? TextDecoration.lineThrough : TextDecoration.none,
                    color: task['completed'] ? AppStyles.mutedForeground : AppStyles.foreground,
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
                        color: AppStyles.muted.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSM),
                      ),
                      child: Text(
                        task['subject'],
                        style: AppStyles.bodySmall.copyWith(
                          color: AppStyles.mutedForeground,
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
                        task['priority'],
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
                  'Due: ${task['dueDate'].day}/${task['dueDate'].month}/${task['dueDate'].year}',
                  style: AppStyles.bodySmall.copyWith(
                    color: isOverdue ? AppStyles.destructive : AppStyles.mutedForeground,
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
              color: AppStyles.mutedForeground,
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
                setState(() {
                  tasks.removeAt(index);
                });
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value task: ${task['title']}')),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppStyles.destructive;
      case 'Medium':
        return AppStyles.warning;
      case 'Low':
        return AppStyles.success;
      default:
        return AppStyles.mutedForeground;
    }
  }
}
