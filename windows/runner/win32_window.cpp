#include "win32_window.h"

#include <flutter_windows.h>

#include <algorithm>
#include <memory>
#include <string>

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Helper that allows non-client region resizing for non-client area to be
// correctly positioned.
// https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-adjustwindowrectex
void AdjustWindowRectExForDpi(HMODULE module, HWND hwnd, UINT style, BOOL menu,
                              DWORD ex_style, UINT dpi) {
  // This is a temporary workaround to enable non-client area resizing for the
  // Flutter Windows runner. It is not a complete implementation and may not
  // work for all window styles.
  RECT rect;
  GetWindowRect(hwnd, &rect);
  AdjustWindowRectExForDpi(rect, style, menu, ex_style, dpi);
  SetWindowPos(hwnd, nullptr, rect.left, rect.top, rect.right - rect.left,
               rect.bottom - rect.top, SWP_NOZORDER | SWP_NOACTIVATE);
}

}  // namespace

// Allow the number of non-empty unique instances to be tracked.
// This is only used for testing instance destruction.
Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring& title, const Point& origin,
                                const Size& size) {
  return CreateAndShowNonClientArea(kWindowClassName, title, origin, size);
}

bool Win32Window::HandleAtomics() { return true; }

void Win32Window::OnCreate() {}

void Win32Window::OnDestroy() {}

HWND Win32Window::GetHandle() const { return hwnd_; }

bool Win32Window::IsVisible() const { return is_visible_; }

bool Win32Window::CreateAndShowNonClientArea(const std::wstring& class_name,
                                             const std::wstring& title,
                                             const Point& origin,
                                             const Size& size) {
  if (!RegisterWindowClass()) {
    return false;
  }

  hwnd_ = CreateWindow(
      class_name, title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN, origin.x,
      origin.y, size.width, size.height, nullptr, nullptr, GetModuleHandle(nullptr),
      this);

  if (!hwnd_) {
    return false;
  }

  return true;
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableNonClientDpiScaling(nullptr);
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      hwnd_ = nullptr;
      is_visible_ = false;
      Destroy();
      if (IsVisible()) {
        PostQuitMessage(0);
        return 0;
      }
      break;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect;
      if (ChildContent() != nullptr) {
        // Move and resize the child window to match the client area.
        MoveWindow(ChildContent(), 0, 0, GetClientArea().width,
                   GetClientArea().height, SWP_NOZORDER | SWP_NOACTIVATE);
      }
      break;
    }

    case WM_FONTCHANGE:
      break;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

bool Win32Window::RegisterWindowClass() {
  WNDCLASS wc = {};
  wc.lpszClassName = kWindowClassName;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszMenuName = nullptr;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = 0;
  wc.lpfnWndProc = Win32Window::WndProc;

  RegisterClass(&wc);
  return true;
}
