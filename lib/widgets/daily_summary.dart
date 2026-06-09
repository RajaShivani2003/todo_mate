import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/todo_service.dart';
import '../providers/theme_provider.dart';

class DailySummary extends StatelessWidget {
  const DailySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final todoService = context.watch<TodoService>();
    final todayTodos = todoService.getTodayTodos();
    final tomorrowTodos = todoService.getTomorrowTodos();
    final todayCompleted = todoService.getTodayCompletedCount();
    final todayTotal = todoService.getTodayTotalCount();

    if (todayTotal == 0 && tomorrowTodos.isEmpty) return const SizedBox.shrink();

    final style = themeProvider.isBigText
        ? const TextStyle(fontSize: 18)
        : const TextStyle(fontSize: 14);

    return Column(
      children: [
        if (todayTotal > 0)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Today's Tasks",
                      style: themeProvider.isBigText
                          ? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                          : const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '$todayCompleted / $todayTotal completed',
                      style: TextStyle(
                        fontSize: themeProvider.isBigText ? 16 : 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: themeProvider.isBigText ? 120 : 80,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: todayTodos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final todo = todayTodos[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            size: themeProvider.isBigText ? 20 : 16,
                            color: todo.isCompleted ? Colors.green : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: style.fontSize,
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                color: todo.isCompleted ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5) : null,
                              ),
                            ),
                          ),
                          if (todo.dueDate != null)
                            Text(
                              '${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: themeProvider.isBigText ? 16 : 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (tomorrowTodos.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'Tomorrow (${tomorrowTodos.length})',
                      style: themeProvider.isBigText
                          ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          : const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...tomorrowTodos.map((todo) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            todo.isCompleted ? Icons.check : Icons.circle,
                            size: themeProvider.isBigText ? 16 : 12,
                            color: todo.isCompleted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              todo.title,
                              style: style,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }
}
