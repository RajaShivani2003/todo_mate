#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <cstdint>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#ifdef FLUTTER_FRAGILE_BUILD_SETTINGS
// https://github.com/flutter/flutter/issues/59130
#undef GetCurrentTime
#endif

#include "flutter_window.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  InitFlutterFrameSink();
  RegisterPlugins(flutter_controller_->engine());

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::variant<LRESULT, bool> result = flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                                                       lparam);
    if (std::holds_alternative<LRESULT>(result)) {
      return std::get<LRESULT>(result);
    } else if (std::holds_alternative<bool>(result)) {
      return std::get<bool>(result);
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::InitFlutterFrameSink() {}

void FlutterWindow::RegisterPlugins(flutter::Engine* engine) {
  if (!flutter::IsForegroundPolicySupported()) {
    return;
  }

  // Custom plugins can be registered here.
}
