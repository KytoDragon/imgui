// dear imgui: Platform Backend for GLFW
// This needs to be used along with a Renderer (e.g. OpenGL3, Vulkan, WebGPU..)
// (Info: GLFW is a cross-platform general purpose library for handling windows, inputs, OpenGL/Vulkan graphics context creation, etc.)
// (Requires: GLFW 3.1+)

// Implemented features:
//  [X] Platform: Clipboard support.
//  [X] Platform: Gamepad support. Enable with 'io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags_NoMouseCursorChange' (note: the resizing cursors requires GLFW 3.4+).
//  [X] Platform: Keyboard arrays indexed using GLFW_KEY_* codes, e.g. ImGui::IsKeyPressed(GLFW_KEY_SPACE).

// You can use unmodified imgui_impl_* files in your project. See examples/ folder for examples of using this.
// Prefer including the entire imgui/ repository into your project (either as a copy or as a submodule), and only build the backends you need.
// If you are new to Dear ImGui, read documentation from the docs/ folder + read the top of imgui.cpp.
// Read online: https://github.com/ocornut/imgui/tree/master/docs

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
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

nothrow @nogc:

import ImGui = d_imgui.imgui;
import d_imgui.imgui_h;

// GLFW
/+
#include <GLFW/glfw3.h>
#ifdef _WIN32
#undef APIENTRY
#define GLFW_EXPOSE_NATIVE_WIN32
#include <GLFW/glfw3native.h>   // for glfwGetWin32Window
#endif
+/
enum GLFW_VERSION               = GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100;
enum GLFW_HAS_WINDOW_TOPMOST       = (GLFW_VERSION >= 3200); // 3.2+ GLFW_FLOATING
enum GLFW_HAS_WINDOW_HOVERED       = (GLFW_VERSION >= 3300); // 3.3+ GLFW_HOVERED
enum GLFW_HAS_WINDOW_ALPHA         = (GLFW_VERSION >= 3300); // 3.3+ glfwSetWindowOpacity
enum GLFW_HAS_PER_MONITOR_DPI      = (GLFW_VERSION >= 3300); // 3.3+ glfwGetMonitorContentScale
enum GLFW_HAS_VULKAN               = (GLFW_VERSION >= 3200); // 3.2+ glfwCreateWindowSurface
//#ifdef GLFW_RESIZE_NESW_CURSOR        // Let's be nice to people who pulled GLFW between 2019-04-16 (3.4 define) and 2019-11-29 (cursors defines) // FIXME: Remove when GLFW 3.4 is released?
enum GLFW_HAS_NEW_CURSORS          = (GLFW_VERSION >= 3400); // 3.4+ GLFW_RESIZE_ALL_CURSOR, GLFW_RESIZE_NESW_CURSOR, GLFW_RESIZE_NWSE_CURSOR, GLFW_NOT_ALLOWED_CURSOR
//#else
//#define GLFW_HAS_NEW_CURSORS          (0)
//#endif

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
    bool[ImGuiMouseButton.COUNT]                    MouseJustPressed;
    GLFWcursor*[ImGuiMouseCursor.COUNT]             MouseCursors;
    bool                    InstalledCallbacks;

    // Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
    GLFWwindowfocusfun      PrevUserCallbackWindowFocus;
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

extern(C) void ImGui_ImplGlfw_MouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackMousebutton != NULL && window == bd.Window)
        bd.PrevUserCallbackMousebutton(window, button, action, mods);

    if (action == GLFW_PRESS && button >= 0 && button < IM_ARRAYSIZE(bd.MouseJustPressed))
        bd.MouseJustPressed[button] = true;
}

extern(C) void ImGui_ImplGlfw_ScrollCallback(GLFWwindow* window, double xoffset, double yoffset)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackScroll != NULL && window == bd.Window)
        bd.PrevUserCallbackScroll(window, xoffset, yoffset);

    ImGuiIO* io = &ImGui.GetIO();
    io.MouseWheelH += cast(float)xoffset;
    io.MouseWheel += cast(float)yoffset;
}

extern(C) void ImGui_ImplGlfw_KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackKey != NULL && window == bd.Window)
        bd.PrevUserCallbackKey(window, key, scancode, action, mods);

    ImGuiIO* io = &ImGui.GetIO();
    if (key >= 0 && key < IM_ARRAYSIZE(io.KeysDown))
    {
        if (action == GLFW_PRESS)
            io.KeysDown[key] = true;
        if (action == GLFW_RELEASE)
            io.KeysDown[key] = false;
    }

    // Modifiers are not reliable across systems
    io.KeyCtrl = io.KeysDown[GLFW_KEY_LEFT_CONTROL] || io.KeysDown[GLFW_KEY_RIGHT_CONTROL];
    io.KeyShift = io.KeysDown[GLFW_KEY_LEFT_SHIFT] || io.KeysDown[GLFW_KEY_RIGHT_SHIFT];
    io.KeyAlt = io.KeysDown[GLFW_KEY_LEFT_ALT] || io.KeysDown[GLFW_KEY_RIGHT_ALT];
version(Windows) {
    io.KeySuper = false;
} else {
    io.KeySuper = io.KeysDown[GLFW_KEY_LEFT_SUPER] || io.KeysDown[GLFW_KEY_RIGHT_SUPER];
}
}

extern(C) void ImGui_ImplGlfw_WindowFocusCallback(GLFWwindow* window, int focused)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackWindowFocus != NULL && window == bd.Window)
        bd.PrevUserCallbackWindowFocus(window, focused);

    ImGuiIO* io = &ImGui.GetIO();
    io.AddFocusEvent(focused != 0);
}

extern(C) void ImGui_ImplGlfw_CursorEnterCallback(GLFWwindow* window, int entered)
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    if (bd.PrevUserCallbackCursorEnter != NULL && window == bd.Window)
        bd.PrevUserCallbackCursorEnter(window, entered);

    if (entered)
        bd.MouseWindow = window;
    if (!entered && bd.MouseWindow == window)
        bd.MouseWindow = NULL;
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

    // Keyboard mapping. Dear ImGui will use those indices to peek into the io.KeysDown[] array.
    io.KeyMap[ImGuiKey.Tab] = GLFW_KEY_TAB;
    io.KeyMap[ImGuiKey.LeftArrow] = GLFW_KEY_LEFT;
    io.KeyMap[ImGuiKey.RightArrow] = GLFW_KEY_RIGHT;
    io.KeyMap[ImGuiKey.UpArrow] = GLFW_KEY_UP;
    io.KeyMap[ImGuiKey.DownArrow] = GLFW_KEY_DOWN;
    io.KeyMap[ImGuiKey.PageUp] = GLFW_KEY_PAGE_UP;
    io.KeyMap[ImGuiKey.PageDown] = GLFW_KEY_PAGE_DOWN;
    io.KeyMap[ImGuiKey.Home] = GLFW_KEY_HOME;
    io.KeyMap[ImGuiKey.End] = GLFW_KEY_END;
    io.KeyMap[ImGuiKey.Insert] = GLFW_KEY_INSERT;
    io.KeyMap[ImGuiKey.Delete] = GLFW_KEY_DELETE;
    io.KeyMap[ImGuiKey.Backspace] = GLFW_KEY_BACKSPACE;
    io.KeyMap[ImGuiKey.Space] = GLFW_KEY_SPACE;
    io.KeyMap[ImGuiKey.Enter] = GLFW_KEY_ENTER;
    io.KeyMap[ImGuiKey.Escape] = GLFW_KEY_ESCAPE;
    io.KeyMap[ImGuiKey.KeyPadEnter] = GLFW_KEY_KP_ENTER;
    io.KeyMap[ImGuiKey.A] = GLFW_KEY_A;
    io.KeyMap[ImGuiKey.C] = GLFW_KEY_C;
    io.KeyMap[ImGuiKey.V] = GLFW_KEY_V;
    io.KeyMap[ImGuiKey.X] = GLFW_KEY_X;
    io.KeyMap[ImGuiKey.Y] = GLFW_KEY_Y;
    io.KeyMap[ImGuiKey.Z] = GLFW_KEY_Z;

    io.SetClipboardTextFn = &ImGui_ImplGlfw_SetClipboardText;
    io.GetClipboardTextFn = &ImGui_ImplGlfw_GetClipboardText;
    io.ClipboardUserData = bd.Window;
version(Windows) {
    loadGLFW_Windows();
    io.ImeWindowHandle = cast(void*)glfwGetWin32Window(bd.Window);
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
    bd.PrevUserCallbackWindowFocus = NULL;
    bd.PrevUserCallbackMousebutton = NULL;
    bd.PrevUserCallbackScroll = NULL;
    bd.PrevUserCallbackKey = NULL;
    bd.PrevUserCallbackChar = NULL;
    bd.PrevUserCallbackMonitor = NULL;
    if (install_callbacks)
    {
        bd.InstalledCallbacks = true;
        bd.PrevUserCallbackWindowFocus = glfwSetWindowFocusCallback(window, &ImGui_ImplGlfw_WindowFocusCallback);
        bd.PrevUserCallbackCursorEnter = glfwSetCursorEnterCallback(window, &ImGui_ImplGlfw_CursorEnterCallback);
        bd.PrevUserCallbackMousebutton = glfwSetMouseButtonCallback(window, &ImGui_ImplGlfw_MouseButtonCallback);
        bd.PrevUserCallbackScroll = glfwSetScrollCallback(window, &ImGui_ImplGlfw_ScrollCallback);
        bd.PrevUserCallbackKey = glfwSetKeyCallback(window, &ImGui_ImplGlfw_KeyCallback);
        bd.PrevUserCallbackChar = glfwSetCharCallback(window, &ImGui_ImplGlfw_CharCallback);
        bd.PrevUserCallbackMonitor = glfwSetMonitorCallback(&ImGui_ImplGlfw_MonitorCallback);
    }

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
    {
        glfwSetWindowFocusCallback(bd.Window, bd.PrevUserCallbackWindowFocus);
        glfwSetCursorEnterCallback(bd.Window, bd.PrevUserCallbackCursorEnter);
        glfwSetMouseButtonCallback(bd.Window, bd.PrevUserCallbackMousebutton);
        glfwSetScrollCallback(bd.Window, bd.PrevUserCallbackScroll);
        glfwSetKeyCallback(bd.Window, bd.PrevUserCallbackKey);
        glfwSetCharCallback(bd.Window, bd.PrevUserCallbackChar);
        glfwSetMonitorCallback(bd.PrevUserCallbackMonitor);
    }

    for (ImGuiMouseCursor cursor_n = cast(ImGuiMouseCursor)0; cursor_n < ImGuiMouseCursor.COUNT; cursor_n++)
        glfwDestroyCursor(bd.MouseCursors[cursor_n]);

    io.BackendPlatformName = NULL;
    io.BackendPlatformUserData = NULL;
    IM_DELETE(bd);
}

static void ImGui_ImplGlfw_UpdateMousePosAndButtons()
{
    ImGui_ImplGlfw_Data* bd = ImGui_ImplGlfw_GetBackendData();
    ImGuiIO* io = &ImGui.GetIO();

    const ImVec2 mouse_pos_prev = io.MousePos;
    io.MousePos = ImVec2(-FLT_MAX, -FLT_MAX);

    // Update mouse buttons
    // (if a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame)
    for (int i = 0; i < IM_ARRAYSIZE(io.MouseDown); i++)
    {
        io.MouseDown[i] = bd.MouseJustPressed[i] || glfwGetMouseButton(bd.Window, i) != 0;
        bd.MouseJustPressed[i] = false;
    }

//#ifdef __EMSCRIPTEN__
//    const bool focused = true;
//#else
    const bool focused = glfwGetWindowAttrib(bd.Window, GLFW_FOCUSED) != 0;
//#endif
    GLFWwindow* mouse_window = (bd.MouseWindow == bd.Window || focused) ? bd.Window : NULL;

    // Set OS mouse position from Dear ImGui if requested (rarely used, only when ImGuiConfigFlags_NavEnableSetMousePos is enabled by user)
    if (io.WantSetMousePos && focused)
        glfwSetCursorPos(bd.Window, cast(double)mouse_pos_prev.x, cast(double)mouse_pos_prev.y);

    // Set Dear ImGui mouse position from OS position
    if (mouse_window != NULL)
    {
        double mouse_x, mouse_y;
        glfwGetCursorPos(mouse_window, &mouse_x, &mouse_y);
        io.MousePos = ImVec2(cast(float)mouse_x, cast(float)mouse_y);
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

static void ImGui_ImplGlfw_UpdateGamepads()
{
    ImGuiIO* io = &ImGui.GetIO();
    memset(io.NavInputs, 0, sizeof(io.NavInputs));
    if ((io.ConfigFlags & ImGuiConfigFlags.NavEnableGamepad) == 0)
        return;

    // Update gamepad inputs
    int axes_count = 0, buttons_count = 0;
    const float* axes = glfwGetJoystickAxes(GLFW_JOYSTICK_1, &axes_count);
    const ubyte* buttons = glfwGetJoystickButtons(GLFW_JOYSTICK_1, &buttons_count);

    pragma(inline, true) void MAP_BUTTON(ImGuiNavInput NAV_NO, uint BUTTON_NO) {
        if (buttons_count > BUTTON_NO && buttons[BUTTON_NO] == GLFW_PRESS)
            io.NavInputs[NAV_NO] = 1.0f;
    }

    pragma(inline, true) void MAP_ANALOG(ImGuiNavInput NAV_NO, uint AXIS_NO, float V0, float V1) {
        float v = (axes_count > AXIS_NO) ? axes[AXIS_NO] : V0;
        v = (v - V0) / (V1 - V0);
        if (v > 1.0f)
            v = 1.0f;
        if (io.NavInputs[NAV_NO] < v)
            io.NavInputs[NAV_NO] = v;
    }

    MAP_BUTTON(ImGuiNavInput.Activate,   0);     // Cross / A
    MAP_BUTTON(ImGuiNavInput.Cancel,     1);     // Circle / B
    MAP_BUTTON(ImGuiNavInput.Menu,       2);     // Square / X
    MAP_BUTTON(ImGuiNavInput.Input,      3);     // Triangle / Y
    MAP_BUTTON(ImGuiNavInput.DpadLeft,   13);    // D-Pad Left
    MAP_BUTTON(ImGuiNavInput.DpadRight,  11);    // D-Pad Right
    MAP_BUTTON(ImGuiNavInput.DpadUp,     10);    // D-Pad Up
    MAP_BUTTON(ImGuiNavInput.DpadDown,   12);    // D-Pad Down
    MAP_BUTTON(ImGuiNavInput.FocusPrev,  4);     // L1 / LB
    MAP_BUTTON(ImGuiNavInput.FocusNext,  5);     // R1 / RB
    MAP_BUTTON(ImGuiNavInput.TweakSlow,  4);     // L1 / LB
    MAP_BUTTON(ImGuiNavInput.TweakFast,  5);     // R1 / RB
    MAP_ANALOG(ImGuiNavInput.LStickLeft, 0,  -0.3f,  -0.9f);
    MAP_ANALOG(ImGuiNavInput.LStickRight,0,  +0.3f,  +0.9f);
    MAP_ANALOG(ImGuiNavInput.LStickUp,   1,  +0.3f,  +0.9f);
    MAP_ANALOG(ImGuiNavInput.LStickDown, 1,  -0.3f,  -0.9f);
    //#undef MAP_BUTTON
    //#undef MAP_ANALOG
    if (axes_count > 0 && buttons_count > 0)
        io.BackendFlags |= ImGuiBackendFlags.HasGamepad;
    else
        io.BackendFlags &= ~ImGuiBackendFlags.HasGamepad;
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
        io.DisplayFramebufferScale = ImVec2(cast(float)display_w / w, cast(float)display_h / h);

    // Setup time step
    double current_time = glfwGetTime();
    io.DeltaTime = bd.Time > 0.0 ? cast(float)(current_time - bd.Time) : cast(float)(1.0f / 60.0f);
    bd.Time = current_time;

    ImGui_ImplGlfw_UpdateMousePosAndButtons();
    ImGui_ImplGlfw_UpdateMouseCursor();

    // Update game controllers (if enabled and available)
    ImGui_ImplGlfw_UpdateGamepads();
}
