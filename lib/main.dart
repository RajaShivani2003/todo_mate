import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'services/todo_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'models/todo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  var todosBox = await Hive.openBox<Todo>('todos');
  var settingsBox = await Hive.openBox<String>('settings');
  
  await NotificationService().initialize();
  
  final themeProvider = ThemeProvider();
  await themeProvider.loadSettings();
  
  final todoService = TodoService();
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await todoService.checkAndSpeakDueTasks();
  });
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: todoService),
      ],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Todo List',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6750A4),
                    brightness: Brightness.dark,
                  ),
                  cardTheme: const CardThemeData(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  tabBarTheme: const TabBarThemeData(
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                  floatingActionButtonTheme: const FloatingActionButtonThemeData(
                    elevation: 4,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF6750A4),
                    brightness: Brightness.light,
                  ),
                  cardTheme: const CardThemeData(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  tabBarTheme: const TabBarThemeData(
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                  floatingActionButtonTheme: const FloatingActionButtonThemeData(
                    elevation: 4,
                  ),
                ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
