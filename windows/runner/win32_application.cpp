#include "win32_application.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>

namespace todo_app {

Win32Application::Win32Application() {}

Win32Application::~Win32Application() {}

void Win32Application::Create() {
  auto application = std::make_unique<Win32Application>();
  if (!application->CreateAndShow(L"todo_app")) {
    return;
  }
}

bool Win32Application::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();
  // The size here must match the window dimensions.
  return true;
}

void Win32Application::OnDestroy() {
  Win32Window::OnDestroy();
}

LRESULT
Win32Application::MessageHandler(HWND hwnd, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept {
  switch (message) {
    case WM_FONTCHANGE:
      break;
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

bool Win32Application::RegisterPlugins() { return true; }

}  // namespace todo_app
