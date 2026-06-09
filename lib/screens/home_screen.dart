import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/todo_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/todo_list.dart';
import '../widgets/daily_summary.dart';
import '../widgets/calendar_view.dart';
import '../models/todo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoService = context.watch<TodoService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TodoMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: () => _showPendingSummary(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      '${todoService.pendingCount}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Pending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${todoService.completedCount}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const DailySummary(),
          const HabitStatsSection(),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
              Tab(text: 'Calendar'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
          Expanded(
            child: _tabController.index == 0
              ? TodoList(
                  key: ValueKey(todoService.version),
                  todos: todoService.pendingTodos,
                  emptyMessage: 'No pending tasks',
                  onEdit: _showEditTaskDialog,
                )
              : _tabController.index == 1
              ? TodoList(
                  key: ValueKey(todoService.version),
                  todos: todoService.completedTodos,
                  emptyMessage: 'No completed tasks yet',
                  onDelete: (todo) => todoService.removeCompletedTodo(todo),
                )
              : CalendarView(
                  onEdit: _showEditTaskDialog,
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  void _showEditTaskDialog(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (context) => EditTaskDialog(todo: todo),
    );
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(onEdit: _showEditTaskDialog),
    );
  }

  void _showSortOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _SortDialog(),
    );
  }

  void _showPendingSummary(BuildContext context) {
    final todoService = context.read<TodoService>();
    final pending = todoService.pendingTodos;
    final pinned = pending.where((t) => t.isPinned).toList();
    final notPinned = pending.where((t) => !t.isPinned).toList();
    final today = todoService.getTodayTodos();
    final tomorrow = todoService.getTomorrowTodos();
    final overdue = pending.where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Tasks Summary'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${pending.length} pending tasks',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (pinned.isNotEmpty) ...[
                  const Text('📌 Pinned Tasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...pinned.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• ${t.title}', style: const TextStyle(fontSize: 14)),
                  )),
                  const SizedBox(height: 12),
                ],
                if (today.isNotEmpty) ...[
                  const Text('📅 Today:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...today.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• ${t.title}${t.dueDate != null ? ' (${t.dueDate!.hour.toString().padLeft(2, "0")}:${t.dueDate!.minute.toString().padLeft(2, "0")})' : ''}', style: const TextStyle(fontSize: 14)),
                  )),
                  const SizedBox(height: 12),
                ],
                if (tomorrow.isNotEmpty) ...[
                  const Text('📆 Tomorrow:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...tomorrow.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• ${t.title}', style: const TextStyle(fontSize: 14)),
                  )),
                  const SizedBox(height: 12),
                ],
                if (overdue.isNotEmpty) ...[
                  const Text('⚠️ Overdue:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  ...overdue.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• ${t.title} (Due: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year})', style: const TextStyle(fontSize: 14, color: Colors.red)),
                  )),
                  const SizedBox(height: 12),
                ],
                if (notPinned.isNotEmpty) ...[
                  const Text('📋 Other Tasks:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...notPinned.map((t) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text('• ${t.title}', style: const TextStyle(fontSize: 14)),
                  )),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final titles = pending.map((t) => t.title).join('\n');
                        NotificationService().speakText('You have ${pending.length} pending tasks. $titles');
                      },
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Read Aloud'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final summary = StringBuffer();
                        summary.writeln('Total: ${pending.length} pending tasks');
                        if (pinned.isNotEmpty) {
                          summary.writeln('\nPinned:');
                          for (final t in pinned) summary.writeln('  - ${t.title}');
                        }
                        if (overdue.isNotEmpty) {
                          summary.writeln('\nOverdue:');
                          for (final t in overdue) summary.writeln('  - ${t.title} (Due: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year})');
                        }
                        summary.writeln('\nToday:');
                        for (final t in today) summary.writeln('  - ${t.title}');
                        summary.writeln('\nTomorrow:');
                        for (final t in tomorrow) summary.writeln('  - ${t.title}');
                        Clipboard.setData(ClipboardData(text: summary.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Summary copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final Function(BuildContext, Todo)? onEdit;

  const _SearchDialog({this.onEdit});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Todo> _filteredTodos = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_filterTodos);
    _filterTodos();
  }

  void _filterTodos() {
    final todoService = context.read<TodoService>();
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredTodos = todoService.todos);
    } else {
      setState(() {
        _filteredTodos = todoService.todos.where((todo) {
          return todo.title.toLowerCase().contains(query) ||
              (todo.notes != null && todo.notes!.toLowerCase().contains(query)) ||
              (todo.category != null && todo.category!.toLowerCase().contains(query)) ||
              (todo.habitTag != null && todo.habitTag!.toLowerCase().contains(query)) ||
              todo.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
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
    return AlertDialog(
      title: const Text('Search Tasks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search by title, notes, category, tags...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _filteredTodos.isEmpty
                ? const Center(child: Text('No tasks found'))
                : ListView.builder(
                    itemCount: _filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = _filteredTodos[index];
                      return ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: todo.isCompleted ? Colors.green : null,
                                size: 20,
                              ),
                              onPressed: () {
                                context.read<TodoService>().toggleComplete(todo);
                                _filterTodos();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.purple, size: 18),
                              onPressed: () {
                                String text = todo.title;
                                if (todo.subtasks.isNotEmpty) {
                                  text += '. Subtasks: ';
                                  text += todo.subtasks.asMap().entries.map((entry) {
                                    return '${entry.key + 1}. ${entry.value}';
                                  }).join(', ');
                                }
                                NotificationService().speakText(text);
                              },
                            ),
                          ],
                        ),
                        title: Text(todo.title),
                        subtitle: Text(todo.category ?? ''),
                        trailing: todo.priority != null
                            ? Icon(
                                Icons.flag,
                                color: _getPriorityColor(todo.priority),
                                size: 16,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onEdit?.call(context, todo);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _SortDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sortMode = context.watch<TodoService>().sortMode;
    return AlertDialog(
      title: const Text('Sort Tasks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortTile(
            icon: Icons.event,
            title: 'Due Date',
            subtitle: 'Sort by due date',
            sortKey: 'dueDate',
            currentSort: sortMode,
          ),
          _SortTile(
            icon: Icons.sort_by_alpha,
            title: 'Title (A-Z)',
            subtitle: 'Sort alphabetically',
            sortKey: 'title',
            currentSort: sortMode,
          ),
          _SortTile(
            icon: Icons.category,
            title: 'Category',
            subtitle: 'Sort by category',
            sortKey: 'category',
            currentSort: sortMode,
          ),
          _SortTile(
            icon: Icons.flag,
            title: 'Priority',
            subtitle: 'Sort by priority (High → Low)',
            sortKey: 'priority',
            currentSort: sortMode,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SortTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String sortKey;
  final String currentSort;

  const _SortTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sortKey,
    required this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = sortKey == currentSort;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: isSelected ? const TextStyle(fontWeight: FontWeight.bold) : null),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        context.read<TodoService>().setSortMode(sortKey);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorted by $title')),
        );
      },
    );
  }
}

class HabitStatsSection extends StatelessWidget {
  const HabitStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, TodoService>(
      builder: (context, themeProvider, todoService, child) {
        final stats = todoService.getHabitStats();

        final nonZeroStats = stats.entries.where((entry) => entry.value.currentStreak > 0).toList();

        if (nonZeroStats.isEmpty && stats.isEmpty) {
          return const SizedBox.shrink();
        }

        final style = themeProvider.isBigText
            ? const TextStyle(fontSize: 16)
            : const TextStyle(fontSize: 12);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Habit Tracker',
                    style: themeProvider.isBigText
                        ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        : const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: themeProvider.isBigText ? 80 : 50,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: nonZeroStats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final stat = nonZeroStats[index].value;
                    return Chip(
                      avatar: Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: stat.currentStreak > 0 ? Colors.orange : Colors.grey,
                      ),
                      label: Text(
                        '${stat.tag} (${stat.currentStreak}🔥)',
                        style: style,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _habitController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  String? _selectedPriority;
  final List<String> _tags = [];
  final List<String> _subtasks = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechInitialized = false;
  bool _isRecurring = false;
  int _recurrenceIntervalDays = 1;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    if (_speechInitialized) return;
    
    if (kIsWeb) {
      if (mounted) {
        setState(() => _speechInitialized = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is not supported on web browsers. Please use a mobile device.')),
        );
      }
      return;
    }
    
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      if (mounted) {
        setState(() => _speechInitialized = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input. Please enable it in settings.')),
        );
      }
      return;
    }
    
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${error.errorMsg}')),
          );
        }
      },
    );
    
    if (mounted) {
      setState(() {
        _speechInitialized = available;
        if (!available) {
          _isListening = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition is not available on this device. Voice input requires a compatible device with microphone access.')),
          );
        }
      });
    }
  }

  Future<void> _startListening() async {
    await _initSpeech();
    
    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available. Please check microphone permissions.')),
        );
      }
      return;
    }

    bool listening = await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _controller.text = result.recognizedWords;
            _selectedCategory = context.read<TodoService>().categorizeTask(result.recognizedWords);
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        listenFor: Duration(minutes: 1),
        pauseFor: Duration(seconds: 10),
      ),
    );

    if (mounted) {
      setState(() => _isListening = listening);
    }
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Consumer<TodoService>(
            builder: (context, todoService, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: todoService.categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ListTile(
                          leading: Icon(
                            _getCategoryIcon(category),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            category,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_cart;
      case 'chores':
        return Icons.cleaning_services;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'health':
        return Icons.favorite;
      case 'personal':
        return Icons.person;
      default:
        return Icons.label;
    }
  }

  void _updateCategory(String text) {
    final todoService = context.read<TodoService>();
    setState(() {
      _selectedCategory = todoService.categorizeTask(text);
    });
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Select Priority',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: const Text('High'),
                onTap: () {
                  setState(() => _selectedPriority = 'high');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.orange),
                title: const Text('Medium'),
                onTap: () {
                  setState(() => _selectedPriority = 'medium');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.green),
                title: const Text('Low'),
                onTap: () {
                  setState(() => _selectedPriority = 'low');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove, color: Colors.grey),
                title: const Text('No Priority'),
                onTap: () {
                  setState(() => _selectedPriority = null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final todoService = context.read<TodoService>();
    DateTime? dueDate;
    
    if (_selectedDate != null && _selectedTime != null) {
      dueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    todoService.addTodo(text, dueDate: dueDate, category: _selectedCategory, priority: _selectedPriority, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(), tags: _tags.isNotEmpty ? _tags : null, subtasks: _subtasks.isNotEmpty ? _subtasks : null, isRecurring: _isRecurring, habitTag: _habitController.text.trim().isEmpty ? null : _habitController.text.trim(), recurrenceIntervalDays: _recurrenceIntervalDays);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added successfully!')),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addSubtask() {
    final subtask = _subtaskController.text.trim();
    if (subtask.isNotEmpty) {
      setState(() => _subtasks.add(subtask));
      _subtaskController.clear();
    }
  }

  void _removeSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  void _showRecurringPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Recurring Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Repeat this task'),
                subtitle: const Text('Task will repeat after completion'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() => _isRecurring = value);
                },
              ),
              if (_isRecurring) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Repeat every',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() => _recurrenceIntervalDays = (_recurrenceIntervalDays - 1).clamp(1, 365));
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_recurrenceIntervalDays',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() => _recurrenceIntervalDays = (_recurrenceIntervalDays + 1).clamp(1, 365));
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _recurrenceIntervalDays == 1 ? 'day' : 'days',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A new instance of this task will be created each time you complete it.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _voiceInput() async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied. Please enable it in settings.')),
        );
      }
      return;
    }

    if (!_isListening) {
      await _startListening();
    } else {
      _stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final style = themeProvider.isBigText
        ? const TextStyle(fontSize: 20)
        : const TextStyle(fontSize: 16);

    return AlertDialog(
      title: const Text('Add New Task'),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                style: style,
                decoration: InputDecoration(
                  hintText: 'What do you need to do?',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                autofocus: true,
                onChanged: _updateCategory,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showCategoryPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCategory ?? 'Auto-detecting...',
                              style: TextStyle(
                                fontSize: themeProvider.isBigText ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategory != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectDate,
                      child: Text(
                        _selectedDate != null
                            ? 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date',
                        style: TextStyle(fontSize: themeProvider.isBigText ? 16 : 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectTime,
                      child: Text(
                        _selectedTime != null
                            ? 'Time: ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select Time',
                        style: TextStyle(fontSize: themeProvider.isBigText ? 16 : 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _voiceInput,
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening ? Colors.red : null,
                    size: themeProvider.isBigText ? 20 : 18,
                  ),
                  label: Text(
                    _isListening ? 'Stop' : 'Voice Input',
                    style: TextStyle(fontSize: themeProvider.isBigText ? 14 : 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showPriorityPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: _getPriorityColor(_selectedPriority),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedPriority ?? 'No priority',
                              style: TextStyle(
                                fontSize: themeProvider.isBigText ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: _getPriorityColor(_selectedPriority),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                style: style,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagController,
                style: style,
                decoration: InputDecoration(
                  hintText: 'Add custom tag + press Enter',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTag,
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _subtaskController,
                style: style,
                decoration: InputDecoration(
                  hintText: 'Add subtask + press Enter',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSubtask,
                  ),
                ),
                onSubmitted: (_) => _addSubtask(),
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._subtasks.map((subtask) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                    title: Text(subtask, style: TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _removeSubtask(_subtasks.indexOf(subtask)),
                    ),
                  ),
                )).toList(),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showRecurringPicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: _isRecurring
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: _isRecurring
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recurring / Habit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRecurring
                                  ? 'Repeat every $_recurrenceIntervalDays day(s)'
                                  : 'Not recurring',
                              style: TextStyle(
                                fontSize: themeProvider.isBigText ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: _isRecurring
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _habitController,
                  style: style,
                  decoration: InputDecoration(
                    hintText: 'Habit tag (e.g., "exercise", "reading") - optional',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addTask,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleDarkMode(),
          ),
          SwitchListTile(
            title: const Text('Big Text Mode'),
            value: themeProvider.isBigText,
            onChanged: (_) => themeProvider.toggleBigText(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<TodoService>().deleteCompletedTodos();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Completed tasks cleared!')),
              );
            },
            child: const Text('Clear Completed Tasks'),
          ),
        ],
      ),
    );
  }
}

class EditTaskDialog extends StatefulWidget {
  final Todo todo;

  const EditTaskDialog({super.key, required this.todo});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  String? _selectedPriority;
  bool _isRecurring = false;
  int _recurrenceIntervalDays = 1;
  final TextEditingController _habitController = TextEditingController();
  final List<String> _tags = [];
  final List<String> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.todo.title;
    _selectedCategory = widget.todo.category;
    _selectedDate = widget.todo.dueDate;
    _selectedTime = widget.todo.dueDate != null ? TimeOfDay.fromDateTime(widget.todo.dueDate!) : null;
    _isRecurring = widget.todo.isRecurring;
    _recurrenceIntervalDays = widget.todo.recurrenceIntervalDays;
    _habitController.text = widget.todo.habitTag ?? '';
    _selectedPriority = widget.todo.priority;
    _notesController.text = widget.todo.notes ?? '';
    _tags.addAll(widget.todo.tags);
    _subtasks.addAll(widget.todo.subtasks);
  }

  void _updateCategory(String text) {
    final todoService = context.read<TodoService>();
    setState(() {
      _selectedCategory = todoService.categorizeTask(text);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addSubtask() {
    final subtask = _subtaskController.text.trim();
    if (subtask.isNotEmpty) {
      setState(() => _subtasks.add(subtask));
      _subtaskController.clear();
    }
  }

  void _removeSubtask(int index) {
    setState(() => _subtasks.removeAt(index));
  }

  void _showPriorityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Select Priority',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: const Text('High'),
                onTap: () {
                  setState(() => _selectedPriority = 'high');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.orange),
                title: const Text('Medium'),
                onTap: () {
                  setState(() => _selectedPriority = 'medium');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.green),
                title: const Text('Low'),
                onTap: () {
                  setState(() => _selectedPriority = 'low');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove, color: Colors.grey),
                title: const Text('No Priority'),
                onTap: () {
                  setState(() => _selectedPriority = null);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  void _showEditCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Consumer<TodoService>(
            builder: (context, todoService, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.category, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Select Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: todoService.categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ListTile(
                          leading: Icon(
                            _getCategoryIcon(category),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            category,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_cart;
      case 'chores':
        return Icons.cleaning_services;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'health':
        return Icons.favorite;
      case 'personal':
        return Icons.person;
      default:
        return Icons.label;
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final todoService = context.read<TodoService>();
    DateTime? dueDate;
    
    if (_selectedDate != null && _selectedTime != null) {
      dueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    todoService.updateTodo(
      widget.todo,
      title,
      dueDate: dueDate,
      category: _selectedCategory,
      priority: _selectedPriority,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      tags: _tags.isNotEmpty ? _tags : null,
      subtasks: _subtasks.isNotEmpty ? _subtasks : null,
      isRecurring: _isRecurring,
      habitTag: _habitController.text.trim().isEmpty ? null : _habitController.text.trim(),
      recurrenceIntervalDays: _recurrenceIntervalDays,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task updated!')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _subtaskController.dispose();
    _habitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final style = themeProvider.isBigText
        ? const TextStyle(fontSize: 20)
        : const TextStyle(fontSize: 16);

    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: style,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onChanged: _updateCategory,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showEditCategoryPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory ?? 'Select Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedCategory != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectDate,
                    child: Text(
                      _selectedDate != null
                          ? 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select Date',
                      style: style,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectTime,
                    child: Text(
                      _selectedTime != null
                          ? 'Time: ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select Time',
                      style: style,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showPriorityPicker(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: _getPriorityColor(_selectedPriority),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Priority',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedPriority ?? 'No priority',
                            style: TextStyle(
                              fontSize: themeProvider.isBigText ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: _getPriorityColor(_selectedPriority),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: style,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagController,
              style: style,
              decoration: InputDecoration(
                hintText: 'Add custom tag + press Enter',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ),
              onSubmitted: (_) => _addTag(),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                )).toList(),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _subtaskController,
              style: style,
              decoration: InputDecoration(
                hintText: 'Add subtask + press Enter',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSubtask,
                ),
              ),
              onSubmitted: (_) => _addSubtask(),
            ),
            if (_subtasks.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._subtasks.map((subtask) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                  title: Text(subtask, style: TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeSubtask(_subtasks.indexOf(subtask)),
                  ),
                ),
              )).toList(),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Task'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            if (_isRecurring) ...[
              TextField(
                controller: _habitController,
                style: style,
                decoration: const InputDecoration(
                  labelText: 'Habit Tag (e.g., daily, weekly)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Repeat every:'),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _recurrenceIntervalDays,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 day')),
                      DropdownMenuItem(value: 2, child: Text('2 days')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('1 week')),
                      DropdownMenuItem(value: 14, child: Text('2 weeks')),
                      DropdownMenuItem(value: 30, child: Text('1 month')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _recurrenceIntervalDays = value);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
