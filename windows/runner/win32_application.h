#ifndef WIN32_APPLICATION_H_
#define WIN32_APPLICATION_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>

#include <windows.h>

#include "win32_window.h"

namespace todo_app {

class Win32Application : public Win32Window {
 public:
  Win32Application();
  ~Win32Application() override;

  // Do not call this directly.
  static void Create();

 private:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

  // Called by Create during creation.
  bool RegisterPlugins();

  std::unique_ptr<flutter::Texture> splash_texture_;
};

}  // namespace todo_app

#endif  // WIN32_APPLICATION_H_
