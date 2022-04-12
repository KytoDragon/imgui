// dear imgui: Platform Backend for GLFW
// This needs to be used along with a Renderer (e.g. OpenGL3, Vulkan, WebGPU..)
// (Info: GLFW is a cross-platform general purpose library for handling windows, inputs, OpenGL/Vulkan graphics context creation, etc.)
// (Requires: GLFW 3.1+)

// Implemented features:
//  [X] Platform: Clipboard support.
//  [X] Platform: Keyboard support. Since 1.87 we are using the io.AddKeyEvent() function. Pass ImGuiKey values to all key functions e.g. ImGui::IsKeyPressed(ImGuiKey_Space). [Legacy GLFW_KEY_* values will also be supported unless IMGUI_DISABLE_OBSOLETE_KEYIO is set]
//  [X] Platform: Gamepad support. Enable with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange' (note: the resizing cursors requires GLFW 3.4+).

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2022-02-07: Added ImGui_ImplGlfw_InstallCallbacks()/ImGui_ImplGlfw_RestoreCallbacks() helpers to facilitate user installing callbacks after iniitializing backend.
//  2022-01-26: Inputs: replaced short-lived io.AddKeyModsEvent() (added two weeks ago)with io.AddKeyEvent() using ImGuiKey_ModXXX flags. Sorry for the confusion.
//  2021-01-20: Inputs: calling new io.AddKeyAnalogEvent() for gamepad support, instead of writing directly to io.NavInputs[].
//  2022-01-17: Inputs: calling new io.AddMousePosEvent(), io.AddMouseButtonEvent(), io.AddMouseWheelEvent() API (1.87+).
//  2022-01-17: Inputs: always update key mods next and before key event (not in NewFrame) to fix input queue with very low framerates.
//  2022-01-12: *BREAKING CHANGE*: Now using glfwSetCursorPosCallback(). If you called ImGui_ImplGlfw_InitXXX() with install_callbacks = false, you MUST install glfwSetCursorPosCallback() and forward it to the backend via ImGui_ImplGlfw_CursorPosCallback().
//  2022-01-10: Inputs: calling new io.AddKeyEvent(), io.AddKeyModsEvent() + io.SetKeyEventNativeData() API (1.87+). Support for full ImGuiKey range.
//  2022-01-05: Inputs: Converting GLFW untranslated keycodes back to translated keycodes (in the ImGui_ImplGlfw_KeyCallback() function) in order to match the behavior of every other backend, and facilitate the use of GLFW with lettered-shortcuts API.
//  2021-08-17: *BREAKING CHANGE*: Now using glfwSetWindowFocusCallback() to calling io.AddFocusEvent(). If you called ImGui_ImplGlfw_InitXXX() with install_callbacks = false, you MUST install glfwSetWindowFocusCallback() and forward it to the backend via ImGui_ImplGlfw_WindowFocusCallback().
//  2021-07-29: *BREAKING CHANGE*: Now using glfwSetCursorEnterCallback(). MousePos is correctly reported when the host platform window is hovered but not focused. If you called ImGui_ImplGlfw_InitXXX() with install_callbacks = false, you MUST install glfwSetWindowFocusCallback() callback and forward it to the backend via ImGui_ImplGlfw_CursorEnterCallback().
//  2021-06-29: Reorganized backend to pull data from a single structure to facilitate usage with multiple-contexts (all g_XXXX access changed to bd->XXXX).
//  2020-01-17: Inputs: Disable error callback while assigning mouse cursors because some X11 setup don't have them and it generates errors.
//  2019-12-05: Inputs: Added support for new mouse cursors added in GLFW 3.4+ (resizing cursors, not allowed cursor).
//  2019-10-18: Misc: Previously installed user callbacks are now restored on shutdown.
//  2019-07-21: Inputs: Added mapping for ImGuiKey_KeyPadEnter.
//  2019-05-11: Inputs: Don't filter value from character callback before calling AddInputCharacter().
//  2019-03-12: Misc: Preserve DisplayFramebufferScale when main window is minimized.
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-11-07: Inputs: When installing our GLFW callbacks, we save user's previously installed ones - if any - and chain call them.
//  2018-08-01: Inputs: Workaround for Emscripten which doesn't seem to handle focus related calls.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor_Hand cursor.
//  2018-06-08: Misc: Extracted imgui_impl_glfw.cpp/.h away from the old combined GLFW+OpenGL/Vulkan examples.
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors flag + honor ImGuiConfigFlags_NoMouseCursorChange flag.
//  2018-02-20: Inputs: Added support for mouse cursors (ImGui::GetMouseCursor() value, passed to glfwSetCursor()).
//  2018-02-06: Misc: Removed call to ImGui::Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
//  2018-01-25: Inputs: Added gamepad support if ImGuiConfigFlags_NavEnableGamepad is set.
//  2018-01-25: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and ImGuiConfigFlags_NavMoveMouse is set).
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-18: Inputs: Added mapping for ImGuiKey_Insert.
//  2017-08-25: Inputs: MousePos set to -FLT_MAX,-FLT_MAX when mouse is unavailable/missing (instead of -1,-1).
//  2016-10-15: Misc: Added a void* user_data parameter to Clipboard function handlers.

// About GLSL version:
// The 'glsl_version' initialization parameter defaults to "#version 150" if NULL.
// Only override if your GL version doesn't handle this GLSL version. Keep NULL if unsure!

version (IMGUI_GLFW):
nothrow @nogc:

import ImGui = d_imgui.imgui;
import d_imgui.imgui_h;

// Clang warnings with -Weverything
/+
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wold-style-cast"     // warning: use of old-style cast
#pragma clang diagnostic ignored "-Wsign-conversion"    // warning: implicit conversion changes signedness
#if __has_warning("-Wzero-as-null-pointer-constant")
#pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
#endif
#endif
+/

// GLFW
/+
#include <GLFW/glfw3.h>
#ifdef _WIN32
#undef APIENTRY
#define GLFW_EXPOSE_NATIVE_WIN32
#include <GLFW/glfw3native.h>   // for glfwGetWin32Window
#endif
+/
//#ifdef GLFW_RESIZE_NESW_CURSOR        // Let's be nice to people who pulled GLFW between 2019-04-16 (3.4 define) and 2019-11-29 (cursors defines) // FIXME: Remove when GLFW 3.4 is released?
enum GLFW_HAS_NEW_CURSORS          = (GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100  >= 3400); // 3.4+ GLFW_RESIZE_ALL_CURSOR, GLFW_RESIZE_NESW_CURSOR, GLFW_RESIZE_NWSE_CURSOR, GLFW_NOT_ALLOWED_CURSOR
//#else
//#define GLFW_HAS_NEW_CURSORS          (0)
//#endif
enum GLFW_HAS_GAMEPAD_API          = (GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100 >= 3300); // 3.3+ glfwGetGamepadState() new api
enum GLFW_HAS_GET_KEY_NAME         = (GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100 >= 3200); // 3.2+ glfwGetKeyName()

import bindbc.glfw;
version(Windows) {
    import core.sys.windows.windows : HWND;    // Import the platform API bindings
    mixin(bindGLFW_Windows);          // Mixin the function declarations and loader
}

// GLFW data
enum GlfwClientApi
{
    Unknown,
    OpenGL,
    Vulkan
}

struct ImGui_ImplGlfw_Data
{
    GLFWwindow*             Window;
    GlfwClientApi           ClientApi;
    double                  Time = 0;
    GLFWwindow*             MouseWindow;
    GLFWcursor*[ImGuiMouseCursor.COUNT]             MouseCursors;
    ImVec2                  LastValidMousePos;
    bool                    InstalledCallbacks;

    // Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
    GLFWwindowfocusfun      PrevUserCallbackWindowFocus;
    GLFWcursorposfun        PrevUserCallbackCursorPos;
    GLFWcursorenterfun      PrevUserCallbackCursorEnter;
    GLFWmousebuttonfun      PrevUserCallbackMousebutton;
    GLFWscrollfun           PrevUserCallbackScroll;
    GLFWkeyfun              PrevUserCallbackKey;
    GLFWcharfun             PrevUserCallbackChar;
    GLFWmonitorfun          PrevUserCallbackMonitor;

    //ImGui_ImplGlfw_Data()   { memset(&this, 0, sizeof(this)); }
}

// Backend data stored in io.BackendPlatformUserData to allow support for multiple Dear ImGui contexts
// It is STRONGLY preferred that you use docking branch with multi-viewports (== single Dear ImGui context + multiple windows) instead of multiple Dear ImGui contexts.
// FIXME: multi-context support is not well tested and probably dysfunctional in this backend.
// - Because glfwPollEvents() process all windows and some events may be called outside of it, you will need to register your own callbacks
//   (passing install_callbacks=false in ImGui_ImplGlfw_InitXXX functions), set the current dear imgui context and then call our callbacks.
// - Otherwise we may need to store a GLFWWindow* -> ImGuiContext* map and handle this in the backend, adding a little bit of extra complexity to it.
// FIXME: some shared resources (mouse cursor shape, gamepad) are mishandled when using multi-context.
static ImGui_ImplGlfw_Data* ImGui_ImplGlfw_GetBackendData()
{
    return ImGui.GetCurrentContext() ? cast(ImGui_ImplGlfw_Data*)ImGui.GetIO().BackendPlatformUserData : NULL;
}

// Functions
static string ImGui_ImplGlfw_GetClipboardText(void* user_data)
{
    return ImGui.ImCstring(glfwGetClipboardString(cast(GLFWwindow*)user_data));
}

static void ImGui_ImplGlfw_SetClipboardText(void* user_data, string text)
{
    glfwSetClipboardString(cast(GLFWwindow*)user_data, text.ptr);
}

static ImGuiKey ImGui_ImplGlfw_KeyToImGuiKey(int key)
{
    switch (key)
    {
        case GLFW_KEY_TAB: return ImGuiKey.Tab;
        case GLFW_KEY_LEFT: return ImGuiKey.LeftArrow;
        case GLFW_KEY_RIGHT: return ImGuiKey.RightArrow;
        case GLFW_KEY_UP: return ImGuiKey.UpArrow;
        case GLFW_KEY_DOWN: return ImGuiKey.DownArrow;
        case GLFW_KEY_PAGE_UP: return ImGuiKey.PageUp;
        case GLFW_KEY_PAGE_DOWN: return ImGuiKey.PageDown;
        case GLFW_KEY_HOME: return ImGuiKey.Home;
        case GLFW_KEY_END: return ImGuiKey.End;
        case GLFW_KEY_INSERT: return ImGuiKey.Insert;
        case GLFW_KEY_DELETE: return ImGuiKey.Delete;
        case GLFW_KEY_BACKSPACE: return ImGuiKey.Backspace;
        case GLFW_KEY_SPACE: return ImGuiKey.Space;
        case GLFW_KEY_ENTER: return ImGuiKey.Enter;
        case GLFW_KEY_ESCAPE: return ImGuiKey.Escape;
        case GLFW_KEY_APOSTROPHE: return ImGuiKey.Apostrophe;
        case GLFW_KEY_COMMA: return ImGuiKey.Comma;
        case GLFW_KEY_MINUS: return ImGuiKey.Minus;
        case GLFW_KEY_PERIOD: return ImGuiKey.Period;
        case GLFW_KEY_SLASH: return ImGuiKey.Slash;
        case GLFW_KEY_SEMICOLON: return ImGuiKey.Semicolon;
        case GLFW_KEY_EQUAL: return ImGuiKey.Equal;
        case GLFW_KEY_LEFT_BRACKET: return ImGuiKey.LeftBracket;
        case GLFW_KEY_BACKSLASH: return ImGuiKey.Backslash;
        case GLFW_KEY_RIGHT_BRACKET: return ImGuiKey.RightBracket;
        case GLFW_KEY_GRAVE_ACCENT: return ImGuiKey.GraveAccent;
        case GLFW_KEY_CAPS_LOCK: return ImGuiKey.CapsLock;
        case GLFW_KEY_SCROLL_LOCK: return ImGuiKey.ScrollLock;
        case GLFW_KEY_NUM_LOCK: return ImGuiKey.NumLock;
        case GLFW_KEY_PRINT_SCREEN: return ImGuiKey.PrintScreen;
        case GLFW_KEY_PAUSE: return ImGuiKey.Pause;
        case GLFW_KEY_KP_0: return ImGuiKey.Keypad0;
        case GLFW_KEY_KP_1: return ImGuiKey.Keypad1;
        case GLFW_KEY_KP_2: return ImGuiKey.Keypad2;
        case GLFW_KEY_KP_3: return ImGuiKey.Keypad3;
        case GLFW_KEY_KP_4: return ImGuiKey.Keypad4;
        case GLFW_KEY_KP_5: return ImGuiKey.Keypad5;
        case GLFW_KEY_KP_6: return ImGuiKey.Keypad6;
        case GLFW_KEY_KP_7: return ImGuiKey.Keypad7;
        case GLFW_KEY_KP_8: return ImGuiKey.Keypad8;
        case GLFW_KEY_KP_9: return ImGuiKey.Keypad9;
        case GLFW_KEY_KP_DECIMAL: return ImGuiKey.KeypadDecimal;
        case GLFW_KEY_KP_DIVIDE: return ImGuiKey.KeypadDivide;
        case GLFW_KEY_KP_MULTIPLY: return ImGuiKey.KeypadMultiply;
        case GLFW_KEY_KP_SUBTRACT: return ImGuiKey.KeypadSubtract;
        case GLFW_KEY_KP_ADD: return ImGuiKey.KeypadAdd;
        case GLFW_KEY_KP_ENTER: return ImGuiKey.KeypadEnter;
        case GLFW_KEY_KP_EQUAL: return ImGuiKey.KeypadEqual;
        case GLFW_KEY_LEFT_SHIFT: return ImGuiKey.LeftShift;
        case GLFW_KEY_LEFT_CONTROL: return ImGuiKey.LeftCtrl;
        case GLFW_KEY_LEFT_ALT: return ImGuiKey.LeftAlt;
        case GLFW_KEY_LEFT_SUPER: return ImGuiKey.LeftSuper;
        case GLFW_KEY_RIGHT_SHIFT: return ImGuiKey.RightShift;
        case GLFW_KEY_RIGHT_CONTROL: return ImGuiKey.RightCtrl;
        case GLFW_KEY_RIGHT_ALT: return ImGuiKey.RightAlt;
        case GLFW_KEY_RIGHT_SUPER: return ImGuiKey.RightSuper;
        case GLFW_KEY_MENU: return ImGuiKey.Menu;
        case GLFW_KEY_0: return ImGuiKey._0;
        case GLFW_KEY_1: return ImGuiKey._1;
        case GLFW_KEY_2: return ImGuiKey._2;
        case GLFW_KEY_3: return ImGuiKey._3;
        case GLFW_KEY_4: return ImGuiKey._4;
        case GLFW_KEY_5: return ImGuiKey._5;
        case GLFW_KEY_6: return ImGuiKey._6;
        case GLFW_KEY_7: return ImGuiKey._7;
        case GLFW_KEY_8: return ImGuiKey._8;
        case GLFW_KEY_9: return ImGuiKey._9;
        case GLFW_KEY_A: return ImGuiKey.A;
        case GLFW_KEY_B: return ImGuiKey.B;
        case GLFW_KEY_C: return ImGuiKey.C;
        case GLFW_KEY_D: return ImGuiKey.D;
        case GLFW_KEY_E: return ImGuiKey.E;
        case GLFW_KEY_F: return ImGuiKey.F;
        case GLFW_KEY_G: return ImGuiKey.G;
        case GLFW_KEY_H: return ImGuiKey.H;
        case GLFW_KEY_I: return ImGuiKey.I;
        case GLFW_KEY_J: return ImGuiKey.J;
        case GLFW_KEY_K: return ImGuiKey.K;
        case GLFW_KEY_L: return ImGuiKey.L;
        case GLFW_KEY_M: return ImGuiKey.M;
        case GLFW_KEY_N: return ImGuiKey.N;
        case GLFW_KEY_O: return ImGuiKey.O;
        case GLFW_KEY_P: return ImGuiKey.P;
        case GLFW_KEY_Q: return ImGuiKey.Q;
        case GLFW_KEY_R: return ImGuiKey.R;
        case GLFW_KEY_S: return ImGuiKey.S;
        case GLFW_KEY_T: return ImGuiKey.T;
        case GLFW_KEY_U: return ImGuiKey.U;
        case GLFW_KEY_V: return ImGuiKey.V;
        case GLFW_KEY_W: return ImGuiKey.W;
        case GLFW_KEY_X: return ImGuiKey.X;
        case GLFW_KEY_Y: return ImGuiKey.Y;
        case GLFW_KEY_Z: return ImGuiKey.Z;
        case GLFW_KEY_F1: return ImGuiKey.F1;
        case GLFW_KEY_F2: return ImGuiKey.F2;
        case GLFW_KEY_F3: return ImGuiKey.F3;
        case GLFW_KEY_F4: return ImGuiKey.F4;
        case GLFW_KEY_F5: return ImGuiKey.F5;
        case GLFW_KEY_F6: return ImGuiKey.F6;
        case GLFW_KEY_F7: return ImGuiKey.F7;
        case GLFW_KEY_F8: return ImGuiKey.F8;
        case GLFW_KEY_F9: return ImGuiKey.F9;
        case GLFW_KEY_F10: return ImGuiKey.F10;
        case GLFW_KEY_F11: return ImGuiKey.F11;
        case GLFW_KEY_F12: return ImGuiKey.F12;
        default: return ImGuiKey.None;
    }
}

static void ImGui_ImplGlfw_UpdateKeyModifiers(int mods)
{
    ImGuiIO* io = &ImGui.GetIO();
    io.AddKeyEvent(ImGuiKey.ModCtrl, (mods & GLFW_MOD_CONTROL) != 0);
    io.AddKeyEvent(ImGuiKey.ModShift, (mods & GLFW_MOD_SHIFT) != 0);
    io.AddKeyEvent(ImGuiKey.ModAlt, (mods & GLFW_MOD_ALT) != 0);
    io.AddKeyEvent(ImGuiKey.ModSuper, (mods & GLFW_MOD_SUPER) != 0);
}

extern(C) void ImGui_ImplGlfw_MouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackMousebutton != NULL && window == bd.Window)
        bd.PrevUserCallbackMousebutton(window, button, action, mods);

    ImGui_ImplGlfw_UpdateKeyModifiers(mods);

    ImGuiIO* io = &ImGui.GetIO();
    if (button >= 0 && button < ImGuiMouseButton.COUNT)
        io.AddMouseButtonEvent(button, action == GLFW_PRESS);
}

extern(C) void ImGui_ImplGlfw_ScrollCallback(GLFWwindow* window, double xoffset, double yoffset)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackScroll != NULL && window == bd.Window)
        bd.PrevUserCallbackScroll(window, xoffset, yoffset);

    ImGuiIO* io = &ImGui.GetIO();
    io.AddMouseWheelEvent(cast(float)xoffset, cast(float)yoffset);
}

static int ImGui_ImplGlfw_TranslateUntranslatedKey(int key, int scancode)
{
static if (GLFW_HAS_GET_KEY_NAME) {// && !defined(__EMSCRIPTEN__)
    // GLFW 3.1+ attempts to "untranslate" keys, which goes the opposite of what every other framework does, making using lettered shortcuts difficult.
    // (It had reasons to do so: namely GLFW is/was more likely to be used for WASD-type game controls rather than lettered shortcuts, but IHMO the 3.1 change could have been done differently)
    // See https://github.com/glfw/glfw/issues/1502 for details.
    // Adding a workaround to undo this (so our keys are translated->untranslated->translated, likely a lossy process).
    // This won't cover edge cases but this is at least going to cover common cases.
    if (key >= GLFW_KEY_KP_0 && key <= GLFW_KEY_KP_EQUAL)
        return key;
    const char* key_name = glfwGetKeyName(key, scancode);
    if (key_name && key_name[0] != 0 && key_name[1] == 0)
    {
        string char_names = "`-=[]\\,;\'./";
        const int[11] char_keys = [ GLFW_KEY_GRAVE_ACCENT, GLFW_KEY_MINUS, GLFW_KEY_EQUAL, GLFW_KEY_LEFT_BRACKET, GLFW_KEY_RIGHT_BRACKET, GLFW_KEY_BACKSLASH, GLFW_KEY_COMMA, GLFW_KEY_SEMICOLON, GLFW_KEY_APOSTROPHE, GLFW_KEY_PERIOD, GLFW_KEY_SLASH];
        IM_ASSERT(char_names.length == IM_ARRAYSIZE(char_keys));
        if (key_name[0] >= '0' && key_name[0] <= '9')               { key = GLFW_KEY_0 + (key_name[0] - '0'); }
        else if (key_name[0] >= 'A' && key_name[0] <= 'Z')          { key = GLFW_KEY_A + (key_name[0] - 'A'); }
        else {
            ptrdiff_t index = ImGui.ImIndexOf(char_names, key_name[0]);
            if (index >= 0)   { key = char_keys[index]; }
        }
    }
    // if (action == GLFW_PRESS) printf("key %d scancode %d name '%s'\n", key, scancode, key_name);
} else {
    IM_UNUSED(scancode);
}
    return key;
}

extern(C) void ImGui_ImplGlfw_KeyCallback(GLFWwindow* window, int keycode, int scancode, int action, int mods)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackKey != NULL && window == bd.Window)
        bd.PrevUserCallbackKey(window, keycode, scancode, action, mods);

    if (action != GLFW_PRESS && action != GLFW_RELEASE)
        return;

    ImGui_ImplGlfw_UpdateKeyModifiers(mods);

    keycode = ImGui_ImplGlfw_TranslateUntranslatedKey(keycode, scancode);

    ImGuiIO* io = &ImGui.GetIO();
    ImGuiKey imgui_key = ImGui_ImplGlfw_KeyToImGuiKey(keycode);
    io.AddKeyEvent(imgui_key, (action == GLFW_PRESS));
    io.SetKeyEventNativeData(imgui_key, keycode, scancode); // To support legacy indexing (<1.87 user code)
}

extern(C) void ImGui_ImplGlfw_WindowFocusCallback(GLFWwindow* window, int focused)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackWindowFocus != NULL && window == bd.Window)
        bd.PrevUserCallbackWindowFocus(window, focused);

    ImGuiIO* io = &ImGui.GetIO();
    io.AddFocusEvent(focused != 0);
}

extern(C) void ImGui_ImplGlfw_CursorPosCallback(GLFWwindow* window, double x, double y)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackCursorPos != NULL && window == bd.Window)
        bd.PrevUserCallbackCursorPos(window, x, y);

    ImGuiIO* io = &ImGui.GetIO();
    io.AddMousePosEvent(cast(float)x, cast(float)y);
    bd.LastValidMousePos = ImVec2(cast(float)x, cast(float)y);
}

// Workaround: X11 seems to send spurious Leave/Enter events which would make us lose our position,
// so we back it up and restore on Leave/Enter (see https://github.com/ocornut/imgui/issues/4984)
extern(C) void ImGui_ImplGlfw_CursorEnterCallback(GLFWwindow* window, int entered)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackCursorEnter != NULL && window == bd.Window)
        bd.PrevUserCallbackCursorEnter(window, entered);

    ImGuiIO* io = &ImGui.GetIO();
    if (entered)
    {
        bd.MouseWindow = window;
        io.AddMousePosEvent(bd.LastValidMousePos.x, bd.LastValidMousePos.y);
    }
    else if (!entered && bd.MouseWindow == window)
    {
        bd.LastValidMousePos = io.MousePos;
        bd.MouseWindow = NULL;
        io.AddMousePosEvent(-FLT_MAX, -FLT_MAX);
    }
}

extern(C) void ImGui_ImplGlfw_CharCallback(GLFWwindow* window, uint c)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackChar != NULL && window == bd.Window)
        bd.PrevUserCallbackChar(window, c);

    ImGuiIO* io = &ImGui.GetIO();
    io.AddInputCharacter(c);
}

extern(C) void ImGui_ImplGlfw_MonitorCallback(GLFWmonitor*, int)
{
	// Unused in 'master' branch but 'docking' branch will use this, so we declare it ahead of it so if you have to install callbacks you can install this one too.
}

void ImGui_ImplGlfw_InstallCallbacks(GLFWwindow* window)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    IM_ASSERT(bd.InstalledCallbacks == false, "Callbacks already installed!");
    IM_ASSERT(bd.Window == window);

    bd.PrevUserCallbackWindowFocus = glfwSetWindowFocusCallback(window, &ImGui_ImplGlfw_WindowFocusCallback);
    bd.PrevUserCallbackCursorEnter = glfwSetCursorEnterCallback(window, &ImGui_ImplGlfw_CursorEnterCallback);
    bd.PrevUserCallbackCursorPos = glfwSetCursorPosCallback(window, &ImGui_ImplGlfw_CursorPosCallback);
    bd.PrevUserCallbackMousebutton = glfwSetMouseButtonCallback(window, &ImGui_ImplGlfw_MouseButtonCallback);
    bd.PrevUserCallbackScroll = glfwSetScrollCallback(window, &ImGui_ImplGlfw_ScrollCallback);
    bd.PrevUserCallbackKey = glfwSetKeyCallback(window, &ImGui_ImplGlfw_KeyCallback);
    bd.PrevUserCallbackChar = glfwSetCharCallback(window, &ImGui_ImplGlfw_CharCallback);
    bd.PrevUserCallbackMonitor = glfwSetMonitorCallback(&ImGui_ImplGlfw_MonitorCallback);
    bd.InstalledCallbacks = true;
}

extern(C) void ImGui_ImplGlfw_RestoreCallbacks(GLFWwindow* window)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    IM_ASSERT(bd.InstalledCallbacks == true, "Callbacks not installed!");
    IM_ASSERT(bd.Window == window);

    glfwSetWindowFocusCallback(window, bd.PrevUserCallbackWindowFocus);
    glfwSetCursorEnterCallback(window, bd.PrevUserCallbackCursorEnter);
    glfwSetCursorPosCallback(window, bd.PrevUserCallbackCursorPos);
    glfwSetMouseButtonCallback(window, bd.PrevUserCallbackMousebutton);
    glfwSetScrollCallback(window, bd.PrevUserCallbackScroll);
    glfwSetKeyCallback(window, bd.PrevUserCallbackKey);
    glfwSetCharCallback(window, bd.PrevUserCallbackChar);
    glfwSetMonitorCallback(bd.PrevUserCallbackMonitor);
    bd.InstalledCallbacks = false;
    bd.PrevUserCallbackWindowFocus = NULL;
    bd.PrevUserCallbackCursorEnter = NULL;
    bd.PrevUserCallbackCursorPos = NULL;
    bd.PrevUserCallbackMousebutton = NULL;
    bd.PrevUserCallbackScroll = NULL;
    bd.PrevUserCallbackKey = NULL;
    bd.PrevUserCallbackChar = NULL;
    bd.PrevUserCallbackMonitor = NULL;
}

static bool ImGui_ImplGlfw_Init(GLFWwindow* window, bool install_callbacks, GlfwClientApi client_api)
{
    ImGuiIO* io = &ImGui.GetIO();
    IM_ASSERT(io.BackendPlatformUserData == NULL, "Already initialized a platform backend!");

    // Setup backend capabilities flags
    ImGui_ImplGlfw_Data* bd = IM_NEW!(ImGui_ImplGlfw_Data)();
    io.BackendPlatformUserData = cast(void*)bd;
    io.BackendPlatformName = "imgui_impl_glfw";
    io.BackendFlags |= ImGuiBackendFlags.HasMouseCursors;         // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags.HasSetMousePos;          // We can honor io.WantSetMousePos requests (optional, rarely used)

    bd.Window = window;
    bd.Time = 0.0;

    io.SetClipboardTextFn = &ImGui_ImplGlfw_SetClipboardText;
    io.GetClipboardTextFn = &ImGui_ImplGlfw_GetClipboardText;
    io.ClipboardUserData = bd.Window;

    // Set platform dependent data in viewport
version(Windows) {
    loadGLFW_Windows();
    ImGui.GetMainViewport().PlatformHandleRaw = cast(void*)glfwGetWin32Window(bd.Window);
}

    // Create mouse cursors
    // (By design, on X11 cursors are user configurable and some cursors may be missing. When a cursor doesn't exist,
    // GLFW will emit an error which will often be printed by the app, so we temporarily disable error reporting.
    // Missing cursors will return NULL and our _UpdateMouseCursor() function will use the Arrow cursor instead.)
    GLFWerrorfun prev_error_callback = glfwSetErrorCallback(NULL);
    bd.MouseCursors[ImGuiMouseCursor.Arrow] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.TextInput] = glfwCreateStandardCursor(GLFW_IBEAM_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeNS] = glfwCreateStandardCursor(GLFW_VRESIZE_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeEW] = glfwCreateStandardCursor(GLFW_HRESIZE_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.Hand] = glfwCreateStandardCursor(GLFW_HAND_CURSOR);
static if (GLFW_HAS_NEW_CURSORS) {
    bd.MouseCursors[ImGuiMouseCursor.ResizeAll] = glfwCreateStandardCursor(GLFW_RESIZE_ALL_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeNESW] = glfwCreateStandardCursor(GLFW_RESIZE_NESW_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeNWSE] = glfwCreateStandardCursor(GLFW_RESIZE_NWSE_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.NotAllowed] = glfwCreateStandardCursor(GLFW_NOT_ALLOWED_CURSOR);
} else {
    bd.MouseCursors[ImGuiMouseCursor.ResizeAll] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeNESW] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.ResizeNWSE] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    bd.MouseCursors[ImGuiMouseCursor.NotAllowed] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
}
    glfwSetErrorCallback(prev_error_callback);

    // Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
    if (install_callbacks)
        ImGui_ImplGlfw_InstallCallbacks(window);

    bd.ClientApi = client_api;
    return true;
}

bool ImGui_ImplGlfw_InitForOpenGL(GLFWwindow* window, bool install_callbacks)
{
    return ImGui_ImplGlfw_Init(window, install_callbacks, GlfwClientApi.OpenGL);
}

bool ImGui_ImplGlfw_InitForVulkan(GLFWwindow* window, bool install_callbacks)
{
    return ImGui_ImplGlfw_Init(window, install_callbacks, GlfwClientApi.Vulkan);
}

bool ImGui_ImplGlfw_InitForOther(GLFWwindow* window, bool install_callbacks)
{
    return ImGui_ImplGlfw_Init(window, install_callbacks, GlfwClientApi.Unknown);
}

void ImGui_ImplGlfw_Shutdown()
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    IM_ASSERT(bd != NULL, "No platform backend to shutdown, or already shutdown?");
    ImGuiIO* io = &ImGui.GetIO();

    if (bd.InstalledCallbacks)
        ImGui_ImplGlfw_RestoreCallbacks(bd.Window);

    for (ImGuiMouseCursor cursor_n = cast(ImGuiMouseCursor)0; cursor_n < ImGuiMouseCursor.COUNT; cursor_n++)
        glfwDestroyCursor(bd.MouseCursors[cursor_n]);

    io.BackendPlatformName = NULL;
    io.BackendPlatformUserData = NULL;
    IM_DELETE(bd);
}

static void ImGui_ImplGlfw_UpdateMouseData()
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    ImGuiIO* io = &ImGui.GetIO();

//#ifdef __EMSCRIPTEN__
//    const bool is_app_focused = true;
//#else
    const bool is_app_focused = glfwGetWindowAttrib(bd.Window, GLFW_FOCUSED) != 0;
//#endif
    if (is_app_focused)
    {
        // (Optional) Set OS mouse position from Dear ImGui if requested (rarely used, only when ImGuiConfigFlags_NavEnableSetMousePos is enabled by user)
        if (io.WantSetMousePos)
            glfwSetCursorPos(bd.Window, cast(double)io.MousePos.x, cast(double)io.MousePos.y);

        // (Optional) Fallback to provide mouse position when focused (ImGui_ImplGlfw_CursorPosCallback already provides this when hovered or captured)
        if (is_app_focused && bd.MouseWindow == NULL)
        {
            double mouse_x, mouse_y;
            glfwGetCursorPos(bd.Window, &mouse_x, &mouse_y);
            io.AddMousePosEvent(cast(float)mouse_x, cast(float)mouse_y);
            bd.LastValidMousePos = ImVec2(cast(float)mouse_x, cast(float)mouse_y);
        }
    }
}

static void ImGui_ImplGlfw_UpdateMouseCursor()
{
    ImGuiIO* io = &ImGui.GetIO();
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if ((io.ConfigFlags & ImGuiConfigFlags.NoMouseCursorChange) || glfwGetInputMode(bd.Window, GLFW_CURSOR) == GLFW_CURSOR_DISABLED)
        return;

    ImGuiMouseCursor imgui_cursor = ImGui.GetMouseCursor();
    if (imgui_cursor == ImGuiMouseCursor.None || io.MouseDrawCursor)
    {
        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
        glfwSetInputMode(bd.Window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    }
    else
    {
        // Show OS mouse cursor
        // FIXME-PLATFORM: Unfocused windows seems to fail changing the mouse cursor with GLFW 3.2, but 3.3 works here.
        glfwSetCursor(bd.Window, bd.MouseCursors[imgui_cursor] ? bd.MouseCursors[imgui_cursor] : bd.MouseCursors[ImGuiMouseCursor.Arrow]);
        glfwSetInputMode(bd.Window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }
}

// Update gamepad inputs
static pragma(inline, true) float Saturate(float v) { return v < 0.0f ? 0.0f : v  > 1.0f ? 1.0f : v; }
static void ImGui_ImplGlfw_UpdateGamepads()
{
    ImGuiIO* io = &ImGui.GetIO();
    if ((io.ConfigFlags & ImGuiConfigFlags.NavEnableGamepad) == 0)
        return;

    io.BackendFlags &= ~ImGuiBackendFlags.HasGamepad;
static if (GLFW_HAS_GAMEPAD_API) {
    GLFWgamepadstate gamepad;
    if (!glfwGetGamepadState(GLFW_JOYSTICK_1, &gamepad))
        return;
    pragma(inline, true) void MAP_BUTTON(ImGuiKey KEY_NO, uint BUTTON_NO, uint _UNUSED)          { io.AddKeyEvent(KEY_NO, gamepad.buttons[BUTTON_NO] != 0); }
    pragma(inline, true) void MAP_ANALOG(ImGuiKey KEY_NO, uint AXIS_NO, uint _UNUSED, float V0, float V1)    { float v = gamepad.axes[AXIS_NO]; v = (v - V0) / (V1 - V0); io.AddKeyAnalogEvent(KEY_NO, v > 0.10f, Saturate(v)); }
} else {
    int axes_count = 0, buttons_count = 0;
    const float* axes = glfwGetJoystickAxes(GLFW_JOYSTICK_1, &axes_count);
    const ubyte* buttons = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &buttons_count);
    if (axes_count == 0 || buttons_count == 0)
        return;
    pragma(inline, true) void MAP_BUTTON(ImGuiKey KEY_NO, uint _UNUSED, uint BUTTON_NO)          { io.AddKeyEvent(KEY_NO, (buttons_count > BUTTON_NO && buttons[BUTTON_NO] == GLFW_PRESS)); }
    pragma(inline, true) void MAP_ANALOG(ImGuiKey KEY_NO, uint _UNUSED, uint AXIS_NO, float V0, float V1)    { float v = (axes_count > AXIS_NO) ? axes[AXIS_NO] : V0; v = (v - V0) / (V1 - V0); io.AddKeyAnalogEvent(KEY_NO, v > 0.10f, Saturate(v)); }
}
    io.BackendFlags |= ImGuiBackendFlags.HasGamepad;
    MAP_BUTTON(ImGuiKey.GamepadStart,       GLFW_GAMEPAD_BUTTON_START,          7);
    MAP_BUTTON(ImGuiKey.GamepadBack,        GLFW_GAMEPAD_BUTTON_BACK,           6);
    MAP_BUTTON(ImGuiKey.GamepadFaceDown,    GLFW_GAMEPAD_BUTTON_A,              0);     // Xbox A, PS Cross
    MAP_BUTTON(ImGuiKey.GamepadFaceRight,   GLFW_GAMEPAD_BUTTON_B,              1);     // Xbox B, PS Circle
    MAP_BUTTON(ImGuiKey.GamepadFaceLeft,    GLFW_GAMEPAD_BUTTON_X,              2);     // Xbox X, PS Square
    MAP_BUTTON(ImGuiKey.GamepadFaceUp,      GLFW_GAMEPAD_BUTTON_Y,              3);     // Xbox Y, PS Triangle
    MAP_BUTTON(ImGuiKey.GamepadDpadLeft,    GLFW_GAMEPAD_BUTTON_DPAD_LEFT,      13);
    MAP_BUTTON(ImGuiKey.GamepadDpadRight,   GLFW_GAMEPAD_BUTTON_DPAD_RIGHT,     11);
    MAP_BUTTON(ImGuiKey.GamepadDpadUp,      GLFW_GAMEPAD_BUTTON_DPAD_UP,        10);
    MAP_BUTTON(ImGuiKey.GamepadDpadDown,    GLFW_GAMEPAD_BUTTON_DPAD_DOWN,      12);
    MAP_BUTTON(ImGuiKey.GamepadL1,          GLFW_GAMEPAD_BUTTON_LEFT_BUMPER,    4);
    MAP_BUTTON(ImGuiKey.GamepadR1,          GLFW_GAMEPAD_BUTTON_RIGHT_BUMPER,   5);
    MAP_ANALOG(ImGuiKey.GamepadL2,          GLFW_GAMEPAD_AXIS_LEFT_TRIGGER,     4,      -0.75f,  +1.0f);
    MAP_ANALOG(ImGuiKey.GamepadR2,          GLFW_GAMEPAD_AXIS_RIGHT_TRIGGER,    5,      -0.75f,  +1.0f);
    MAP_BUTTON(ImGuiKey.GamepadL3,          GLFW_GAMEPAD_BUTTON_LEFT_THUMB,     8);
    MAP_BUTTON(ImGuiKey.GamepadR3,          GLFW_GAMEPAD_BUTTON_RIGHT_THUMB,    9);
    MAP_ANALOG(ImGuiKey.GamepadLStickLeft,  GLFW_GAMEPAD_AXIS_LEFT_X,           0,      -0.25f,  -1.0f);
    MAP_ANALOG(ImGuiKey.GamepadLStickRight, GLFW_GAMEPAD_AXIS_LEFT_X,           0,      +0.25f,  +1.0f);
    MAP_ANALOG(ImGuiKey.GamepadLStickUp,    GLFW_GAMEPAD_AXIS_LEFT_Y,           1,      -0.25f,  -1.0f);
    MAP_ANALOG(ImGuiKey.GamepadLStickDown,  GLFW_GAMEPAD_AXIS_LEFT_Y,           1,      +0.25f,  +1.0f);
    MAP_ANALOG(ImGuiKey.GamepadRStickLeft,  GLFW_GAMEPAD_AXIS_RIGHT_X,          2,      -0.25f,  -1.0f);
    MAP_ANALOG(ImGuiKey.GamepadRStickRight, GLFW_GAMEPAD_AXIS_RIGHT_X,          2,      +0.25f,  +1.0f);
    MAP_ANALOG(ImGuiKey.GamepadRStickUp,    GLFW_GAMEPAD_AXIS_RIGHT_Y,          3,      -0.25f,  -1.0f);
    MAP_ANALOG(ImGuiKey.GamepadRStickDown,  GLFW_GAMEPAD_AXIS_RIGHT_Y,          3,      +0.25f,  +1.0f);
    //#undef MAP_BUTTON
    //#undef MAP_ANALOG
}

void ImGui_ImplGlfw_NewFrame()
{
    ImGuiIO* io = &ImGui.GetIO();
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    IM_ASSERT(bd != NULL, "Did you call ImGui_ImplGlfw_InitForXXX()?");

    // Setup display size (every frame to accommodate for window resizing)
    int w, h;
    int display_w, display_h;
    glfwGetWindowSize(bd.Window, &w, &h);
    glfwGetFramebufferSize(bd.Window, &display_w, &display_h);
    io.DisplaySize = ImVec2(cast(float)w, cast(float)h);
    if (w > 0 && h > 0)
        io.DisplayFramebufferScale = ImVec2(cast(float)display_w / cast(float)w, cast(float)display_h / cast(float)h);

    // Setup time step
    double current_time = glfwGetTime();
    io.DeltaTime = bd.Time > 0.0 ? cast(float)(current_time - bd.Time) : cast(float)(1.0f / 60.0f);
    bd.Time = current_time;

    ImGui_ImplGlfw_UpdateMouseData();
    ImGui_ImplGlfw_UpdateMouseCursor();

    // Update game controllers (if enabled and available)
    ImGui_ImplGlfw_UpdateGamepads();
}

/+
#if defined(__clang__)
#pragma clang diagnostic pop
#endif
+/
