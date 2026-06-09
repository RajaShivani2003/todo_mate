import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../services/todo_service.dart';
import '../models/todo.dart';
import '../widgets/todo_list.dart';
import '../providers/theme_provider.dart';

class CalendarView extends StatefulWidget {
  final Function(BuildContext, Todo)? onEdit;

  const CalendarView({super.key, this.onEdit});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final todoService = context.watch<TodoService>();
    final allTodos = todoService.todos;

    List<Todo> getTodosForDay(DateTime day) {
      return allTodos.where((todo) {
        if (todo.dueDate == null) return false;
        final taskDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        return taskDate == DateTime(day.year, day.month, day.day);
      }).toList();
    }

    List<Todo> getSelectedDayTodos() {
      if (_selectedDay == null) return [];
      return getTodosForDay(_selectedDay!);
    }

    bool isSelectedDay(DateTime day) {
      if (_selectedDay == null) return false;
      return day.year == _selectedDay!.year &&
          day.month == _selectedDay!.month &&
          day.day == _selectedDay!.day;
    }

    bool isToday(DateTime day) {
      final now = DateTime.now();
      return day.year == now.year && day.month == now.month && day.day == now.day;
    }

    bool hasOverdue(DateTime day) {
      final todos = getTodosForDay(day);
      final now = DateTime.now();
      return todos.any((t) => t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        const SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSelectedDay(day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: getTodosForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerSize: 6,
            markerMargin: const EdgeInsets.all(1),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            formatButtonShowsNext: false,
            titleTextStyle: TextStyle(
              fontSize: themeProvider.isBigText ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final todos = getTodosForDay(day);
              final hasOverdueDay = hasOverdue(day);
              return Container(
                margin: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: themeProvider.isBigText ? 18 : 14,
                        color: hasOverdueDay ? Colors.red : null,
                        fontWeight: isToday(day) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (todos.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: todos.map((t) {
                            return Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: t.isCompleted ? Colors.green : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final todos = getTodosForDay(day);
              final hasOverdueDay = hasOverdue(day);
              return Container(
                margin: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: themeProvider.isBigText ? 18 : 14,
                        color: hasOverdueDay ? Colors.red : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (todos.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: todos.map((t) {
                            return Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: t.isCompleted ? Colors.green : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final todos = getTodosForDay(day);
              final hasOverdueDay = hasOverdue(day);
              return Container(
                margin: const EdgeInsets.all(4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: themeProvider.isBigText ? 18 : 14,
                        color: hasOverdueDay ? Colors.red : Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (todos.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: todos.map((t) {
                            return Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: t.isCompleted ? Colors.green : Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_selectedDay != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _selectedDay = null);
                  },
                ),
                Expanded(
                  child: Text(
                    'Tasks for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    style: TextStyle(
                      fontSize: themeProvider.isBigText ? 18 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TodoList(
              key: ValueKey('${todoService.version}-${_selectedDay}'),
              todos: getSelectedDayTodos(),
              emptyMessage: 'No tasks for this day',
              onEdit: widget.onEdit,
            ),
          ),
        ],
      ],
    );
  }
}
