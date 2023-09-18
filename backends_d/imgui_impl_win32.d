// dear imgui: Platform Backend for Windows (standard windows API for 32-bits AND 64-bits applications)
// This needs to be used along with a Renderer (e.g. DirectX11, OpenGL3, Vulkan..)

// Implemented features:
//  [X] Platform: Clipboard support (for Win32 this is actually part of core dear imgui)
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy VK_* values will also be supported unless IMGUI_DISABLE_OBSOLETE_KEYIO is set]
//  [X] Platform: Gamepad support. Enabled with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange'.

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

version (IMGUI_WIN32):
nothrow @nogc:

import ImGui = d_imgui.imgui;
import d_imgui.imgui_h;
import d_imgui.imgui_h : NULL;
//import d_imgui.imconfig;
/*
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
}
*/
import d_imgui;
import imgui_windows;

/+
#include <windowsx.h> // GET_X_LPARAM(), GET_Y_LPARAM()
#include <tchar.h>
#include <dwmapi.h>
+/

// Configuration flags to add in your imconfig.h file:
//#define IMGUI_IMPL_WIN32_DISABLE_GAMEPAD              // Disable gamepad support. This was meaningful before <1.81 but we now load XInput dynamically so the option is now less relevant.

// Using XInput for gamepad (will load DLL dynamically)
version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
import directx.xinput;
alias PFN_XInputGetCapabilities = extern(Windows) DWORD function(DWORD, DWORD, XINPUT_CAPABILITIES*);
alias PFN_XInputGetState = extern(Windows) DWORD function(DWORD, XINPUT_STATE*);
}

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2023-02-02: Inputs: Flipping WM_MOUSEHWHEEL (horizontal mouse-wheel) value to match other backends and offer consistent horizontal scrolling direction. (#4019, #6096, #1463)
//  2022-10-11: Using 'nullptr' instead of 'NULL' as per our switch to C++11.
//  2022-09-28: Inputs: Convert WM_CHAR values with MultiByteToWideChar() when window class was registered as MBCS (not Unicode).
//  2022-09-26: Inputs: Renamed ImGuiKey_ModXXX introduced in 1.87 to ImGuiMod_XXX (old names still supported).
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago) with io.AddKeyEvent() using ImGuiKey_ModXXX flags. Sorry for the confusion.
//  2021-01-20: Inputs: calling new io.AddKeyAnalogEvent() for gamepad support, instead of writing directly to io.NavInputs[].
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always update key mods next and before a key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-12: Inputs: Update mouse inputs using WM_MOUSEMOVE/WM_MOUSELEAVE + fallback to provide it when focused but not hovered/captured. More standard and will allow us to pass it to future input queue API.
//  2022-01-12: Inputs: Maintain our own copy of MouseButtonsDown mask instead of using ImGui::IsAnyMouseDown() which will be obsoleted.
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2021-12-16: Inputs: Fill VK_LCONTROL/VK_RCONTROL/VK_LSHIFT/VK_RSHIFT/VK_LMENU/VK_RMENU for completeness.
//  2021-08-17: Calling io.AddFocusEvent() on WM_SETFOCUS/WM_KILLFOCUS messages.
//  2021-08-02: Inputs: Fixed keyboard modifiers being reported when host window doesn't have focus.
//  2021-07-29: Inputs: MousePos is correctly reported when the host platform window is hovered but not focused (using TrackMouseEvent() to receive WM_MOUSELEAVE events).
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2021-06-08: Fixed ImGui_ImplWin32_EnableDpiAwareness() and ImGui_ImplWin32_GetDpiScaleForMonitor() to handle Windows 8.1/10 features without a manifest (per-monitor DPI, and properly calls SetProcessDpiAwareness() on 8.1).
//  2021-03-23: Inputs: Clearing keyboard down array when losing focus (WM_KILLFOCUS).
//  2021-02-18: Added ImGui_ImplWin32_EnableAlphaCompositing(). Non Visual Studio users will need to link with dwmapi.lib (MinGW/gcc: use -ldwmapi).
//  2021-02-17: Fixed ImGui_ImplWin32_EnableDpiAwareness() attempting to get SetProcessDpiAwareness from shcore.dll on Windows 8 whereas it is only supported on Windows 8.1.
//  2021-01-25: Inputs: Dynamically loading XInput DLL.
//  2020-12-04: Misc: Fixed setting of io.DisplaySize to invalid/uninitialized data when after hwnd has been closed.
//  2020-03-03: Inputs: Calling AddInputCharacterUTF16() to support surrogate pairs leading to codepoint >= 0x10000 (for more complete CJK inputs)
//  2020-02-17: Added ImGui_ImplWin32_EnableDpiAwareness(), ImGui_ImplWin32_GetDpiScaleForHwnd(), ImGui_ImplWin32_GetDpiScaleForMonitor() helper functions.
//  2020-01-14: Inputs: Added support for #define IMGUI_IMPL_WIN32_DISABLE_GAMEPAD/IMGUI_IMPL_WIN32_DISABLE_LINKING_XINPUT.
//  2019-12-05: Inputs: Added support for ImGuiMouseCursor_NotAllowed mouse cursor.
//  2019-05-11: Inputs: Don't filter value from WM_CHAR before calling AddInputCharacter().
//  2019-01-17: Misc: Using GetForegroundWindow()+IsChild() instead of GetActiveWindow() to be compatible with windows created in a different thread or parent.
//  2019-01-17: Inputs: Added support for mouse buttons 4 and 5 via WM_XBUTTON* messages.
//  2019-01-15: Inputs: Added support for XInput gamepads (if ImGuiConfigFlags_NavEnableGamepad is set by user application).
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
//  2018-06-10: Inputs: Fixed handling of mouse wheel messages to support fine position messages (typically sent by track-pads).
//  2018-06-08: Misc: Extracted imgui_impl_win32.cpp/.h away from the old combined DX9/DX10/DX11/DX12 examples.
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors and ImGuiBackendFlags_HasSetMousePos flags + honor ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-02-20: Inputs: Added support for mouse cursors (ImGui::GetMouseCursor() value and WM_SETCURSOR message handling).
//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
//  2018-02-06: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and ImGuiConfigFlags_NavMoveMouse is set).
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-08: Inputs: Added mapping for ImGuiKey_Insert.
//  2018-01-05: Inputs: Added WM_LBUTTONDBLCLK double-click handlers for window classes with the CS_DBLCLKS flag.
//  2017-10-23: Inputs: Added WM_SYSKEYDOWN / WM_SYSKEYUP handlers so e.g. the VK_MENU key can be read.
//  2017-10-23: Inputs: Using Win32 ::SetCapture/::GetCapture() to retrieve mouse positions outside the client area when dragging.
//  2016-11-12: Inputs: Only call Win32 ::SetCursor(nullptr) when io.MouseDrawCursor is set.

struct ImGui_ImplWin32_Data
{
    HWND                        hWnd;
    HWND                        MouseHwnd;
    bool                        MouseTracked;
    int                         MouseButtonsDown;
    INT64                       Time;
    INT64                       TicksPerSecond;
    ImGuiMouseCursor            LastMouseCursor;

version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
    bool                        HasGamepad;
    bool                        WantUpdateHasGamepad;
    HMODULE                     XInputDLL;
    PFN_XInputGetCapabilities   XInputGetCapabilities;
    PFN_XInputGetState          XInputGetState;
}

    //ImGui_ImplWin32_Data()      { memset((void*)this, 0, sizeof(*this)); }
}

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
static ImGui_ImplWin32_Data* ImGui_ImplWin32_GetBackendData()
{
    return ImGui.GetCurrentContext() ? cast(ImGui_ImplWin32_Data*)ImGui.GetIO().BackendPlatformUserData : null;
}

// Functions
bool    ImGui_ImplWin32_Init(void* hwnd)
{
    ImGuiIO* io = &ImGui.GetIO();
    IM_ASSERT(io.BackendPlatformUserData == null, "Already initialized a platform backend!");

    INT64 perf_frequency, perf_counter;
    if (!QueryPerformanceFrequency(cast(LARGE_INTEGER*)&perf_frequency))
        return false;
    if (!QueryPerformanceCounter(cast(LARGE_INTEGER*)&perf_counter))
        return false;

    // Setup backend capabilities flags
    ImGui_ImplWin32_Data* bd = IM_NEW!(ImGui_ImplWin32_Data)();
    io.BackendPlatformUserData = cast(void*)bd;
    io.BackendPlatformName = "imgui_impl_win32";
    io.BackendFlags |= ImGuiBackendFlags.HasMouseCursors;         // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags.HasSetMousePos;          // We can honor io.WantSetMousePos requests (optional, rarely used)

    bd.hWnd = cast(HWND)hwnd;
    bd.TicksPerSecond = perf_frequency;
    bd.Time = perf_counter;
    bd.LastMouseCursor = ImGuiMouseCursor.COUNT;

    // Set platform dependent data in viewport
    ImGui.GetMainViewport().PlatformHandleRaw = cast(void*)hwnd;

    // Dynamically load XInput library
version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
    bd.WantUpdateHasGamepad = true;
    string[5] xinput_dll_names =
    [
        "xinput1_4.dll",   // Windows 8+
        "xinput1_3.dll",   // DirectX SDK
        "xinput9_1_0.dll", // Windows Vista, Windows 7
        "xinput1_2.dll",   // DirectX SDK
        "xinput1_1.dll"    // DirectX SDK
    ];
    for (int n = 0; n < IM_ARRAYSIZE(xinput_dll_names); n++)
        if (HMODULE dll = LoadLibraryA(xinput_dll_names[n].ptr))
        {
            bd.XInputDLL = dll;
            bd.XInputGetCapabilities = cast(PFN_XInputGetCapabilities)GetProcAddress(dll, "XInputGetCapabilities");
            bd.XInputGetState = cast(PFN_XInputGetState)GetProcAddress(dll, "XInputGetState");
            break;
        }
} // IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

    return true;
}

void    ImGui_ImplWin32_Shutdown()
{
    ImGui_ImplWin32_Data* bd = ImGui_ImplWin32_GetBackendData();
    IM_ASSERT(bd != null, "No platform backend to shutdown, or already shutdown?");
    ImGuiIO* io = &ImGui.GetIO();

    // Unload XInput library
version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
    if (bd.XInputDLL)
        FreeLibrary(bd.XInputDLL);
} // IMGUI_IMPL_WIN32_DISABLE_GAMEPAD

    io.BackendPlatformName = null;
    io.BackendPlatformUserData = null;
    IM_DELETE(bd);
}

static bool ImGui_ImplWin32_UpdateMouseCursor()
{
    ImGuiIO* io = &ImGui.GetIO();
    if (io.ConfigFlags & ImGuiConfigFlags.NoMouseCursorChange)
        return false;

    ImGuiMouseCursor imgui_cursor = ImGui.GetMouseCursor();
    if (imgui_cursor == ImGuiMouseCursor.None || io.MouseDrawCursor)
    {
        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
        SetCursor(null);
    }
    else
    {
        // Show OS mouse cursor
        LPTSTR win32_cursor = IDC_ARROW;
        switch (imgui_cursor)
        {
        case ImGuiMouseCursor.Arrow:        win32_cursor = IDC_ARROW; break;
        case ImGuiMouseCursor.TextInput:    win32_cursor = IDC_IBEAM; break;
        case ImGuiMouseCursor.ResizeAll:    win32_cursor = IDC_SIZEALL; break;
        case ImGuiMouseCursor.ResizeEW:     win32_cursor = IDC_SIZEWE; break;
        case ImGuiMouseCursor.ResizeNS:     win32_cursor = IDC_SIZENS; break;
        case ImGuiMouseCursor.ResizeNESW:   win32_cursor = IDC_SIZENESW; break;
        case ImGuiMouseCursor.ResizeNWSE:   win32_cursor = IDC_SIZENWSE; break;
        case ImGuiMouseCursor.Hand:         win32_cursor = IDC_HAND; break;
        case ImGuiMouseCursor.NotAllowed:   win32_cursor = IDC_NO; break;
        default: break;
        }
        SetCursor(LoadCursor(null, win32_cursor));
    }
    return true;
}

static bool IsVkDown(int vk)
{
    return (GetKeyState(vk) & 0x8000) != 0;
}

static void ImGui_ImplWin32_AddKeyEvent(ImGuiKey key, bool down, int native_keycode, int native_scancode = -1)
{
    ImGuiIO* io = &ImGui.GetIO();
    io.AddKeyEvent(key, down);
    io.SetKeyEventNativeData(key, native_keycode, native_scancode); // To support legacy indexing (<1.87 user code)
    IM_UNUSED(native_scancode);
}

static void ImGui_ImplWin32_ProcessKeyEventsWorkarounds()
{
    // Left & right Shift keys: when both are pressed together, Windows tend to not generate the WM_KEYUP event for the first released one.
    if (ImGui.IsKeyDown(ImGuiKey.LeftShift) && !IsVkDown(VK_LSHIFT))
        ImGui_ImplWin32_AddKeyEvent(ImGuiKey.LeftShift, false, VK_LSHIFT);
    if (ImGui.IsKeyDown(ImGuiKey.RightShift) && !IsVkDown(VK_RSHIFT))
        ImGui_ImplWin32_AddKeyEvent(ImGuiKey.RightShift, false, VK_RSHIFT);

    // Sometimes WM_KEYUP for Win key is not passed down to the app (e.g. for Win+V on some setups, according to GLFW).
    if (ImGui.IsKeyDown(ImGuiKey.LeftSuper) && !IsVkDown(VK_LWIN))
        ImGui_ImplWin32_AddKeyEvent(ImGuiKey.LeftSuper, false, VK_LWIN);
    if (ImGui.IsKeyDown(ImGuiKey.RightSuper) && !IsVkDown(VK_RWIN))
        ImGui_ImplWin32_AddKeyEvent(ImGuiKey.RightSuper, false, VK_RWIN);
}

static void ImGui_ImplWin32_UpdateKeyModifiers()
{
    ImGuiIO* io = &ImGui.GetIO();
    io.AddKeyEvent(ImGuiMod.Ctrl, IsVkDown(VK_CONTROL));
    io.AddKeyEvent(ImGuiMod.Shift, IsVkDown(VK_SHIFT));
    io.AddKeyEvent(ImGuiMod.Alt, IsVkDown(VK_MENU));
    io.AddKeyEvent(ImGuiMod.Super, IsVkDown(VK_APPS));
}

static void ImGui_ImplWin32_UpdateMouseData()
{
    ImGui_ImplWin32_Data* bd = ImGui_ImplWin32_GetBackendData();
    ImGuiIO* io = &ImGui.GetIO();
    IM_ASSERT(bd.hWnd != null);

    HWND focused_window = GetForegroundWindow();
    const bool is_app_focused = (focused_window == bd.hWnd);
    if (is_app_focused)
    {
        // (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when ImGuiConfigFlags_NavEnableSetMousePos is enabled by user)
        if (io.WantSetMousePos)
        {
            POINT pos = { cast(int)io.MousePos.x, cast(int)io.MousePos.y };
            if (ClientToScreen(bd.hWnd, &pos))
                SetCursorPos(pos.x, pos.y);
        }

        // (Optional) Fallback to provide mouse position when focused (WM_MOUSEMOVE already provides this when hovered or captured)
        if (!io.WantSetMousePos && !bd.MouseTracked)
        {
            POINT pos;
            if (GetCursorPos(&pos) && ScreenToClient(bd.hWnd, &pos))
                io.AddMousePosEvent(cast(float)pos.x, cast(float)pos.y);
        }
    }
}

// Gamepad navigation mapping
static void ImGui_ImplWin32_UpdateGamepads()
{
version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
    ImGuiIO* io = &ImGui.GetIO();
    ImGui_ImplWin32_Data* bd = ImGui_ImplWin32_GetBackendData();
    //if ((io.ConfigFlags & ImGuiConfigFlags_NavEnableGamepad) == 0) // FIXME: Technically feeding gamepad shouldn't depend on this now that they are regular inputs.
    //    return;

    // Calling XInputGetState() every frame on disconnected gamepads is unfortunately too slow.
    // Instead we refresh gamepad availability by calling XInputGetCapabilities() _only_ after receiving WM_DEVICECHANGE.
    if (bd.WantUpdateHasGamepad)
    {
        XINPUT_CAPABILITIES caps = {};
        bd.HasGamepad = bd.XInputGetCapabilities ? (bd.XInputGetCapabilities(0, XINPUT_FLAG_GAMEPAD, &caps) == ERROR_SUCCESS) : false;
        bd.WantUpdateHasGamepad = false;
    }

    io.BackendFlags &= ~ImGuiBackendFlags.HasGamepad;
    XINPUT_STATE xinput_state;
    XINPUT_GAMEPAD* gamepad = &xinput_state.Gamepad;
    if (!bd.HasGamepad || bd.XInputGetState == null || bd.XInputGetState(0, &xinput_state) != ERROR_SUCCESS)
        return;
    io.BackendFlags |= ImGuiBackendFlags.HasGamepad;

    pragma(inline, true) float IM_SATURATE(float V)                      { return (V < 0.0f ? 0.0f : V > 1.0f ? 1.0f : V); }
    pragma(inline, true) void MAP_BUTTON(ImGuiKey KEY_NO, int BUTTON_ENUM)     { io.AddKeyEvent(KEY_NO, (gamepad.wButtons & BUTTON_ENUM) != 0); }
    pragma(inline, true) void MAP_ANALOG(ImGuiKey KEY_NO, int VALUE, int V0, int V1)   { float vn = cast(float)(VALUE - V0) / cast(float)(V1 - V0); io.AddKeyAnalogEvent(KEY_NO, vn > 0.10f, IM_SATURATE(vn)); }
    MAP_BUTTON(ImGuiKey.GamepadStart,           XINPUT_GAMEPAD_START);
    MAP_BUTTON(ImGuiKey.GamepadBack,            XINPUT_GAMEPAD_BACK);
    MAP_BUTTON(ImGuiKey.GamepadFaceLeft,        XINPUT_GAMEPAD_X);
    MAP_BUTTON(ImGuiKey.GamepadFaceRight,       XINPUT_GAMEPAD_B);
    MAP_BUTTON(ImGuiKey.GamepadFaceUp,          XINPUT_GAMEPAD_Y);
    MAP_BUTTON(ImGuiKey.GamepadFaceDown,        XINPUT_GAMEPAD_A);
    MAP_BUTTON(ImGuiKey.GamepadDpadLeft,        XINPUT_GAMEPAD_DPAD_LEFT);
    MAP_BUTTON(ImGuiKey.GamepadDpadRight,       XINPUT_GAMEPAD_DPAD_RIGHT);
    MAP_BUTTON(ImGuiKey.GamepadDpadUp,          XINPUT_GAMEPAD_DPAD_UP);
    MAP_BUTTON(ImGuiKey.GamepadDpadDown,        XINPUT_GAMEPAD_DPAD_DOWN);
    MAP_BUTTON(ImGuiKey.GamepadL1,              XINPUT_GAMEPAD_LEFT_SHOULDER);
    MAP_BUTTON(ImGuiKey.GamepadR1,              XINPUT_GAMEPAD_RIGHT_SHOULDER);
    MAP_ANALOG(ImGuiKey.GamepadL2,              gamepad.bLeftTrigger, XINPUT_GAMEPAD_TRIGGER_THRESHOLD, 255);
    MAP_ANALOG(ImGuiKey.GamepadR2,              gamepad.bRightTrigger, XINPUT_GAMEPAD_TRIGGER_THRESHOLD, 255);
    MAP_BUTTON(ImGuiKey.GamepadL3,              XINPUT_GAMEPAD_LEFT_THUMB);
    MAP_BUTTON(ImGuiKey.GamepadR3,              XINPUT_GAMEPAD_RIGHT_THUMB);
    MAP_ANALOG(ImGuiKey.GamepadLStickLeft,      gamepad.sThumbLX, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768);
    MAP_ANALOG(ImGuiKey.GamepadLStickRight,     gamepad.sThumbLX, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767);
    MAP_ANALOG(ImGuiKey.GamepadLStickUp,        gamepad.sThumbLY, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767);
    MAP_ANALOG(ImGuiKey.GamepadLStickDown,      gamepad.sThumbLY, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768);
    MAP_ANALOG(ImGuiKey.GamepadRStickLeft,      gamepad.sThumbRX, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768);
    MAP_ANALOG(ImGuiKey.GamepadRStickRight,     gamepad.sThumbRX, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767);
    MAP_ANALOG(ImGuiKey.GamepadRStickUp,        gamepad.sThumbRY, +XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, +32767);
    MAP_ANALOG(ImGuiKey.GamepadRStickDown,      gamepad.sThumbRY, -XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE, -32768);
    //#undef MAP_BUTTON
    //#undef MAP_ANALOG
} // #ifndef IMGUI_IMPL_WIN32_DISABLE_GAMEPAD
}

void    ImGui_ImplWin32_NewFrame()
{
    ImGuiIO* io = &ImGui.GetIO();
    ImGui_ImplWin32_Data* bd = ImGui_ImplWin32_GetBackendData();
    IM_ASSERT(bd != null, "Did you call ImGui_ImplWin32_Init()?");

    // Setup display size (every frame to accommodate for window resizing)
    RECT rect = { 0, 0, 0, 0 };
    GetClientRect(bd.hWnd, &rect);
    io.DisplaySize = ImVec2(cast(float)(rect.right - rect.left), cast(float)(rect.bottom - rect.top));

    // Setup time step
    INT64 current_time = 0;
    QueryPerformanceCounter(cast(LARGE_INTEGER*)&current_time);
    io.DeltaTime = cast(float)(current_time - bd.Time) / bd.TicksPerSecond;
    bd.Time = current_time;

    // Update OS mouse position
    ImGui_ImplWin32_UpdateMouseData();

    // Process workarounds for known Windows key handling issues
    ImGui_ImplWin32_ProcessKeyEventsWorkarounds();

    // Update OS mouse cursor with the cursor requested by imgui
    ImGuiMouseCursor mouse_cursor = io.MouseDrawCursor ? ImGuiMouseCursor.None : ImGui.GetMouseCursor();
    if (bd.LastMouseCursor != mouse_cursor)
    {
        bd.LastMouseCursor = mouse_cursor;
        ImGui_ImplWin32_UpdateMouseCursor();
    }

    // Update game controllers (if enabled and available)
    ImGui_ImplWin32_UpdateGamepads();
}

// There is no distinct VK_xxx for keypad enter, instead it is VK_RETURN + KF_EXTENDED, we assign it an arbitrary value to make code more readable (VK_ codes go up to 255)
enum IM_VK_KEYPAD_ENTER      = (VK_RETURN + 256);

// Map VK_xxx to ImGuiKey_xxx.
static ImGuiKey ImGui_ImplWin32_VirtualKeyToImGuiKey(WPARAM wParam)
{
    switch (wParam)
    {
        case VK_TAB: return ImGuiKey.Tab;
        case VK_LEFT: return ImGuiKey.LeftArrow;
        case VK_RIGHT: return ImGuiKey.RightArrow;
        case VK_UP: return ImGuiKey.UpArrow;
        case VK_DOWN: return ImGuiKey.DownArrow;
        case VK_PRIOR: return ImGuiKey.PageUp;
        case VK_NEXT: return ImGuiKey.PageDown;
        case VK_HOME: return ImGuiKey.Home;
        case VK_END: return ImGuiKey.End;
        case VK_INSERT: return ImGuiKey.Insert;
        case VK_DELETE: return ImGuiKey.Delete;
        case VK_BACK: return ImGuiKey.Backspace;
        case VK_SPACE: return ImGuiKey.Space;
        case VK_RETURN: return ImGuiKey.Enter;
        case VK_ESCAPE: return ImGuiKey.Escape;
        case VK_OEM_7: return ImGuiKey.Apostrophe;
        case VK_OEM_COMMA: return ImGuiKey.Comma;
        case VK_OEM_MINUS: return ImGuiKey.Minus;
        case VK_OEM_PERIOD: return ImGuiKey.Period;
        case VK_OEM_2: return ImGuiKey.Slash;
        case VK_OEM_1: return ImGuiKey.Semicolon;
        case VK_OEM_PLUS: return ImGuiKey.Equal;
        case VK_OEM_4: return ImGuiKey.LeftBracket;
        case VK_OEM_5: return ImGuiKey.Backslash;
        case VK_OEM_6: return ImGuiKey.RightBracket;
        case VK_OEM_3: return ImGuiKey.GraveAccent;
        case VK_CAPITAL: return ImGuiKey.CapsLock;
        case VK_SCROLL: return ImGuiKey.ScrollLock;
        case VK_NUMLOCK: return ImGuiKey.NumLock;
        case VK_SNAPSHOT: return ImGuiKey.PrintScreen;
        case VK_PAUSE: return ImGuiKey.Pause;
        case VK_NUMPAD0: return ImGuiKey.Keypad0;
        case VK_NUMPAD1: return ImGuiKey.Keypad1;
        case VK_NUMPAD2: return ImGuiKey.Keypad2;
        case VK_NUMPAD3: return ImGuiKey.Keypad3;
        case VK_NUMPAD4: return ImGuiKey.Keypad4;
        case VK_NUMPAD5: return ImGuiKey.Keypad5;
        case VK_NUMPAD6: return ImGuiKey.Keypad6;
        case VK_NUMPAD7: return ImGuiKey.Keypad7;
        case VK_NUMPAD8: return ImGuiKey.Keypad8;
        case VK_NUMPAD9: return ImGuiKey.Keypad9;
        case VK_DECIMAL: return ImGuiKey.KeypadDecimal;
        case VK_DIVIDE: return ImGuiKey.KeypadDivide;
        case VK_MULTIPLY: return ImGuiKey.KeypadMultiply;
        case VK_SUBTRACT: return ImGuiKey.KeypadSubtract;
        case VK_ADD: return ImGuiKey.KeypadAdd;
        case IM_VK_KEYPAD_ENTER: return ImGuiKey.KeypadEnter;
        case VK_LSHIFT: return ImGuiKey.LeftShift;
        case VK_LCONTROL: return ImGuiKey.LeftCtrl;
        case VK_LMENU: return ImGuiKey.LeftAlt;
        case VK_LWIN: return ImGuiKey.LeftSuper;
        case VK_RSHIFT: return ImGuiKey.RightShift;
        case VK_RCONTROL: return ImGuiKey.RightCtrl;
        case VK_RMENU: return ImGuiKey.RightAlt;
        case VK_RWIN: return ImGuiKey.RightSuper;
        case VK_APPS: return ImGuiKey.Menu;
        case '0': return ImGuiKey._0;
        case '1': return ImGuiKey._1;
        case '2': return ImGuiKey._2;
        case '3': return ImGuiKey._3;
        case '4': return ImGuiKey._4;
        case '5': return ImGuiKey._5;
        case '6': return ImGuiKey._6;
        case '7': return ImGuiKey._7;
        case '8': return ImGuiKey._8;
        case '9': return ImGuiKey._9;
        case 'A': return ImGuiKey.A;
        case 'B': return ImGuiKey.B;
        case 'C': return ImGuiKey.C;
        case 'D': return ImGuiKey.D;
        case 'E': return ImGuiKey.E;
        case 'F': return ImGuiKey.F;
        case 'G': return ImGuiKey.G;
        case 'H': return ImGuiKey.H;
        case 'I': return ImGuiKey.I;
        case 'J': return ImGuiKey.J;
        case 'K': return ImGuiKey.K;
        case 'L': return ImGuiKey.L;
        case 'M': return ImGuiKey.M;
        case 'N': return ImGuiKey.N;
        case 'O': return ImGuiKey.O;
        case 'P': return ImGuiKey.P;
        case 'Q': return ImGuiKey.Q;
        case 'R': return ImGuiKey.R;
        case 'S': return ImGuiKey.S;
        case 'T': return ImGuiKey.T;
        case 'U': return ImGuiKey.U;
        case 'V': return ImGuiKey.V;
        case 'W': return ImGuiKey.W;
        case 'X': return ImGuiKey.X;
        case 'Y': return ImGuiKey.Y;
        case 'Z': return ImGuiKey.Z;
        case VK_F1: return ImGuiKey.F1;
        case VK_F2: return ImGuiKey.F2;
        case VK_F3: return ImGuiKey.F3;
        case VK_F4: return ImGuiKey.F4;
        case VK_F5: return ImGuiKey.F5;
        case VK_F6: return ImGuiKey.F6;
        case VK_F7: return ImGuiKey.F7;
        case VK_F8: return ImGuiKey.F8;
        case VK_F9: return ImGuiKey.F9;
        case VK_F10: return ImGuiKey.F10;
        case VK_F11: return ImGuiKey.F11;
        case VK_F12: return ImGuiKey.F12;
        default: return ImGuiKey.None;
    }
}

// Allow compilation with old Windows SDK. MinGW doesn't have default _WIN32_WINNT/WINVER versions.
/+
#ifndef WM_MOUSEHWHEEL
#define WM_MOUSEHWHEEL 0x020E
}
#ifndef DBT_DEVNODES_CHANGED
#define DBT_DEVNODES_CHANGED 0x0007
}
+/

// Win32 message handler (process Win32 mouse/keyboard inputs, etc.)
// Call from your application's message handler. Keep calling your message handler unless this function returns TRUE.
// When implementing your own backend, you can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if Dear ImGui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application, or clear/overwrite your copy of the mouse data.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application, or clear/overwrite your copy of the keyboard data.
// Generally you may always pass all inputs to Dear ImGui, and hide them from your application based on those two flags.
// PS: In this Win32 handler, we use the capture API (GetCapture/SetCapture/ReleaseCapture) to be able to read mouse coordinates when dragging mouse outside of our window bounds.
// PS: We treat DBLCLK messages as regular mouse down messages, so this code will work on windows classes that have the CS_DBLCLKS flag set. Our own example app code doesn't set this flag.
static if (false) {
// Copy this line into your .cpp file to forward declare the function.
extern LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
}
LRESULT ImGui_ImplWin32_WndProcHandler(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui.GetCurrentContext() == null)
        return 0;

    ImGuiIO* io = &ImGui.GetIO();
    ImGui_ImplWin32_Data* bd = ImGui_ImplWin32_GetBackendData();

    switch (msg)
    {
    case WM_MOUSEMOVE:
    {
        // We need to call TrackMouseEvent in order to receive WM_MOUSELEAVE events
        bd.MouseHwnd = hwnd;
        if (!bd.MouseTracked)
        {
            TRACKMOUSEEVENT tme = { sizeof!(TRACKMOUSEEVENT), TME_LEAVE, hwnd, 0 };
            TrackMouseEvent(&tme);
            bd.MouseTracked = true;
        }
        POINT mouse_pos = { cast(LONG)GET_X_LPARAM(lParam), cast(LONG)GET_Y_LPARAM(lParam) };
        io.AddMousePosEvent(cast(float)mouse_pos.x, cast(float)mouse_pos.y);
        break;
    }
    case WM_MOUSELEAVE:
        if (bd.MouseHwnd == hwnd)
            bd.MouseHwnd = null;
        bd.MouseTracked = false;
        io.AddMousePosEvent(-FLT_MAX, -FLT_MAX);
        break;
    case WM_LBUTTONDOWN: case WM_LBUTTONDBLCLK:
    case WM_RBUTTONDOWN: case WM_RBUTTONDBLCLK:
    case WM_MBUTTONDOWN: case WM_MBUTTONDBLCLK:
    case WM_XBUTTONDOWN: case WM_XBUTTONDBLCLK:
    {
        int button = 0;
        if (msg == WM_LBUTTONDOWN || msg == WM_LBUTTONDBLCLK) { button = 0; }
        if (msg == WM_RBUTTONDOWN || msg == WM_RBUTTONDBLCLK) { button = 1; }
        if (msg == WM_MBUTTONDOWN || msg == WM_MBUTTONDBLCLK) { button = 2; }
        if (msg == WM_XBUTTONDOWN || msg == WM_XBUTTONDBLCLK) { button = (GET_XBUTTON_WPARAM(wParam) == XBUTTON1) ? 3 : 4; }
        if (bd.MouseButtonsDown == 0 && GetCapture() == null)
            SetCapture(hwnd);
        bd.MouseButtonsDown |= 1 << button;
        io.AddMouseButtonEvent(button, true);
        return 0;
    }
    case WM_LBUTTONUP:
    case WM_RBUTTONUP:
    case WM_MBUTTONUP:
    case WM_XBUTTONUP:
    {
        int button = 0;
        if (msg == WM_LBUTTONUP) { button = 0; }
        if (msg == WM_RBUTTONUP) { button = 1; }
        if (msg == WM_MBUTTONUP) { button = 2; }
        if (msg == WM_XBUTTONUP) { button = (GET_XBUTTON_WPARAM(wParam) == XBUTTON1) ? 3 : 4; }
        bd.MouseButtonsDown &= ~(1 << button);
        if (bd.MouseButtonsDown == 0 && GetCapture() == hwnd)
            ReleaseCapture();
        io.AddMouseButtonEvent(button, false);
        return 0;
    }
    case WM_MOUSEWHEEL:
        io.AddMouseWheelEvent(0.0f, cast(float)GET_WHEEL_DELTA_WPARAM(wParam) / cast(float)WHEEL_DELTA);
        return 0;
    case WM_MOUSEHWHEEL:
        io.AddMouseWheelEvent(-cast(float)GET_WHEEL_DELTA_WPARAM(wParam) / cast(float)WHEEL_DELTA, 0.0f);
        return 0;
    case WM_KEYDOWN:
    case WM_KEYUP:
    case WM_SYSKEYDOWN:
    case WM_SYSKEYUP:
    {
        const bool is_key_down = (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN);
        if (wParam < 256)
        {
            // Submit modifiers
            ImGui_ImplWin32_UpdateKeyModifiers();

            // Obtain virtual key code
            // (keypad enter doesn't have its own... VK_RETURN with KF_EXTENDED flag means keypad enter, see IM_VK_KEYPAD_ENTER definition for details, it is mapped to ImGuiKey_KeyPadEnter.)
            int vk = cast(int)wParam;
            if ((wParam == VK_RETURN) && (HIWORD(lParam) & KF_EXTENDED))
                vk = IM_VK_KEYPAD_ENTER;

            // Submit key event
            const ImGuiKey key = ImGui_ImplWin32_VirtualKeyToImGuiKey(vk);
            const int scancode = cast(int)LOBYTE(HIWORD(lParam));
            if (key != ImGuiKey.None)
                ImGui_ImplWin32_AddKeyEvent(key, is_key_down, vk, scancode);

            // Submit individual left/right modifier events
            if (vk == VK_SHIFT)
            {
                // Important: Shift keys tend to get stuck when pressed together, missing key-up events are corrected in ImGui_ImplWin32_ProcessKeyEventsWorkarounds()
                if (IsVkDown(VK_LSHIFT) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.LeftShift, is_key_down, VK_LSHIFT, scancode); }
                if (IsVkDown(VK_RSHIFT) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.RightShift, is_key_down, VK_RSHIFT, scancode); }
            }
            else if (vk == VK_CONTROL)
            {
                if (IsVkDown(VK_LCONTROL) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.LeftCtrl, is_key_down, VK_LCONTROL, scancode); }
                if (IsVkDown(VK_RCONTROL) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.RightCtrl, is_key_down, VK_RCONTROL, scancode); }
            }
            else if (vk == VK_MENU)
            {
                if (IsVkDown(VK_LMENU) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.LeftAlt, is_key_down, VK_LMENU, scancode); }
                if (IsVkDown(VK_RMENU) == is_key_down) { ImGui_ImplWin32_AddKeyEvent(ImGuiKey.RightAlt, is_key_down, VK_RMENU, scancode); }
            }
        }
        return 0;
    }
    case WM_SETFOCUS:
    case WM_KILLFOCUS:
        io.AddFocusEvent(msg == WM_SETFOCUS);
        return 0;
    case WM_CHAR:
        if (IsWindowUnicode(hwnd))
        {
            // You can also use ToAscii()+GetKeyboardState() to retrieve characters.
            if (wParam > 0 && wParam < 0x10000)
                io.AddInputCharacterUTF16(cast(ushort)wParam);
        }
        else
        {
            wchar wch = 0;
            MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, cast(char*)&wParam, 1, &wch, 1);
            io.AddInputCharacter(wch);
        }
        return 0;
    case WM_SETCURSOR:
        // This is required to restore cursor when transitioning from e.g resize borders to client area.
        if (LOWORD(lParam) == HTCLIENT && ImGui_ImplWin32_UpdateMouseCursor())
            return 1;
        return 0;
    case WM_DEVICECHANGE:
version (IMGUI_IMPL_WIN32_DISABLE_GAMEPAD) {} else {
        if (cast(UINT)wParam == DBT_DEVNODES_CHANGED)
            bd.WantUpdateHasGamepad = true;
}
        return 0;
    default:
        break;
    }
    return 0;
}


//--------------------------------------------------------------------------------------------------------
// DPI-related helpers (optional)
//--------------------------------------------------------------------------------------------------------
// - Use to enable DPI awareness without having to create an application manifest.
// - Your own app may already do this via a manifest or explicit calls. This is mostly useful for our examples/ apps.
// - In theory we could call simple functions from Windows SDK such as SetProcessDPIAware(), SetProcessDpiAwareness(), etc.
//   but most of the functions provided by Microsoft require Windows 8.1/10+ SDK at compile time and Windows 8/10+ at runtime,
//   neither we want to require the user to have. So we dynamically select and load those functions to avoid dependencies.
//---------------------------------------------------------------------------------------------------------
// This is the scheme successfully used by GLFW (from which we borrowed some of the code) and other apps aiming to be highly portable.
// ImGui_ImplWin32_EnableDpiAwareness() is just a helper called by main.cpp, we don't call it automatically.
// If you are trying to implement your own backend for your own engine, you may ignore that noise.
//---------------------------------------------------------------------------------------------------------

extern(Windows)
ULONGLONG
VerSetConditionMask(
    ULONGLONG ConditionMask,
    DWORD TypeMask,
    BYTE  Condition
    );

pragma(inline, true) void VER_SET_CONDITION(ref ULONGLONG ConditionMask, DWORD TypeMask, BYTE Condition) {
    ConditionMask = VerSetConditionMask(ConditionMask, TypeMask, Condition);
}

// Perform our own check with RtlVerifyVersionInfo() instead of using functions from <VersionHelpers.h> as they
// require a manifest to be functional for checks above 8.1. See https://github.com/ocornut/imgui/issues/4200
static BOOL _IsWindowsVersionOrGreater(WORD major, WORD minor, WORD)
{
    alias PFN_RtlVerifyVersionInfo = extern(Windows) LONG function(OSVERSIONINFOEXW*, ULONG, ULONGLONG) nothrow @nogc;
    static PFN_RtlVerifyVersionInfo RtlVerifyVersionInfoFn = null;
	if (RtlVerifyVersionInfoFn == null)
		if (HMODULE ntdllModule = GetModuleHandleA("ntdll.dll"))
			RtlVerifyVersionInfoFn = cast(PFN_RtlVerifyVersionInfo)GetProcAddress(ntdllModule, "RtlVerifyVersionInfo");
    if (RtlVerifyVersionInfoFn == null)
        return FALSE;

    OSVERSIONINFOEXW versionInfo;
    ULONGLONG conditionMask = 0;
    versionInfo.dwOSVersionInfoSize = sizeof!(OSVERSIONINFOEXW);
    versionInfo.dwMajorVersion = major;
	versionInfo.dwMinorVersion = minor;
	VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
	VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
	return (RtlVerifyVersionInfoFn(&versionInfo, VER_MAJORVERSION | VER_MINORVERSION, conditionMask) == 0) ? TRUE : FALSE;
}

pragma(inline, true) BOOL _IsWindowsVistaOrGreater()   { return _IsWindowsVersionOrGreater(HIBYTE(0x0600), LOBYTE(0x0600), 0);} // _WIN32_WINNT_VISTA
pragma(inline, true) BOOL _IsWindows8OrGreater()       { return _IsWindowsVersionOrGreater(HIBYTE(0x0602), LOBYTE(0x0602), 0);} // _WIN32_WINNT_WIN8
pragma(inline, true) BOOL _IsWindows8Point1OrGreater() { return _IsWindowsVersionOrGreater(HIBYTE(0x0603), LOBYTE(0x0603), 0);} // _WIN32_WINNT_WINBLUE
pragma(inline, true) BOOL _IsWindows10OrGreater()      { return _IsWindowsVersionOrGreater(HIBYTE(0x0A00), LOBYTE(0x0A00), 0);} // _WIN32_WINNT_WINTHRESHOLD / _WIN32_WINNT_WIN10

//#ifndef DPI_ENUMS_DECLARED
//enum PROCESS_DPI_AWARENESS { PROCESS_DPI_UNAWARE = 0, PROCESS_SYSTEM_DPI_AWARE = 1, PROCESS_PER_MONITOR_DPI_AWARE = 2 }
//enum MONITOR_DPI_TYPE { MDT_EFFECTIVE_DPI = 0, MDT_ANGULAR_DPI = 1, MDT_RAW_DPI = 2, MDT_DEFAULT = MDT_EFFECTIVE_DPI }
//#endif
// #ifndef _DPI_AWARENESS_CONTEXTS_
//alias DPI_AWARENESS_CONTEXT = HANDLE;
//enum DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    = cast(DPI_AWARENESS_CONTEXT)-3;
//#endif
//#ifndef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
//enum DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = cast(DPI_AWARENESS_CONTEXT)-4;
//#endif
alias PFN_SetProcessDpiAwareness = extern(Windows) HRESULT function(PROCESS_DPI_AWARENESS);                     // Shcore.lib + dll, Windows 8.1+
alias PFN_GetDpiForMonitor = extern(Windows) HRESULT function(HMONITOR, MONITOR_DPI_TYPE, UINT*, UINT*);        // Shcore.lib + dll, Windows 8.1+
alias PFN_SetThreadDpiAwarenessContext = extern(Windows) DPI_AWARENESS_CONTEXT function(DPI_AWARENESS_CONTEXT); // User32.lib + dll, Windows 10 v1607+ (Creators Update)

// Helper function to enable DPI awareness without setting up a manifest
void ImGui_ImplWin32_EnableDpiAwareness()
{
    if (_IsWindows10OrGreater())
    {
        /*static*/ HINSTANCE user32_dll = LoadLibraryA("user32.dll"); // Reference counted per-process
        if (PFN_SetThreadDpiAwarenessContext SetThreadDpiAwarenessContextFn = cast(PFN_SetThreadDpiAwarenessContext)GetProcAddress(user32_dll, "SetThreadDpiAwarenessContext"))
        {
            SetThreadDpiAwarenessContextFn(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
            return;
        }
    }
    if (_IsWindows8Point1OrGreater())
    {
        /*static*/ HINSTANCE shcore_dll = LoadLibraryA("shcore.dll"); // Reference counted per-process
        if (PFN_SetProcessDpiAwareness SetProcessDpiAwarenessFn = cast(PFN_SetProcessDpiAwareness)GetProcAddress(shcore_dll, "SetProcessDpiAwareness"))
        {
            SetProcessDpiAwarenessFn(PROCESS_DPI_AWARENESS.PROCESS_PER_MONITOR_DPI_AWARE);
            return;
        }
    }
//#if _WIN32_WINNT >= 0x0600
    SetProcessDPIAware();
//#endif
}

//#if defined(_MSC_VER) && !defined(NOGDI)
pragma(lib, "gdi32");   // Link with gdi32.lib for GetDeviceCaps(). MinGW will require linking with '-lgdi32'
//#endif

float ImGui_ImplWin32_GetDpiScaleForMonitor(void* monitor)
{
    UINT xdpi = 96, ydpi = 96;
    if (_IsWindows8Point1OrGreater())
    {
		/*static*/ HINSTANCE shcore_dll = LoadLibraryA("shcore.dll"); // Reference counted per-process
		static PFN_GetDpiForMonitor GetDpiForMonitorFn = null;
		if (GetDpiForMonitorFn == null && shcore_dll != null)
            GetDpiForMonitorFn = cast(PFN_GetDpiForMonitor)GetProcAddress(shcore_dll, "GetDpiForMonitor");
		if (GetDpiForMonitorFn != null)
		{
			GetDpiForMonitorFn(cast(HMONITOR)monitor, MONITOR_DPI_TYPE.MDT_EFFECTIVE_DPI, &xdpi, &ydpi);
            IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
			return xdpi / 96.0f;
		}
    }
//#ifndef NOGDI
    /*const*/ HDC dc = GetDC(null);
    xdpi = GetDeviceCaps(dc, LOGPIXELSX);
    ydpi = GetDeviceCaps(dc, LOGPIXELSY);
    IM_ASSERT(xdpi == ydpi); // Please contact me if you hit this assert!
    ReleaseDC(null, dc);
//#endif
    return xdpi / 96.0f;
}

float ImGui_ImplWin32_GetDpiScaleForHwnd(void* hwnd)
{
    HMONITOR monitor = MonitorFromWindow(cast(HWND)hwnd, MONITOR_DEFAULTTONEAREST);
    return ImGui_ImplWin32_GetDpiScaleForMonitor(monitor);
}

//---------------------------------------------------------------------------------------------------------
// Transparency related helpers (optional)
//--------------------------------------------------------------------------------------------------------

//#if defined(_MSC_VER)
pragma(lib, "dwmapi.lib");  // Link with dwmapi.lib. MinGW will require linking with '-ldwmapi'
//#endif

// [experimental]
// Borrowed from GLFW's function updateFramebufferTransparency() in src/win32_window.c
// (the Dwm* functions are Vista era functions but we are borrowing logic from GLFW)
/+
// D_IMGUI: No dwmapi headers seem to exists for D.
void ImGui_ImplWin32_EnableAlphaCompositing(void* hwnd)
{
    if (!_IsWindowsVistaOrGreater())
        return;

    BOOL composition;
    if (FAILED(DwmIsCompositionEnabled(&composition)) || !composition)
        return;

    BOOL opaque;
    DWORD color;
    if (_IsWindows8OrGreater() || (SUCCEEDED(DwmGetColorizationColor(&color, &opaque)) && !opaque))
    {
        HRGN region = CreateRectRgn(0, 0, -1, -1);
        DWM_BLURBEHIND bb = {};
        bb.dwFlags = DWM_BB_ENABLE | DWM_BB_BLURREGION;
        bb.hRgnBlur = region;
        bb.fEnable = TRUE;
        DwmEnableBlurBehindWindow(cast(HWND)hwnd, &bb);
        DeleteObject(region);
    }
    else
    {
        DWM_BLURBEHIND bb = {};
        bb.dwFlags = DWM_BB_ENABLE;
        DwmEnableBlurBehindWindow(cast(HWND)hwnd, &bb);
    }
}
+/

//---------------------------------------------------------------------------------------------------------
