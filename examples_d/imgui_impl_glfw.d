// dear imgui: Platform Binding for GLFW
// This needs to be used along with a Renderer (e.g. OpenGL3, Vulkan..)
// (Info: GLFW is a cross-platform general purpose library for handling windows, inputs, OpenGL/Vulkan graphics context creation, etc.)
// (Requires: GLFW 3.1+)

// Implemented features:
//  [X] Platform: Clipboard support.
//  [X] Platform: Gamepad support. Enable with 'io.ConfigFlags |= ImGuiConfigFlags.NavEnableGamepad'.
//  [X] Platform: Mouse cursor shape and visibility. Disable with 'io.ConfigFlags |= ImGuiConfigFlags.NoMouseCursorChange' (note: the resizing cursors requires GLFW 3.4+).
//  [X] Platform: Keyboard arrays indexed using GLFW_KEY_* codes, e.g. ImGui.IsKeyPressed(GLFW_KEY_SPACE).

// You can copy and use unmodified imgui_impl_* files in your project. See main.cpp for an example of using this.
// If you are new to dear imgui, read examples/README.txt and read the documentation at the top of imgui.cpp.
// https://github.com/ocornut/imgui

// CHANGELOG
// (minor and older changes stripped away, please see git history for details)
//  2020-01-17: Inputs: Disable error callback while assigning mouse cursors because some X11 setup don't have them and it generates errors.
//  2019-12-05: Inputs: Added support for new mouse cursors added in GLFW 3.4+ (resizing cursors, not allowed cursor).
//  2019-10-18: Misc: Previously installed user callbacks are now restored on shutdown.
//  2019-07-21: Inputs: Added mapping for ImGuiKey_KeyPadEnter.
//  2019-05-11: Inputs: Don't filter value from character callback before calling AddInputCharacter().
//  2019-03-12: Misc: Preserve DisplayFramebufferScale when main window is minimized.
//  2018-11-30: Misc: Setting up io.BackendPlatformName so it can be displayed in the About Window.
//  2018-11-07: Inputs: When installing our GLFW callbacks, we save user's previously installed ones - if any - and chain call them.
//  2018-08-01: Inputs: Workaround for Emscripten which doesn't seem to handle focus related calls.
//  2018-06-29: Inputs: Added support for the ImGuiMouseCursor.Hand cursor.
//  2018-06-08: Misc: Extracted imgui_impl_glfw.cpp/.h away from the old combined GLFW+OpenGL/Vulkan examples.
//  2018-03-20: Misc: Setup io.BackendFlags ImGuiBackendFlags_HasMouseCursors flag + honor ImGuiConfigFlags.NoMouseCursorChange flag.
//  2018-02-20: Inputs: Added support for mouse cursors (ImGui.GetMouseCursor() value, passed to glfwSetCursor()).
//  2018-02-06: Misc: Removed call to ImGui.Shutdown() which is not available from 1.60 WIP, user needs to call CreateContext/DestroyContext themselves.
//  2018-02-06: Inputs: Added mapping for ImGuiKey_Space.
//  2018-01-25: Inputs: Added gamepad support if ImGuiConfigFlags.NavEnableGamepad is set.
//  2018-01-25: Inputs: Honoring the io.WantSetMousePos by repositioning the mouse (when using navigation and ImGuiConfigFlags.NavMoveMouse is set).
//  2018-01-20: Inputs: Added Horizontal Mouse Wheel support.
//  2018-01-18: Inputs: Added mapping for ImGuiKey_Insert.
//  2017-08-25: Inputs: MousePos set to -FLT_MAX,-FLT_MAX when mouse is unavailable/missing (instead of -1,-1).
//  2016-10-15: Misc: Added a void* user_data parameter to Clipboard function handlers.

// About GLSL version:
// The 'glsl_version' initialization parameter defaults to "#version 150" if NULL.
// Only override if your GL version doesn't handle this GLSL version. Keep NULL if unsure!

nothrow @nogc:

import ImGui = d_imgui.imgui;   //#include "imgui.h"
import d_imgui.imgui_h;
//#include "imgui_impl_glfw.h"

// GLFW
import bindbc.glfw;         //#include <GLFW/glfw3.h>

version(Windows)
{
    import core.sys.windows.windows;    // Import the platform API bindings
    mixin(bindGLFW_Windows);          // Mixin the function declarations and loader
}

//#ifdef _WIN32
//#undef APIENTRY
//#define GLFW_EXPOSE_NATIVE_WIN32
//#include <GLFW/glfw3native.h>   // for glfwGetWin32Window
//#endif
enum GLFW_VERSION               = GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100;
enum GLFW_HAS_WINDOW_TOPMOST    = GLFW_VERSION >= 3200; // 3.2+ GLFW_FLOATING
enum GLFW_HAS_WINDOW_HOVERED    = GLFW_VERSION >= 3300; // 3.3+ GLFW_HOVERED
enum GLFW_HAS_WINDOW_ALPHA      = GLFW_VERSION >= 3300; // 3.3+ glfwSetWindowOpacity
enum GLFW_HAS_PER_MONITOR_DPI   = GLFW_VERSION >= 3300; // 3.3+ glfwGetMonitorContentScale
enum GLFW_HAS_VULKAN            = GLFW_VERSION >= 3200; // 3.2+ glfwCreateWindowSurface
enum GLFW_HAS_NEW_CURSORS       = GLFW_VERSION >= 3400; // 3.4+ GLFW_RESIZE_ALL_CURSOR, GLFW_RESIZE_NESW_CURSOR, GLFW_RESIZE_NWSE_CURSOR, GLFW_NOT_ALLOWED_CURSOR
//#ifdef GLFW_RESIZE_NESW_CURSOR  // let's be nice to people who pulled GLFW between 2019-04-16 (3.4 define) and 2019-11-29 (cursors defines) // FIXME: Remove when GLFW 3.4 is released?
//#define GLFW_HAS_NEW_CURSORS          (GLFW_VERSION_MAJOR * 1000 + GLFW_VERSION_MINOR * 100 >= 3400) // 3.4+ GLFW_RESIZE_ALL_CURSOR, GLFW_RESIZE_NESW_CURSOR, GLFW_RESIZE_NWSE_CURSOR, GLFW_NOT_ALLOWED_CURSOR
//#else
//#define GLFW_HAS_NEW_CURSORS          (0)
//#endif


// Data
enum GlfwClientApi {
    Unknown,
    OpenGL,
    Vulkan
};

//enum ImGuiMouseButton_COUNT = 5;    // Todo(pp): implement in imgui_h.d, see imgui.h
//enum ImGuiMouseCursor.COUNT = 1;    // Todo(pp): implement in imgui_h.d, see imgui.h
static GLFWwindow*          g_Window = null;    // Main window
static GlfwClientApi        g_ClientApi = GlfwClientApi.Unknown;
static double               g_Time = 0.0;
static bool[ImGuiMouseButton.COUNT]               g_MouseJustPressed;
static GLFWcursor*[ImGuiMouseCursor.COUNT]        g_MouseCursors;
static bool                 g_InstalledCallbacks = false;

// Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
// D-Issue: Current limitation of BindBC-GLFW is that these function pointer types are non-@NoGC, but it'll be fixed soon.
// Our current workaround is to simply not use any previously existing callbacks, even if captured. We can do that,
// as we know that none have been assigned before, and that capturing any previously assigned ones is of educational nature.
// This BindBC-GLFW limitation is reported and will be fixed soon.
GLFWmousebuttonfun  g_PrevUserCallbackMousebutton = null;
GLFWscrollfun       g_PrevUserCallbackScroll = null;
GLFWkeyfun          g_PrevUserCallbackKey = null;
GLFWcharfun         g_PrevUserCallbackChar = null;


//static const(char)* ImGui_ImplGlfw_GetClipboardText(void* user_data) {
static string ImGui_ImplGlfw_GetClipboardText(void* user_data)
{
    import std.string : fromStringz;
    import std.exception : assumeUnique;
    return glfwGetClipboardString(cast(GLFWwindow*)user_data).fromStringz.assumeUnique;
}

static void ImGui_ImplGlfw_SetClipboardText(void* user_data, const(char)* text)
{
    glfwSetClipboardString(cast(GLFWwindow*)user_data, text);
}

extern(C) void ImGui_ImplGlfw_MouseButtonCallback(GLFWwindow* window, int button, int action, int mods)
{
    // see comment at variable deceleration
    //if (g_PrevUserCallbackMousebutton != null)
    //    g_PrevUserCallbackMousebutton(window, button, action, mods);

    if (action == GLFW_PRESS && button >= 0 && button < g_MouseJustPressed.length)
        g_MouseJustPressed[button] = true;
}

extern(C) void ImGui_ImplGlfw_ScrollCallback(GLFWwindow* window, double xoffset, double yoffset)
{
    // see comment at variable deceleration
    //if (g_PrevUserCallbackScroll != null)
    //    g_PrevUserCallbackScroll(window, xoffset, yoffset);

    ImGuiIO* io = & ImGui.GetIO();
    io.MouseWheelH += cast(float)xoffset;
    io.MouseWheel += cast(float)yoffset;
}

extern(C) void ImGui_ImplGlfw_KeyCallback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    // see comment at variable deceleration
    //if (g_PrevUserCallbackKey != null)
    //    g_PrevUserCallbackKey(window, key, scancode, action, mods);

    ImGuiIO* io = & ImGui.GetIO();
    if (action == GLFW_PRESS)
        io.KeysDown[key] = true;
    if (action == GLFW_RELEASE)
        io.KeysDown[key] = false;

    // Modifiers are not reliable across systems
    io.KeyCtrl = io.KeysDown[GLFW_KEY_LEFT_CONTROL] || io.KeysDown[GLFW_KEY_RIGHT_CONTROL];
    io.KeyShift = io.KeysDown[GLFW_KEY_LEFT_SHIFT] || io.KeysDown[GLFW_KEY_RIGHT_SHIFT];
    io.KeyAlt = io.KeysDown[GLFW_KEY_LEFT_ALT] || io.KeysDown[GLFW_KEY_RIGHT_ALT];
    version(Windows)
        io.KeySuper = false;
    else
        io.KeySuper = io.KeysDown[GLFW_KEY_LEFT_SUPER] || io.KeysDown[GLFW_KEY_RIGHT_SUPER];
}

extern(C) void ImGui_ImplGlfw_CharCallback(GLFWwindow* window, uint c)
{
    // see comment at variable deceleration
    //if (g_PrevUserCallbackChar != null)
    //    g_PrevUserCallbackChar(window, c);

    ImGuiIO* io = & ImGui.GetIO();
    io.AddInputCharacter(c);
}

static bool ImGui_ImplGlfw_Init(GLFWwindow* window, bool install_callbacks, GlfwClientApi client_api)
{
    g_Window = window;
    g_Time = 0.0;

    // Setup back-end capabilities flags
    ImGuiIO* io = & ImGui.GetIO();
    io.BackendFlags |= ImGuiBackendFlags.HasMouseCursors;         // We can honor GetMouseCursor() values (optional)
    io.BackendFlags |= ImGuiBackendFlags.HasSetMousePos;          // We can honor io.WantSetMousePos requests (optional, rarely used)
    io.BackendPlatformName = "imgui_impl_glfw";

    // Keyboard mapping. ImGui will use those indices to peek into the io.KeysDown[] array.
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

    io.SetClipboardTextFn = cast(void function(void* user_data, string text) nothrow @nogc)(& ImGui_ImplGlfw_SetClipboardText);
    io.GetClipboardTextFn = cast(string function(void* user_data) nothrow @nogc)(& ImGui_ImplGlfw_GetClipboardText);
    io.ClipboardUserData = g_Window;
    version(Windows)
    {
        loadGLFW_Windows();
        io.ImeWindowHandle = glfwGetWin32Window(g_Window);    // cast(void*)
    }

    // Create mouse cursors
    // (By design, on X11 cursors are user configurable and some cursors may be missing. When a cursor doesn't exist,
    // GLFW will emit an error which will often be printed by the app, so we temporarily disable error reporting.
    // Missing cursors will return null and our _UpdateMouseCursor() function will use the Arrow cursor instead.)
    GLFWerrorfun prev_error_callback = glfwSetErrorCallback(null);
    g_MouseCursors[ImGuiMouseCursor.Arrow] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    g_MouseCursors[ImGuiMouseCursor.TextInput] = glfwCreateStandardCursor(GLFW_IBEAM_CURSOR);
    g_MouseCursors[ImGuiMouseCursor.ResizeNS] = glfwCreateStandardCursor(GLFW_VRESIZE_CURSOR);
    g_MouseCursors[ImGuiMouseCursor.ResizeEW] = glfwCreateStandardCursor(GLFW_HRESIZE_CURSOR);
    g_MouseCursors[ImGuiMouseCursor.Hand] = glfwCreateStandardCursor(GLFW_HAND_CURSOR);
    static if (GLFW_HAS_NEW_CURSORS)
    {
        g_MouseCursors[ImGuiMouseCursor.ResizeAll]  = glfwCreateStandardCursor(GLFW_RESIZE_ALL_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.ResizeNESW] = glfwCreateStandardCursor(GLFW_RESIZE_NESW_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.ResizeNWSE] = glfwCreateStandardCursor(GLFW_RESIZE_NWSE_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.NotAllowed] = glfwCreateStandardCursor(GLFW_NOT_ALLOWED_CURSOR);
    }

    else
    {
        g_MouseCursors[ImGuiMouseCursor.ResizeAll]  = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.ResizeNESW] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.ResizeNWSE] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
        g_MouseCursors[ImGuiMouseCursor.NotAllowed] = glfwCreateStandardCursor(GLFW_ARROW_CURSOR);
    }

    glfwSetErrorCallback(prev_error_callback);

    // Chain GLFW callbacks: our callbacks will call the user's previously installed callbacks, if any.
    g_PrevUserCallbackMousebutton = null;
    g_PrevUserCallbackScroll = null;
    g_PrevUserCallbackKey = null;
    g_PrevUserCallbackChar = null;
    if (install_callbacks)
    {
        g_InstalledCallbacks = true;
        g_PrevUserCallbackMousebutton = glfwSetMouseButtonCallback(window, & ImGui_ImplGlfw_MouseButtonCallback);
        g_PrevUserCallbackScroll = glfwSetScrollCallback(window, & ImGui_ImplGlfw_ScrollCallback);
        g_PrevUserCallbackKey = glfwSetKeyCallback(window, & ImGui_ImplGlfw_KeyCallback);
        g_PrevUserCallbackChar = glfwSetCharCallback(window, & ImGui_ImplGlfw_CharCallback);
    }

    g_ClientApi = client_api;
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

void ImGui_ImplGlfw_Shutdown()
{
    if (g_InstalledCallbacks)
    {
        glfwSetMouseButtonCallback(g_Window, g_PrevUserCallbackMousebutton);
        glfwSetScrollCallback(g_Window, g_PrevUserCallbackScroll);
        glfwSetKeyCallback(g_Window, g_PrevUserCallbackKey);
        glfwSetCharCallback(g_Window, g_PrevUserCallbackChar);
        g_InstalledCallbacks = false;
    }

    for (ImGuiMouseCursor cursor_n = cast(ImGuiMouseCursor)0; cursor_n < ImGuiMouseCursor.COUNT; cursor_n++)
    {
        glfwDestroyCursor(g_MouseCursors[cursor_n]);
        g_MouseCursors[cursor_n] = null;
    }
    g_ClientApi = GlfwClientApi.Unknown;
}

static void ImGui_ImplGlfw_UpdateMousePosAndButtons()
{
    // Update buttons
    ImGuiIO* io = & ImGui.GetIO();
    for (int i = 0; i < io.MouseDown.length; i++)
    {
        // If a mouse press event came, always pass it as "mouse held this frame", so we don't miss click-release events that are shorter than 1 frame.
        io.MouseDown[i] = g_MouseJustPressed[i] || glfwGetMouseButton(g_Window, i) != 0;
        g_MouseJustPressed[i] = false;
    }

    // Update mouse position
    const ImVec2 mouse_pos_backup = io.MousePos;
    io.MousePos = ImVec2(-FLT_MAX, -FLT_MAX);
    //#ifdef __EMSCRIPTEN__
    //    const bool focused = true; // Emscripten
    //#else
    const bool focused = glfwGetWindowAttrib(g_Window, GLFW_FOCUSED) != 0;
    //#endif
    if (focused)
    {
        if (io.WantSetMousePos)
        {
            glfwSetCursorPos(g_Window, cast(double)mouse_pos_backup.x, cast(double)mouse_pos_backup.y);
        }
        else
        {
            double mouse_x, mouse_y;
            glfwGetCursorPos(g_Window, & mouse_x, & mouse_y);
            io.MousePos = ImVec2(cast(float)mouse_x, cast(float)mouse_y);
        }
    }
}

static void ImGui_ImplGlfw_UpdateMouseCursor()
{
    ImGuiIO* io = & ImGui.GetIO();
    if ((io.ConfigFlags & ImGuiConfigFlags.NoMouseCursorChange) || glfwGetInputMode(g_Window, GLFW_CURSOR) == GLFW_CURSOR_DISABLED)
        return;

    ImGuiMouseCursor imgui_cursor = ImGui.GetMouseCursor();
    if (imgui_cursor == ImGuiMouseCursor.None || io.MouseDrawCursor)
    {
        // Hide OS mouse cursor if imgui is drawing it or if it wants no cursor
        glfwSetInputMode(g_Window, GLFW_CURSOR, GLFW_CURSOR_HIDDEN);
    }
    else
    {
        // Show OS mouse cursor
        // FIXME-PLATFORM: Unfocused windows seems to fail changing the mouse cursor with GLFW 3.2, but 3.3 works here.
        glfwSetCursor(g_Window, g_MouseCursors[imgui_cursor] ? g_MouseCursors[imgui_cursor] : g_MouseCursors[ImGuiMouseCursor.Arrow]);
        glfwSetInputMode(g_Window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
    }
}


static void ImGui_ImplGlfw_UpdateGamepads()
{
    ImGuiIO* io = & ImGui.GetIO();
    memset(io.NavInputs, 0, sizeof(io.NavInputs));
    if ((io.ConfigFlags & ImGuiConfigFlags.NavEnableGamepad) == 0)
        return;

    // Update gamepad inputs

    int axes_count = 0, buttons_count = 0;
    const float* axes = glfwGetJoystickAxes(GLFW_JOYSTICK_1, & axes_count);
    const ubyte* buttons = glfwGetJoystickButtons(GLFW_JOYSTICK_1, & buttons_count);

    void MAP_BUTTON(ImGuiNavInput NAV_NO, uint BUTTON_NO)
    {
        if (buttons_count > BUTTON_NO && buttons[BUTTON_NO] == GLFW_PRESS)
            io.NavInputs[NAV_NO] = 1.0f;
    }

    void MAP_ANALOG(ImGuiNavInput NAV_NO, uint AXIS_NO, float V0, float V1)
    {
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
    ImGuiIO* io = & ImGui.GetIO();
    IM_ASSERT(io.Fonts.IsBuilt() && "Font atlas not built! It is generally built by the renderer back-end. Missing call to renderer _NewFrame() function? e.g. ImGui_ImplOpenGL3_NewFrame().");

    // Setup display size (every frame to accommodate for window resizing)
    int w, h;
    int display_w, display_h;
    glfwGetWindowSize(g_Window, & w, & h);
    glfwGetFramebufferSize(g_Window, & display_w, & display_h);
    io.DisplaySize = ImVec2(cast(float)w, cast(float)h);
    if (w > 0 && h > 0)
        io.DisplayFramebufferScale = ImVec2(cast(float)display_w / w, cast(float)display_h / h);

    // Setup time step
    double current_time = glfwGetTime();
    io.DeltaTime = g_Time > 0.0 ? cast(float)(current_time - g_Time) : (1.0f / 60.0f);
    g_Time = current_time;

    ImGui_ImplGlfw_UpdateMousePosAndButtons();
    ImGui_ImplGlfw_UpdateMouseCursor();

    // Update game controllers (if enabled and available)
    ImGui_ImplGlfw_UpdateGamepads();
}
