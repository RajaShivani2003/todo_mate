import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/todo_service.dart';
import '../services/notification_service.dart';
import '../models/todo.dart';
import '../providers/theme_provider.dart';

class TodoList extends StatefulWidget {
  final List<Todo> todos;
  final String emptyMessage;
  final Function(BuildContext, Todo)? onEdit;
  final Function(Todo)? onDelete;

  const TodoList({
    super.key,
    required this.todos,
    this.emptyMessage = '',
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final todoService = context.watch<TodoService>();
    final style = themeProvider.isBigText
        ? const TextStyle(fontSize: 18)
        : const TextStyle(fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.todos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${widget.emptyMessage} (${widget.todos.length})',
              style: themeProvider.isBigText
                  ? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  : const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          child: widget.todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap + to add your first task',
                        style: TextStyle(
                          fontSize: themeProvider.isBigText ? 20 : 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  key: ValueKey(todoService.version),
                  itemCount: widget.todos.length,
                  itemBuilder: (context, index) {
                    return _TodoItem(
                      key: ValueKey(widget.todos[index].id),
                      todo: widget.todos[index],
                      themeProvider: themeProvider,
                      style: style,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final ThemeProvider themeProvider;
  final TextStyle style;
  final Function(BuildContext, Todo)? onEdit;
  final Function(Todo)? onDelete;

  const _TodoItem({
    super.key,
    required this.todo,
    required this.themeProvider,
    required this.style,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final todoService = context.read<TodoService>();
    final color = themeProvider.isBigText ? 20.0 : 16.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: todo.isCompleted ? Colors.green : null,
                    size: color,
                  ),
                  onPressed: () => todoService.toggleComplete(todo),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: themeProvider.isBigText ? 18 : 15,
                          fontWeight: FontWeight.w600,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (todo.subtasks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...todo.subtasks.asMap().entries
                            .where((entry) {
                              int idx = entry.key;
                              return idx >= todo.subtasksCompleted.length || !todo.subtasksCompleted[idx];
                            })
                            .map((entry) {
                              int idx = entry.key;
                              String subtask = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: false,
                                      onChanged: (_) {
                                        final updated = List<bool>.from(todo.subtasksCompleted);
                                        while (updated.length <= idx) updated.add(false);
                                        updated[idx] = true;
                                        context.read<TodoService>().updateTodo(
                                          todo,
                                          todo.title,
                                          subtasksCompleted: updated,
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      side: const BorderSide(color: Colors.grey),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        subtask,
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        final updatedSubtasks = List<String>.from(todo.subtasks);
                                        final updatedCompleted = List<bool>.from(todo.subtasksCompleted);
                                        updatedSubtasks.removeAt(idx);
                                        if (idx < updatedCompleted.length) {
                                          updatedCompleted.removeAt(idx);
                                        }
                                        context.read<TodoService>().updateTodo(
                                          todo,
                                          todo.title,
                                          subtasks: updatedSubtasks,
                                          subtasksCompleted: updatedCompleted,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ],
                    ],
                  ),
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                if (!todo.isCompleted) ...[
                  IconButton(
                    icon: Icon(
                      todo.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: todo.isPinned ? Colors.amber : null,
                      size: 18,
                    ),
                    onPressed: () => todoService.togglePin(todo),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 2),
                ],
                if (onEdit != null && !todo.isCompleted) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                    onPressed: () => onEdit!(context, todo),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 2),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => onDelete != null ? onDelete!(todo) : todoService.deleteTodo(todo),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (todo.category != null || todo.notes != null || todo.dueDate != null || todo.habitTag != null || todo.isRecurring) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  if (todo.category != null)
                    Chip(
                      label: Text(
                        todo.category!,
                        style: TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  if (todo.dueDate != null)
                    Chip(
                      label: Text(
                        'Due: ${todo.dueDate!.day}/${todo.dueDate!.month}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isOverdue(todo.dueDate!) ? Colors.red : null,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  if (todo.habitTag != null)
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 10, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(todo.habitTag!, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  if (todo.isRecurring && todo.currentStreak > 0)
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat, size: 10),
                          const SizedBox(width: 2),
                          Text('${todo.currentStreak}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}
