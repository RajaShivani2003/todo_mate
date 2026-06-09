#ifndef WIN32_WINDOW_H_
#define WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class that serves as a base class for constructing and managing win32
// windows.
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates and shows a win32 window with |title| and absolute position and
  // size with respect to the screen. For desktop apps, this is typically
  // called during app initialization.
  // Returns true if the window was successfully created.
  bool CreateAndShow(const std::wstring& title, const Point& origin,
                     const Size& size);

  // Dispatches link target messages.
  bool HandleAtomics() override;

  // Called during OnCreate after a new window is created to allow subclasses to
  // set up its contents, such as other controls.
  // This is only called during window creation, and the window must be
  // confirmed valid (i.e., valid() is true) in the implementation.
  virtual void OnCreate();

  // Called during OnDestroy during window destruction.
  // After this method is invoked, the window is in the process of being
  // destroyed and should not be referenced by the application.
  virtual void OnDestroy();

  // Helper method to retrieve the currently visible window handler, returns
  // handle to the currently visible window.
  HWND GetHandle() const;

  // Returns whether this instance is a visible window.
  bool IsVisible() const;

 protected:
  // Processes and route salient window messages for message handling.
  // Messages may be discarded by certain implementations.
  virtual LRESULT MessageHandler(HWND hwnd, UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept = 0;

  // Called in CreateAndShow to create and render a child window with the
  // |class_name| and |title|. Current process will be used as the
  // |h_instance|.
  bool CreateAndShowNonClientArea(const std::wstring& class_name,
                                  const std::wstring& title, const Point& origin,
                                  const Size& size);

 private:
  // Window procedure for the window being managed.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Registers the window class.
  static bool RegisterWindowClass();

  HWND hwnd_ = nullptr;

  // This is true if the window is currently visible.
  bool is_visible_ = false;

  // The difference between the window and client area coordinates.
  NONCLIENTMETRICS non_client_metrics_;
};

#endif  // WIN32_WINDOW_H_
