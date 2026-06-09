import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';

class TodoService extends ChangeNotifier {
  late Box<Todo> _todoBox;
  final NotificationService _notificationService = NotificationService();
  String _sortMode = 'priority';
  int _version = 0;

  int get version => _version;

  String get sortMode => _sortMode;

  void setSortMode(String mode) {
    _sortMode = mode;
    _version++;
    notifyListeners();
  }

  List<Todo> get todos {
    _todoBox = Hive.box<Todo>('todos');
    var list = _todoBox.values.where((t) => !t.isDeleted).toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      switch (_sortMode) {
        case 'dueDate':
          if (a.dueDate != null && b.dueDate == null) return -1;
          if (a.dueDate == null && b.dueDate != null) return 1;
          return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
        case 'title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'category':
          final catA = a.category ?? 'Other';
          final catB = b.category ?? 'Other';
          if (catA != catB) return catA.compareTo(catB);
          return a.title.compareTo(b.title);
        case 'priority':
        default:
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          final aPriority = priorityOrder[a.priority ?? ''] ?? 3;
          final bPriority = priorityOrder[b.priority ?? ''] ?? 3;
          if (aPriority != bPriority) return aPriority.compareTo(bPriority);
          if (a.dueDate != null && b.dueDate == null) return -1;
          if (a.dueDate == null && b.dueDate != null) return 1;
          return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
      }
    });
    return list;
  }

  List<Todo> get completedTodos {
    _todoBox = Hive.box<Todo>('todos');
    var list = _todoBox.values.where((t) => t.isCompleted && !t.isDeleted).toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return _compareForSort(a, b);
    });
    return list;
  }

  List<Todo> get pendingTodos {
    _todoBox = Hive.box<Todo>('todos');
    var list = _todoBox.values.where((t) => !t.isCompleted && !t.isDeleted).toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return _compareForSort(a, b);
    });
    return list;
  }

  int _compareForSort(Todo a, Todo b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    switch (_sortMode) {
      case 'dueDate':
        if (a.dueDate != null && b.dueDate == null) return -1;
        if (a.dueDate == null && b.dueDate != null) return 1;
        return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
      case 'title':
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case 'category':
        final catA = a.category ?? 'Other';
        final catB = b.category ?? 'Other';
        if (catA != catB) return catA.compareTo(catB);
        return a.title.compareTo(b.title);
      case 'priority':
      default:
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        final aPriority = priorityOrder[a.priority ?? ''] ?? 3;
        final bPriority = priorityOrder[b.priority ?? ''] ?? 3;
        if (aPriority != bPriority) return aPriority.compareTo(bPriority);
        if (a.dueDate != null && b.dueDate == null) return -1;
        if (a.dueDate == null && b.dueDate != null) return 1;
        return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
    }
  }

  void _applySort(List<Todo> list) {
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      switch (_sortMode) {
        case 'dueDate':
          if (a.dueDate != null && b.dueDate == null) return -1;
          if (a.dueDate == null && b.dueDate != null) return 1;
          return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
        case 'title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'category':
          final catA = a.category ?? 'Other';
          final catB = b.category ?? 'Other';
          if (catA != catB) return catA.compareTo(catB);
          return a.title.compareTo(b.title);
        case 'priority':
        default:
          final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          final aPriority = priorityOrder[a.priority ?? ''] ?? 3;
          final bPriority = priorityOrder[b.priority ?? ''] ?? 3;
          if (aPriority != bPriority) return aPriority.compareTo(bPriority);
          if (a.dueDate != null && b.dueDate == null) return -1;
          if (a.dueDate == null && b.dueDate != null) return 1;
          return (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now());
      }
    });
  }

  List<Todo> getTodayTodos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return pendingTodos.where((todo) {
      if (todo.dueDate == null) return false;
      final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return todoDate == today;
    }).toList();
  }

  List<Todo> getTomorrowTodos() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return pendingTodos.where((todo) {
      if (todo.dueDate == null) return false;
      final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return todoDate == tomorrow;
    }).toList();
  }

  int getTodayCompletedCount() {
    final todayTodos = getTodayTodos();
    return todayTodos.where((t) => t.isCompleted).length;
  }

  int getTodayTotalCount() {
    return getTodayTodos().length;
  }

  List<Todo> getCategoryTodos(String category) {
    return pendingTodos.where((t) => t.category == category).toList();
  }

  List<String> get categories {
    const categories = ['Shopping', 'Chores', 'Work', 'School', 'Health', 'Personal', 'Other'];
    return categories;
  }

  String categorizeTask(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('buy') || lower.contains('shop') || lower.contains('milk') ||
        lower.contains('food') || lower.contains('grocery')) return 'Shopping';
    if (lower.contains('clean') || lower.contains('wash') || lower.contains('dust') ||
        lower.contains('room') || lower.contains('laundry')) return 'Chores';
    if (lower.contains('meeting') || lower.contains('report') || lower.contains('email') ||
        lower.contains('work') || lower.contains('deadline')) return 'Work';
    if (lower.contains('homework') || lower.contains('study') || lower.contains('exam') ||
        lower.contains('assignment') || lower.contains('class')) return 'School';
    if (lower.contains('doctor') || lower.contains('medicine') || lower.contains('exercise') ||
        lower.contains('gym') || lower.contains('health')) return 'Health';
    if (lower.contains('personal') || lower.contains('birthday') || lower.contains('anniversary')) return 'Personal';
    return 'Other';
  }

  Future<void> addTodo(String title, {DateTime? dueDate, String? category, String? priority, String? notes, List<String>? tags, List<String>? subtasks, bool isRecurring = false, String? habitTag, int recurrenceIntervalDays = 1}) async {
    _todoBox = Hive.box<Todo>('todos');
    final finalCategory = category ?? categorizeTask(title);
    final todo = Todo(
      title: title,
      category: finalCategory,
      dueDate: dueDate,
      priority: priority,
      notes: notes,
      tags: tags ?? [],
      subtasks: subtasks ?? [],
      isRecurring: isRecurring,
      habitTag: habitTag,
      recurrenceIntervalDays: recurrenceIntervalDays,
    );
    _todoBox.add(todo);
    _version++; notifyListeners();

    if (dueDate != null) {
      final todoId = todo.id.hashCode;
      await _notificationService.scheduleNotification(
        id: todoId,
        title: 'Todo Reminder',
        body: title,
        scheduledDate: dueDate,
      );
    }
  }

  Future<void> toggleComplete(Todo todo) async {
    todo.isCompleted = !todo.isCompleted;
    todo.save();
    _version++; notifyListeners();

    if (todo.isCompleted) {
      await _notificationService.cancelNotification(todo.id.hashCode);

      if (todo.isRecurring) {
        int streak = todo.currentStreak + 1;
        int longest = streak > todo.longestStreak ? streak : todo.longestStreak;
        todo.currentStreak = streak;
        todo.longestStreak = longest;
        todo.lastCompletedDate = DateTime.now();
        todo.totalCompletions++;

        DateTime? nextDueDate;
        if (todo.dueDate != null) {
          nextDueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day)
              .add(Duration(days: todo.recurrenceIntervalDays));
          if (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0) {
            nextDueDate = nextDueDate.add(Duration(hours: todo.dueDate!.hour, minutes: todo.dueDate!.minute));
          }
        }

        Todo nextTodo = Todo(
          title: todo.title,
          category: todo.category,
          dueDate: nextDueDate,
          isRecurring: true,
          habitTag: todo.habitTag,
          recurrenceIntervalDays: todo.recurrenceIntervalDays,
          priority: todo.priority,
          notes: todo.notes,
          tags: todo.tags,
          subtasks: todo.subtasks,
          subtasksCompleted: todo.subtasksCompleted,
        );
        _todoBox = Hive.box<Todo>('todos');
        _todoBox.add(nextTodo);

        if (nextDueDate != null) {
          int nextId = nextTodo.id.hashCode;
          await _notificationService.scheduleNotification(
            id: nextId,
            title: 'Recurring Task: ${nextTodo.title}',
            body: 'This is a recurring task that started from "${todo.title}"',
            scheduledDate: nextDueDate,
            speakOnNotify: true,
          );
        }

        todo.save();
        _version++; notifyListeners();
      } else {
        todo.currentStreak = 0;
        todo.save();
      }
    } else {
      if (todo.isRecurring && todo.lastCompletedDate != null) {
        todo.currentStreak = 0;
        todo.save();
      }
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    todo.isCompleted = true;
    todo.save();
    await _notificationService.cancelNotification(todo.id.hashCode);
    _version++; notifyListeners();
  }

  Future<void> removeCompletedTodo(Todo todo) async {
    _todoBox = Hive.box<Todo>('todos');
    todo.isDeleted = true;
    todo.save();
    await _notificationService.cancelNotification(todo.id.hashCode);
    _todoBox.delete(todo.key);
    _version++; notifyListeners();
  }

  Future<void> updateTodo(Todo todo, String title, {DateTime? dueDate, String? category, String? priority, bool? isRecurring, String? habitTag, int? recurrenceIntervalDays, String? notes, List<String>? tags, List<String>? subtasks, List<bool>? subtasksCompleted}) async {
    todo.title = title;
    todo.category = category ?? categorizeTask(title);
    if (dueDate != null) todo.dueDate = dueDate;
    if (priority != null) todo.priority = priority;
    if (notes != null) todo.notes = notes;
    if (tags != null) todo.tags = tags;
    if (subtasks != null) todo.subtasks = subtasks;
    if (subtasksCompleted != null && (subtasks == null || subtasksCompleted.length == subtasks.length)) {
      todo.subtasksCompleted = subtasksCompleted;
    }
    if (isRecurring != null) todo.isRecurring = isRecurring;
    if (habitTag != null) todo.habitTag = habitTag;
    if (recurrenceIntervalDays != null) todo.recurrenceIntervalDays = recurrenceIntervalDays;
    todo.save();
    _version++; notifyListeners();

    if (dueDate != null) {
      await _notificationService.cancelNotification(todo.id.hashCode);
      final todoId = todo.id.hashCode;
      await _notificationService.scheduleNotification(
        id: todoId,
        title: 'Todo Reminder',
        body: title,
        scheduledDate: dueDate,
      );
    }
  }

  Future<void> deleteCompletedTodos() async {
    _todoBox = Hive.box<Todo>('todos');
    final completed = _todoBox.values.where((t) => t.isCompleted && t.isDeleted).toList();
    for (final todo in completed) {
      _todoBox.delete(todo.key);
    }
    _version++; notifyListeners();
  }

  Future<List<Todo>> getDailySummary() async {
    return getTodayTodos();
  }

  List<Todo> getHabitTodos(String habitTag) {
    return pendingTodos.where((t) => t.habitTag == habitTag).toList();
  }

  List<String> get allHabitTags {
    _todoBox = Hive.box<Todo>('todos');
    final tags = <String>{};
    for (final todo in _todoBox.values) {
      if (todo.habitTag != null && todo.habitTag!.isNotEmpty) {
        tags.add(todo.habitTag!);
      }
    }
    return tags.toList();
  }

  Map<String, HabitStats> getHabitStats() {
    _todoBox = Hive.box<Todo>('todos');
    final stats = <String, HabitStats>{};
    for (final todo in _todoBox.values) {
      if (todo.habitTag == null || todo.habitTag!.isEmpty) continue;
      final tag = todo.habitTag!;
      if (!stats.containsKey(tag)) {
        stats[tag] = HabitStats(
          tag: tag,
          currentStreak: 0,
          longestStreak: 0,
          totalCompletions: 0,
          lastCompletedDate: null,
        );
      }
      if (todo.currentStreak > stats[tag]!.currentStreak) {
        stats[tag] = HabitStats(
          tag: tag,
          currentStreak: todo.currentStreak,
          longestStreak: stats[tag]!.longestStreak,
          totalCompletions: stats[tag]!.totalCompletions + todo.totalCompletions,
          lastCompletedDate: todo.lastCompletedDate,
        );
      } else {
        stats[tag] = HabitStats(
          tag: tag,
          currentStreak: stats[tag]!.currentStreak,
          longestStreak: todo.longestStreak > stats[tag]!.longestStreak ? todo.longestStreak : stats[tag]!.longestStreak,
          totalCompletions: stats[tag]!.totalCompletions + todo.totalCompletions,
          lastCompletedDate: todo.lastCompletedDate,
        );
      }
    }
    return stats;
  }

  Future<void> checkAndSpeakDueTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueTasks = pendingTodos.where((todo) {
      if (todo.dueDate == null) return false;
      final taskDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return taskDate == today || taskDate == tomorrow;
    }).toList();

    if (dueTasks.isNotEmpty) {
      final taskTitles = dueTasks.map((t) => t.title).join(', ');
      await _notificationService.speakText(
        'Today you have ${dueTasks.length} tasks remaining: $taskTitles',
      );
    }
  }

  int get pendingCount {
    return pendingTodos.length;
  }

  int get completedCount {
    return completedTodos.length;
  }

  Future<void> togglePin(Todo todo) async {
    todo.isPinned = !todo.isPinned;
    todo.save();
    _version++; notifyListeners();
  }

  Future<void> rescheduleTodo(Todo todo, DateTime newDate) async {
    todo.dueDate = newDate;
    todo.save();
    _version++; notifyListeners();

    await _notificationService.cancelNotification(todo.id.hashCode);
    final todoId = todo.id.hashCode;
    await _notificationService.scheduleNotification(
      id: todoId,
      title: 'Rescheduled: ${todo.title}',
      body: 'This task was rescheduled to ${newDate.day}/${newDate.month}/${newDate.year}',
      scheduledDate: newDate,
    );
  }
}

class HabitStats {
  final String tag;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final DateTime? lastCompletedDate;

  HabitStats({
    required this.tag,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.lastCompletedDate,
  });
}
