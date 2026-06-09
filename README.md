# TodoMate

A smart todo list app built with Flutter, featuring voice input, text-to-speech, and intelligent reminder notifications.

## Features

- ? **Smart Task Management** - Add, edit, complete, and organize tasks
- ?? **Intelligent Notifications** - Yes/No action buttons on reminders
- ?? **Voice Input** - Add tasks using your voice
- ?? **Text-to-Speech** - Hear your tasks read aloud
- ?? **Calendar View** - Visualize tasks on a monthly calendar
- ?? **Dark/Light Mode** - Toggle between themes
- ?? **Habit Tracking** - Track daily habits with streaks
- ?? **Categories** - Organize tasks by category
- ?? **Sorting** - Sort by priority, due date, title, or category
- ?? **Offline-First** - All data stored locally with Hive

## Requirements

- **Flutter SDK** >= 3.0.0
- **Dart SDK** >= 3.0.0 < 4.0.0
- **Android Studio** or **VS Code** with Flutter extension
- **Android device** or **emulator** (API 21+)

## Installation

### Step 1: Clone the Repository

`ash
git clone https://github.com/RajaShivani2003/todo_mate.git
cd todo_mate/todo_app
`

### Step 2: Install Dependencies

`ash
flutter pub get
`

### Step 3: Run the App

**Android Device:**
`ash
flutter run
`

**Android Emulator:**
`ash
flutter run -d <emulator_id>
`

**Windows Desktop (optional):**
`ash
flutter run -d windows
`

## Usage

### Adding a Task

1. Tap the **+**** button on the home screen
2. Enter the **task title** (or use voice input)
3. Set a **due date and time** (optional)
4. Choose a **priority** (High/Medium/Low)
5. Add **notes** or **subtasks** (optional)
6. Tap **Add** to save

### Notification Actions

When a task reaches its due time:

- **Yes, Done** - Marks the task as complete and removes the notification
- **Not Yet** - Keeps the notification visible
- **Swipe** - Notification is dismissed (normal behavior)

### Voice Input

1. Tap the **microphone icon** in the add task screen
2. Speak your task title
3. The task will be added automatically

### Calendar View

1. Navigate to the **Calendar** tab
2. Tap on any date to see tasks
3. Tasks are marked on the calendar with colored dots

### Habit Tracking

1. Create a task with a **habit tag** (e.g., exercise)
2. Complete it daily to build streaks
3. View your progress in the **Habit** tab

## Project Structure

``ntodo_app/
+-- lib/
¦   +-- main.dart              # App entry point
¦   +-- models/
¦   ¦   +-- todo.dart          # Todo data model
¦   +-- providers/
¦   ¦   +-- theme_provider.dart # Theme management
¦   +-- screens/
¦   ¦   +-- home_screen.dart   # Main UI screen
¦   +-- services/
¦   ¦   +-- todo_service.dart  # Business logic
¦   ¦   +-- notification_service.dart # Notifications
¦   +-- widgets/
¦       +-- calendar_view.dart # Calendar widget
¦       +-- daily_summary.dart # Daily summary widget
¦       +-- todo_list.dart     # Task list widget
+-- android/                   # Android platform files
+-- windows/                   # Windows platform files
+-- pubspec.yaml              # Dependencies
`

## Dependencies

| Package | Purpose |
|---------|---------|
| hive | Local database |
| hive_flutter | Hive Flutter adapter |
| flutter_local_notifications | Push notifications |
| speech_to_text | Voice input |
| flutter_tts | Text-to-speech |
| table_calendar | Calendar view |
| provider | State management |
| permission_handler | Permission management |
| shared_preferences | Settings storage |
| timezone | Timezone handling |
| uuid | Unique ID generation |

## Building for Production

### Android APK

`ash
flutter build apk --release
`

The APK will be located at:
uild/app/outputs/flutter-apk/app-release.apk

### Android App Bundle (for Play Store)

`ash
flutter build appbundle --release
`

## Troubleshooting

**Notifications not showing?**
- Go to phone Settings ? Apps ? TodoMate ? Permissions
- Enable **Notification** permission
- Enable **Exact Alarm** permission (if prompted)

**Voice input not working?**
- Go to phone Settings ? Apps ? TodoMate ? Permissions
- Enable **Microphone** permission

**App crashes on startup?**
- Make sure you have Flutter SDK >= 3.0.0
- Run lutter clean then lutter pub get

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Icons from [Material Icons](https://fonts.google.com/icons)
- Uses [Hive](https://hive.dev/) for local storage
