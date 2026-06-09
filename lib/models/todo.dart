import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String? category;
  
  @HiveField(3)
  DateTime? dueDate;
  
  @HiveField(4)
  bool isCompleted;
  
  @HiveField(5)
  bool isDeleted;
  
  @HiveField(6)
  DateTime createdAt;
  
  @HiveField(7)
  String? assignedTo;
  
  @HiveField(8)
  bool isRecurring;
  
  @HiveField(9)
  String? habitTag;

  @HiveField(10)
  int recurrenceIntervalDays;

  @HiveField(11)
  int currentStreak;

  @HiveField(12)
  int longestStreak;

  @HiveField(13)
  DateTime? lastCompletedDate;

  @HiveField(14)
  int totalCompletions;

  @HiveField(15)
  String? priority;

  @HiveField(16)
  String? notes;

  @HiveField(17)
  List<String> tags;

  @HiveField(18)
  List<String> subtasks;

  @HiveField(19)
  List<bool> subtasksCompleted;

  @HiveField(20)
  bool isPinned;

  Todo({
    String? id,
    required this.title,
    this.category,
    this.dueDate,
    this.isCompleted = false,
    this.isDeleted = false,
    this.isRecurring = false,
    this.habitTag,
    this.recurrenceIntervalDays = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.totalCompletions = 0,
    this.priority,
    this.notes,
    List<String>? tags,
    List<String>? subtasks,
    List<bool>? subtasksCompleted,
    bool isPinned = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now(),
        tags = tags ?? [],
        subtasks = subtasks ?? [],
        subtasksCompleted = subtasksCompleted ?? [],
        isPinned = isPinned;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'isRecurring': isRecurring,
      'habitTag': habitTag,
      'recurrenceIntervalDays': recurrenceIntervalDays,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'totalCompletions': totalCompletions,
      'priority': priority,
      'notes': notes,
      'tags': tags,
      'subtasks': subtasks,
      'subtasksCompleted': subtasksCompleted,
      'isPinned': isPinned,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String?,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isRecurring: map['isRecurring'] as bool? ?? false,
      habitTag: map['habitTag'] as String?,
      recurrenceIntervalDays: map['recurrenceIntervalDays'] as int? ?? 1,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null ? DateTime.parse(map['lastCompletedDate']) : null,
      totalCompletions: map['totalCompletions'] as int? ?? 0,
      priority: map['priority'] as String?,
      notes: map['notes'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      subtasks: List<String>.from(map['subtasks'] ?? []),
      subtasksCompleted: List<bool>.from(map['subtasksCompleted'] ?? []),
    );
  }
}
