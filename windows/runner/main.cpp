#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L".");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  // Set up the executable path
  auto exe_path = GetExecutablePath();
  project.set_dart_entrypoint_arguments(std::vector<std::string>{"--packages=${exe_path}\\flutter_assets\\packages"});

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow("todo_app", origin, size)) {
    return EXIT_FAILURE;
  }

  // Set foreground policy for Flutter Windows v2 Runner.
  // https://github.com/flutter/flutter/issues/59130
  flutter::SetForegroundPolicy(flutter::kForegroundPolicyNever);

  // Run message loop while message windows are still open.
  while (window.message_loop()) {
    // Perform periodic tasks.
    window.RunPulse();
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

std::wstring GetExecutablePath() {
  wchar_t path[MAX_PATH];
  GetModuleFileNameW(nullptr, path, MAX_PATH);
  auto last_slash = wcsrchr(path, L'\\');
  if (last_slash) {
    *last_slash = L'\0';
  }
  return std::wstring(path);
}
