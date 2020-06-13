module d_imgui.imgui_h;
// dear imgui, v1.76
// (headers)

// Help:
// - Read FAQ at http://dearimgui.org/faq
// - Newcomers, read 'Programmer guide' in imgui.cpp for notes on how to setup Dear ImGui in your codebase.
// - Call and read ImGui::ShowDemoWindow() in imgui_demo.cpp for demo code. All applications in examples/ are doing that.
// Read imgui.cpp for details, links and comments.

// Resources:
// - FAQ                   http://dearimgui.org/faq
// - Homepage & latest     https://github.com/ocornut/imgui
// - Releases & changelog  https://github.com/ocornut/imgui/releases
// - Gallery               https://github.com/ocornut/imgui/issues/3075 (please post your screenshots/video there!)
// - Glossary              https://github.com/ocornut/imgui/wiki/Glossary
// - Wiki                  https://github.com/ocornut/imgui/wiki
// - Issues & support      https://github.com/ocornut/imgui/issues

/*

Index of this file:
// Header mess
// Forward declarations and basic types
// ImGui API (Dear ImGui end-user API)
// Flags & Enumerations
// Memory allocations macros
// ImVector<>
// ImGuiStyle
// ImGuiIO
// Misc data structures (ImGuiInputTextCallbackData, ImGuiSizeCallbackData, ImGuiPayload)
// Obsolete functions
// Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, ImColor)
// Draw List API (ImDrawCallback, ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
// Font API (ImFontConfig, ImFontGlyph, ImFontGlyphRangesBuilder, ImFontAtlasFlags, ImFontAtlas, ImFont)

*/

// #pragma once

// Configuration file with compile-time options (edit imconfig.h or #define IMGUI_USER_CONFIG to your own filename)
// #ifdef IMGUI_USER_CONFIG
// #include IMGUI_USER_CONFIG
// #endif
// #if !defined(IMGUI_DISABLE_INCLUDE_IMCONFIG_H) || defined(IMGUI_INCLUDE_IMCONFIG_H)
import d_imgui.imconfig;
// #endif

// #ifndef IMGUI_DISABLE

//-----------------------------------------------------------------------------
// Header mess
//-----------------------------------------------------------------------------

// Includes
// #include <float.h>                  // FLT_MIN, FLT_MAX
immutable float FLT_MIN = float.min_normal;
immutable float FLT_MAX = float.max;
immutable float DBL_MAX = double.max;
immutable int INT_MIN = int.min;
immutable int INT_MAX = int.max;
import d_snprintf.vararg;                 // va_list, va_start, va_end
// #include <stddef.h>                 // ptrdiff_t, NULL
enum NULL = null;
// #include <string.h>                 // memset, memmove, memcpy, strlen, strchr, strcpy, strcmp
import core.stdc.string : memset, memmove, memcpy, memcmp, strlen, strchr, strcpy, strcmp;
import core.stdc.stdlib : alloca;

import d_imgui.imgui_internal;
import d_imgui.imgui;
import d_imgui.imgui_draw;
import d_imgui.imgui_widgets;

nothrow:
@nogc:

// D_IMGUI: System compile-time enums (for static ifs)
version (Windows) {
    enum D_IMGUI_Windows = true;
} else {
    enum D_IMGUI_Windows = false;
}
version (OSX) {
    enum D_IMGUI_Apple = true;
} else {
    enum D_IMGUI_Apple = false;
}

// Version
// (Integer encoded as XYYZZ for use in #if preprocessor conditionals. Work in progress versions typically starts at XYY99 then bounce up to XYY00, XYY01 etc. when release tagging happens)
enum IMGUI_VERSION              = "1.76";
enum IMGUI_VERSION_NUM          = 17600;
pragma(inline, true) void IMGUI_CHECKVERSION()        { DebugCheckVersionAndDataLayout(IMGUI_VERSION, sizeof!(ImGuiIO), sizeof!(ImGuiStyle), sizeof!(ImVec2), sizeof!(ImVec4), sizeof!(ImDrawVert), sizeof!(ImDrawIdx));}

pragma(inline, true) int sizeof(T)() {return cast(int)T.sizeof;}
pragma(inline, true) int sizeof(T)(T t) {return cast(int)T.sizeof;}

// D_IMGUI: D doesn't properly initialise empty strings
enum EMPTY_STRING = "\0"[0..0];

// Define attributes of all API symbols declarations (e.g. for DLL under Windows)
// IMGUI_API is used for core imgui functions, IMGUI_IMPL_API is used for the default bindings files (imgui_impl_xxx.h)
// Using dear imgui via a shared library is not recommended, because we don't guarantee backward nor forward ABI compatibility (also function call overhead, as dear imgui is a call-heavy API)
// #ifndef IMGUI_API
// #define IMGUI_API
// #endif
// #ifndef IMGUI_IMPL_API
// #define IMGUI_IMPL_API              IMGUI_API
// #endif

// Helper Macros
static if (!D_IMGUI_USER_DEFINED_ASSERT) {
}
    pragma(inline, true) void IM_ASSERT(T)(T _EXPR) {assert(_EXPR);}                               // You can override the default assert handler by editing imconfig.h
    pragma(inline, true) void IM_ASSERT(T)(T _EXPR, string _MSG) {assert(_EXPR, _MSG);} // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
// #if !defined(IMGUI_USE_STB_SPRINTF) && (defined(__clang__) || defined(__GNUC__))
// #define IM_FMTARGS(FMT)             __attribute__((format(printf, FMT, FMT+1))) // To apply printf-style warnings to our functions.
// #define IM_FMTLIST(FMT)             __attribute__((format(printf, FMT, 0)))
// #else
// #define IM_FMTARGS(FMT)
// #define IM_FMTLIST(FMT)
// #endif
pragma(inline, true) int IM_ARRAYSIZE(T, size_t N)(T[N] _ARR) { return cast(int)N;}       // Size of a static C-style array. Don't use on pointers!
pragma(inline, true) void IM_UNUSED(T)(T _VAR) {(cast(void)_VAR);}                                // Used to silence "unused variable warnings". Often useful as asserts may be stripped out from final builds.
// #if (__cplusplus >= 201100)
// #define IM_OFFSETOF(_TYPE,_MEMBER)  offsetof(_TYPE, _MEMBER)                    // Offset of _MEMBER within _TYPE. Standardized as offsetof() in C++11
// #else
// #define IM_OFFSETOF(_TYPE,_MEMBER)  ((size_t)&(((_TYPE*)0)->_MEMBER))           // Offset of _MEMBER within _TYPE. Old style macro.
// #endif

// Warnings
// #if defined(__clang__)
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wold-style-cast"
// #if __has_warning("-Wzero-as-null-pointer-constant")
// #pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
// #endif
// #elif defined(__GNUC__)
// #pragma GCC diagnostic push
// #pragma GCC diagnostic ignored "-Wpragmas"                  // warning: unknown option after '#pragma GCC diagnostic' kind
// #pragma GCC diagnostic ignored "-Wclass-memaccess"          // [__GNUC__ >= 8] warning: 'memset/memcpy' clearing/writing an object of type 'xxxx' with no trivial copy-assignment; use assignment or value-initialization instead
// #endif

//-----------------------------------------------------------------------------
// Forward declarations and basic types
//-----------------------------------------------------------------------------

// Forward declarations
// struct ImDrawChannel;               // Temporary storage to output draw commands out of order, used by ImDrawListSplitter and ImDrawList::ChannelsSplit()
// struct ImDrawCmd;                   // A single draw command within a parent ImDrawList (generally maps to 1 GPU draw call, unless it is a callback)
// struct ImDrawData;                  // All draw command lists required to render the frame + pos/size coordinates to use for the projection matrix.
// struct ImDrawList;                  // A single draw command list (generally one per window, conceptually you may see this as a dynamic "mesh" builder)
// struct ImDrawListSharedData;        // Data shared among multiple draw lists (typically owned by parent ImGui context, but you may create one yourself)
// struct ImDrawListSplitter;          // Helper to split a draw list into different layers which can be drawn into out of order, then flattened back.
// struct ImDrawVert;                  // A single vertex (pos + uv + col = 20 bytes by default. Override layout with IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT)
// struct ImFont;                      // Runtime data for a single font within a parent ImFontAtlas
// struct ImFontAtlas;                 // Runtime data for multiple fonts, bake multiple fonts into a single texture, TTF/OTF font loader
// struct ImFontConfig;                // Configuration data when adding a font or merging fonts
// struct ImFontGlyph;                 // A single font glyph (code point + coordinates within in ImFontAtlas + offset)
// struct ImFontGlyphRangesBuilder;    // Helper to build glyph ranges from text/string data
// struct ImColor;                     // Helper functions to create a color that can be converted to either u32 or float4 (*OBSOLETE* please avoid using)
// struct ImGuiContext;                // Dear ImGui context (opaque structure, unless including imgui_internal.h)
// struct ImGuiIO;                     // Main configuration and I/O between your application and ImGui
// struct ImGuiInputTextCallbackData;  // Shared state of InputText() when using custom ImGuiInputTextCallback (rare/advanced use)
// struct ImGuiListClipper;            // Helper to manually clip large list of items
// struct ImGuiOnceUponAFrame;         // Helper for running a block of code not more than once a frame, used by IMGUI_ONCE_UPON_A_FRAME macro
// struct ImGuiPayload;                // User data payload for drag and drop operations
// struct ImGuiSizeCallbackData;       // Callback data when using SetNextWindowSizeConstraints() (rare/advanced use)
// struct ImGuiStorage;                // Helper for key->value storage
// struct ImGuiStyle;                  // Runtime data for styling/colors
// struct ImGuiTextBuffer;             // Helper to hold and append into a text buffer (~string builder)
// struct ImGuiTextFilter;             // Helper to parse and apply text filters (e.g. "aaaaa[,bbbbb][,ccccc]")

// Enums/Flags (declared as int for compatibility with old C++, to allow using as flags and to not pollute the top of this file)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   In Visual Studio IDE: CTRL+comma ("Edit.NavigateTo") can follow symbols in comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   With Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols in comments.
// typedef int ImGuiCol;               // -> enum ImGuiCol_             // Enum: A color identifier for styling
// typedef int ImGuiCond;              // -> enum ImGuiCond_            // Enum: A condition for many Set*() functions
// typedef int ImGuiDataType;          // -> enum ImGuiDataType_        // Enum: A primary data type
// typedef int ImGuiDir;               // -> enum ImGuiDir_             // Enum: A cardinal direction
// typedef int ImGuiKey;               // -> enum ImGuiKey_             // Enum: A key identifier (ImGui-side enum)
// typedef int ImGuiNavInput;          // -> enum ImGuiNavInput_        // Enum: An input identifier for navigation
// typedef int ImGuiMouseButton;       // -> enum ImGuiMouseButton_     // Enum: A mouse button identifier (0=left, 1=right, 2=middle)
// typedef int ImGuiMouseCursor;       // -> enum ImGuiMouseCursor_     // Enum: A mouse cursor identifier
// typedef int ImGuiStyleVar;          // -> enum ImGuiStyleVar_        // Enum: A variable identifier for styling
// typedef int ImDrawCornerFlags;      // -> enum ImDrawCornerFlags_    // Flags: for ImDrawList::AddRect(), AddRectFilled() etc.
// typedef int ImDrawListFlags;        // -> enum ImDrawListFlags_      // Flags: for ImDrawList
// typedef int ImFontAtlasFlags;       // -> enum ImFontAtlasFlags_     // Flags: for ImFontAtlas
// typedef int ImGuiBackendFlags;      // -> enum ImGuiBackendFlags_    // Flags: for io.BackendFlags
// typedef int ImGuiColorEditFlags;    // -> enum ImGuiColorEditFlags_  // Flags: for ColorEdit4(), ColorPicker4() etc.
// typedef int ImGuiConfigFlags;       // -> enum ImGuiConfigFlags_     // Flags: for io.ConfigFlags
// typedef int ImGuiComboFlags;        // -> enum ImGuiComboFlags_      // Flags: for BeginCombo()
// typedef int ImGuiDragDropFlags;     // -> enum ImGuiDragDropFlags_   // Flags: for BeginDragDropSource(), AcceptDragDropPayload()
// typedef int ImGuiFocusedFlags;      // -> enum ImGuiFocusedFlags_    // Flags: for IsWindowFocused()
// typedef int ImGuiHoveredFlags;      // -> enum ImGuiHoveredFlags_    // Flags: for IsItemHovered(), IsWindowHovered() etc.
// typedef int ImGuiInputTextFlags;    // -> enum ImGuiInputTextFlags_  // Flags: for InputText(), InputTextMultiline()
// typedef int ImGuiKeyModFlags;       // -> enum ImGuiKeyModFlags_     // Flags: for io.KeyMods (Ctrl/Shift/Alt/Super)
// typedef int ImGuiSelectableFlags;   // -> enum ImGuiSelectableFlags_ // Flags: for Selectable()
// typedef int ImGuiTabBarFlags;       // -> enum ImGuiTabBarFlags_     // Flags: for BeginTabBar()
// typedef int ImGuiTabItemFlags;      // -> enum ImGuiTabItemFlags_    // Flags: for BeginTabItem()
// typedef int ImGuiTreeNodeFlags;     // -> enum ImGuiTreeNodeFlags_   // Flags: for TreeNode(), TreeNodeEx(), CollapsingHeader()
// typedef int ImGuiWindowFlags;       // -> enum ImGuiWindowFlags_     // Flags: for Begin(), BeginChild()

// Other types
// #ifndef ImTextureID                 // ImTextureID [configurable type: override in imconfig.h with '#define ImTextureID xxx']
// typedef void* ImTextureID;          // User data for rendering back-end to identify a texture. This is whatever to you want it to be! read the FAQ about ImTextureID for details.
// #endif
alias ImGuiID = uint;       // A unique ID used by widgets, typically hashed from a stack of string.
alias ImGuiInputTextCallback = int function(ImGuiInputTextCallbackData*);
alias ImGuiSizeCallback = void function(ImGuiSizeCallbackData*);

// Decoded character types
// (we generally use UTF-8 encoded string in the API. This is storage specifically for a decoded character used for keyboard input and display)
alias ImWchar16 = ushort;   // A single decoded U16 character/code point. We encode them as multi bytes UTF-8 when used in strings.
alias ImWchar32 = uint;     // A single decoded U32 character/code point. We encode them as multi bytes UTF-8 when used in strings.
version (IMGUI_USE_WCHAR32) {            // ImWchar [configurable type: override in imconfig.h with '#define IMGUI_USE_WCHAR32' to support Unicode planes 1-16]
    alias ImWchar = ImWchar32;
} else {
    alias ImWchar = ImWchar16;
}

// Basic scalar data types
alias ImS8 = byte;   // 8-bit signed integer
alias ImU8 = ubyte;   // 8-bit unsigned integer
alias ImS16 = short;  // 16-bit signed integer
alias ImU16 = ushort;  // 16-bit unsigned integer
alias ImS32 = int;  // 32-bit signed integer == int
alias ImU32 = uint;  // 32-bit unsigned integer (often used to store packed colors)
alias ImS64 = long;  // 64-bit signed integer
alias ImU64 = ulong;  // 64-bit unsigned integer

// 2D vector (often used to store positions or sizes)
struct ImVec2
{
    nothrow:
    @nogc:

    float                                   x = 0.0f, y = 0.0f;
    this(float _x, float _y)              { x = _x; y = _y; }
    float  opIndex(size_t idx) const    { IM_ASSERT(idx <= 1); return (&x)[idx]; }    // We very rarely use this [] operator, the assert overhead is fine.
    ref float opIndex(size_t idx)          { IM_ASSERT(idx <= 1); return (&x)[idx]; }    // We very rarely use this [] operator, the assert overhead is fine.
    // #ifdef IM_VEC2_CLASS_EXTRA
    //     IM_VEC2_CLASS_EXTRA     // Define additional constructors and implicit cast operators in imconfig.h to convert back and forth between your math types and ImVec2.
    // #endif

    pragma(inline, true) ImVec2 opBinary(string op)(float rhs) const {
        static if (op == "*") {
            return ImVec2(this.x*rhs, this.y*rhs);
        } else static if (op == "/") {
            return ImVec2(this.x/rhs, this.y/rhs);
        }
    }
    pragma(inline, true) ImVec2 opBinary(string op)(const /*ref*/ ImVec2 rhs) const {
        static if (op == "+") {
            return ImVec2(this.x+rhs.x, this.y+rhs.y);
        } else static if (op == "-") {
            return ImVec2(this.x-rhs.x, this.y-rhs.y);
        } else static if (op == "*") {
            return ImVec2(this.x*rhs.x, this.y*rhs.y);
        } else static if (op == "/") {
            return ImVec2(this.x/rhs.x, this.y/rhs.y);
        }
    }
    pragma(inline, true) ref ImVec2 opOpAssign(string op)(float rhs) {
        static if (op == "*") {
            this.x *= rhs;
            this.y *= rhs;
            return this;
        } else static if (op == "/") {
            this.x /= rhs;
            this.y /= rhs;
            return this;
        }
    }
    pragma(inline, true) ref ImVec2 opOpAssign(string op)(const /*ref*/ ImVec2 rhs) {
        static if (op == "+") {
            this.x += rhs.x;
            this.y += rhs.y;
            return this;
        } else static if (op == "-") {
            this.x -= rhs.x;
            this.y -= rhs.y;
            return this;
        } else static if (op == "*") {
            this.x *= rhs.x;
            this.y *= rhs.y;
            return this;
        } else static if (op == "/") {
            this.x /= rhs.x;
            this.y /= rhs.y;
            return this;
        }
    }
}

// 4D vector (often used to store floating-point colors)
struct ImVec4
{
    nothrow:
    @nogc:

    float                                   x = 0.0f, y = 0.0f, z = 0.0f, w = 0.0f;
    this(float _x, float _y, float _z, float _w)  { x = _x; y = _y; z = _z; w = _w; }
    // #ifdef IM_VEC4_CLASS_EXTRA
    //     IM_VEC4_CLASS_EXTRA     // Define additional constructors and implicit cast operators in imconfig.h to convert back and forth between your math types and ImVec4.
    // #endif

    pragma(inline, true) ImVec4 opBinary(string op)(const /*ref*/ ImVec4 rhs) const {
        static if (op == "+") {
            return ImVec4(this.x+rhs.x, this.y+rhs.y, this.z+rhs.z, this.w+rhs.w);
        } else static if (op == "-") {
            return ImVec4(this.x-rhs.x, this.y-rhs.y, this.z-rhs.z, this.w-rhs.w);
        } else static if (op == "*") {
            return ImVec4(this.x*rhs.x, this.y*rhs.y, this.z*rhs.z, this.w*rhs.w);
        }
    }
    
    pragma(inline, true) float[] array() return {
        return (&x)[0..4];
    }
}

//-----------------------------------------------------------------------------
// ImGui: Dear ImGui end-user API
// (This is a namespace. You can add extra ImGui:: functions in your own separate file. Please don't modify imgui source files!)
//-----------------------------------------------------------------------------

/+
namespace ImGui
{
    // Context creation and access
    // Each context create its own ImFontAtlas by default. You may instance one yourself and pass it to CreateContext() to share a font atlas between imgui contexts.
    // None of those functions is reliant on the current context.
    IMGUI_API ImGuiContext* CreateContext(ImFontAtlas* shared_font_atlas = NULL);
    IMGUI_API void          DestroyContext(ImGuiContext* ctx = NULL);   // NULL = destroy current context
    IMGUI_API ImGuiContext* GetCurrentContext();
    IMGUI_API void          SetCurrentContext(ImGuiContext* ctx);

    // Main
    IMGUI_API ImGuiIO&      GetIO();                                    // access the IO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
    IMGUI_API ImGuiStyle&   GetStyle();                                 // access the Style structure (colors, sizes). Always use PushStyleCol(), PushStyleVar() to modify style mid-frame!
    IMGUI_API void          NewFrame();                                 // start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
    IMGUI_API void          EndFrame();                                 // ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
    IMGUI_API void          Render();                                   // ends the Dear ImGui frame, finalize the draw data. You can get call GetDrawData() to obtain it and run your rendering function (up to v1.60, this used to call io.RenderDrawListsFn(). Nowadays, we allow and prefer calling your render function yourself.)
    IMGUI_API ImDrawData*   GetDrawData();                              // valid after Render() and until the next call to NewFrame(). this is what you have to render.

    // Demo, Debug, Information
    IMGUI_API void          ShowDemoWindow(bool* p_open = NULL);        // create Demo window (previously called ShowTestWindow). demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
    IMGUI_API void          ShowAboutWindow(bool* p_open = NULL);       // create About window. display Dear ImGui version, credits and build/system information.
    IMGUI_API void          ShowMetricsWindow(bool* p_open = NULL);     // create Debug/Metrics window. display Dear ImGui internals: draw commands (with individual draw calls and vertices), window list, basic internal state, etc.
    IMGUI_API void          ShowStyleEditor(ImGuiStyle* ref = NULL);    // add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
    IMGUI_API bool          ShowStyleSelector(const char* label);       // add style selector block (not a window), essentially a combo listing the default styles.
    IMGUI_API void          ShowFontSelector(const char* label);        // add font selector block (not a window), essentially a combo listing the loaded fonts.
    IMGUI_API void          ShowUserGuide();                            // add basic help/info block (not a window): how to manipulate ImGui as a end-user (mouse/keyboard controls).
    IMGUI_API const char*   GetVersion();                               // get the compiled version string e.g. "1.23" (essentially the compiled value for IMGUI_VERSION)

    // Styles
    IMGUI_API void          StyleColorsDark(ImGuiStyle* dst = NULL);    // new, recommended style (default)
    IMGUI_API void          StyleColorsClassic(ImGuiStyle* dst = NULL); // classic imgui style
    IMGUI_API void          StyleColorsLight(ImGuiStyle* dst = NULL);   // best used with borders and a custom, thicker font

    // Windows
    // - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
    // - You may append multiple times to the same window during the same frame.
    // - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
    //   which clicking will set the boolean to false when clicked.
    // - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
    //   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
    //   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
    //    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
    //    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
    // - Note that the bottom of window stack always contains a window called "Debug".
    IMGUI_API bool          Begin(const char* name, bool* p_open = NULL, ImGuiWindowFlags flags = 0);
    IMGUI_API void          End();

    // Child Windows
    // - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
    // - For each independent axis of 'size': ==0.0f: use remaining host window size / >0.0f: fixed size / <0.0f: use remaining window size minus abs(size) / Each axis can use a different mode, e.g. ImVec2(0,400).
    // - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.
    //   Always call a matching EndChild() for each BeginChild() call, regardless of its return value [as with Begin: this is due to legacy reason and inconsistent with most BeginXXX functions apart from the regular Begin() which behaves like BeginChild().]
    IMGUI_API bool          BeginChild(const char* str_id, const ImVec2& size = ImVec2(0,0), bool border = false, ImGuiWindowFlags flags = 0);
    IMGUI_API bool          BeginChild(ImGuiID id, const ImVec2& size = ImVec2(0,0), bool border = false, ImGuiWindowFlags flags = 0);
    IMGUI_API void          EndChild();

    // Windows Utilities
    // - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
    IMGUI_API bool          IsWindowAppearing();
    IMGUI_API bool          IsWindowCollapsed();
    IMGUI_API bool          IsWindowFocused(ImGuiFocusedFlags flags=0); // is current window focused? or its root/child, depending on flags. see flags for options.
    IMGUI_API bool          IsWindowHovered(ImGuiHoveredFlags flags=0); // is current window hovered (and typically: not blocked by a popup/modal)? see flags for options. NB: If you are trying to check whether your mouse should be dispatched to imgui or to your app, you should use the 'io.WantCaptureMouse' boolean for that! Please read the FAQ!
    IMGUI_API ImDrawList*   GetWindowDrawList();                        // get draw list associated to the current window, to append your own drawing primitives
    IMGUI_API ImVec2        GetWindowPos();                             // get current window position in screen space (useful if you want to do your own drawing via the DrawList API)
    IMGUI_API ImVec2        GetWindowSize();                            // get current window size
    IMGUI_API float         GetWindowWidth();                           // get current window width (shortcut for GetWindowSize().x)
    IMGUI_API float         GetWindowHeight();                          // get current window height (shortcut for GetWindowSize().y)

    // Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
    IMGUI_API void          SetNextWindowPos(const ImVec2& pos, ImGuiCond cond = 0, const ImVec2& pivot = ImVec2(0,0)); // set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
    IMGUI_API void          SetNextWindowSize(const ImVec2& size, ImGuiCond cond = 0);                  // set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
    IMGUI_API void          SetNextWindowSizeConstraints(const ImVec2& size_min, const ImVec2& size_max, ImGuiSizeCallback custom_callback = NULL, void* custom_callback_data = NULL); // set next window size limits. use -1,-1 on either X/Y axis to preserve the current size. Sizes will be rounded down. Use callback to apply non-trivial programmatic constraints.
    IMGUI_API void          SetNextWindowContentSize(const ImVec2& size);                               // set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
    IMGUI_API void          SetNextWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                 // set next window collapsed state. call before Begin()
    IMGUI_API void          SetNextWindowFocus();                                                       // set next window to be focused / top-most. call before Begin()
    IMGUI_API void          SetNextWindowBgAlpha(float alpha);                                          // set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
    IMGUI_API void          SetWindowPos(const ImVec2& pos, ImGuiCond cond = 0);                        // (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
    IMGUI_API void          SetWindowSize(const ImVec2& size, ImGuiCond cond = 0);                      // (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0,0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
    IMGUI_API void          SetWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                     // (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
    IMGUI_API void          SetWindowFocus();                                                           // (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
    IMGUI_API void          SetWindowFontScale(float scale);                                            // set font scale. Adjust IO.FontGlobalScale if you want to scale all windows. This is an old API! For correct scaling, prefer to reload font + rebuild ImFontAtlas + call style.ScaleAllSizes().
    IMGUI_API void          SetWindowPos(const char* name, const ImVec2& pos, ImGuiCond cond = 0);      // set named window position.
    IMGUI_API void          SetWindowSize(const char* name, const ImVec2& size, ImGuiCond cond = 0);    // set named window size. set axis to 0.0f to force an auto-fit on this axis.
    IMGUI_API void          SetWindowCollapsed(const char* name, bool collapsed, ImGuiCond cond = 0);   // set named window collapsed state
    IMGUI_API void          SetWindowFocus(const char* name);                                           // set named window to be focused / top-most. use NULL to remove focus.

    // Content region
    // - Those functions are bound to be redesigned soon (they are confusing, incomplete and return values in local window coordinates which increases confusion)
    IMGUI_API ImVec2        GetContentRegionMax();                                          // current content boundaries (typically window boundaries including scrolling, or current column boundaries), in windows coordinates
    IMGUI_API ImVec2        GetContentRegionAvail();                                        // == GetContentRegionMax() - GetCursorPos()
    IMGUI_API ImVec2        GetWindowContentRegionMin();                                    // content boundaries min (roughly (0,0)-Scroll), in window coordinates
    IMGUI_API ImVec2        GetWindowContentRegionMax();                                    // content boundaries max (roughly (0,0)+Size-Scroll) where Size can be override with SetNextWindowContentSize(), in window coordinates
    IMGUI_API float         GetWindowContentRegionWidth();                                  //

    // Windows Scrolling
    IMGUI_API float         GetScrollX();                                                   // get scrolling amount [0..GetScrollMaxX()]
    IMGUI_API float         GetScrollY();                                                   // get scrolling amount [0..GetScrollMaxY()]
    IMGUI_API float         GetScrollMaxX();                                                // get maximum scrolling amount ~~ ContentSize.X - WindowSize.X
    IMGUI_API float         GetScrollMaxY();                                                // get maximum scrolling amount ~~ ContentSize.Y - WindowSize.Y
    IMGUI_API void          SetScrollX(float scroll_x);                                     // set scrolling amount [0..GetScrollMaxX()]
    IMGUI_API void          SetScrollY(float scroll_y);                                     // set scrolling amount [0..GetScrollMaxY()]
    IMGUI_API void          SetScrollHereX(float center_x_ratio = 0.5f);                    // adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    IMGUI_API void          SetScrollHereY(float center_y_ratio = 0.5f);                    // adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    IMGUI_API void          SetScrollFromPosX(float local_x, float center_x_ratio = 0.5f);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
    IMGUI_API void          SetScrollFromPosY(float local_y, float center_y_ratio = 0.5f);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.

    // Parameters stacks (shared)
    IMGUI_API void          PushFont(ImFont* font);                                         // use NULL as a shortcut to push default font
    IMGUI_API void          PopFont();
    IMGUI_API void          PushStyleColor(ImGuiCol idx, ImU32 col);
    IMGUI_API void          PushStyleColor(ImGuiCol idx, const ImVec4& col);
    IMGUI_API void          PopStyleColor(int count = 1);
    IMGUI_API void          PushStyleVar(ImGuiStyleVar idx, float val);
    IMGUI_API void          PushStyleVar(ImGuiStyleVar idx, const ImVec2& val);
    IMGUI_API void          PopStyleVar(int count = 1);
    IMGUI_API const ImVec4& GetStyleColorVec4(ImGuiCol idx);                                // retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.
    IMGUI_API ImFont*       GetFont();                                                      // get current font
    IMGUI_API float         GetFontSize();                                                  // get current font size (= height in pixels) of current font with current scale applied
    IMGUI_API ImVec2        GetFontTexUvWhitePixel();                                       // get UV coordinate for a while pixel, useful to draw custom shapes via the ImDrawList API
    IMGUI_API ImU32         GetColorU32(ImGuiCol idx, float alpha_mul = 1.0f);              // retrieve given style color with style alpha applied and optional extra alpha multiplier
    IMGUI_API ImU32         GetColorU32(const ImVec4& col);                                 // retrieve given color with style alpha applied
    IMGUI_API ImU32         GetColorU32(ImU32 col);                                         // retrieve given color with style alpha applied

    // Parameters stacks (current window)
    IMGUI_API void          PushItemWidth(float item_width);                                // push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -1.0f always align width to the right side). 0.0f = default to ~2/3 of windows width,
    IMGUI_API void          PopItemWidth();
    IMGUI_API void          SetNextItemWidth(float item_width);                             // set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -1.0f always align width to the right side)
    IMGUI_API float         CalcItemWidth();                                                // width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
    IMGUI_API void          PushTextWrapPos(float wrap_local_pos_x = 0.0f);                 // push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
    IMGUI_API void          PopTextWrapPos();
    IMGUI_API void          PushAllowKeyboardFocus(bool allow_keyboard_focus);              // allow focusing using TAB/Shift-TAB, enabled by default but you can disable it for certain widgets
    IMGUI_API void          PopAllowKeyboardFocus();
    IMGUI_API void          PushButtonRepeat(bool repeat);                                  // in 'repeat' mode, Button*() functions return repeated true in a typematic manner (using io.KeyRepeatDelay/io.KeyRepeatRate setting). Note that you can call IsItemActive() after any Button() to tell if the button is held in the current frame.
    IMGUI_API void          PopButtonRepeat();

    // Cursor / Layout
    // - By "cursor" we mean the current output position.
    // - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
    // - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceeding widget.
    // - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
    //    Window-local coordinates:   SameLine(), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), GetContentRegionMax(), GetWindowContentRegion*(), PushTextWrapPos()
    //    Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions.
    IMGUI_API void          Separator();                                                    // separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
    IMGUI_API void          SameLine(float offset_from_start_x=0.0f, float spacing=-1.0f);  // call between widgets or groups to layout them horizontally. X position given in window coordinates.
    IMGUI_API void          NewLine();                                                      // undo a SameLine() or force a new line when in an horizontal-layout context.
    IMGUI_API void          Spacing();                                                      // add vertical spacing.
    IMGUI_API void          Dummy(const ImVec2& size);                                      // add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
    IMGUI_API void          Indent(float indent_w = 0.0f);                                  // move content position toward the right, by style.IndentSpacing or indent_w if != 0
    IMGUI_API void          Unindent(float indent_w = 0.0f);                                // move content position back to the left, by style.IndentSpacing or indent_w if != 0
    IMGUI_API void          BeginGroup();                                                   // lock horizontal starting position
    IMGUI_API void          EndGroup();                                                     // unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
    IMGUI_API ImVec2        GetCursorPos();                                                 // cursor position in window coordinates (relative to window position)
    IMGUI_API float         GetCursorPosX();                                                //   (some functions are using window-relative coordinates, such as: GetCursorPos, GetCursorStartPos, GetContentRegionMax, GetWindowContentRegion* etc.
    IMGUI_API float         GetCursorPosY();                                                //    other functions such as GetCursorScreenPos or everything in ImDrawList::
    IMGUI_API void          SetCursorPos(const ImVec2& local_pos);                          //    are using the main, absolute coordinate system.
    IMGUI_API void          SetCursorPosX(float local_x);                                   //    GetWindowPos() + GetCursorPos() == GetCursorScreenPos() etc.)
    IMGUI_API void          SetCursorPosY(float local_y);                                   //
    IMGUI_API ImVec2        GetCursorStartPos();                                            // initial cursor position in window coordinates
    IMGUI_API ImVec2        GetCursorScreenPos();                                           // cursor position in absolute screen coordinates [0..io.DisplaySize] (useful to work with ImDrawList API)
    IMGUI_API void          SetCursorScreenPos(const ImVec2& pos);                          // cursor position in absolute screen coordinates [0..io.DisplaySize]
    IMGUI_API void          AlignTextToFramePadding();                                      // vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
    IMGUI_API float         GetTextLineHeight();                                            // ~ FontSize
    IMGUI_API float         GetTextLineHeightWithSpacing();                                 // ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
    IMGUI_API float         GetFrameHeight();                                               // ~ FontSize + style.FramePadding.y * 2
    IMGUI_API float         GetFrameHeightWithSpacing();                                    // ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)

    // ID stack/scopes
    // - Read the FAQ for more details about how ID are handled in dear imgui. If you are creating widgets in a loop you most
    //   likely want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
    // - The resulting ID are hashes of the entire stack.
    // - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
    // - In this header file we use the "label"/"name" terminology to denote a string that will be displayed and used as an ID,
    //   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
    IMGUI_API void          PushID(const char* str_id);                                     // push string into the ID stack (will hash string).
    IMGUI_API void          PushID(const char* str_id_begin, const char* str_id_end);       // push string into the ID stack (will hash string).
    IMGUI_API void          PushID(const void* ptr_id);                                     // push pointer into the ID stack (will hash pointer).
    IMGUI_API void          PushID(int int_id);                                             // push integer into the ID stack (will hash integer).
    IMGUI_API void          PopID();                                                        // pop from the ID stack.
    IMGUI_API ImGuiID       GetID(const char* str_id);                                      // calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
    IMGUI_API ImGuiID       GetID(const char* str_id_begin, const char* str_id_end);
    IMGUI_API ImGuiID       GetID(const void* ptr_id);

    // Widgets: Text
    IMGUI_API void          TextUnformatted(const char* text, const char* text_end = NULL); // raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
    IMGUI_API void          Text(const char* fmt, ...)                                      IM_FMTARGS(1); // formatted text
    IMGUI_API void          TextV(const char* fmt, va_list args)                            IM_FMTLIST(1);
    IMGUI_API void          TextColored(const ImVec4& col, const char* fmt, ...)            IM_FMTARGS(2); // shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
    IMGUI_API void          TextColoredV(const ImVec4& col, const char* fmt, va_list args)  IM_FMTLIST(2);
    IMGUI_API void          TextDisabled(const char* fmt, ...)                              IM_FMTARGS(1); // shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
    IMGUI_API void          TextDisabledV(const char* fmt, va_list args)                    IM_FMTLIST(1);
    IMGUI_API void          TextWrapped(const char* fmt, ...)                               IM_FMTARGS(1); // shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
    IMGUI_API void          TextWrappedV(const char* fmt, va_list args)                     IM_FMTLIST(1);
    IMGUI_API void          LabelText(const char* label, const char* fmt, ...)              IM_FMTARGS(2); // display text+label aligned the same way as value+label widgets
    IMGUI_API void          LabelTextV(const char* label, const char* fmt, va_list args)    IM_FMTLIST(2);
    IMGUI_API void          BulletText(const char* fmt, ...)                                IM_FMTARGS(1); // shortcut for Bullet()+Text()
    IMGUI_API void          BulletTextV(const char* fmt, va_list args)                      IM_FMTLIST(1);

    // Widgets: Main
    // - Most widgets return true when the value has been changed or when pressed/selected
    // - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
    IMGUI_API bool          Button(const char* label, const ImVec2& size = ImVec2(0,0));    // button
    IMGUI_API bool          SmallButton(const char* label);                                 // button with FramePadding=(0,0) to easily embed within text
    IMGUI_API bool          InvisibleButton(const char* str_id, const ImVec2& size);        // button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
    IMGUI_API bool          ArrowButton(const char* str_id, ImGuiDir dir);                  // square button with an arrow shape
    IMGUI_API void          Image(ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0 = ImVec2(0,0), const ImVec2& uv1 = ImVec2(1,1), const ImVec4& tint_col = ImVec4(1,1,1,1), const ImVec4& border_col = ImVec4(0,0,0,0));
    IMGUI_API bool          ImageButton(ImTextureID user_texture_id, const ImVec2& size, const ImVec2& uv0 = ImVec2(0,0),  const ImVec2& uv1 = ImVec2(1,1), int frame_padding = -1, const ImVec4& bg_col = ImVec4(0,0,0,0), const ImVec4& tint_col = ImVec4(1,1,1,1));    // <0 frame_padding uses default frame padding settings. 0 for no padding
    IMGUI_API bool          Checkbox(const char* label, bool* v);
    IMGUI_API bool          CheckboxFlags(const char* label, unsigned int* flags, unsigned int flags_value);
    IMGUI_API bool          RadioButton(const char* label, bool active);                    // use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
    IMGUI_API bool          RadioButton(const char* label, int* v, int v_button);           // shortcut to handle the above pattern when value is an integer
    IMGUI_API void          ProgressBar(float fraction, const ImVec2& size_arg = ImVec2(-1,0), const char* overlay = NULL);
    IMGUI_API void          Bullet();                                                       // draw a small circle and keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses

    // Widgets: Combo Box
    // - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
    // - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose.
    IMGUI_API bool          BeginCombo(const char* label, const char* preview_value, ImGuiComboFlags flags = 0);
    IMGUI_API void          EndCombo(); // only call EndCombo() if BeginCombo() returns true!
    IMGUI_API bool          Combo(const char* label, int* current_item, const char* const items[], int items_count, int popup_max_height_in_items = -1);
    IMGUI_API bool          Combo(const char* label, int* current_item, const char* items_separated_by_zeros, int popup_max_height_in_items = -1);      // Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
    IMGUI_API bool          Combo(const char* label, int* current_item, bool(*items_getter)(void* data, int idx, const char** out_text), void* data, int items_count, int popup_max_height_in_items = -1);

    // Widgets: Drags
    // - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped and can go off-bounds.
    // - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every functions, note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    // - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For gamepad/keyboard navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
    // - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits.
    // - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
    // - Use v_min > v_max to lock edits.
    IMGUI_API bool          DragFloat(const char* label, float* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const char* format = "%.3f", float power = 1.0f);     // If v_min >= v_max we have no bound
    IMGUI_API bool          DragFloat2(const char* label, float v[2], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          DragFloat3(const char* label, float v[3], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          DragFloat4(const char* label, float v[4], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          DragFloatRange2(const char* label, float* v_current_min, float* v_current_max, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, const char* format = "%.3f", const char* format_max = NULL, float power = 1.0f);
    IMGUI_API bool          DragInt(const char* label, int* v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const char* format = "%d");                                       // If v_min >= v_max we have no bound
    IMGUI_API bool          DragInt2(const char* label, int v[2], float v_speed = 1.0f, int v_min = 0, int v_max = 0, const char* format = "%d");
    IMGUI_API bool          DragInt3(const char* label, int v[3], float v_speed = 1.0f, int v_min = 0, int v_max = 0, const char* format = "%d");
    IMGUI_API bool          DragInt4(const char* label, int v[4], float v_speed = 1.0f, int v_min = 0, int v_max = 0, const char* format = "%d");
    IMGUI_API bool          DragIntRange2(const char* label, int* v_current_min, int* v_current_max, float v_speed = 1.0f, int v_min = 0, int v_max = 0, const char* format = "%d", const char* format_max = NULL);
    IMGUI_API bool          DragScalar(const char* label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min = NULL, const void* p_max = NULL, const char* format = NULL, float power = 1.0f);
    IMGUI_API bool          DragScalarN(const char* label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min = NULL, const void* p_max = NULL, const char* format = NULL, float power = 1.0f);

    // Widgets: Sliders
    // - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped and can go off-bounds.
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    IMGUI_API bool          SliderFloat(const char* label, float* v, float v_min, float v_max, const char* format = "%.3f", float power = 1.0f);     // adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display. Use power!=1.0 for power curve sliders
    IMGUI_API bool          SliderFloat2(const char* label, float v[2], float v_min, float v_max, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          SliderFloat3(const char* label, float v[3], float v_min, float v_max, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          SliderFloat4(const char* label, float v[4], float v_min, float v_max, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          SliderAngle(const char* label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = +360.0f, const char* format = "%.0f deg");
    IMGUI_API bool          SliderInt(const char* label, int* v, int v_min, int v_max, const char* format = "%d");
    IMGUI_API bool          SliderInt2(const char* label, int v[2], int v_min, int v_max, const char* format = "%d");
    IMGUI_API bool          SliderInt3(const char* label, int v[3], int v_min, int v_max, const char* format = "%d");
    IMGUI_API bool          SliderInt4(const char* label, int v[4], int v_min, int v_max, const char* format = "%d");
    IMGUI_API bool          SliderScalar(const char* label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const char* format = NULL, float power = 1.0f);
    IMGUI_API bool          SliderScalarN(const char* label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, const char* format = NULL, float power = 1.0f);
    IMGUI_API bool          VSliderFloat(const char* label, const ImVec2& size, float* v, float v_min, float v_max, const char* format = "%.3f", float power = 1.0f);
    IMGUI_API bool          VSliderInt(const char* label, const ImVec2& size, int* v, int v_min, int v_max, const char* format = "%d");
    IMGUI_API bool          VSliderScalar(const char* label, const ImVec2& size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, const char* format = NULL, float power = 1.0f);

    // Widgets: Input with Keyboard
    // - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
    // - Most of the ImGuiInputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
    IMGUI_API bool          InputText(const char* label, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    IMGUI_API bool          InputTextMultiline(const char* label, char* buf, size_t buf_size, const ImVec2& size = ImVec2(0,0), ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    IMGUI_API bool          InputTextWithHint(const char* label, const char* hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    IMGUI_API bool          InputFloat(const char* label, float* v, float step = 0.0f, float step_fast = 0.0f, const char* format = "%.3f", ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputFloat2(const char* label, float v[2], const char* format = "%.3f", ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputFloat3(const char* label, float v[3], const char* format = "%.3f", ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputFloat4(const char* label, float v[4], const char* format = "%.3f", ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputInt(const char* label, int* v, int step = 1, int step_fast = 100, ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputInt2(const char* label, int v[2], ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputInt3(const char* label, int v[3], ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputInt4(const char* label, int v[4], ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputDouble(const char* label, double* v, double step = 0.0, double step_fast = 0.0, const char* format = "%.6f", ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputScalar(const char* label, ImGuiDataType data_type, void* p_data, const void* p_step = NULL, const void* p_step_fast = NULL, const char* format = NULL, ImGuiInputTextFlags flags = 0);
    IMGUI_API bool          InputScalarN(const char* label, ImGuiDataType data_type, void* p_data, int components, const void* p_step = NULL, const void* p_step_fast = NULL, const char* format = NULL, ImGuiInputTextFlags flags = 0);

    // Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little colored preview square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
    // - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
    // - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
    IMGUI_API bool          ColorEdit3(const char* label, float col[3], ImGuiColorEditFlags flags = 0);
    IMGUI_API bool          ColorEdit4(const char* label, float col[4], ImGuiColorEditFlags flags = 0);
    IMGUI_API bool          ColorPicker3(const char* label, float col[3], ImGuiColorEditFlags flags = 0);
    IMGUI_API bool          ColorPicker4(const char* label, float col[4], ImGuiColorEditFlags flags = 0, const float* ref_col = NULL);
    IMGUI_API bool          ColorButton(const char* desc_id, const ImVec4& col, ImGuiColorEditFlags flags = 0, ImVec2 size = ImVec2(0,0));  // display a colored square/button, hover for details, return true when pressed.
    IMGUI_API void          SetColorEditOptions(ImGuiColorEditFlags flags);                     // initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.

    // Widgets: Trees
    // - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
    IMGUI_API bool          TreeNode(const char* label);
    IMGUI_API bool          TreeNode(const char* str_id, const char* fmt, ...) IM_FMTARGS(2);   // helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
    IMGUI_API bool          TreeNode(const void* ptr_id, const char* fmt, ...) IM_FMTARGS(2);   // "
    IMGUI_API bool          TreeNodeV(const char* str_id, const char* fmt, va_list args) IM_FMTLIST(2);
    IMGUI_API bool          TreeNodeV(const void* ptr_id, const char* fmt, va_list args) IM_FMTLIST(2);
    IMGUI_API bool          TreeNodeEx(const char* label, ImGuiTreeNodeFlags flags = 0);
    IMGUI_API bool          TreeNodeEx(const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, ...) IM_FMTARGS(3);
    IMGUI_API bool          TreeNodeEx(const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, ...) IM_FMTARGS(3);
    IMGUI_API bool          TreeNodeExV(const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, va_list args) IM_FMTLIST(3);
    IMGUI_API bool          TreeNodeExV(const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, va_list args) IM_FMTLIST(3);
    IMGUI_API void          TreePush(const char* str_id);                                       // ~ Indent()+PushId(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
    IMGUI_API void          TreePush(const void* ptr_id = NULL);                                // "
    IMGUI_API void          TreePop();                                                          // ~ Unindent()+PopId()
    IMGUI_API float         GetTreeNodeToLabelSpacing();                                        // horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
    IMGUI_API bool          CollapsingHeader(const char* label, ImGuiTreeNodeFlags flags = 0);  // if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
    IMGUI_API bool          CollapsingHeader(const char* label, bool* p_open, ImGuiTreeNodeFlags flags = 0); // when 'p_open' isn't NULL, display an additional small close button on upper right of the header
    IMGUI_API void          SetNextItemOpen(bool is_open, ImGuiCond cond = 0);                  // set next TreeNode/CollapsingHeader open state.

    // Widgets: Selectables
    // - A selectable highlights when hovered, and can display another color when selected.
    // - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
    IMGUI_API bool          Selectable(const char* label, bool selected = false, ImGuiSelectableFlags flags = 0, const ImVec2& size = ImVec2(0,0));  // "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
    IMGUI_API bool          Selectable(const char* label, bool* p_selected, ImGuiSelectableFlags flags = 0, const ImVec2& size = ImVec2(0,0));       // "bool* p_selected" point to the selection state (read-write), as a convenient helper.

    // Widgets: List Boxes
    // - FIXME: To be consistent with all the newer API, ListBoxHeader/ListBoxFooter should in reality be called BeginListBox/EndListBox. Will rename them.
    IMGUI_API bool          ListBox(const char* label, int* current_item, const char* const items[], int items_count, int height_in_items = -1);
    IMGUI_API bool          ListBox(const char* label, int* current_item, bool (*items_getter)(void* data, int idx, const char** out_text), void* data, int items_count, int height_in_items = -1);
    IMGUI_API bool          ListBoxHeader(const char* label, const ImVec2& size = ImVec2(0,0)); // use if you want to reimplement ListBox() will custom data or interactions. if the function return true, you can output elements then call ListBoxFooter() afterwards.
    IMGUI_API bool          ListBoxHeader(const char* label, int items_count, int height_in_items = -1); // "
    IMGUI_API void          ListBoxFooter();                                                    // terminate the scrolling region. only call ListBoxFooter() if ListBoxHeader() returned true!

    // Widgets: Data Plotting
    IMGUI_API void          PlotLines(const char* label, const float* values, int values_count, int values_offset = 0, const char* overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof(float));
    IMGUI_API void          PlotLines(const char* label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, const char* overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0));
    IMGUI_API void          PlotHistogram(const char* label, const float* values, int values_count, int values_offset = 0, const char* overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof(float));
    IMGUI_API void          PlotHistogram(const char* label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, const char* overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0));

    // Widgets: Value() Helpers.
    // - Those are merely shortcut to calling Text() with a format string. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
    IMGUI_API void          Value(const char* prefix, bool b);
    IMGUI_API void          Value(const char* prefix, int v);
    IMGUI_API void          Value(const char* prefix, unsigned int v);
    IMGUI_API void          Value(const char* prefix, float v, const char* float_format = NULL);

    // Widgets: Menus
    // - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
    // - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
    // - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
    IMGUI_API bool          BeginMenuBar();                                                     // append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
    IMGUI_API void          EndMenuBar();                                                       // only call EndMenuBar() if BeginMenuBar() returns true!
    IMGUI_API bool          BeginMainMenuBar();                                                 // create and append to a full screen menu-bar.
    IMGUI_API void          EndMainMenuBar();                                                   // only call EndMainMenuBar() if BeginMainMenuBar() returns true!
    IMGUI_API bool          BeginMenu(const char* label, bool enabled = true);                  // create a sub-menu entry. only call EndMenu() if this returns true!
    IMGUI_API void          EndMenu();                                                          // only call EndMenu() if BeginMenu() returns true!
    IMGUI_API bool          MenuItem(const char* label, const char* shortcut = NULL, bool selected = false, bool enabled = true);  // return true when activated. shortcuts are displayed for convenience but not processed by ImGui at the moment
    IMGUI_API bool          MenuItem(const char* label, const char* shortcut, bool* p_selected, bool enabled = true);              // return true when activated + toggle (*p_selected) if p_selected != NULL

    // Tooltips
    // - Tooltip are windows following the mouse which do not take focus away.
    IMGUI_API void          BeginTooltip();                                                     // begin/append a tooltip window. to create full-featured tooltip (with any kind of items).
    IMGUI_API void          EndTooltip();
    IMGUI_API void          SetTooltip(const char* fmt, ...) IM_FMTARGS(1);                     // set a text-only tooltip, typically use with ImGui::IsItemHovered(). override any previous call to SetTooltip().
    IMGUI_API void          SetTooltipV(const char* fmt, va_list args) IM_FMTLIST(1);

    // Popups, Modals
    // The properties of popups windows are:
    // - They block normal mouse hovering detection outside them. (*)
    // - Unless modal, they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    // - Their visibility state (~bool) is held internally by imgui instead of being held by the programmer as we are used to with regular Begin() calls.
    //   User can manipulate the visibility state by calling OpenPopup().
    // - We default to use the right mouse (ImGuiMouseButton_Right=1) for the Popup Context functions.
    // (*) You can use IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByPopup) to bypass it and detect hovering even when normally blocked by a popup.
    // Those three properties are connected. The library needs to hold their visibility state because it can close popups at any time.
    IMGUI_API void          OpenPopup(const char* str_id);                                      // call to mark popup as open (don't call every frame!). popups are closed when user click outside, or if CloseCurrentPopup() is called within a BeginPopup()/EndPopup() block. By default, Selectable()/MenuItem() are calling CloseCurrentPopup(). Popup identifiers are relative to the current ID-stack (so OpenPopup and BeginPopup needs to be at the same level).
    IMGUI_API bool          BeginPopup(const char* str_id, ImGuiWindowFlags flags = 0);                                             // return true if the popup is open, and you can start outputting to it. only call EndPopup() if BeginPopup() returns true!
    IMGUI_API bool          BeginPopupContextItem(const char* str_id = NULL, ImGuiMouseButton mouse_button = 1);                    // helper to open and begin popup when clicked on last item. if you can pass a NULL str_id only if the previous item had an id. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
    IMGUI_API bool          BeginPopupContextWindow(const char* str_id = NULL, ImGuiMouseButton mouse_button = 1, bool also_over_items = true);  // helper to open and begin popup when clicked on current window.
    IMGUI_API bool          BeginPopupContextVoid(const char* str_id = NULL, ImGuiMouseButton mouse_button = 1);                    // helper to open and begin popup when clicked in void (where there are no imgui windows).
    IMGUI_API bool          BeginPopupModal(const char* name, bool* p_open = NULL, ImGuiWindowFlags flags = 0);                     // modal dialog (regular window with title bar, block interactions behind the modal window, can't close the modal window by clicking outside)
    IMGUI_API void          EndPopup();                                                                                             // only call EndPopup() if BeginPopupXXX() returns true!
    IMGUI_API bool          OpenPopupOnItemClick(const char* str_id = NULL, ImGuiMouseButton mouse_button = 1);                     // helper to open popup when clicked on last item (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors). return true when just opened.
    IMGUI_API bool          IsPopupOpen(const char* str_id);                                    // return true if the popup is open at the current begin-ed level of the popup stack.
    IMGUI_API void          CloseCurrentPopup();                                                // close the popup we have begin-ed into. clicking on a MenuItem or Selectable automatically close the current popup.

    // Columns
    // - You can also use SameLine(pos_x) to mimic simplified columns.
    // - The columns API is work-in-progress and rather lacking (columns are arguably the worst part of dear imgui at the moment!)
    // - There is a maximum of 64 columns.
    // - Currently working on new 'Tables' api which will replace columns around Q2 2020 (see GitHub #2957).
    IMGUI_API void          Columns(int count = 1, const char* id = NULL, bool border = true);
    IMGUI_API void          NextColumn();                                                       // next column, defaults to current row or next row if the current row is finished
    IMGUI_API int           GetColumnIndex();                                                   // get current column index
    IMGUI_API float         GetColumnWidth(int column_index = -1);                              // get column width (in pixels). pass -1 to use current column
    IMGUI_API void          SetColumnWidth(int column_index, float width);                      // set column width (in pixels). pass -1 to use current column
    IMGUI_API float         GetColumnOffset(int column_index = -1);                             // get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
    IMGUI_API void          SetColumnOffset(int column_index, float offset_x);                  // set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
    IMGUI_API int           GetColumnsCount();

    // Tab Bars, Tabs
    IMGUI_API bool          BeginTabBar(const char* str_id, ImGuiTabBarFlags flags = 0);        // create and append into a TabBar
    IMGUI_API void          EndTabBar();                                                        // only call EndTabBar() if BeginTabBar() returns true!
    IMGUI_API bool          BeginTabItem(const char* label, bool* p_open = NULL, ImGuiTabItemFlags flags = 0);// create a Tab. Returns true if the Tab is selected.
    IMGUI_API void          EndTabItem();                                                       // only call EndTabItem() if BeginTabItem() returns true!
    IMGUI_API void          SetTabItemClosed(const char* tab_or_docked_window_label);           // notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.

    // Logging/Capture
    // - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
    IMGUI_API void          LogToTTY(int auto_open_depth = -1);                                 // start logging to tty (stdout)
    IMGUI_API void          LogToFile(int auto_open_depth = -1, const char* filename = NULL);   // start logging to file
    IMGUI_API void          LogToClipboard(int auto_open_depth = -1);                           // start logging to OS clipboard
    IMGUI_API void          LogFinish();                                                        // stop logging (close file, etc.)
    IMGUI_API void          LogButtons();                                                       // helper to display buttons for logging to tty/file/clipboard
    IMGUI_API void          LogText(const char* fmt, ...) IM_FMTARGS(1);                        // pass text data straight to log (without being displayed)

    // Drag and Drop
    // - [BETA API] API may evolve!
    IMGUI_API bool          BeginDragDropSource(ImGuiDragDropFlags flags = 0);                                      // call when the current item is active. If this return true, you can call SetDragDropPayload() + EndDragDropSource()
    IMGUI_API bool          SetDragDropPayload(const char* type, const void* data, size_t sz, ImGuiCond cond = 0);  // type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui.
    IMGUI_API void          EndDragDropSource();                                                                    // only call EndDragDropSource() if BeginDragDropSource() returns true!
    IMGUI_API bool                  BeginDragDropTarget();                                                          // call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
    IMGUI_API const ImGuiPayload*   AcceptDragDropPayload(const char* type, ImGuiDragDropFlags flags = 0);          // accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
    IMGUI_API void                  EndDragDropTarget();                                                            // only call EndDragDropTarget() if BeginDragDropTarget() returns true!
    IMGUI_API const ImGuiPayload*   GetDragDropPayload();                                                           // peek directly into the current payload from anywhere. may return NULL. use ImGuiPayload::IsDataType() to test for the payload type.

    // Clipping
    IMGUI_API void          PushClipRect(const ImVec2& clip_rect_min, const ImVec2& clip_rect_max, bool intersect_with_current_clip_rect);
    IMGUI_API void          PopClipRect();

    // Focus, Activation
    // - Prefer using "SetItemDefaultFocus()" over "if (IsWindowAppearing()) SetScrollHereY()" when applicable to signify "this is the default item"
    IMGUI_API void          SetItemDefaultFocus();                                              // make last item the default focused item of a window.
    IMGUI_API void          SetKeyboardFocusHere(int offset = 0);                               // focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.

    // Item/Widgets Utilities
    // - Most of the functions are referring to the last/previous item we submitted.
    // - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
    IMGUI_API bool          IsItemHovered(ImGuiHoveredFlags flags = 0);                         // is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
    IMGUI_API bool          IsItemActive();                                                     // is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
    IMGUI_API bool          IsItemFocused();                                                    // is the last item focused for keyboard/gamepad navigation?
    IMGUI_API bool          IsItemClicked(ImGuiMouseButton mouse_button = 0);                   // is the last item clicked? (e.g. button/node just clicked on) == IsMouseClicked(mouse_button) && IsItemHovered()
    IMGUI_API bool          IsItemVisible();                                                    // is the last item visible? (items may be out of sight because of clipping/scrolling)
    IMGUI_API bool          IsItemEdited();                                                     // did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
    IMGUI_API bool          IsItemActivated();                                                  // was the last item just made active (item was previously inactive).
    IMGUI_API bool          IsItemDeactivated();                                                // was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that requires continuous editing.
    IMGUI_API bool          IsItemDeactivatedAfterEdit();                                       // was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that requires continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
    IMGUI_API bool          IsItemToggledOpen();                                                // was the last item open state toggled? set by TreeNode().
    IMGUI_API bool          IsAnyItemHovered();                                                 // is any item hovered?
    IMGUI_API bool          IsAnyItemActive();                                                  // is any item active?
    IMGUI_API bool          IsAnyItemFocused();                                                 // is any item focused?
    IMGUI_API ImVec2        GetItemRectMin();                                                   // get upper-left bounding rectangle of the last item (screen space)
    IMGUI_API ImVec2        GetItemRectMax();                                                   // get lower-right bounding rectangle of the last item (screen space)
    IMGUI_API ImVec2        GetItemRectSize();                                                  // get size of last item
    IMGUI_API void          SetItemAllowOverlap();                                              // allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.

    // Miscellaneous Utilities
    IMGUI_API bool          IsRectVisible(const ImVec2& size);                                  // test if rectangle (of given size, starting from cursor position) is visible / not clipped.
    IMGUI_API bool          IsRectVisible(const ImVec2& rect_min, const ImVec2& rect_max);      // test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
    IMGUI_API double        GetTime();                                                          // get global imgui time. incremented by io.DeltaTime every frame.
    IMGUI_API int           GetFrameCount();                                                    // get global imgui frame count. incremented by 1 every frame.
    IMGUI_API ImDrawList*   GetBackgroundDrawList();                                            // this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
    IMGUI_API ImDrawList*   GetForegroundDrawList();                                            // this draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.
    IMGUI_API ImDrawListSharedData* GetDrawListSharedData();                                    // you may use this when creating your own ImDrawList instances.
    IMGUI_API const char*   GetStyleColorName(ImGuiCol idx);                                    // get a string corresponding to the enum value (for display, saving, etc.).
    IMGUI_API void          SetStateStorage(ImGuiStorage* storage);                             // replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
    IMGUI_API ImGuiStorage* GetStateStorage();
    IMGUI_API void          CalcListClipping(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);    // calculate coarse clipping for large list of evenly sized items. Prefer using the ImGuiListClipper higher-level helper if you can.
    IMGUI_API bool          BeginChildFrame(ImGuiID id, const ImVec2& size, ImGuiWindowFlags flags = 0); // helper to create a child window / scrolling region that looks like a normal widget frame
    IMGUI_API void          EndChildFrame();                                                    // always call EndChildFrame() regardless of BeginChildFrame() return values (which indicates a collapsed/clipped window)

    // Text Utilities
    IMGUI_API ImVec2        CalcTextSize(const char* text, const char* text_end = NULL, bool hide_text_after_double_hash = false, float wrap_width = -1.0f);

    // Color Utilities
    IMGUI_API ImVec4        ColorConvertU32ToFloat4(ImU32 in);
    IMGUI_API ImU32         ColorConvertFloat4ToU32(const ImVec4& in);
    IMGUI_API void          ColorConvertRGBtoHSV(float r, float g, float b, float& out_h, float& out_s, float& out_v);
    IMGUI_API void          ColorConvertHSVtoRGB(float h, float s, float v, float& out_r, float& out_g, float& out_b);

    // Inputs Utilities: Keyboard
    // - For 'int user_key_index' you can use your own indices/enums according to how your backend/engine stored them in io.KeysDown[].
    // - We don't know the meaning of those value. You can use GetKeyIndex() to map a ImGuiKey_ value into the user index.
    IMGUI_API int           GetKeyIndex(ImGuiKey imgui_key);                                    // map ImGuiKey_* values into user's key index. == io.KeyMap[key]
    IMGUI_API bool          IsKeyDown(int user_key_index);                                      // is key being held. == io.KeysDown[user_key_index].
    IMGUI_API bool          IsKeyPressed(int user_key_index, bool repeat = true);               // was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
    IMGUI_API bool          IsKeyReleased(int user_key_index);                                  // was key released (went from Down to !Down)?
    IMGUI_API int           GetKeyPressedAmount(int key_index, float repeat_delay, float rate); // uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
    IMGUI_API void          CaptureKeyboardFromApp(bool want_capture_keyboard_value = true);    // attention: misleading name! manually override io.WantCaptureKeyboard flag next frame (said flag is entirely left for your application to handle). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard_value"; after the next NewFrame() call.

    // Inputs Utilities: Mouse
    // - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
    // - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
    // - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
    IMGUI_API bool          IsMouseDown(ImGuiMouseButton button);                               // is mouse button held?
    IMGUI_API bool          IsMouseClicked(ImGuiMouseButton button, bool repeat = false);       // did mouse button clicked? (went from !Down to Down)
    IMGUI_API bool          IsMouseReleased(ImGuiMouseButton button);                           // did mouse button released? (went from Down to !Down)
    IMGUI_API bool          IsMouseDoubleClicked(ImGuiMouseButton button);                      // did mouse button double-clicked? a double-click returns false in IsMouseClicked(). uses io.MouseDoubleClickTime.
    IMGUI_API bool          IsMouseHoveringRect(const ImVec2& r_min, const ImVec2& r_max, bool clip = true);// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
    IMGUI_API bool          IsMousePosValid(const ImVec2* mouse_pos = NULL);                    // by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
    IMGUI_API bool          IsAnyMouseDown();                                                   // is any mouse button held?
    IMGUI_API ImVec2        GetMousePos();                                                      // shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
    IMGUI_API ImVec2        GetMousePosOnOpeningCurrentPopup();                                 // retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
    IMGUI_API bool          IsMouseDragging(ImGuiMouseButton button, float lock_threshold = -1.0f);         // is mouse dragging? (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
    IMGUI_API ImVec2        GetMouseDragDelta(ImGuiMouseButton button = 0, float lock_threshold = -1.0f);   // return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
    IMGUI_API void          ResetMouseDragDelta(ImGuiMouseButton button = 0);                   //
    IMGUI_API ImGuiMouseCursor GetMouseCursor();                                                // get desired cursor type, reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
    IMGUI_API void          SetMouseCursor(ImGuiMouseCursor cursor_type);                       // set desired cursor type
    IMGUI_API void          CaptureMouseFromApp(bool want_capture_mouse_value = true);          // attention: misleading name! manually override io.WantCaptureMouse flag next frame (said flag is entirely left for your application to handle). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse_value;" after the next NewFrame() call.

    // Clipboard Utilities
    // - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
    IMGUI_API const char*   GetClipboardText();
    IMGUI_API void          SetClipboardText(const char* text);

    // Settings/.Ini Utilities
    // - The disk functions are automatically called if io.IniFilename != NULL (default is "imgui.ini").
    // - Set io.IniFilename to NULL to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
    IMGUI_API void          LoadIniSettingsFromDisk(const char* ini_filename);                  // call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
    IMGUI_API void          LoadIniSettingsFromMemory(const char* ini_data, size_t ini_size=0); // call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
    IMGUI_API void          SaveIniSettingsToDisk(const char* ini_filename);                    // this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
    IMGUI_API const char*   SaveIniSettingsToMemory(size_t* out_ini_size = NULL);               // return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.

    // Debug Utilities
    IMGUI_API bool          DebugCheckVersionAndDataLayout(const char* version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx); // This is called by IMGUI_CHECKVERSION() macro.

    // Memory Allocators
    // - All those functions are not reliant on the current context.
    // - If you reload the contents of imgui.cpp at runtime, you may need to call SetCurrentContext() + SetAllocatorFunctions() again because we use global storage for those.
    IMGUI_API void          SetAllocatorFunctions(void* (*alloc_func)(size_t sz, void* user_data), void (*free_func)(void* ptr, void* user_data), void* user_data = NULL);
    IMGUI_API void*         MemAlloc(size_t size);
    IMGUI_API void          MemFree(void* ptr);

} // namespace ImGui
+/

//-----------------------------------------------------------------------------
// Flags & Enumerations
//-----------------------------------------------------------------------------

// Flags for ImGui::Begin()
enum ImGuiWindowFlags : int
{
    None                   = 0,
    NoTitleBar             = 1 << 0,   // Disable title-bar
    NoResize               = 1 << 1,   // Disable user resizing with the lower-right grip
    NoMove                 = 1 << 2,   // Disable user moving the window
    NoScrollbar            = 1 << 3,   // Disable scrollbars (window can still scroll with mouse or programmatically)
    NoScrollWithMouse      = 1 << 4,   // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
    NoCollapse             = 1 << 5,   // Disable user collapsing window by double-clicking on it
    AlwaysAutoResize       = 1 << 6,   // Resize every window to its content every frame
    NoBackground           = 1 << 7,   // Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
    NoSavedSettings        = 1 << 8,   // Never load/save settings in .ini file
    NoMouseInputs          = 1 << 9,   // Disable catching mouse, hovering test with pass through.
    MenuBar                = 1 << 10,  // Has a menu-bar
    HorizontalScrollbar    = 1 << 11,  // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
    NoFocusOnAppearing     = 1 << 12,  // Disable taking focus when transitioning from hidden to visible state
    NoBringToFrontOnFocus  = 1 << 13,  // Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
    AlwaysVerticalScrollbar= 1 << 14,  // Always show vertical scrollbar (even if ContentSize.y < Size.y)
    AlwaysHorizontalScrollbar=1<< 15,  // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
    AlwaysUseWindowPadding = 1 << 16,  // Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient)
    NoNavInputs            = 1 << 18,  // No gamepad/keyboard navigation within the window
    NoNavFocus             = 1 << 19,  // No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB)
    UnsavedDocument        = 1 << 20,  // Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. When used in a tab/docking context, tab is selected on closure and closure is deferred by one frame to allow code to cancel the closure (with a confirmation popup, etc.) without flicker.
    NoNav                  = NoNavInputs | NoNavFocus,
    NoDecoration           = NoTitleBar | NoResize | NoScrollbar | NoCollapse,
    NoInputs               = NoMouseInputs | NoNavInputs | NoNavFocus,

    // [Internal]
    NavFlattened           = 1 << 23,  // [BETA] Allow gamepad/keyboard navigation to cross over parent border to this child (only use on child that have no scrolling!)
    ChildWindow            = 1 << 24,  // Don't use! For internal use by BeginChild()
    Tooltip                = 1 << 25,  // Don't use! For internal use by BeginTooltip()
    Popup                  = 1 << 26,  // Don't use! For internal use by BeginPopup()
    Modal                  = 1 << 27,  // Don't use! For internal use by BeginPopupModal()
    ChildMenu              = 1 << 28   // Don't use! For internal use by BeginMenu()

    // [Obsolete]
    //ShowBorders          = 1 << 7,   // --> Set style.FrameBorderSize=1.0f or style.WindowBorderSize=1.0f to enable borders around items or windows.
    //ResizeFromAnySide    = 1 << 17,  // --> Set io.ConfigWindowsResizeFromEdges=true and make sure mouse cursors are supported by back-end (io.BackendFlags & ImGuiBackendFlags_HasMouseCursors)
}

// Flags for ImGui::InputText()
enum ImGuiInputTextFlags : int
{
    None                = 0,
    CharsDecimal        = 1 << 0,   // Allow 0123456789.+-*/
    CharsHexadecimal    = 1 << 1,   // Allow 0123456789ABCDEFabcdef
    CharsUppercase      = 1 << 2,   // Turn a..z into A..Z
    CharsNoBlank        = 1 << 3,   // Filter out spaces, tabs
    AutoSelectAll       = 1 << 4,   // Select entire text when first taking mouse focus
    EnterReturnsTrue    = 1 << 5,   // Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider looking at the IsItemDeactivatedAfterEdit() function.
    CallbackCompletion  = 1 << 6,   // Callback on pressing TAB (for completion handling)
    CallbackHistory     = 1 << 7,   // Callback on pressing Up/Down arrows (for history handling)
    CallbackAlways      = 1 << 8,   // Callback on each iteration. User code may query cursor position, modify text buffer.
    CallbackCharFilter  = 1 << 9,   // Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
    AllowTabInput       = 1 << 10,  // Pressing TAB input a '\t' character into the text field
    CtrlEnterForNewLine = 1 << 11,  // In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
    NoHorizontalScroll  = 1 << 12,  // Disable following the cursor horizontally
    AlwaysInsertMode    = 1 << 13,  // Insert mode
    ReadOnly            = 1 << 14,  // Read-only mode
    Password            = 1 << 15,  // Password mode, display all characters as '*'
    NoUndoRedo          = 1 << 16,  // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
    CharsScientific     = 1 << 17,  // Allow 0123456789.+-*/eE (Scientific notation input)
    CallbackResize      = 1 << 18,  // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
    // [Internal]
    Multiline           = 1 << 20,  // For internal use by InputTextMultiline()
    NoMarkEdited        = 1 << 21   // For internal use by functions using InputText() before reformatting data
}

// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
enum ImGuiTreeNodeFlags : int
{
    None                 = 0,
    Selected             = 1 << 0,   // Draw as selected
    Framed               = 1 << 1,   // Full colored frame (e.g. for CollapsingHeader)
    AllowItemOverlap     = 1 << 2,   // Hit testing to allow subsequent widgets to overlap this one
    NoTreePushOnOpen     = 1 << 3,   // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
    NoAutoOpenOnLog      = 1 << 4,   // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
    DefaultOpen          = 1 << 5,   // Default node to be open
    OpenOnDoubleClick    = 1 << 6,   // Need double-click to open node
    OpenOnArrow          = 1 << 7,   // Only open when clicking on the arrow part. If OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
    Leaf                 = 1 << 8,   // No collapsing, no arrow (use as a convenience for leaf nodes).
    Bullet               = 1 << 9,   // Display a bullet instead of arrow
    FramePadding         = 1 << 10,  // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
    SpanAvailWidth       = 1 << 11,  // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line. In the future we may refactor the hit system to be front-to-back, allowing natural overlaps and then this can become the default.
    SpanFullWidth        = 1 << 12,  // Extend hit box to the left-most and right-most edges (bypass the indented area).
    NavLeftJumpsBackHere = 1 << 13,  // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
    //NoScrollOnOpen     = 1 << 14,  // FIXME: TODO: Disable automatic scroll on TreePop() if node got just open and contents is not visible
    CollapsingHeader     = Framed | NoTreePushOnOpen | NoAutoOpenOnLog,
    
    // [Internal]
    ClipLabelForTrailingButton = 1 << 20
}

// Flags for ImGui::Selectable()
enum ImGuiSelectableFlags : int
{
    None               = 0,
    DontClosePopups    = 1 << 0,   // Clicking this don't close parent popup window
    SpanAllColumns     = 1 << 1,   // Selectable frame can span all columns (text will still fit in current column)
    AllowDoubleClick   = 1 << 2,   // Generate press events on double clicks too
    Disabled           = 1 << 3,   // Cannot be selected, display greyed out text
    AllowItemOverlap   = 1 << 4,   // (WIP) Hit testing to allow subsequent widgets to overlap this one

    // [Internal]
    NoHoldingActiveID  = 1 << 20,
    SelectOnClick      = 1 << 21,  // Override button behavior to react on Click (default is Click+Release)
    SelectOnRelease    = 1 << 22,  // Override button behavior to react on Release (default is Click+Release)
    SpanAvailWidth     = 1 << 23,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    DrawHoveredWhenHeld= 1 << 24,  // Always show active when held, even is not hovered. This concept could probably be renamed/formalized somehow.
    SetNavIdOnHover    = 1 << 25
}

// Flags for ImGui::BeginCombo()
enum ImGuiComboFlags : int
{
    None                    = 0,
    PopupAlignLeft          = 1 << 0,   // Align the popup toward the left by default
    HeightSmall             = 1 << 1,   // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
    HeightRegular           = 1 << 2,   // Max ~8 items visible (default)
    HeightLarge             = 1 << 3,   // Max ~20 items visible
    HeightLargest           = 1 << 4,   // As many fitting items as possible
    NoArrowButton           = 1 << 5,   // Display on the preview box without the square arrow button
    NoPreview               = 1 << 6,   // Display only a square arrow button
    HeightMask_             = HeightSmall | HeightRegular | HeightLarge | HeightLargest
}

// Flags for ImGui::BeginTabBar()
enum ImGuiTabBarFlags : int
{
    None                           = 0,
    Reorderable                    = 1 << 0,   // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
    AutoSelectNewTabs              = 1 << 1,   // Automatically select new tabs when they appear
    TabListPopupButton             = 1 << 2,   // Disable buttons to open the tab list popup
    NoCloseWithMiddleMouseButton   = 1 << 3,   // Disable behavior of closing tabs (that are submitted with p_open != null) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoTabListScrollingButtons      = 1 << 4,   // Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags.FittingPolicyScroll)
    NoTooltip                      = 1 << 5,   // Disable tooltips when hovering a tab
    FittingPolicyResizeDown        = 1 << 6,   // Resize tabs when they don't fit
    FittingPolicyScroll            = 1 << 7,   // Add scroll buttons when tabs don't fit
    FittingPolicyMask_             = FittingPolicyResizeDown | FittingPolicyScroll,
    FittingPolicyDefault_          = FittingPolicyResizeDown,

    // [Internal]
    DockNode                   = 1 << 20,  // Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
    IsFocused                  = 1 << 21,
    SaveSettings               = 1 << 22   // FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
}

// Flags for ImGui::BeginTabItem()
enum ImGuiTabItemFlags : int
{
    None                          = 0,
    UnsavedDocument               = 1 << 0,   // Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. Also: tab is selected on closure and closure is deferred by one frame to allow code to undo it without flicker.
    SetSelected                   = 1 << 1,   // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
    NoCloseWithMiddleMouseButton  = 1 << 2,   // Disable behavior of closing tabs (that are submitted with p_open != null) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoPushId                      = 1 << 3,   // Don't call PushID(tab.ID)/PopID() on BeginTabItem()/EndTabItem()
    
    // [Internal]
    NoCloseButton             = 1 << 20   // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
}

// Flags for ImGui::IsWindowFocused()
enum ImGuiFocusedFlags : int
{
    None                          = 0,
    ChildWindows                  = 1 << 0,   // IsWindowFocused(): Return true if any children of the window is focused
    RootWindow                    = 1 << 1,   // IsWindowFocused(): Test from root window (top most parent of the current hierarchy)
    AnyWindow                     = 1 << 2,   // IsWindowFocused(): Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
    RootAndChildWindows           = RootWindow | ChildWindows
}

// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
// Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
enum ImGuiHoveredFlags : int
{
    None                          = 0,        // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
    ChildWindows                  = 1 << 0,   // IsWindowHovered() only: Return true if any children of the window is hovered
    RootWindow                    = 1 << 1,   // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
    AnyWindow                     = 1 << 2,   // IsWindowHovered() only: Return true if any window is hovered
    AllowWhenBlockedByPopup       = 1 << 3,   // Return true even if a popup window is normally blocking access to this item/window
    //AllowWhenBlockedByModal     = 1 << 4,   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
    AllowWhenBlockedByActiveItem  = 1 << 5,   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
    AllowWhenOverlapped           = 1 << 6,   // Return true even if the position is obstructed or overlapped by another window
    AllowWhenDisabled             = 1 << 7,   // Return true even if the item is disabled
    RectOnly                      = AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped,
    RootAndChildWindows           = RootWindow | ChildWindows
}

// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
enum ImGuiDragDropFlags : int
{
    None                         = 0,
    // BeginDragDropSource() flags
    SourceNoPreviewTooltip       = 1 << 0,   // By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disable this behavior.
    SourceNoDisableHover         = 1 << 1,   // By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disable this behavior so you can still call IsItemHovered() on the source item.
    SourceNoHoldToOpenOthers     = 1 << 2,   // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
    SourceAllowNullID            = 1 << 3,   // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
    SourceExtern                 = 1 << 4,   // External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
    SourceAutoExpirePayload      = 1 << 5,   // Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
    // AcceptDragDropPayload() flags
    AcceptBeforeDelivery         = 1 << 10,  // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
    AcceptNoDrawDefaultRect      = 1 << 11,  // Do not draw the default highlight rectangle when hovering over target.
    AcceptNoPreviewTooltip       = 1 << 12,  // Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
    AcceptPeekOnly               = AcceptBeforeDelivery | AcceptNoDrawDefaultRect  // For peeking ahead and inspecting the payload before delivery.
}

// Standard Drag and Drop payload types. You can define you own payload types using short strings. Types starting with '_' are defined by Dear ImGui.
enum IMGUI_PAYLOAD_TYPE_COLOR_3F    = "_COL3F";    // float[3]: Standard type for colors, without alpha. User code may use this type.
enum IMGUI_PAYLOAD_TYPE_COLOR_4F    = "_COL4F";    // float[4]: Standard type for colors. User code may use this type.

// A primary data type
enum ImGuiDataType : int
{
    S8,       // signed char / char (with sensible compilers)
    U8,       // unsigned char
    S16,      // short
    U16,      // unsigned short
    S32,      // int
    U32,      // ubyte
    S64,      // long long / __int64
    U64,      // unsigned long long / unsigned __int64
    Float,    // float
    Double,   // double
    COUNT
}

// A cardinal direction
enum ImGuiDir : int
{
    None    = -1,
    Left    = 0,
    Right   = 1,
    Up      = 2,
    Down    = 3,
    COUNT
}

// User fill ImGuiIO.KeyMap[] array with indices into the ImGuiIO.KeysDown[512] array
enum ImGuiKey : int
{
    Tab,
    LeftArrow,
    RightArrow,
    UpArrow,
    DownArrow,
    PageUp,
    PageDown,
    Home,
    End,
    Insert,
    Delete,
    Backspace,
    Space,
    Enter,
    Escape,
    KeyPadEnter,
    A,                 // for text edit CTRL+A: select all
    C,                 // for text edit CTRL+C: copy
    V,                 // for text edit CTRL+V: paste
    X,                 // for text edit CTRL+X: cut
    Y,                 // for text edit CTRL+Y: redo
    Z,                 // for text edit CTRL+Z: undo
    COUNT
}

// To test io.KeyMods (which is a combination of individual fields io.KeyCtrl, io.KeyShift, io.KeyAlt set by user/back-end)
enum ImGuiKeyModFlags : int
{
    None       = 0,
    Ctrl       = 1 << 0,
    Shift      = 1 << 1,
    Alt        = 1 << 2,
    Super      = 1 << 3
}

// Gamepad/Keyboard navigation
// Keyboard: Set io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard to enable. NewFrame() will automatically fill io.NavInputs[] based on your io.KeysDown[] + io.KeyMap[] arrays.
// Gamepad:  Set io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad to enable. Back-end: set ImGuiBackendFlags_HasGamepad and fill the io.NavInputs[] fields before calling NewFrame(). Note that io.NavInputs[] is cleared by EndFrame().
// Read instructions in imgui.cpp for more details. Download PNG/PSD at http://goo.gl/9LgVZW.
enum ImGuiNavInput : int
{
    // Gamepad Mapping
    Activate,      // activate / open / toggle / tweak value       // e.g. Cross  (PS4), A (Xbox), A (Switch), Space (Keyboard)
    Cancel,        // cancel / close / exit                        // e.g. Circle (PS4), B (Xbox), B (Switch), Escape (Keyboard)
    Input,         // text input / on-screen keyboard              // e.g. Triang.(PS4), Y (Xbox), X (Switch), Return (Keyboard)
    Menu,          // tap: toggle menu / hold: focus, move, resize // e.g. Square (PS4), X (Xbox), Y (Switch), Alt (Keyboard)
    DpadLeft,      // move / tweak / resize window (w/ PadMenu)    // e.g. D-pad Left/Right/Up/Down (Gamepads), Arrow keys (Keyboard)
    DpadRight,     //
    DpadUp,        //
    DpadDown,      //
    LStickLeft,    // scroll / move window (w/ PadMenu)            // e.g. Left Analog Stick Left/Right/Up/Down
    LStickRight,   //
    LStickUp,      //
    LStickDown,    //
    FocusPrev,     // next window (w/ PadMenu)                     // e.g. L1 or L2 (PS4), LB or LT (Xbox), L or ZL (Switch)
    FocusNext,     // prev window (w/ PadMenu)                     // e.g. R1 or R2 (PS4), RB or RT (Xbox), R or ZL (Switch)
    TweakSlow,     // slower tweaks                                // e.g. L1 or L2 (PS4), LB or LT (Xbox), L or ZL (Switch)
    TweakFast,     // faster tweaks                                // e.g. R1 or R2 (PS4), RB or RT (Xbox), R or ZL (Switch)

    // [Internal] Don't use directly! This is used internally to differentiate keyboard from gamepad inputs for behaviors that require to differentiate them.
    // Keyboard behavior that have no corresponding gamepad mapping (e.g. CTRL+TAB) will be directly reading from io.KeysDown[] instead of io.NavInputs[].
    KeyMenu_,      // toggle menu                                  // = io.KeyAlt
    KeyLeft_,      // move left                                    // = Arrow keys
    KeyRight_,     // move right
    KeyUp_,        // move up
    KeyDown_,      // move down
    COUNT,
    InternalStart_ = KeyMenu_
}

// Configuration flags stored in io.ConfigFlags. Set by user/application.
enum ImGuiConfigFlags : int
{
    None                   = 0,
    NavEnableKeyboard      = 1 << 0,   // Master keyboard navigation enable flag. NewFrame() will automatically fill io.NavInputs[] based on io.KeysDown[].
    NavEnableGamepad       = 1 << 1,   // Master gamepad navigation enable flag. This is mostly to instruct your imgui back-end to fill io.NavInputs[]. Back-end also needs to set ImGuiBackendFlags.HasGamepad.
    NavEnableSetMousePos   = 1 << 2,   // Instruct navigation to move the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is awkward. Will update io.MousePos and set io.WantSetMousePos=true. If enabled you MUST honor io.WantSetMousePos requests in your binding, otherwise ImGui will react as if the mouse is jumping around back and forth.
    NavNoCaptureKeyboard   = 1 << 3,   // Instruct navigation to not set the io.WantCaptureKeyboard flag when io.NavActive is set.
    NoMouse                = 1 << 4,   // Instruct imgui to clear mouse position/buttons in NewFrame(). This allows ignoring the mouse information set by the back-end.
    NoMouseCursorChange    = 1 << 5,   // Instruct back-end to not alter mouse cursor shape and visibility. Use if the back-end cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.

    // User storage (to allow your back-end/engine to communicate to code that may be shared between multiple projects. Those flags are not used by core Dear ImGui)
    IsSRGB                 = 1 << 20,  // Application is SRGB-aware.
    IsTouchScreen          = 1 << 21   // Application is using a touch screen instead of a mouse.
}

// Back-end capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom back-end.
enum ImGuiBackendFlags : int
{
    None                  = 0,
    HasGamepad            = 1 << 0,   // Back-end Platform supports gamepad and currently has one connected.
    HasMouseCursors       = 1 << 1,   // Back-end Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
    HasSetMousePos        = 1 << 2,   // Back-end Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if ImGuiConfigFlags.NavEnableSetMousePos is set).
    RendererHasVtxOffset  = 1 << 3    // Back-end Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.
}

// Enumeration for PushStyleColor() / PopStyleColor()
enum ImGuiCol : int
{
    Text,
    TextDisabled,
    WindowBg,              // Background of normal windows
    ChildBg,               // Background of child windows
    PopupBg,               // Background of popups, menus, tooltips windows
    Border,
    BorderShadow,
    FrameBg,               // Background of checkbox, radio button, plot, slider, text input
    FrameBgHovered,
    FrameBgActive,
    TitleBg,
    TitleBgActive,
    TitleBgCollapsed,
    MenuBarBg,
    ScrollbarBg,
    ScrollbarGrab,
    ScrollbarGrabHovered,
    ScrollbarGrabActive,
    CheckMark,
    SliderGrab,
    SliderGrabActive,
    Button,
    ButtonHovered,
    ButtonActive,
    Header,                // Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
    HeaderHovered,
    HeaderActive,
    Separator,
    SeparatorHovered,
    SeparatorActive,
    ResizeGrip,
    ResizeGripHovered,
    ResizeGripActive,
    Tab,
    TabHovered,
    TabActive,
    TabUnfocused,
    TabUnfocusedActive,
    PlotLines,
    PlotLinesHovered,
    PlotHistogram,
    PlotHistogramHovered,
    TextSelectedBg,
    DragDropTarget,
    NavHighlight,          // Gamepad/keyboard: current highlighted item
    NavWindowingHighlight, // Highlight window when using CTRL+TAB
    NavWindowingDimBg,     // Darken/colorize entire screen behind the CTRL+TAB window list, when active
    ModalWindowDimBg,      // Darken/colorize entire screen behind a modal window, when one is active
    COUNT,
}

// D_IMGUI: In D, "static if" does not work inside enums
// Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiCol_ModalWindowDarkening = ImGuiCol.ModalWindowDimBg;                      // [renamed in 1.63]
    //, ImGuiCol_CloseButton, ImGuiCol_CloseButtonActive, ImGuiCol_CloseButtonHovered// [unused since 1.60+] the close button now uses regular button colors.
}


// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
//   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
//   In Visual Studio IDE: CTRL+comma ("Edit.NavigateTo") can follow symbols in comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   With Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols in comments.
// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
enum ImGuiStyleVar : int
{
    // Enum name --------------------- // Member in ImGuiStyle structure (see ImGuiStyle for descriptions)
    Alpha,               // float     Alpha
    WindowPadding,       // ImVec2    WindowPadding
    WindowRounding,      // float     WindowRounding
    WindowBorderSize,    // float     WindowBorderSize
    WindowMinSize,       // ImVec2    WindowMinSize
    WindowTitleAlign,    // ImVec2    WindowTitleAlign
    ChildRounding,       // float     ChildRounding
    ChildBorderSize,     // float     ChildBorderSize
    PopupRounding,       // float     PopupRounding
    PopupBorderSize,     // float     PopupBorderSize
    FramePadding,        // ImVec2    FramePadding
    FrameRounding,       // float     FrameRounding
    FrameBorderSize,     // float     FrameBorderSize
    ItemSpacing,         // ImVec2    ItemSpacing
    ItemInnerSpacing,    // ImVec2    ItemInnerSpacing
    IndentSpacing,       // float     IndentSpacing
    ScrollbarSize,       // float     ScrollbarSize
    ScrollbarRounding,   // float     ScrollbarRounding
    GrabMinSize,         // float     GrabMinSize
    GrabRounding,        // float     GrabRounding
    TabRounding,         // float     TabRounding
    ButtonTextAlign,     // ImVec2    ButtonTextAlign
    SelectableTextAlign, // ImVec2    SelectableTextAlign
    COUNT
}

// Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiStyleVar_Count_ = ImGuiStyleVar.COUNT;                    // [renamed in 1.60]
}

// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
enum ImGuiColorEditFlags : int
{
    None            = 0,
    NoAlpha         = 1 << 1,   //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
    NoPicker        = 1 << 2,   //              // ColorEdit: disable picker when clicking on colored square.
    NoOptions       = 1 << 3,   //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
    NoSmallPreview  = 1 << 4,   //              // ColorEdit, ColorPicker: disable colored square preview next to the inputs. (e.g. to show only the inputs)
    NoInputs        = 1 << 5,   //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview colored square).
    NoTooltip       = 1 << 6,   //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
    NoLabel         = 1 << 7,   //              // ColorEdit, ColorPicker: disable display of text label (the label is still forwarded to the tooltip and picker).
    NoSidePreview   = 1 << 8,   //              // ColorPicker: disable bigger color preview on right side of the picker, use small colored square preview instead.
    NoDragDrop      = 1 << 9,   //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
    NoBorder        = 1 << 10,  //              // ColorButton: disable border (which is enforced by default)

    // User Options (right-click on widget to change some of them).
    AlphaBar        = 1 << 16,  //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
    AlphaPreview    = 1 << 17,  //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
    AlphaPreviewHalf= 1 << 18,  //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
    HDR             = 1 << 19,  //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags.Float flag as well).
    DisplayRGB      = 1 << 20,  // [Display]    // ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
    DisplayHSV      = 1 << 21,  // [Display]    // "
    DisplayHex      = 1 << 22,  // [Display]    // "
    Uint8           = 1 << 23,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
    Float           = 1 << 24,  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
    PickerHueBar    = 1 << 25,  // [Picker]     // ColorPicker: bar for Hue, rectangle for Sat/Value.
    PickerHueWheel  = 1 << 26,  // [Picker]     // ColorPicker: wheel for Hue, triangle for Sat/Value.
    InputRGB        = 1 << 27,  // [Input]      // ColorEdit, ColorPicker: input and output data in RGB format.
    InputHSV        = 1 << 28,  // [Input]      // ColorEdit, ColorPicker: input and output data in HSV format.

    // Defaults Options. You can set application defaults using SetColorEditOptions(). The intent is that you probably don't want to
    // override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
    _OptionsDefault = Uint8|DisplayRGB|InputRGB|PickerHueBar,

    // [Internal] Masks
    _DisplayMask    = DisplayRGB|DisplayHSV|DisplayHex,
    _DataTypeMask   = Uint8|Float,
    _PickerMask     = PickerHueWheel|PickerHueBar,
    _InputMask      = InputRGB|InputHSV
}
// Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiColorEditFlags_RGB = ImGuiColorEditFlags.DisplayRGB;
    deprecated enum ImGuiColorEditFlags_HSV = ImGuiColorEditFlags.DisplayHSV;
    deprecated enum ImGuiColorEditFlags_HEX = ImGuiColorEditFlags.DisplayHex;  // [renamed in 1.69]
}

// Identify a mouse button.
// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
enum ImGuiMouseButton : int
{
    None = -1,
    Left = 0,
    Right = 1,
    Middle = 2,
    COUNT = 5
}

// Enumeration for GetMouseCursor()
// User code may request binding to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
enum ImGuiMouseCursor : int
{
    None = -1,
    Arrow = 0,
    TextInput,         // When hovering over InputText, etc.
    ResizeAll,         // (Unused by Dear ImGui functions)
    ResizeNS,          // When hovering over an horizontal border
    ResizeEW,          // When hovering over a vertical border or a column
    ResizeNESW,        // When hovering over the bottom-left corner of a window
    ResizeNWSE,        // When hovering over the bottom-right corner of a window
    Hand,              // (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
    NotAllowed,        // When hovering something with disallowed interaction. Usually a crossed circle.
    COUNT,
}

// Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiMouseCursor_Count_ = ImGuiMouseCursor.COUNT;      // [renamed in 1.60]
}

// Enumeration for ImGui::SetWindow***(), SetNextWindow***(), SetNextItem***() functions
// Represent a condition.
// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
enum ImGuiCond : int
{
    None          = 0,
    Always        = 1 << 0,   // Set the variable
    Once          = 1 << 1,   // Set the variable once per runtime session (only the first call with succeed)
    FirstUseEver  = 1 << 2,   // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
    Appearing     = 1 << 3,    // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
}

//-----------------------------------------------------------------------------
// Helpers: Memory allocations macros
// IM_MALLOC(), IM_FREE(), IM_NEW(), IM_PLACEMENT_NEW(), IM_DELETE()
// We call C++ constructor on own allocated memory via the placement "new(ptr) Type()" syntax.
// Defining a custom placement new() with a dummy parameter allows us to bypass including <new> which on some platforms complains when user has disabled exceptions.
//-----------------------------------------------------------------------------

// struct ImNewDummy {}
// inline void* operator new(size_t, ImNewDummy, void* ptr) { return ptr; }
// inline void  operator delete(void*, ImNewDummy, void*)   {} // This is only required so we can use the symmetrical new()
pragma(inline) T[] IM_ALLOC(T)(size_t amount) {
    return (cast(T*)MemAlloc(amount * T.sizeof))[0..amount];
}
alias IM_FREE = MemFree;
pragma(inline) void IM_PLACEMENT_NEW(T)(T* ptr, T value) {
    *ptr = value;
}
pragma(inline) T* IM_NEW(T, A...)(A args) {
    import std.conv : emplace;
    T* result = cast(T*)MemAlloc((T).sizeof);
    emplace(result, args);
    return result;
}
pragma(inline) void IM_DELETE(T)(T* p)   { if (p) { p.destroy(); MemFree(p); } }
// D_IMGUI separate definition for string
pragma(inline) void IM_DELETE(string s)   { if (s !is NULL) { MemFree(cast(char*)s.ptr); } }

//-----------------------------------------------------------------------------
// Helper: ImVector<>
// Lightweight std::vector<>-like class to avoid dragging dependencies (also, some implementations of STL with debug enabled are absurdly slow, we bypass it so our code runs fast in debug).
//-----------------------------------------------------------------------------
// - You generally do NOT need to care or use this ever. But we need to make it available in imgui.h because some of our public structures are relying on it.
// - We use std-like naming convention here, which is a little unusual for this codebase.
// - Important: clear() frees memory, resize(0) keep the allocated buffer. We use resize(0) a lot to intentionally recycle allocated buffers across frames and amortize our costs.
// - Important: our implementation does NOT call C++ constructors/destructors, we treat everything as raw data! This is intentional but be extra mindful of that,
//   Do NOT use this class as a std::vector replacement in your own code! Many of the structures used by dear imgui can be safely initialized by a zero-memset.
//-----------------------------------------------------------------------------

struct ImVector(T)
{
    nothrow:
    @nogc:

    int                 Size;
    int                 Capacity;
    T*                  Data;

    // Provide standard typedefs but we don't use them ourselves.
    // typedef T                   value_type;
    // typedef value_type*         iterator;
    // typedef const value_type*   const_iterator;

    // Constructors, destructor
    // inline ImVector()                                       { Size = Capacity = 0; Data = NULL; }
    pragma(inline, true) this(const ImVector!T* src)                 { Size = Capacity = 0; Data = NULL; opAssign(src); }
    pragma(inline, true) ref ImVector!T opAssign(const ImVector!T* src)   { clear(); resize(src.Size); memcpy(Data, src.Data, cast(size_t)Size * (T).sizeof); return this; }
    pragma(inline, true) void destroy()                                      { if (Data) IM_FREE(Data); }
    // D_IMGUI function to get an array representation of the vector
    pragma(inline, true) inout (T)[] asArray() inout                         { return Data ? Data[0..Size] : NULL; }

    pragma(inline, true) bool         empty() const                       { return Size == 0; }
    pragma(inline, true) int          size() const                        { return Size; }
    pragma(inline, true) int          size_in_bytes() const               { return Size * cast(int)(T).sizeof; }
    pragma(inline, true) int          capacity() const                    { return Capacity; }
    pragma(inline, true) ref inout (T)     opIndex(int i) inout             { IM_ASSERT(i < Size); return Data[i]; }

    pragma(inline, true) void         clear()                             { if (Data) { Size = Capacity = 0; IM_FREE(Data); Data = NULL; } }
    pragma(inline, true) inout (T)*     begin() inout                       { return Data; }
    pragma(inline, true) inout (T)*     end() inout                         { return Data + Size; }
    pragma(inline, true) ref inout (T)     front() inout                       { IM_ASSERT(Size > 0); return Data[0]; }
    pragma(inline, true) ref inout (T)     back() inout                        { IM_ASSERT(Size > 0); return Data[Size - 1]; }
    pragma(inline, true) void         swap(ImVector!T* rhs)              { int rhs_size = rhs.Size; rhs.Size = Size; Size = rhs_size; int rhs_cap = rhs.Capacity; rhs.Capacity = Capacity; Capacity = rhs_cap; T* rhs_data = rhs.Data; rhs.Data = Data; Data = rhs_data; }

    pragma(inline, true) int          _grow_capacity(int sz) const        { int new_capacity = Capacity ? (Capacity + Capacity/2) : 8; return new_capacity > sz ? new_capacity : sz; }
    pragma(inline, true) void         resize(int new_size)                { if (new_size > Capacity) reserve(_grow_capacity(new_size)); Size = new_size; }
    pragma(inline, true) void         resize(int new_size, const T/*&*/ v)    { if (new_size > Capacity) reserve(_grow_capacity(new_size)); if (new_size > Size) for (int n = Size; n < new_size; n++) memcpy(&Data[n], &v, sizeof(v)); Size = new_size; }
    pragma(inline, true) void         shrink(int new_size)                { IM_ASSERT(new_size <= Size); Size = new_size; } // Resize a vector to a smaller size, guaranteed not to cause a reallocation
    pragma(inline, true) void         reserve(int new_capacity)           { if (new_capacity <= Capacity) return; T* new_data = IM_ALLOC!T(cast(size_t)new_capacity).ptr; if (Data) { memcpy(new_data, Data, cast(size_t)Size * sizeof!(T)); IM_FREE(Data); } Data = new_data; Capacity = new_capacity; }

    // NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
    pragma(inline, true) void         push_back(const T/*&*/ v)               { if (Size == Capacity) reserve(_grow_capacity(Size + 1)); memcpy(&Data[Size], &v, sizeof(v)); Size++; }
    pragma(inline, true) void         pop_back()                          { IM_ASSERT(Size > 0); Size--; }
    pragma(inline, true) void         push_front(const T/*&*/ v)              { if (Size == 0) push_back(v); else insert(Data, v); }
    pragma(inline, true) T*           erase(const T* it)                  { IM_ASSERT(it >= Data && it < Data+Size); const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + 1, (cast(size_t)Size - cast(size_t)off - 1) * (T).sizeof); Size--; return Data + off; }
    pragma(inline, true) T*           erase(const T* it, const T* it_last){ IM_ASSERT(it >= Data && it < Data+Size && it_last > it && it_last <= Data+Size); const ptrdiff_t count = it_last - it; const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + count, (cast(size_t)Size - cast(size_t)off - count) * (T).sizeof); Size -= cast(int)count; return Data + off; }
    pragma(inline, true) T*           erase_unsorted(const T* it)         { IM_ASSERT(it >= Data && it < Data+Size);  const ptrdiff_t off = it - Data; if (it < Data+Size-1) memcpy(Data + off, Data + Size - 1, sizeof!(T)); Size--; return Data + off; }
    pragma(inline, true) T*           insert(const T* it, const T/*&*/ v)     { IM_ASSERT(it >= Data && it <= Data+Size); const ptrdiff_t off = it - Data; if (Size == Capacity) reserve(_grow_capacity(Size + 1)); if (off < cast(int)Size) memmove(Data + off + 1, Data + off, (cast(size_t)Size - cast(size_t)off) * (T).sizeof); memcpy(&Data[off], &v, (v).sizeof); Size++; return Data + off; }
    pragma(inline, true) bool         contains(const T/*&*/ v) const          { const (T)* data = Data;  const T* data_end = Data + Size; while (data < data_end) if (*data++ == v) return true; return false; }
    pragma(inline, true) inout (T)*     find(const T/*&*/ v) inout              { inout (T)* data = Data;  const T* data_end = Data + Size; while (data < data_end) if (*data == v) break; else ++data; return data; }
    pragma(inline, true) bool         find_erase(const T/*&*/ v)              { const T* it = find(v); if (it < Data + Size) { erase(it); return true; } return false; }
    pragma(inline, true) bool         find_erase_unsorted(const T/*&*/ v)     { const T* it = find(v); if (it < Data + Size) { erase_unsorted(it); return true; } return false; }
    pragma(inline, true) int          index_from_ptr(const T* it) const   { IM_ASSERT(it >= Data && it < Data + Size); const ptrdiff_t off = it - Data; return cast(int)off; }
}

//-----------------------------------------------------------------------------
// ImGuiStyle
// You may modify the ImGui::GetStyle() main instance during initialization and before NewFrame().
// During the frame, use ImGui::PushStyleVar(ImGuiStyleVar_XXXX)/PopStyleVar() to alter the main style values,
// and ImGui::PushStyleColor(ImGuiCol_XXX)/PopStyleColor() for colors.
//-----------------------------------------------------------------------------

struct ImGuiStyle
{
    nothrow:
    @nogc:

    float       Alpha;                      // Global alpha applies to everything in Dear ImGui.
    ImVec2      WindowPadding;              // Padding within a window.
    float       WindowRounding;             // Radius of window corners rounding. Set to 0.0f to have rectangular windows.
    float       WindowBorderSize;           // Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    ImVec2      WindowMinSize;              // Minimum window size. This is a global setting. If you want to constraint individual windows, use SetNextWindowSizeConstraints().
    ImVec2      WindowTitleAlign;           // Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
    ImGuiDir    WindowMenuButtonPosition;   // Side of the collapsing/docking button in the title bar (None/Left/Right). Defaults to ImGuiDir_Left.
    float       ChildRounding;              // Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
    float       ChildBorderSize;            // Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    float       PopupRounding;              // Radius of popup window corners rounding. (Note that tooltip windows use WindowRounding)
    float       PopupBorderSize;            // Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    ImVec2      FramePadding;               // Padding within a framed rectangle (used by most widgets).
    float       FrameRounding;              // Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
    float       FrameBorderSize;            // Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
    ImVec2      ItemSpacing;                // Horizontal and vertical spacing between widgets/lines.
    ImVec2      ItemInnerSpacing;           // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
    ImVec2      TouchExtraPadding;          // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
    float       IndentSpacing;              // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
    float       ColumnsMinSpacing;          // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
    float       ScrollbarSize;              // Width of the vertical scrollbar, Height of the horizontal scrollbar.
    float       ScrollbarRounding;          // Radius of grab corners for scrollbar.
    float       GrabMinSize;                // Minimum width/height of a grab box for slider/scrollbar.
    float       GrabRounding;               // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
    float       TabRounding;                // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
    float       TabBorderSize;              // Thickness of border around tabs.
    ImGuiDir    ColorButtonPosition;        // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
    ImVec2      ButtonTextAlign;            // Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
    ImVec2      SelectableTextAlign;        // Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
    ImVec2      DisplayWindowPadding;       // Window position are clamped to be visible within the display area by at least this amount. Only applies to regular windows.
    ImVec2      DisplaySafeAreaPadding;     // If you cannot see the edges of your screen (e.g. on a TV) increase the safe area padding. Apply to popups/tooltips as well regular windows. NB: Prefer configuring your TV sets correctly!
    float       MouseCursorScale;           // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). May be removed later.
    bool        AntiAliasedLines;           // Enable anti-aliasing on lines/borders. Disable if you are really tight on CPU/GPU.
    bool        AntiAliasedFill;            // Enable anti-aliasing on filled shapes (rounded rectangles, circles, etc.)
    float       CurveTessellationTol;       // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
    float       CircleSegmentMaxError;      // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
    ImVec4[ImGuiCol.COUNT]      Colors;

    @disable this();
    this(bool dummy)
    {
        Alpha                   = 1.0f;             // Global alpha applies to everything in ImGui
        WindowPadding           = ImVec2(8,8);      // Padding within a window
        WindowRounding          = 7.0f;             // Radius of window corners rounding. Set to 0.0f to have rectangular windows
        WindowBorderSize        = 1.0f;             // Thickness of border around windows. Generally set to 0.0f or 1.0f. Other values not well tested.
        WindowMinSize           = ImVec2(32,32);    // Minimum window size
        WindowTitleAlign        = ImVec2(0.0f,0.5f);// Alignment for title bar text
        WindowMenuButtonPosition= ImGuiDir.Left;    // Position of the collapsing/docking button in the title bar (left/right). Defaults to ImGuiDir_Left.
        ChildRounding           = 0.0f;             // Radius of child window corners rounding. Set to 0.0f to have rectangular child windows
        ChildBorderSize         = 1.0f;             // Thickness of border around child windows. Generally set to 0.0f or 1.0f. Other values not well tested.
        PopupRounding           = 0.0f;             // Radius of popup window corners rounding. Set to 0.0f to have rectangular child windows
        PopupBorderSize         = 1.0f;             // Thickness of border around popup or tooltip windows. Generally set to 0.0f or 1.0f. Other values not well tested.
        FramePadding            = ImVec2(4,3);      // Padding within a framed rectangle (used by most widgets)
        FrameRounding           = 0.0f;             // Radius of frame corners rounding. Set to 0.0f to have rectangular frames (used by most widgets).
        FrameBorderSize         = 0.0f;             // Thickness of border around frames. Generally set to 0.0f or 1.0f. Other values not well tested.
        ItemSpacing             = ImVec2(8,4);      // Horizontal and vertical spacing between widgets/lines
        ItemInnerSpacing        = ImVec2(4,4);      // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label)
        TouchExtraPadding       = ImVec2(0,0);      // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
        IndentSpacing           = 21.0f;            // Horizontal spacing when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
        ColumnsMinSpacing       = 6.0f;             // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
        ScrollbarSize           = 14.0f;            // Width of the vertical scrollbar, Height of the horizontal scrollbar
        ScrollbarRounding       = 9.0f;             // Radius of grab corners rounding for scrollbar
        GrabMinSize             = 10.0f;            // Minimum width/height of a grab box for slider/scrollbar
        GrabRounding            = 0.0f;             // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
        TabRounding             = 4.0f;             // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
        TabBorderSize           = 0.0f;             // Thickness of border around tabs.
        ColorButtonPosition     = ImGuiDir.Right;   // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
        ButtonTextAlign         = ImVec2(0.5f,0.5f);// Alignment of button text when button is larger than text.
        SelectableTextAlign     = ImVec2(0.0f,0.0f);// Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
        DisplayWindowPadding    = ImVec2(19,19);    // Window position are clamped to be visible within the display area or monitors by at least this amount. Only applies to regular windows.
        DisplaySafeAreaPadding  = ImVec2(3,3);      // If you cannot see the edge of your screen (e.g. on a TV) increase the safe area padding. Covers popups/tooltips as well regular windows.
        MouseCursorScale        = 1.0f;             // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). May be removed later.
        AntiAliasedLines        = true;             // Enable anti-aliasing on lines/borders. Disable if you are really short on CPU/GPU.
        AntiAliasedFill         = true;             // Enable anti-aliasing on filled shapes (rounded rectangles, circles, etc.)
        CurveTessellationTol    = 1.25f;            // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
        CircleSegmentMaxError   = 1.60f;            // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.

        // Default theme
        StyleColorsDark(&this);
    }

    void ScaleAllSizes(float scale_factor)
    {
        WindowPadding = ImFloor(WindowPadding * scale_factor);
        WindowRounding = ImFloor(WindowRounding * scale_factor);
        WindowMinSize = ImFloor(WindowMinSize * scale_factor);
        ChildRounding = ImFloor(ChildRounding * scale_factor);
        PopupRounding = ImFloor(PopupRounding * scale_factor);
        FramePadding = ImFloor(FramePadding * scale_factor);
        FrameRounding = ImFloor(FrameRounding * scale_factor);
        ItemSpacing = ImFloor(ItemSpacing * scale_factor);
        ItemInnerSpacing = ImFloor(ItemInnerSpacing * scale_factor);
        TouchExtraPadding = ImFloor(TouchExtraPadding * scale_factor);
        IndentSpacing = ImFloor(IndentSpacing * scale_factor);
        ColumnsMinSpacing = ImFloor(ColumnsMinSpacing * scale_factor);
        ScrollbarSize = ImFloor(ScrollbarSize * scale_factor);
        ScrollbarRounding = ImFloor(ScrollbarRounding * scale_factor);
        GrabMinSize = ImFloor(GrabMinSize * scale_factor);
        GrabRounding = ImFloor(GrabRounding * scale_factor);
        TabRounding = ImFloor(TabRounding * scale_factor);
        DisplayWindowPadding = ImFloor(DisplayWindowPadding * scale_factor);
        DisplaySafeAreaPadding = ImFloor(DisplaySafeAreaPadding * scale_factor);
        MouseCursorScale = ImFloor(MouseCursorScale * scale_factor);
    }
}

//-----------------------------------------------------------------------------
// ImGuiIO
// Communicate most settings and inputs/outputs to Dear ImGui using this structure.
// Access via ImGui::GetIO(). Read 'Programmer guide' section in .cpp file for general usage.
//-----------------------------------------------------------------------------

struct ImGuiIO
{
    nothrow:
    @nogc:
    //------------------------------------------------------------------
    // Configuration (fill once)                // Default value
    //------------------------------------------------------------------

    ImGuiConfigFlags   ConfigFlags;             // = 0              // See ImGuiConfigFlags enum. Set by user/application. Gamepad/keyboard navigation options, etc.
    ImGuiBackendFlags  BackendFlags;            // = 0              // Set ImGuiBackendFlags enum. Set by back-end (imgui_impl_xxx files or custom back-end) to communicate features supported by the back-end.
    ImVec2      DisplaySize;                    // <unset>          // Main display size, in pixels.
    float       DeltaTime;                      // = 1.0f/60.0f     // Time elapsed since last frame, in seconds.
    float       IniSavingRate;                  // = 5.0f           // Minimum time between saving positions/sizes to .ini file, in seconds.
    string      IniFilename;                    // = "imgui.ini"    // Path to .ini file. Set null to disable automatic .ini loading/saving, if e.g. you want to manually load/save from memory.
    string      LogFilename;                    // = "imgui_log.txt"// Path to .log file (default parameter to ImGui.LogToFile when no file is specified).
    float       MouseDoubleClickTime;           // = 0.30f          // Time for a double-click, in seconds.
    float       MouseDoubleClickMaxDist;        // = 6.0f           // Distance threshold to stay in to validate a double-click, in pixels.
    float       MouseDragThreshold;             // = 6.0f           // Distance threshold before considering we are dragging.
    int[ImGuiKey.COUNT]       KeyMap;           // <unset>          // Map of indices into the KeysDown[512] entries array which represent your "native" keyboard state.
    float       KeyRepeatDelay;                 // = 0.250f         // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
    float       KeyRepeatRate;                  // = 0.050f         // When holding a key/button, rate at which it repeats, in seconds.
    void*       UserData;                       // = null           // Store your own data for retrieval by callbacks.

    ImFontAtlas*Fonts;                          // <auto>           // Font atlas: load, rasterize and pack one or more fonts into a single texture.
    float       FontGlobalScale;                // = 1.0f           // Global scale all fonts
    bool        FontAllowUserScaling;           // = false          // Allow user scaling text of individual window with CTRL+Wheel.
    ImFont*     FontDefault;                    // = null           // Font to use on NewFrame(). Use null to uses Fonts.Fonts[0].
    ImVec2      DisplayFramebufferScale;        // = (1.0f,1.0f)    // For retina display or other situations where window coordinates are different from framebuffer coordinates. This generally ends up in ImDrawData.FramebufferScale.

    // Miscellaneous configuration options
    bool        MouseDrawCursor;                // = false          // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by back-end implementations.
    bool        ConfigMacOSXBehaviors;          // = defined(__APPLE__) // OS X style: Text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl (was called io.OptMacOSXBehaviors prior to 1.63)
    bool        ConfigInputTextCursorBlink;     // = true           // Set to false to disable blinking cursor, for users who consider it distracting. (was called: io.OptCursorBlink prior to 1.63)
    bool        ConfigWindowsResizeFromEdges;   // = true           // Enable resizing of windows from their edges and from the lower-left corner. This requires (io.BackendFlags & ImGuiBackendFlags.HasMouseCursors) because it needs mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags.ResizeFromAnySide flag)
    bool        ConfigWindowsMoveFromTitleBarOnly; // = false       // [BETA] Set to true to only allow moving windows when clicked+dragged from the title bar. Windows without a title bar are not affected.
    float       ConfigWindowsMemoryCompactTimer;// = 60.0f          // [BETA] Compact window memory usage when unused. Set to -1.0f to disable.

    //------------------------------------------------------------------
    // Platform Functions
    // (the imgui_impl_xxxx back-end files are setting those up for you)
    //------------------------------------------------------------------

    // Optional: Platform/Renderer back-end name (informational only! will be displayed in About Window) + User data for back-end/wrappers to store their own stuff.
    string      BackendPlatformName;            // = null
    string      BackendRendererName;            // = null
    void*       BackendPlatformUserData;        // = null           // User data for platform back-end
    void*       BackendRendererUserData;        // = null           // User data for renderer back-end
    void*       BackendLanguageUserData;        // = null           // User data for non C++ programming language back-end

    // Optional: Access OS clipboard
    // (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
    string function(void* user_data) GetClipboardTextFn;
    void        function(void* user_data, string text) SetClipboardTextFn;
    void*       ClipboardUserData;

    // Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME in Windows)
    // (default to use native imm32 api on Windows)
    void        function(int x, int y) ImeSetInputScreenPosFn;
    void*       ImeWindowHandle;                // = null           // (Windows) Set this to your HWND to get automatic IME cursor positioning.

    static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
        // [OBSOLETE since 1.60+] Rendering function, will be automatically called in Render(). Please call your rendering function yourself now!
        // You can obtain the ImDrawData* by calling ImGui::GetDrawData() after Render(). See example applications if you are unsure of how to implement this.
        void        function(ImDrawData* data) RenderDrawListsFn;
    } else {
        // This is only here to keep ImGuiIO the same size/layout, so that IMGUI_DISABLE_OBSOLETE_FUNCTIONS can exceptionally be used outside of imconfig.h.
        void*       RenderDrawListsFnUnused;
    }

    //------------------------------------------------------------------
    // Input - Fill before calling NewFrame()
    //------------------------------------------------------------------

    ImVec2      MousePos;                       // Mouse position, in pixels. Set to ImVec2(-FLT_MAX,-FLT_MAX) if mouse is unavailable (on another screen, etc.)
    bool[5]     MouseDown;                      // Mouse buttons: 0=left, 1=right, 2=middle + extras. ImGui itself mostly only uses left button (BeginPopupContext** are using right button). Others buttons allows us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
    float       MouseWheel;                     // Mouse wheel Vertical: 1 unit scrolls about 5 lines text.
    float       MouseWheelH;                    // Mouse wheel Horizontal. Most users don't have a mouse with an horizontal wheel, may not be filled by all back-ends.
    bool        KeyCtrl;                        // Keyboard modifier pressed: Control
    bool        KeyShift;                       // Keyboard modifier pressed: Shift
    bool        KeyAlt;                         // Keyboard modifier pressed: Alt
    bool        KeySuper;                       // Keyboard modifier pressed: Cmd/Super/Windows
    bool[512]   KeysDown;                       // Keyboard keys that are pressed (ideally left in the "native" order your engine has access to keyboard keys, so you can use your own defines/enums for keys).
    float[ImGuiNavInput.COUNT]       NavInputs; // Gamepad inputs. Cleared back to zero by EndFrame(). Keyboard keys will be auto-mapped and be written here by NewFrame().

    // Functions
    void  AddInputCharacter(uint c)          // Queue new character input
    {
        InputQueueCharacters.push_back(c > 0 && c <= IM_UNICODE_CODEPOINT_MAX ? cast(ImWchar)c : IM_UNICODE_CODEPOINT_INVALID);
    }

    void  AddInputCharacterUTF16(ImWchar16 c)        // Queue new character input from an UTF-16 character, it can be a surrogate
    {
        if ((c & 0xFC00) == 0xD800) // High surrogate, must save
        {
            if (InputQueueSurrogate != 0)
                InputQueueCharacters.push_back(0xFFFD);
            InputQueueSurrogate = c;
            return;
        }

        ImWchar cp = c;
        if (InputQueueSurrogate != 0)
        {
            if ((c & 0xFC00) != 0xDC00) // Invalid low surrogate
                InputQueueCharacters.push_back(IM_UNICODE_CODEPOINT_INVALID);
            else if (IM_UNICODE_CODEPOINT_MAX == (0xFFFF)) // Codepoint will not fit in ImWchar (extra parenthesis around 0xFFFF somehow fixes -Wunreachable-code with Clang)
                cp = IM_UNICODE_CODEPOINT_INVALID;
            else
                cp = cast(ImWchar)(((InputQueueSurrogate - 0xD800) << 10) + (c - 0xDC00) + 0x10000);
            InputQueueSurrogate = 0;
        }
        InputQueueCharacters.push_back(cp);
    }

    void  AddInputCharactersUTF8(string utf8_chars)    // Queue new characters input from an UTF-8 string
    {
        size_t index = 0;
        while (index < utf8_chars.length) {
            uint c = 0;
            index += ImTextCharFromUtf8(&c, utf8_chars[index..$]);
            if (c > 0)
                InputQueueCharacters.push_back(cast(ImWchar)c);
        }
    }
    
    void  ClearInputCharacters()                     // Clear the text input buffer manually
    {
        InputQueueCharacters.resize(0);
    }

    //------------------------------------------------------------------
    // Output - Updated by NewFrame() or EndFrame()/Render()
    // (when reading from the io.WantCaptureMouse, io.WantCaptureKeyboard flags to dispatch your inputs, it is
    //  generally easier and more correct to use their state BEFORE calling NewFrame(). See FAQ for details!)
    //------------------------------------------------------------------

    bool        WantCaptureMouse;               // Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
    bool        WantCaptureKeyboard;            // Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
    bool        WantTextInput;                  // Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
    bool        WantSetMousePos;                // MousePos has been altered, back-end should reposition mouse on next frame. Rarely used! Set only when ImGuiConfigFlags_NavEnableSetMousePos flag is enabled.
    bool        WantSaveIniSettings;            // When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
    bool        NavActive;                      // Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
    bool        NavVisible;                     // Keyboard/Gamepad navigation is visible and allowed (will handle ImGuiKey_NavXXX events).
    float       Framerate;                      // Application framerate estimate, in frame per second. Solely for convenience. Rolling average estimation based on io.DeltaTime over 120 frames.
    int         MetricsRenderVertices;          // Vertices output during last call to Render()
    int         MetricsRenderIndices;           // Indices output during last call to Render() = number of triangles * 3
    int         MetricsRenderWindows;           // Number of visible windows
    int         MetricsActiveWindows;           // Number of active windows
    int         MetricsActiveAllocations;       // Number of active allocations, updated by MemAlloc/MemFree based on current context. May be off if you have multiple imgui contexts.
    ImVec2      MouseDelta;                     // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.

    //------------------------------------------------------------------
    // [Internal] Dear ImGui will maintain those fields. Forward compatibility not guaranteed!
    //------------------------------------------------------------------

    ImGuiKeyModFlags KeyMods;                   // Key mods flags (same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags), updated by NewFrame()
    ImVec2      MousePosPrev;                   // Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
    ImVec2[5]      MouseClickedPos;             // Position at time of clicking
    double[5]      MouseClickedTime;            // Time of last click (used to figure out double-click)
    bool[5]        MouseClicked;                // Mouse button went from !Down to Down
    bool[5]        MouseDoubleClicked;          // Has mouse button been double-clicked?
    bool[5]        MouseReleased;               // Mouse button went from Down to !Down
    bool[5]        MouseDownOwned;              // Track if button was clicked inside a dear imgui window. We don't request mouse capture from the application if click started outside ImGui bounds.
    bool[5]        MouseDownWasDoubleClick;     // Track if button down was a double-click
    float[5]       MouseDownDuration;           // Duration the mouse button has been down (0.0f == just clicked)
    float[5]       MouseDownDurationPrev;       // Previous time the mouse button has been down
    ImVec2[5]      MouseDragMaxDistanceAbs;     // Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
    float[5]       MouseDragMaxDistanceSqr;     // Squared maximum distance of how much mouse has traveled from the clicking point
    float[512]       KeysDownDuration;          // Duration the keyboard key has been down (0.0f == just pressed)
    float[512]       KeysDownDurationPrev;      // Previous duration the key has been down
    float[ImGuiNavInput.COUNT]       NavInputsDownDuration;
    float[ImGuiNavInput.COUNT]       NavInputsDownDurationPrev;
    ImWchar16   InputQueueSurrogate;            // For AddInputCharacterUTF16
    ImVector!ImWchar InputQueueCharacters;          // Queue of _characters_ input (obtained by platform back-end). Fill using AddInputCharacter() helper.

    @disable this();
    this(bool dummy)
    {
        // Most fields are initialized with zero
        memset(&this, 0, (this).sizeof);
        IM_ASSERT(IM_ARRAYSIZE(MouseDown) == ImGuiMouseButton.COUNT && IM_ARRAYSIZE(MouseClicked) == ImGuiMouseButton.COUNT); // Our pre-C++11 IM_STATIC_ASSERT() macros triggers warning on modern compilers so we don't use it here.

        // Settings
        ConfigFlags = ImGuiConfigFlags.None;
        BackendFlags = ImGuiBackendFlags.None;
        DisplaySize = ImVec2(-1.0f, -1.0f);
        DeltaTime = 1.0f/60.0f;
        IniSavingRate = 5.0f;
        IniFilename = "imgui.ini";
        LogFilename = "imgui_log.txt";
        MouseDoubleClickTime = 0.30f;
        MouseDoubleClickMaxDist = 6.0f;
        for (int i = 0; i < ImGuiKey.COUNT; i++)
            KeyMap[i] = -1;
        KeyRepeatDelay = 0.275f;
        KeyRepeatRate = 0.050f;
        UserData = NULL;

        Fonts = NULL;
        FontGlobalScale = 1.0f;
        FontDefault = NULL;
        FontAllowUserScaling = false;
        DisplayFramebufferScale = ImVec2(1.0f, 1.0f);

        // Miscellaneous options
        MouseDrawCursor = false;
        static if (D_IMGUI_Apple) {
            ConfigMacOSXBehaviors = true;  // Set Mac OS X style defaults based on __APPLE__ compile time flag
        } else {
            ConfigMacOSXBehaviors = false;
        }
        ConfigInputTextCursorBlink = true;
        ConfigWindowsResizeFromEdges = true;
        ConfigWindowsMoveFromTitleBarOnly = false;
        ConfigWindowsMemoryCompactTimer = 60.0f;

        // Platform Functions
        BackendPlatformName = BackendRendererName = NULL;
        BackendPlatformUserData = BackendRendererUserData = BackendLanguageUserData = NULL;
        GetClipboardTextFn = &GetClipboardTextFn_DefaultImpl;   // Platform dependent default implementations
        SetClipboardTextFn = &SetClipboardTextFn_DefaultImpl;
        ClipboardUserData = NULL;
        ImeSetInputScreenPosFn = &ImeSetInputScreenPosFn_DefaultImpl;
        ImeWindowHandle = NULL;

        // Input (NB: we already have memset zero the entire structure!)
        MousePos = ImVec2(-FLT_MAX, -FLT_MAX);
        MousePosPrev = ImVec2(-FLT_MAX, -FLT_MAX);
        MouseDragThreshold = 6.0f;
        for (int i = 0; i < IM_ARRAYSIZE(MouseDownDuration); i++) MouseDownDuration[i] = MouseDownDurationPrev[i] = -1.0f;
        for (int i = 0; i < IM_ARRAYSIZE(KeysDownDuration); i++) KeysDownDuration[i]  = KeysDownDurationPrev[i] = -1.0f;
        for (int i = 0; i < IM_ARRAYSIZE(NavInputsDownDuration); i++) NavInputsDownDuration[i] = -1.0f;
    }
    
    void destroy() {
        InputQueueCharacters.destroy();
    }
}

//-----------------------------------------------------------------------------
// Misc data structures
//-----------------------------------------------------------------------------

// Shared state of InputText(), passed as an argument to your callback when a ImGuiInputTextFlags_Callback* flag is used.
// The callback function should return 0 by default.
// Callbacks (follow a flag name and see comments in ImGuiInputTextFlags_ declarations for more details)
// - ImGuiInputTextFlags_CallbackCompletion:  Callback on pressing TAB
// - ImGuiInputTextFlags_CallbackHistory:     Callback on pressing Up/Down arrows
// - ImGuiInputTextFlags_CallbackAlways:      Callback on each iteration
// - ImGuiInputTextFlags_CallbackCharFilter:  Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
// - ImGuiInputTextFlags_CallbackResize:      Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow.
struct ImGuiInputTextCallbackData
{
    nothrow:
    @nogc:

    ImGuiInputTextFlags EventFlag;      // One ImGuiInputTextFlags_Callback*    // Read-only
    ImGuiInputTextFlags Flags;          // What user passed to InputText()      // Read-only
    void*               UserData;       // What user passed to InputText()      // Read-only

    // Arguments for the different callback events
    // - To modify the text buffer in a callback, prefer using the InsertChars() / DeleteChars() function. InsertChars() will take care of calling the resize callback if necessary.
    // - If you know your edits are not going to resize the underlying buffer allocation, you may modify the contents of 'Buf[]' directly. You need to update 'BufTextLen' accordingly (0 <= BufTextLen < BufSize) and set 'BufDirty'' to true so InputText can update its internal state.
    ImWchar             EventChar;      // Character input                      // Read-write   // [CharFilter] Replace character with another one, or set to zero to drop. return 1 is equivalent to setting EventChar=0;
    ImGuiKey            EventKey;       // Key pressed (Up/Down/TAB)            // Read-only    // [Completion,History]
    char*               Buf;            // Text buffer                          // Read-write   // [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
    int                 BufTextLen;     // Text length (in bytes)               // Read-write   // [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
    int                 BufSize;        // Buffer size (in bytes) = capacity+1  // Read-only    // [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
    bool                BufDirty;       // Set if you modify Buf/BufTextLen!    // Write        // [Completion,History,Always]
    int                 CursorPos;      //                                      // Read-write   // [Completion,History,Always]
    int                 SelectionStart; //                                      // Read-write   // [Completion,History,Always] == to SelectionEnd when no selection)
    int                 SelectionEnd;   //                                      // Read-write   // [Completion,History,Always]

    // Helper functions for text manipulation.
    // Use those function to benefit from the CallbackResize behaviors. Calling those function reset the selection.
    // this();
    void      DeleteChars(int pos, int bytes_count)
    {
        IM_ASSERT(pos + bytes_count <= BufTextLen);
        size_t dst = pos;
        size_t src = pos + bytes_count;
        char c = Buf[src++];
        while (c) {
            Buf[dst++] = c;
            c = Buf[src++];
        }
        Buf[dst] = '\0';

        if (CursorPos + bytes_count >= pos)
            CursorPos -= bytes_count;
        else if (CursorPos >= pos)
            CursorPos = pos;
        SelectionStart = SelectionEnd = CursorPos;
        BufDirty = true;
        BufTextLen -= bytes_count;
    }

    void      InsertChars(int pos, string new_text)
    {
        const bool is_resizable = (Flags & ImGuiInputTextFlags.CallbackResize) != 0;
        const int new_text_len = cast(int)new_text.length;
        if (new_text_len + BufTextLen >= BufSize)
        {
            if (!is_resizable)
                return;

            // Contrary to STB_TEXTEDIT_INSERTCHARS() this is working in the UTF8 buffer, hence the midly similar code (until we remove the U16 buffer alltogether!)
            ImGuiContext* g = GImGui;
            ImGuiInputTextState* edit_state = &g.InputTextState;
            IM_ASSERT(edit_state.ID != 0 && g.ActiveId == edit_state.ID);
            IM_ASSERT(Buf == edit_state.TextA.Data);
            int new_buf_size = BufTextLen + ImClamp(new_text_len * 4, 32, ImMax(256, new_text_len)) + 1;
            edit_state.TextA.reserve(new_buf_size + 1);
            Buf = edit_state.TextA.Data;
            BufSize = edit_state.BufCapacityA = new_buf_size;
        }

        if (BufTextLen != pos)
            memmove(Buf + pos + new_text_len, Buf + pos, cast(size_t)(BufTextLen - pos));
        memcpy(Buf + pos, new_text.ptr, cast(size_t)new_text_len * (char).sizeof);
        Buf[BufTextLen + new_text_len] = '\0';

        if (CursorPos >= pos)
            CursorPos += new_text_len;
        SelectionStart = SelectionEnd = CursorPos;
        BufDirty = true;
        BufTextLen += new_text_len;
    }
    bool                HasSelection() const { return SelectionStart != SelectionEnd; }
}

// Resizing callback data to apply custom constraint. As enabled by SetNextWindowSizeConstraints(). Callback is called during the next Begin().
// NB: For basic min/max size constraint on each axis you don't need to use the callback! The SetNextWindowSizeConstraints() parameters are enough.
struct ImGuiSizeCallbackData
{
    void*   UserData;       // Read-only.   What user passed to SetNextWindowSizeConstraints()
    ImVec2  Pos;            // Read-only.   Window position, for reference.
    ImVec2  CurrentSize;    // Read-only.   Current window size.
    ImVec2  DesiredSize;    // Read-write.  Desired size, based on user's mouse position. Write to this field to restrain resizing.
}

// Data payload for Drag and Drop operations: AcceptDragDropPayload(), GetDragDropPayload()
struct ImGuiPayload
{
    nothrow:
    @nogc:

    // Members
    void*           Data;               // Data (copied and owned by dear imgui)
    int             DataSize;           // Data size

    // [Internal]
    ImGuiID         SourceId;           // Source item id
    ImGuiID         SourceParentId;     // Source parent id (if available)
    int             DataFrameCount;     // Data timestamp
    char[32]            DataType = 0;     // Data type tag (short user-supplied string, 32 characters max)
    bool            Preview;            // Set when AcceptDragDropPayload() was called and mouse has been hovering the target item (nb: handle overlapping drag targets)
    bool            Delivery;           // Set when AcceptDragDropPayload() was called and mouse button is released over the target item.
    size_t          DataTypeLength;

    // this()  { Clear(); }
    void Clear()    { SourceId = SourceParentId = 0; Data = NULL; DataSize = 0; memset(DataType.ptr, 0, (DataType).sizeof); DataFrameCount = -1; Preview = Delivery = false; }
    bool IsDataType(string type) const { return DataFrameCount != -1 && type == cast(string)DataType[0..DataTypeLength]; }
    bool IsPreview() const                  { return Preview; }
    bool IsDelivery() const                 { return Delivery; }
}

//-----------------------------------------------------------------------------
// Obsolete functions (Will be removed! Read 'API BREAKING CHANGES' section in imgui.cpp for details)
// Please keep your copy of dear imgui up to date! Occasionally set '#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS' in imconfig.h to stay ahead.
//-----------------------------------------------------------------------------

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
// namespace ImGui
// {
    // OBSOLETED in 1.72 (from July 2019)
    deprecated pragma(inline, true) void  TreeAdvanceToLabelPos()               { SetCursorPosX(GetCursorPosX() + GetTreeNodeToLabelSpacing()); }
    // OBSOLETED in 1.71 (from June 2019)
    deprecated pragma(inline, true) void  SetNextTreeNodeOpen(bool open, ImGuiCond cond = ImGuiCond.None) { SetNextItemOpen(open, cond); }
    // OBSOLETED in 1.70 (from May 2019)
    deprecated pragma(inline, true) float GetContentRegionAvailWidth()          { return GetContentRegionAvail().x; }
    // OBSOLETED in 1.69 (from Mar 2019)
    deprecated pragma(inline, true) ImDrawList* GetOverlayDrawList()            { return GetForegroundDrawList(); }
    // OBSOLETED in 1.66 (from Sep 2018)
    deprecated pragma(inline, true) void  SetScrollHere(float center_ratio=0.5f){ SetScrollHereY(center_ratio); }
    // OBSOLETED in 1.63 (between Aug 2018 and Sept 2018)
    deprecated pragma(inline, true) bool  IsItemDeactivatedAfterChange()        { return IsItemDeactivatedAfterEdit(); }
    // OBSOLETED in 1.61 (between Apr 2018 and Aug 2018)
    // IMGUI_API bool      InputFloat(const char* label, float* v, float step, float step_fast, int decimal_precision, ImGuiInputTextFlags flags = 0); // Use the 'const char* format' version instead of 'decimal_precision'!
    // IMGUI_API bool      InputFloat2(const char* label, float v[2], int decimal_precision, ImGuiInputTextFlags flags = 0);
    // IMGUI_API bool      InputFloat3(const char* label, float v[3], int decimal_precision, ImGuiInputTextFlags flags = 0);
    // IMGUI_API bool      InputFloat4(const char* label, float v[4], int decimal_precision, ImGuiInputTextFlags flags = 0);
    // OBSOLETED in 1.60 (between Dec 2017 and Apr 2018)
    deprecated pragma(inline, true) bool  IsAnyWindowFocused()                  { return IsWindowFocused(ImGuiFocusedFlags.AnyWindow); }
    deprecated pragma(inline, true) bool  IsAnyWindowHovered()                  { return IsWindowHovered(ImGuiHoveredFlags.AnyWindow); }
    deprecated pragma(inline, true) ImVec2 CalcItemRectClosestPoint(const ImVec2/*&*/ pos, bool on_edge = false, float outward = 0.0f) { IM_UNUSED(on_edge); IM_UNUSED(outward); IM_ASSERT(0); return pos; }
// }
deprecated alias ImGuiTextEditCallback =      ImGuiInputTextCallback;    // OBSOLETED in 1.63 (from Aug 2018): made the names consistent
deprecated alias ImGuiTextEditCallbackData =  ImGuiInputTextCallbackData;
}

//-----------------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------------

// Helper: Unicode defines
enum IM_UNICODE_CODEPOINT_INVALID = 0xFFFD;     // Invalid Unicode code point (standard value).
version (IMGUI_USE_WCHAR32) {
    enum IM_UNICODE_CODEPOINT_MAX     = 0x10FFFF;   // Maximum Unicode code point supported by this build.
} else {
    enum IM_UNICODE_CODEPOINT_MAX     = 0xFFFF;     // Maximum Unicode code point supported by this build.
}

// Helper: Execute a block of code at maximum once a frame. Convenient if you want to quickly create an UI within deep-nested code that runs multiple times every frame.
// Usage: static ImGuiOnceUponAFrame oaf; if (oaf) ImGui::Text("This will be called only once per frame");
struct ImGuiOnceUponAFrame
{
    // ImGuiOnceUponAFrame() { RefFrame = -1; }
    int RefFrame = -1;
    bool opCast(T:bool)(){ int current_frame = GetFrameCount(); if (RefFrame == current_frame) return false; RefFrame = current_frame; return true; }
}

// Helper: Parse and apply text filters. In format "aaaaa[,bbbb][,ccccc]"
struct ImGuiTextFilter
{
    nothrow:
    @nogc:

    this(string default_filter)
    {
        if (default_filter)
        {
            ImStrncpy(InputBuf, default_filter);
            Build();
        }
        else
        {
            InputBuf[0] = 0;
            CountGrep = 0;
        }
    }

    void destroy() {
        Filters.destroy();
    }

    bool      Draw(string label = "Filter (inc,-exc)", float width = 0.0f)  // Helper calling InputText+Build
    {
        if (width != 0.0f)
            SetNextItemWidth(width);
        bool value_changed = InputText(label, InputBuf);
        if (value_changed)
            Build();
        return value_changed;
    }

    bool      PassFilter(string text) const
    {
        if (Filters.empty())
            return true;

        if (text == NULL)
            text = EMPTY_STRING;

        for (int i = 0; i != Filters.Size; i++)
        {
            const ImGuiTextRange* f = &Filters[i];
            if (f.empty())
                continue;
            if (f.s[0] == '-')
            {
                // Subtract
                if (ImStristr(text, f.s[1..$]) != NULL)
                    return false;
            }
            else
            {
                // Grep
                if (ImStristr(text, f.s) != NULL)
                    return true;
            }
        }

        // Implicit * grep
        if (CountGrep == 0)
            return true;

        return false;
    }


    void      Build()
    {
        Filters.resize(0);
        ImGuiTextRange input_range = ImGuiTextRange(ImCstring(InputBuf));
        input_range.split(',', &Filters);

        CountGrep = 0;
        for (int i = 0; i != Filters.Size; i++)
        {
            ImGuiTextRange* f = &Filters[i];
            while (f.s.length > 0 && ImCharIsBlankA(f.s[0]))
                f.s = f.s[1..$];
            while (f.s.length > 0 && ImCharIsBlankA(f.s[$-1]))
                f.s = f.s[0..$-1];
            if (f.empty())
                continue;
            if (Filters[i].s[0] != '-')
                CountGrep += 1;
        }
    }

    void                Clear()          { InputBuf[0] = 0; Build(); }
    bool                IsActive() const { return !Filters.empty(); }

    // [Internal]
    struct ImGuiTextRange
    {
        nothrow:
        @nogc:

        string     s;

        // ImGuiTextRange()                                { s = NULL; }
        this(string _s)  { s = _s; }
        bool            empty() const                   { return s.length == 0; }
        void  split(char separator, ImVector!ImGuiTextRange* _out) const
        {
            _out.resize(0);
            size_t wb = 0;
            size_t we = wb;
            while (we < s.length)
            {
                if (s[we] == separator)
                {
                    _out.push_back(ImGuiTextRange(s[wb..we]));
                    wb = we + 1;
                }
                we++;
            }
            if (wb != we)
                _out.push_back(ImGuiTextRange(s[wb..we]));
        }
    }
    char[256]                    InputBuf = 0;
    ImVector!ImGuiTextRange Filters;
    int                     CountGrep;
}

// Helper: Growable text buffer for logging/accumulating text
// (this could be called 'ImGuiTextBuilder' / 'ImGuiStringBuilder')
struct ImGuiTextBuffer
{
    nothrow:
    @nogc:

    ImVector!char      Buf;
    __gshared char[1] EmptyString = 0;

    // ImGuiTextBuffer()   { }
    void destroy() { Buf.destroy(); }
    pragma(inline, true) char         opIndex(int i) const { IM_ASSERT(Buf.Data != NULL); return Buf.Data[i]; }
    const (char)*         begin() const           { return Buf.Data ? &Buf.front() : EmptyString.ptr; }
    const (char)*         end() const             { return Buf.Data ? &Buf.back() : EmptyString.ptr; }   // Buf is zero-terminated, so end() will point on the zero-terminator
    int                 size() const            { return Buf.Size ? Buf.Size - 1 : 0; }
    bool                empty() const           { return Buf.Size <= 1; }
    void                clear()                 { Buf.clear(); }
    void                reserve(int capacity)   { Buf.reserve(capacity); }
    string         c_str() const
    {
        if (!Buf.Data)
            return cast(string)EmptyString[0..0];
        
        // don't include zero terminator, if present
        if (Buf.Size > 0 && Buf.back() == '\0')
            return cast(string)Buf.Data[0..Buf.Size - 1];

        return cast(string)Buf.asArray();
    }

    void      append(string str)
    {
        int len = cast(int)str.length;

        // Add zero-terminator the first time
        const int write_off = (Buf.Size != 0) ? Buf.Size : 1;
        const int needed_sz = write_off + len;
        if (write_off + len >= Buf.Capacity)
        {
            int new_capacity = Buf.Capacity * 2;
            Buf.reserve(needed_sz > new_capacity ? needed_sz : new_capacity);
        }
        
        Buf.resize(needed_sz);
        memcpy(&Buf[write_off - 1], str.ptr, cast(size_t)len);
        Buf[write_off - 1 + len] = 0;
    }

    void      appendf(string fmt, ...)
    {
        mixin va_start;
        appendfv(fmt, va_args);
        va_end(va_args);
    }

    void      appendfv(string fmt, va_list va_args)
    {
        va_list args_copy;
        va_copy(args_copy, va_args);

        int len = ImFormatStringV(NULL, fmt, va_args);         // FIXME-OPT: could do a first pass write attempt, likely successful on first pass.
        if (len <= 0)
        {
            va_end(args_copy);
            return;
        }

        // Add zero-terminator the first time
        const int write_off = (Buf.Size != 0) ? Buf.Size : 1;
        const int needed_sz = write_off + len;
        if (write_off + len >= Buf.Capacity)
        {
            int new_capacity = Buf.Capacity * 2;
            Buf.reserve(needed_sz > new_capacity ? needed_sz : new_capacity);
        }

        Buf.resize(needed_sz);
        ImFormatStringV(Buf.Data[write_off - 1..write_off + len], fmt, args_copy);
        va_end(args_copy);
    }
}

// Helper: Key->Value storage
// Typically you don't have to worry about this since a storage is held within each Window.
// We use it to e.g. store collapse state for a tree (Int 0/1)
// This is optimized for efficient lookup (dichotomy into a contiguous buffer) and rare insertion (typically tied to user interactions aka max once a frame)
// You can use it as custom user storage for temporary values. Declare your own storage if, for example:
// - You want to manipulate the open/close state of a particular sub-tree in your interface (tree node uses Int 0/1 to store their state).
// - You want to store custom debug data easily without adding or editing structures in your code (probably not efficient, but convenient)
// Types are NOT stored, so it is up to you to make sure your Key don't collide with different types.
struct ImGuiStorage
{
    nothrow:
    @nogc:

    // [Internal]
    struct ImGuiStoragePair
    {
        nothrow:
        @nogc:

        ImGuiID key;
        union { int val_i; float val_f; void* val_p; }
        this(ImGuiID _key, int _val_i)      { key = _key; val_i = _val_i; }
        this(ImGuiID _key, float _val_f)    { key = _key; val_f = _val_f; }
        this(ImGuiID _key, void* _val_p)    { key = _key; val_p = _val_p; }
    }

    ImVector!ImGuiStoragePair      Data;

    // - Get***() functions find pair, never add/allocate. Pairs are sorted so a query is O(log N)
    // - Set***() functions find pair, insertion on demand if missing.
    // - Sorted insertion is costly, paid once. A typical frame shouldn't need to insert any new pair.
    void                Clear() { Data.clear(); }

    void destroy() {
        Data.destroy();
    }

    int       GetInt(ImGuiID key, int default_val = 0) const
    {
        const ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            return default_val;
        return it.val_i;
    }

    void      SetInt(ImGuiID key, int val)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
        {
            Data.insert(it, ImGuiStoragePair(key, val));
            return;
        }
        it.val_i = val;
    }

    bool      GetBool(ImGuiID key, bool default_val = false) const
    {
        return GetInt(key, default_val ? 1 : 0) != 0;
    }

    void      SetBool(ImGuiID key, bool val)
    {
        SetInt(key, val ? 1 : 0);
    }

    float     GetFloat(ImGuiID key, float default_val = 0.0f) const
    {
        const ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            return default_val;
        return it.val_f;
    }

    void      SetFloat(ImGuiID key, float val)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
        {
            Data.insert(it, ImGuiStoragePair(key, val));
            return;
        }
        it.val_f = val;
    }

    void*     GetVoidPtr(ImGuiID key) // default_val is NULL
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            return NULL;
        return it.val_p;
    }

    void      SetVoidPtr(ImGuiID key, void* val)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
        {
            Data.insert(it, ImGuiStoragePair(key, val));
            return;
        }
        it.val_p = val;
    }

    // - Get***Ref() functions finds pair, insert on demand if missing, return pointer. Useful if you intend to do Get+Set.
    // - References are only valid until a new value is added to the storage. Calling a Set***() function or a Get***Ref() function invalidates the pointer.
    // - A typical use case where this is convenient for quick hacking (e.g. add storage during a live Edit&Continue session if you can't modify existing struct)
    //      float* pvar = ImGui::GetFloatRef(key); ImGui::SliderFloat("var", pvar, 0, 100.0f); some_var += *pvar;
    int*      GetIntRef(ImGuiID key, int default_val = 0)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            it = Data.insert(it, ImGuiStoragePair(key, default_val));
        return &it.val_i;
    }

    bool*     GetBoolRef(ImGuiID key, bool default_val = false)
    {
        return cast(bool*)GetIntRef(key, default_val ? 1 : 0);
    }

    float*    GetFloatRef(ImGuiID key, float default_val = 0.0f)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            it = Data.insert(it, ImGuiStoragePair(key, default_val));
        return &it.val_f;
    }

    void**    GetVoidPtrRef(ImGuiID key, void* default_val = NULL)
    {
        ImGuiStoragePair* it = LowerBound(&Data, key);
        if (it == Data.end() || it.key != key)
            it = Data.insert(it, ImGuiStoragePair(key, default_val));
        return &it.val_p;
    }

    // Use on your own storage if you know only integer are being stored (open/close all tree nodes)
    void      SetAllInt(int v)
    {
        for (int i = 0; i < Data.Size; i++)
            Data[i].val_i = v;
    }

    // For quicker full rebuild of a storage (instead of an incremental one), you may add all your contents and then sort once.
    void      BuildSortByKey()
    {
        struct StaticFunc {
            nothrow:
            @nogc:

            static int PairCompareByID(ImGuiStoragePair* lhs, ImGuiStoragePair* rhs) {
                // We can't just do a subtraction because qsort uses signed integers and subtracting our ID doesn't play well with that.
                if (lhs.key > rhs.key) return +1;
                if (lhs.key < rhs.key) return -1;
                return 0;
            }
        }
        if (Data.Size > 1)
            ImQsort(Data.Data[0..Data.Size], &StaticFunc.PairCompareByID);
    }
}

// Helper: Manually clip large list of items.
// If you are submitting lots of evenly spaced items and you have a random access to the list, you can perform coarse clipping based on visibility to save yourself from processing those items at all.
// The clipper calculates the range of visible items and advance the cursor to compensate for the non-visible items we have skipped.
// ImGui already clip items based on their bounds but it needs to measure text size to do so. Coarse clipping before submission makes this cost and your own data fetching/submission cost null.
// Usage:
//     ImGuiListClipper clipper(1000);  // we have 1000 elements, evenly spaced.
//     while (clipper.Step())
//         for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
//             ImGui::Text("line number %d", i);
// - Step 0: the clipper let you process the first element, regardless of it being visible or not, so we can measure the element height (step skipped if we passed a known height as second arg to constructor).
// - Step 1: the clipper infer height from first element, calculate the actual range of elements to display, and position the cursor before the first element.
// - (Step 2: dummy step only required if an explicit items_height was passed to constructor or Begin() and user call Step(). Does nothing and switch to Step 3.)
// - Step 3: the clipper validate that we have reached the expected Y position (corresponding to element DisplayEnd), advance the cursor to the end of the list and then returns 'false' to end the loop.
struct ImGuiListClipper
{
    nothrow:
    @nogc:

    int     DisplayStart, DisplayEnd;
    int     ItemsCount;

    // [Internal]
    int     StepNo;
    float   ItemsHeight;
    float   StartPosY;

    // items_count:  Use -1 to ignore (you can call Begin later). Use INT_MAX if you don't know how many items you have (in which case the cursor won't be advanced in the final step).
    // items_height: Use -1.0f to be calculated automatically on first step. Otherwise pass in the distance between your items, typically GetTextLineHeightWithSpacing() or GetFrameHeightWithSpacing().
    // If you don't specify an items_height, you NEED to call Step(). If you specify items_height you may call the old Begin()/End() api directly, but prefer calling Step().
    this(int items_count, float items_height = -1.0f)  { Begin(items_count, items_height); } // NB: Begin() initialize every fields (as we allow user to call Begin/End multiple times on a same instance if they want).
    void destroy()                                                 { IM_ASSERT(ItemsCount == -1); }      // Assert if user forgot to call End() or Step() until false.

    bool Step()                                              // Call until it returns false. The DisplayStart/DisplayEnd fields will be set and you can process/draw those items.
    {
        ImGuiContext* g = GImGui;
        ImGuiWindow* window = g.CurrentWindow;

        if (ItemsCount == 0 || window.SkipItems)
        {
            ItemsCount = -1;
            return false;
        }
        if (StepNo == 0) // Step 0: the clipper let you process the first element, regardless of it being visible or not, so we can measure the element height.
        {
            DisplayStart = 0;
            DisplayEnd = 1;
            StartPosY = window.DC.CursorPos.y;
            StepNo = 1;
            return true;
        }
        if (StepNo == 1) // Step 1: the clipper infer height from first element, calculate the actual range of elements to display, and position the cursor before the first element.if (StepNo == 1) // Step 1: the clipper infer height from first element, calculate the actual range of elements to display, and position the cursor before the first element.
        {
            if (ItemsCount == 1) { ItemsCount = -1; return false; }
            float items_height = window.DC.CursorPos.y - StartPosY;
            IM_ASSERT(items_height > 0.0f);   // If this triggers, it means Item 0 hasn't moved the cursor vertically
            Begin(ItemsCount - 1, items_height);
            DisplayStart++;
            DisplayEnd++;
            StepNo = 3;
            return true;
        }
        if (StepNo == 2) // Step 2: dummy step only required if an explicit items_height was passed to constructor or Begin() and user still call Step(). Does nothing and switch to Step 3.
        {
            IM_ASSERT(DisplayStart >= 0 && DisplayEnd >= 0);
            StepNo = 3;
            return true;
        }
        if (StepNo == 3) // Step 3: the clipper validate that we have reached the expected Y position (corresponding to element DisplayEnd), advance the cursor to the end of the list and then returns 'false' to end the loop.
            End();
        return false;
    }

    void Begin(int count, float items_height = -1.0f)  // Automatically called by constructor if you passed 'items_count' or by Step() in Step 1.
    {
        ImGuiContext* g = GImGui;
        ImGuiWindow* window = g.CurrentWindow;

        StartPosY = window.DC.CursorPos.y;
        ItemsHeight = items_height;
        ItemsCount = count;
        StepNo = 0;
        DisplayEnd = DisplayStart = -1;
        if (ItemsHeight > 0.0f)
        {
            CalcListClipping(ItemsCount, ItemsHeight, &DisplayStart, &DisplayEnd); // calculate how many to clip/display
            if (DisplayStart > 0)
                SetCursorPosYAndSetupDummyPrevLine(StartPosY + DisplayStart * ItemsHeight, ItemsHeight); // advance cursor
            StepNo = 2;
        }
    }

    void End()                                               // Automatically called on the last call of Step() that returns false.
    {
        if (ItemsCount < 0)
            return;
        // In theory here we should assert that ImGui.GetCursorPosY() == StartPosY + DisplayEnd * ItemsHeight, but it feels saner to just seek at the end and not assert/crash the user.
        if (ItemsCount < INT_MAX)
            SetCursorPosYAndSetupDummyPrevLine(StartPosY + ItemsCount * ItemsHeight, ItemsHeight); // advance cursor
        ItemsCount = -1;
        StepNo = 3;
    }
}

// Helpers macros to generate 32-bit encoded colors
version (IMGUI_USE_BGRA_PACKED_COLOR) {
    enum IM_COL32_R_SHIFT    = 16;
    enum IM_COL32_G_SHIFT    = 8;
    enum IM_COL32_B_SHIFT    = 0;
    enum IM_COL32_A_SHIFT    = 24;
    enum IM_COL32_A_MASK     = 0xFF000000;
} else {
    enum IM_COL32_R_SHIFT    = 0;
    enum IM_COL32_G_SHIFT    = 8;
    enum IM_COL32_B_SHIFT    = 16;
    enum IM_COL32_A_SHIFT    = 24;
    enum IM_COL32_A_MASK     = 0xFF000000;
}
pragma(inline, true) ImU32 IM_COL32(ImU8 R, ImU8 G, ImU8 B, ImU8 A) {
    return ((cast(ImU32)(A)<<IM_COL32_A_SHIFT) | (cast(ImU32)(B)<<IM_COL32_B_SHIFT) | (cast(ImU32)(G)<<IM_COL32_G_SHIFT) | (cast(ImU32)(R)<<IM_COL32_R_SHIFT));
}
enum IM_COL32_WHITE       = IM_COL32(255,255,255,255);  // Opaque white = 0xFFFFFFFF
enum IM_COL32_BLACK       = IM_COL32(0,0,0,255);        // Opaque black
enum IM_COL32_BLACK_TRANS = IM_COL32(0,0,0,0);          // Transparent black = 0x00000000

// Helper: ImColor() implicitly converts colors to either ImU32 (packed 4x1 byte) or ImVec4 (4x1 float)
// Prefer using IM_COL32() macros if you want a guaranteed compile-time ImU32 for usage with ImDrawList API.
// **Avoid storing ImColor! Store either ImU32 of ImVec4. This is not a full-featured color class. MAY OBSOLETE.
// **None of the ImGui API are using ImColor directly but you can use it as a convenience to pass colors in either ImU32 or ImVec4 formats. Explicitly cast to ImU32 or ImVec4 if needed.
struct ImColor
{
    nothrow:
    @nogc:

    ImVec4              Value;

    // ImColor()                                                       { Value.x = Value.y = Value.z = Value.w = 0.0f; }
    this(int r, int g, int b, int a = 255)                       { float sc = 1.0f/255.0f; Value.x = cast(float)r * sc; Value.y = cast(float)g * sc; Value.z = cast(float)b * sc; Value.w = cast(float)a * sc; }
    this(ImU32 rgba)                                             { float sc = 1.0f/255.0f; Value.x = cast(float)((rgba>>IM_COL32_R_SHIFT)&0xFF) * sc; Value.y = cast(float)((rgba>>IM_COL32_G_SHIFT)&0xFF) * sc; Value.z = cast(float)((rgba>>IM_COL32_B_SHIFT)&0xFF) * sc; Value.w = cast(float)((rgba>>IM_COL32_A_SHIFT)&0xFF) * sc; }
    this(float r, float g, float b, float a = 1.0f)              { Value.x = r; Value.y = g; Value.z = b; Value.w = a; }
    this(const ImVec4/*&*/ col)                                      { Value = col; }
    pragma(inline, true) ImU32 opCast(T:ImU32)() const                                   { return ColorConvertFloat4ToU32(Value); }
    pragma(inline, true) ImVec4 opCast(T:ImVec4)() const                                  { return Value; }

    // FIXME-OBSOLETE: May need to obsolete/cleanup those helpers.
    pragma(inline, true) void    SetHSV(float h, float s, float v, float a = 1.0f){ ColorConvertHSVtoRGB(h, s, v, Value.x, Value.y, Value.z); Value.w = a; }
    static ImColor HSV(float h, float s, float v, float a = 1.0f)   { float r,g,b; ColorConvertHSVtoRGB(h, s, v, r, g, b); return ImColor(r,g,b,a); }
}

//-----------------------------------------------------------------------------
// Draw List API (ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
// Hold a series of drawing commands. The user provides a renderer for ImDrawData which essentially contains an array of ImDrawList.
//-----------------------------------------------------------------------------

// ImDrawCallback: Draw callbacks for advanced uses [configurable type: override in imconfig.h]
// NB: You most likely do NOT need to use draw callbacks just to create your own widget or customized UI rendering,
// you can poke into the draw list for that! Draw callback may be useful for example to:
//  A) Change your GPU render state,
//  B) render a complex 3D scene inside a UI element without an intermediate texture/render target, etc.
// The expected behavior from your rendering function is 'if (cmd.UserCallback != NULL) { cmd.UserCallback(parent_list, cmd); } else { RenderTriangles() }'
// If you want to override the signature of ImDrawCallback, you can simply use e.g. '#define ImDrawCallback MyDrawCallback' (in imconfig.h) + update rendering back-end accordingly.
static if (!D_IMGUI_USER_DEFINED_DRAW_CALLBACK) {
}
    alias ImDrawCallback = void function(const ImDrawList* parent_list, const ImDrawCmd* cmd); // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905

// Special Draw callback value to request renderer back-end to reset the graphics/render state.
// The renderer back-end needs to handle this special value, otherwise it will crash trying to call a function at this address.
// This is useful for example if you submitted callbacks which you know have altered the render state and you want it to be restored.
// It is not done by default because they are many perfectly useful way of altering render state for imgui contents (e.g. changing shader/blending settings before an Image call).
enum ImDrawCallback_ResetRenderState = cast(ImDrawCallback)(-1);

// Typically, 1 command = 1 GPU draw call (unless command is a callback)
// Pre 1.71 back-ends will typically ignore the VtxOffset/IdxOffset fields. When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset'
// is enabled, those fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
struct ImDrawCmd
{
    nothrow:
    @nogc:

    uint    ElemCount;                      // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
    ImVec4          ClipRect;               // Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
    ImTextureID     TextureId;              // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
    uint    VtxOffset;              // Start offset in vertex buffer. Pre-1.71 or without ImGuiBackendFlags_RendererHasVtxOffset: always 0. With ImGuiBackendFlags_RendererHasVtxOffset: may be >0 to support meshes larger than 64K vertices with 16-bit indices.
    uint    IdxOffset;              // Start offset in index buffer. Always equal to sum of ElemCount drawn so far.
    ImDrawCallback  UserCallback;           // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
    void*           UserCallbackData;       // The draw callback code can access this.

    // this() { ElemCount = 0; TextureId = cast(ImTextureID)NULL; VtxOffset = IdxOffset = 0;  UserCallback = NULL; UserCallbackData = NULL; }
}

// Vertex index, default to 16-bit
// To allow large meshes with 16-bit indices: set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset' and handle ImDrawCmd::VtxOffset in the renderer back-end (recommended).
// To use 32-bit indices: override with '#define ImDrawIdx unsigned int' in imconfig.h.
static if (!D_IMGUI_USER_DEFINED_DRAW_IDX) {
}
    alias ImDrawIdx = ushort; // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905

// Vertex layout
// #ifndef IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT
struct ImDrawVert
{
    ImVec2  pos;
    ImVec2  uv;
    ImU32   col;
}
// #else
// You can override the vertex format layout by defining IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT in imconfig.h
// The code expect ImVec2 pos (8 bytes), ImVec2 uv (8 bytes), ImU32 col (4 bytes), but you can re-order them or add other fields as needed to simplify integration in your engine.
// The type has to be described within the macro (you can either declare the struct or use a typedef). This is because ImVec2/ImU32 are likely not declared a the time you'd want to set your type up.
// NOTE: IMGUI DOESN'T CLEAR THE STRUCTURE AND DOESN'T CALL A CONSTRUCTOR SO ANY CUSTOM FIELD WILL BE UNINITIALIZED. IF YOU ADD EXTRA FIELDS (SUCH AS A 'Z' COORDINATES) YOU WILL NEED TO CLEAR THEM DURING RENDER OR TO IGNORE THEM.
// IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT;
// #endif

// For use by ImDrawListSplitter.
struct ImDrawChannel
{
    ImVector!ImDrawCmd         _CmdBuffer;
    ImVector!ImDrawIdx         _IdxBuffer;

    void destroy() {
        _CmdBuffer.destroy();
        _IdxBuffer.destroy();
    }
}

// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
// This is used by the Columns api, so items of each column can be batched together in a same draw call.
struct ImDrawListSplitter
{
    nothrow:
    @nogc:

    int                         _Current;    // Current channel number (0)
    int                         _Count = 1;      // Number of active channels (1+)
    ImVector!ImDrawChannel     _Channels;   // Draw channels (not resized down so _Count might be < Channels.Size)

    // pragma(inline, true) this()  { Clear(); }
    pragma(inline, true) void destroy() { ClearFreeMemory(); }
    pragma(inline, true) void                 Clear() { _Current = 0; _Count = 1; } // Do not clear Channels[] so our allocations are reused next frame
    
    void              ClearFreeMemory()
    {
        for (int i = 0; i < _Channels.Size; i++)
        {
            if (i == _Current)
                memset(&_Channels[i], 0, (_Channels[i]).sizeof);  // Current channel is a copy of CmdBuffer/IdxBuffer, don't destruct again
            _Channels[i]._CmdBuffer.clear();
            _Channels[i]._IdxBuffer.clear();
        }
        _Current = 0;
        _Count = 1;
        _Channels.clear();
    }

    void              Split(ImDrawList* draw_list, int channels_count)
    {
        IM_ASSERT(_Current == 0 && _Count <= 1, "Nested channel splitting is not supported. Please use separate instances of ImDrawListSplitter.");
        int old_channels_count = _Channels.Size;
        if (old_channels_count < channels_count)
            _Channels.resize(channels_count);
        _Count = channels_count;

        // Channels[] (24/32 bytes each) hold storage that we'll swap with draw_list->_CmdBuffer/_IdxBuffer
        // The content of Channels[0] at this point doesn't matter. We clear it to make state tidy in a debugger but we don't strictly need to.
        // When we switch to the next channel, we'll copy draw_list->_CmdBuffer/_IdxBuffer into Channels[0] and then Channels[1] into draw_list->CmdBuffer/_IdxBuffer
        memset(&_Channels[0], 0, (ImDrawChannel).sizeof);
        for (int i = 1; i < channels_count; i++)
        {
            if (i >= old_channels_count)
            {
                IM_PLACEMENT_NEW(&_Channels[i], ImDrawChannel());
            }
            else
            {
                _Channels[i]._CmdBuffer.resize(0);
                _Channels[i]._IdxBuffer.resize(0);
            }
            if (_Channels[i]._CmdBuffer.Size == 0)
            {
                ImDrawCmd draw_cmd;
                draw_cmd.ClipRect = draw_list._ClipRectStack.back();
                draw_cmd.TextureId = draw_list._TextureIdStack.back();
                _Channels[i]._CmdBuffer.push_back(draw_cmd);
            }
        }
    }

    void              Merge(ImDrawList* draw_list)
    {
        // Note that we never use or rely on channels.Size because it is merely a buffer that we never shrink back to 0 to keep all sub-buffers ready for use.
        if (_Count <= 1)
            return;

        SetCurrentChannel(draw_list, 0);
        if (draw_list.CmdBuffer.Size != 0 && draw_list.CmdBuffer.back().ElemCount == 0)
            draw_list.CmdBuffer.pop_back();

        // Calculate our final buffer sizes. Also fix the incorrect IdxOffset values in each command.
        int new_cmd_buffer_count = 0;
        int new_idx_buffer_count = 0;
        ImDrawCmd* last_cmd = (_Count > 0 && draw_list.CmdBuffer.Size > 0) ? &draw_list.CmdBuffer.back() : NULL;
        int idx_offset = last_cmd ? last_cmd.IdxOffset + last_cmd.ElemCount : 0;
        for (int i = 1; i < _Count; i++)
        {
            ImDrawChannel* ch = &_Channels[i];
            if (ch._CmdBuffer.Size > 0 && ch._CmdBuffer.back().ElemCount == 0)
                ch._CmdBuffer.pop_back();
            if (ch._CmdBuffer.Size > 0 && last_cmd != NULL && CanMergeDrawCommands(last_cmd, &ch._CmdBuffer[0]))
            {
                // Merge previous channel last draw command with current channel first draw command if matching.
                last_cmd.ElemCount += ch._CmdBuffer[0].ElemCount;
                idx_offset += ch._CmdBuffer[0].ElemCount;
                ch._CmdBuffer.erase(ch._CmdBuffer.Data); // FIXME-OPT: Improve for multiple merges.
            }
            if (ch._CmdBuffer.Size > 0)
                last_cmd = &ch._CmdBuffer.back();
            new_cmd_buffer_count += ch._CmdBuffer.Size;
            new_idx_buffer_count += ch._IdxBuffer.Size;
            for (int cmd_n = 0; cmd_n < ch._CmdBuffer.Size; cmd_n++)
            {
                ch._CmdBuffer.Data[cmd_n].IdxOffset = idx_offset;
                idx_offset += ch._CmdBuffer.Data[cmd_n].ElemCount;
            }
        }
        draw_list.CmdBuffer.resize(draw_list.CmdBuffer.Size + new_cmd_buffer_count);
        draw_list.IdxBuffer.resize(draw_list.IdxBuffer.Size + new_idx_buffer_count);

        // Write commands and indices in order (they are fairly small structures, we don't copy vertices only indices)
        ImDrawCmd* cmd_write = draw_list.CmdBuffer.Data + draw_list.CmdBuffer.Size - new_cmd_buffer_count;
        ImDrawIdx* idx_write = draw_list.IdxBuffer.Data + draw_list.IdxBuffer.Size - new_idx_buffer_count;
        for (int i = 1; i < _Count; i++)
        {
            ImDrawChannel* ch = &_Channels[i];
            if (int sz = ch._CmdBuffer.Size) { memcpy(cmd_write, ch._CmdBuffer.Data, sz * (ImDrawCmd).sizeof); cmd_write += sz; }
            if (int sz = ch._IdxBuffer.Size) { memcpy(idx_write, ch._IdxBuffer.Data, sz * (ImDrawIdx).sizeof); idx_write += sz; }
        }
        draw_list._IdxWritePtr = idx_write;
        draw_list.UpdateClipRect(); // We call this instead of AddDrawCmd(), so that empty channels won't produce an extra draw call.
        draw_list.UpdateTextureID();
        _Count = 1;
    }

    void              SetCurrentChannel(ImDrawList* draw_list, int idx)
    {
        IM_ASSERT(idx >= 0 && idx < _Count);
        if (_Current == idx)
            return;
        // Overwrite ImVector (12/16 bytes), four times. This is merely a silly optimization instead of doing .swap()
        memcpy(&_Channels.Data[_Current]._CmdBuffer, &draw_list.CmdBuffer, (draw_list.CmdBuffer).sizeof);
        memcpy(&_Channels.Data[_Current]._IdxBuffer, &draw_list.IdxBuffer, (draw_list.IdxBuffer).sizeof);
        _Current = idx;
        memcpy(&draw_list.CmdBuffer, &_Channels.Data[idx]._CmdBuffer, (draw_list.CmdBuffer).sizeof);
        memcpy(&draw_list.IdxBuffer, &_Channels.Data[idx]._IdxBuffer, (draw_list.IdxBuffer).sizeof);
        draw_list._IdxWritePtr = draw_list.IdxBuffer.Data + draw_list.IdxBuffer.Size;
    }
}

enum ImDrawCornerFlags : int
{
    None      = 0,
    TopLeft   = 1 << 0, // 0x1
    TopRight  = 1 << 1, // 0x2
    BotLeft   = 1 << 2, // 0x4
    BotRight  = 1 << 3, // 0x8
    Top       = TopLeft | TopRight,   // 0x3
    Bot       = BotLeft | BotRight,   // 0xC
    Left      = TopLeft | BotLeft,    // 0x5
    Right     = TopRight | BotRight,  // 0xA
    All       = 0xF     // In your function calls you may use ~0 (= all bits sets) instead of ImDrawCornerFlags_All, as a convenience
}

enum ImDrawListFlags : int
{
    None             = 0,
    AntiAliasedLines = 1 << 0,  // Lines are anti-aliased (*2 the number of triangles for 1.0f wide line, otherwise *3 the number of triangles)
    AntiAliasedFill  = 1 << 1,  // Filled shapes have anti-aliased edges (*2 the number of vertices)
    AllowVtxOffset   = 1 << 2   // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
}

// Draw command list
// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
// access the current window draw list and draw custom primitives.
// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
// All positions are generally in pixel coordinates (top-left at (0,0), bottom-right at io.DisplaySize), but you are totally free to apply whatever transformation matrix to want to the data (if you apply such transformation you'll want to apply it to ClipRect as well)
// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
struct ImDrawList
{
    nothrow:
    @nogc:

    // This is what you have to render
    ImVector!ImDrawCmd     CmdBuffer;          // Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
    ImVector!ImDrawIdx     IdxBuffer;          // Index buffer. Each command consume ImDrawCmd::ElemCount of those
    ImVector!ImDrawVert    VtxBuffer;          // Vertex buffer.
    ImDrawListFlags         Flags;              // Flags, you may poke into these to adjust anti-aliasing settings per-primitive.

    // [Internal, used while building lists]
    const (ImDrawListSharedData)* _Data;          // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
    string             _OwnerName;         // Pointer to owner window's name for debugging
    uint            _VtxCurrentOffset;  // [Internal] Always 0 unless 'Flags & ImDrawListFlags_AllowVtxOffset'.
    uint            _VtxCurrentIdx;     // [Internal] Generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
    ImDrawVert*             _VtxWritePtr;       // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    ImDrawIdx*              _IdxWritePtr;       // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    ImVector!ImVec4        _ClipRectStack;     // [Internal]
    ImVector!ImTextureID   _TextureIdStack;    // [Internal]
    ImVector!ImVec2        _Path;              // [Internal] current path building
    ImDrawListSplitter      _Splitter;          // [Internal] for channels api

    // If you want to create ImDrawList instances, pass them ImGui::GetDrawListSharedData() or create and use your own ImDrawListSharedData (so you can use ImDrawList without ImGui)
    this(const ImDrawListSharedData* shared_data) { _Data = shared_data; _OwnerName = NULL; Clear(); }
    void destroy() { ClearFreeMemory(); }

    void  PushClipRect(ImVec2 cr_min, ImVec2 cr_max, bool intersect_with_current_clip_rect = false)  // Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
    {
        ImVec4 cr = ImVec4(cr_min.x, cr_min.y, cr_max.x, cr_max.y);
        if (intersect_with_current_clip_rect && _ClipRectStack.Size)
        {
            ImVec4 current = _ClipRectStack.Data[_ClipRectStack.Size-1];
            if (cr.x < current.x) cr.x = current.x;
            if (cr.y < current.y) cr.y = current.y;
            if (cr.z > current.z) cr.z = current.z;
            if (cr.w > current.w) cr.w = current.w;
        }
        cr.z = ImMax(cr.x, cr.z);
        cr.w = ImMax(cr.y, cr.w);

        _ClipRectStack.push_back(cr);
        UpdateClipRect();
    }

    void  PushClipRectFullScreen()
    {
        PushClipRect(ImVec2(_Data.ClipRectFullscreen.x, _Data.ClipRectFullscreen.y), ImVec2(_Data.ClipRectFullscreen.z, _Data.ClipRectFullscreen.w));
    }

    void  PopClipRect()
    {
        IM_ASSERT(_ClipRectStack.Size > 0);
        _ClipRectStack.pop_back();
        UpdateClipRect();
    }

    void  PushTextureID(ImTextureID texture_id)
    {
        _TextureIdStack.push_back(texture_id);
        UpdateTextureID();
    }

    void  PopTextureID()
    {
        IM_ASSERT(_TextureIdStack.Size > 0);
        _TextureIdStack.pop_back();
        UpdateTextureID();
    }

    pragma(inline, true) ImVec2   GetClipRectMin() const { const ImVec4/*&*/ cr = _ClipRectStack.back(); return ImVec2(cr.x, cr.y); }
    pragma(inline, true) ImVec2   GetClipRectMax() const { const ImVec4/*&*/ cr = _ClipRectStack.back(); return ImVec2(cr.z, cr.w); }

    // Primitives
    // - For rectangular primitives, "p_min" and "p_max" represent the upper-left and lower-right corners.
    // - For circle primitives, use "num_segments == 0" to automatically calculate tessellation (preferred).
    //   In future versions we will use textures to provide cheaper and higher-quality circles.
    //   Use AddNgon() and AddNgonFilled() functions if you need to guaranteed a specific number of sides.
    void  AddLine(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, ImU32 col, float thickness = 1.0f)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;
        PathLineTo(p1 + ImVec2(0.5f, 0.5f));
        PathLineTo(p2 + ImVec2(0.5f, 0.5f));
        PathStroke(col, false, thickness);
    }
    
    void  AddRect(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col, float rounding = 0.0f, ImDrawCornerFlags rounding_corners_flags = ImDrawCornerFlags.All, float thickness = 1.0f)   // a: upper-left, b: lower-right (== upper-left + size), rounding_corners_flags: 4 bits corresponding to which corner to round
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;
        if (Flags & ImDrawListFlags.AntiAliasedLines)
            PathRect(p_min + ImVec2(0.50f,0.50f), p_max - ImVec2(0.50f,0.50f), rounding, rounding_corners_flags);
        else
            PathRect(p_min + ImVec2(0.50f,0.50f), p_max - ImVec2(0.49f,0.49f), rounding, rounding_corners_flags); // Better looking lower-right corner and rounded non-AA shapes.
        PathStroke(col, true, thickness);
    }
    
    void  AddRectFilled(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col, float rounding = 0.0f, ImDrawCornerFlags rounding_corners_flags = ImDrawCornerFlags.All)                     // a: upper-left, b: lower-right (== upper-left + size)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;
        if (rounding > 0.0f)
        {
            PathRect(p_min, p_max, rounding, rounding_corners_flags);
            PathFillConvex(col);
        }
        else
        {
            PrimReserve(6, 4);
            PrimRect(p_min, p_max, col);
        }
    }
    
    void  AddRectFilledMultiColor(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left)
    {
        if (((col_upr_left | col_upr_right | col_bot_right | col_bot_left) & IM_COL32_A_MASK) == 0)
            return;

        const ImVec2 uv = _Data.TexUvWhitePixel;
        PrimReserve(6, 4);
        PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx)); PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx+1)); PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx+2));
        PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx)); PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx+2)); PrimWriteIdx(cast(ImDrawIdx)(_VtxCurrentIdx+3));
        PrimWriteVtx(p_min, uv, col_upr_left);
        PrimWriteVtx(ImVec2(p_max.x, p_min.y), uv, col_upr_right);
        PrimWriteVtx(p_max, uv, col_bot_right);
        PrimWriteVtx(ImVec2(p_min.x, p_max.y), uv, col_bot_left);
    }
    
    void  AddQuad(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col, float thickness = 1.0f)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        PathLineTo(p1);
        PathLineTo(p2);
        PathLineTo(p3);
        PathLineTo(p4);
        PathStroke(col, true, thickness);
    }
    
    void  AddQuadFilled(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        PathLineTo(p1);
        PathLineTo(p2);
        PathLineTo(p3);
        PathLineTo(p4);
        PathFillConvex(col);
    }
    
    void  AddTriangle(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, ImU32 col, float thickness = 1.0f)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        PathLineTo(p1);
        PathLineTo(p2);
        PathLineTo(p3);
        PathStroke(col, true, thickness);
    }
    
    void  AddTriangleFilled(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, ImU32 col)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        PathLineTo(p1);
        PathLineTo(p2);
        PathLineTo(p3);
        PathFillConvex(col);
    }
    
    void  AddCircle(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments = 12, float thickness = 1.0f)
    {
        if ((col & IM_COL32_A_MASK) == 0 || radius <= 0.0f)
            return;

        // Obtain segment count
        if (num_segments <= 0)
        {
            // Automatic segment count
            const int radius_idx = cast(int)radius - 1;
            if (radius_idx < IM_ARRAYSIZE(_Data.CircleSegmentCounts))
                num_segments = _Data.CircleSegmentCounts[radius_idx]; // Use cached value
            else
                num_segments = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, _Data.CircleSegmentMaxError);
        }
        else
        {
            // Explicit segment count (still clamp to avoid drawing insanely tessellated shapes)
            num_segments = ImClamp(num_segments, 3, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX);
        }

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        const float a_max = (IM_PI * 2.0f) * (cast(float)num_segments - 1.0f) / cast(float)num_segments;
        if (num_segments == 12)
            PathArcToFast(center, radius - 0.5f, 0, 12);
        else
            PathArcTo(center, radius - 0.5f, 0.0f, a_max, num_segments - 1);
        PathStroke(col, true, thickness);
    }
    
    void  AddCircleFilled(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments = 12)
    {
        if ((col & IM_COL32_A_MASK) == 0 || radius <= 0.0f)
            return;

        // Obtain segment count
        if (num_segments <= 0)
        {
            // Automatic segment count
            const int radius_idx = cast(int)radius - 1;
            if (radius_idx < IM_ARRAYSIZE(_Data.CircleSegmentCounts))
                num_segments = _Data.CircleSegmentCounts[radius_idx]; // Use cached value
            else
                num_segments = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, _Data.CircleSegmentMaxError);
        }
        else
        {
            // Explicit segment count (still clamp to avoid drawing insanely tessellated shapes)
            num_segments = ImClamp(num_segments, 3, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX);
        }

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        const float a_max = (IM_PI * 2.0f) * (cast(float)num_segments - 1.0f) / cast(float)num_segments;
        if (num_segments == 12)
            PathArcToFast(center, radius, 0, 12);
        else
            PathArcTo(center, radius, 0.0f, a_max, num_segments - 1);
        PathFillConvex(col);
    }
    
    void  AddNgon(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments, float thickness = 1.0f)
    {
        if ((col & IM_COL32_A_MASK) == 0 || num_segments <= 2)
            return;

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        const float a_max = (IM_PI * 2.0f) * (cast(float)num_segments - 1.0f) / cast(float)num_segments;
        PathArcTo(center, radius - 0.5f, 0.0f, a_max, num_segments - 1);
        PathStroke(col, true, thickness);
    }
    
    void  AddNgonFilled(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments)
    {
        if ((col & IM_COL32_A_MASK) == 0 || num_segments <= 2)
            return;

        // Because we are filling a closed shape we remove 1 from the count of segments/points
        const float a_max = (IM_PI * 2.0f) * (cast(float)num_segments - 1.0f) / cast(float)num_segments;
        PathArcTo(center, radius, 0.0f, a_max, num_segments - 1);
        PathFillConvex(col);
    }
    
    void  AddText(const ImVec2/*&*/ pos, ImU32 col, string text)
    {
        AddText(NULL, 0.0f, pos, col, text);
    }
    
    void  AddText(const (ImFont)* font, float font_size, const ImVec2/*&*/ pos, ImU32 col, string text, float wrap_width = 0.0f, const ImVec4* cpu_fine_clip_rect = NULL)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        if (text.length == 0)
            return;

        // Pull default font/size from the shared ImDrawListSharedData instance
        if (font == NULL)
            font = _Data.Font;
        if (font_size == 0.0f)
            font_size = _Data.FontSize;

        IM_ASSERT(font.ContainerAtlas.TexID == _TextureIdStack.back());  // Use high-level ImGui.PushFont() or low-level ImDrawList.PushTextureId() to change font.

        ImVec4 clip_rect = _ClipRectStack.back();
        if (cpu_fine_clip_rect)
        {
            clip_rect.x = ImMax(clip_rect.x, cpu_fine_clip_rect.x);
            clip_rect.y = ImMax(clip_rect.y, cpu_fine_clip_rect.y);
            clip_rect.z = ImMin(clip_rect.z, cpu_fine_clip_rect.z);
            clip_rect.w = ImMin(clip_rect.w, cpu_fine_clip_rect.w);
        }
        font.RenderText(&this, font_size, pos, col, clip_rect, text, wrap_width, cpu_fine_clip_rect != NULL);
    }
    
    pragma(inline, true) void IM_NORMALIZE2F_OVER_ZERO(ref float VX, ref float VY) { float d2 = VX*VX + VY*VY; if (d2 > 0.0f) { float inv_len = 1.0f / ImSqrt(d2); VX *= inv_len; VY *= inv_len; } }
    pragma(inline, true) void IM_FIXNORMAL2F(ref float VX, ref float VY) { float d2 = VX*VX + VY*VY; if (d2 < 0.5f) d2 = 0.5f; float inv_lensq = 1.0f / d2; VX *= inv_lensq; VY *= inv_lensq; }

    void  AddPolyline(const ImVec2* points, int points_count, ImU32 col, bool closed, float thickness)
    {
        if (points_count < 2)
            return;

        const ImVec2 uv = _Data.TexUvWhitePixel;

        int count = points_count;
        if (!closed)
            count = points_count-1;

        const bool thick_line = thickness > 1.0f;
        if (Flags & ImDrawListFlags.AntiAliasedLines)
        {
            // Anti-aliased stroke
            const float AA_SIZE = 1.0f;
            const ImU32 col_trans = col & ~IM_COL32_A_MASK;

            const int idx_count = thick_line ? count*18 : count*12;
            const int vtx_count = thick_line ? points_count*4 : points_count*3;
            PrimReserve(idx_count, vtx_count);

            // Temporary buffer
            ImVec2* temp_normals = cast(ImVec2*)alloca(points_count * (thick_line ? 5 : 3) * (ImVec2).sizeof); //-V630
            ImVec2* temp_points = temp_normals + points_count;

            for (int i1 = 0; i1 < count; i1++)
            {
                const int i2 = (i1+1) == points_count ? 0 : i1+1;
                float dx = points[i2].x - points[i1].x;
                float dy = points[i2].y - points[i1].y;
                IM_NORMALIZE2F_OVER_ZERO(dx, dy);
                temp_normals[i1].x = dy;
                temp_normals[i1].y = -dx;
            }
            if (!closed)
                temp_normals[points_count-1] = temp_normals[points_count-2];

            if (!thick_line)
            {
                if (!closed)
                {
                    temp_points[0] = points[0] + temp_normals[0] * AA_SIZE;
                    temp_points[1] = points[0] - temp_normals[0] * AA_SIZE;
                    temp_points[(points_count-1)*2+0] = points[points_count-1] + temp_normals[points_count-1] * AA_SIZE;
                    temp_points[(points_count-1)*2+1] = points[points_count-1] - temp_normals[points_count-1] * AA_SIZE;
                }

                // FIXME-OPT: Merge the different loops, possibly remove the temporary buffer.
                uint idx1 = _VtxCurrentIdx;
                for (int i1 = 0; i1 < count; i1++)
                {
                    const int i2 = (i1+1) == points_count ? 0 : i1+1;
                    uint idx2 = (i1+1) == points_count ? _VtxCurrentIdx : idx1+3;

                    // Average normals
                    float dm_x = (temp_normals[i1].x + temp_normals[i2].x) * 0.5f;
                    float dm_y = (temp_normals[i1].y + temp_normals[i2].y) * 0.5f;
                    IM_FIXNORMAL2F(dm_x, dm_y);
                    dm_x *= AA_SIZE;
                    dm_y *= AA_SIZE;

                    // Add temporary vertexes
                    ImVec2* out_vtx = &temp_points[i2*2];
                    out_vtx[0].x = points[i2].x + dm_x;
                    out_vtx[0].y = points[i2].y + dm_y;
                    out_vtx[1].x = points[i2].x - dm_x;
                    out_vtx[1].y = points[i2].y - dm_y;


                    // Add indexes
                    _IdxWritePtr[0] = cast(ImDrawIdx)(idx2+0); _IdxWritePtr[1] = cast(ImDrawIdx)(idx1+0); _IdxWritePtr[2] = cast(ImDrawIdx)(idx1+2);
                    _IdxWritePtr[3] = cast(ImDrawIdx)(idx1+2); _IdxWritePtr[4] = cast(ImDrawIdx)(idx2+2); _IdxWritePtr[5] = cast(ImDrawIdx)(idx2+0);
                    _IdxWritePtr[6] = cast(ImDrawIdx)(idx2+1); _IdxWritePtr[7] = cast(ImDrawIdx)(idx1+1); _IdxWritePtr[8] = cast(ImDrawIdx)(idx1+0);
                    _IdxWritePtr[9] = cast(ImDrawIdx)(idx1+0); _IdxWritePtr[10]= cast(ImDrawIdx)(idx2+0); _IdxWritePtr[11]= cast(ImDrawIdx)(idx2+1);
                    _IdxWritePtr += 12;

                    idx1 = idx2;
                }

                // Add vertexes
                for (int i = 0; i < points_count; i++)
                {
                    _VtxWritePtr[0].pos = points[i];          _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col;
                    _VtxWritePtr[1].pos = temp_points[i*2+0]; _VtxWritePtr[1].uv = uv; _VtxWritePtr[1].col = col_trans;
                    _VtxWritePtr[2].pos = temp_points[i*2+1]; _VtxWritePtr[2].uv = uv; _VtxWritePtr[2].col = col_trans;
                    _VtxWritePtr += 3;
                }
            }
            else
            {
                const float half_inner_thickness = (thickness - AA_SIZE) * 0.5f;
                if (!closed)
                {
                    temp_points[0] = points[0] + temp_normals[0] * (half_inner_thickness + AA_SIZE);
                    temp_points[1] = points[0] + temp_normals[0] * (half_inner_thickness);
                    temp_points[2] = points[0] - temp_normals[0] * (half_inner_thickness);
                    temp_points[3] = points[0] - temp_normals[0] * (half_inner_thickness + AA_SIZE);
                    temp_points[(points_count-1)*4+0] = points[points_count-1] + temp_normals[points_count-1] * (half_inner_thickness + AA_SIZE);
                    temp_points[(points_count-1)*4+1] = points[points_count-1] + temp_normals[points_count-1] * (half_inner_thickness);
                    temp_points[(points_count-1)*4+2] = points[points_count-1] - temp_normals[points_count-1] * (half_inner_thickness);
                    temp_points[(points_count-1)*4+3] = points[points_count-1] - temp_normals[points_count-1] * (half_inner_thickness + AA_SIZE);
                }

                // FIXME-OPT: Merge the different loops, possibly remove the temporary buffer.
                uint idx1 = _VtxCurrentIdx;
                for (int i1 = 0; i1 < count; i1++)
                {
                    const int i2 = (i1+1) == points_count ? 0 : i1+1;
                    uint idx2 = (i1+1) == points_count ? _VtxCurrentIdx : idx1+4;

                    // Average normals
                    float dm_x = (temp_normals[i1].x + temp_normals[i2].x) * 0.5f;
                    float dm_y = (temp_normals[i1].y + temp_normals[i2].y) * 0.5f;
                    IM_FIXNORMAL2F(dm_x, dm_y);
                    float dm_out_x = dm_x * (half_inner_thickness + AA_SIZE);
                    float dm_out_y = dm_y * (half_inner_thickness + AA_SIZE);
                    float dm_in_x = dm_x * half_inner_thickness;
                    float dm_in_y = dm_y * half_inner_thickness;

                    // Add temporary vertexes
                    ImVec2* out_vtx = &temp_points[i2*4];
                    out_vtx[0].x = points[i2].x + dm_out_x;
                    out_vtx[0].y = points[i2].y + dm_out_y;
                    out_vtx[1].x = points[i2].x + dm_in_x;
                    out_vtx[1].y = points[i2].y + dm_in_y;
                    out_vtx[2].x = points[i2].x - dm_in_x;
                    out_vtx[2].y = points[i2].y - dm_in_y;
                    out_vtx[3].x = points[i2].x - dm_out_x;
                    out_vtx[3].y = points[i2].y - dm_out_y;

                    // Add indexes
                    _IdxWritePtr[0]  = cast(ImDrawIdx)(idx2+1); _IdxWritePtr[1]  = cast(ImDrawIdx)(idx1+1); _IdxWritePtr[2]  = cast(ImDrawIdx)(idx1+2);
                    _IdxWritePtr[3]  = cast(ImDrawIdx)(idx1+2); _IdxWritePtr[4]  = cast(ImDrawIdx)(idx2+2); _IdxWritePtr[5]  = cast(ImDrawIdx)(idx2+1);
                    _IdxWritePtr[6]  = cast(ImDrawIdx)(idx2+1); _IdxWritePtr[7]  = cast(ImDrawIdx)(idx1+1); _IdxWritePtr[8]  = cast(ImDrawIdx)(idx1+0);
                    _IdxWritePtr[9]  = cast(ImDrawIdx)(idx1+0); _IdxWritePtr[10] = cast(ImDrawIdx)(idx2+0); _IdxWritePtr[11] = cast(ImDrawIdx)(idx2+1);
                    _IdxWritePtr[12] = cast(ImDrawIdx)(idx2+2); _IdxWritePtr[13] = cast(ImDrawIdx)(idx1+2); _IdxWritePtr[14] = cast(ImDrawIdx)(idx1+3);
                    _IdxWritePtr[15] = cast(ImDrawIdx)(idx1+3); _IdxWritePtr[16] = cast(ImDrawIdx)(idx2+3); _IdxWritePtr[17] = cast(ImDrawIdx)(idx2+2);
                    _IdxWritePtr += 18;

                    idx1 = idx2;
                }

                // Add vertexes
                for (int i = 0; i < points_count; i++)
                {
                    _VtxWritePtr[0].pos = temp_points[i*4+0]; _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col_trans;
                    _VtxWritePtr[1].pos = temp_points[i*4+1]; _VtxWritePtr[1].uv = uv; _VtxWritePtr[1].col = col;
                    _VtxWritePtr[2].pos = temp_points[i*4+2]; _VtxWritePtr[2].uv = uv; _VtxWritePtr[2].col = col;
                    _VtxWritePtr[3].pos = temp_points[i*4+3]; _VtxWritePtr[3].uv = uv; _VtxWritePtr[3].col = col_trans;
                    _VtxWritePtr += 4;
                }
            }
            _VtxCurrentIdx += cast(ImDrawIdx)vtx_count;
        }
        else
        {
            // Non Anti-aliased Stroke
            const int idx_count = count*6;
            const int vtx_count = count*4;      // FIXME-OPT: Not sharing edges
            PrimReserve(idx_count, vtx_count);

            for (int i1 = 0; i1 < count; i1++)
            {
                const int i2 = (i1+1) == points_count ? 0 : i1+1;
                const ImVec2/*&*/ p1 = points[i1];
                const ImVec2/*&*/ p2 = points[i2];
                    
                float dx = p2.x - p1.x;
                float dy = p2.y - p1.y;
                IM_NORMALIZE2F_OVER_ZERO(dx, dy);
                dx *= (thickness * 0.5f);
                dy *= (thickness * 0.5f);

                _VtxWritePtr[0].pos.x = p1.x + dy; _VtxWritePtr[0].pos.y = p1.y - dx; _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col;
                _VtxWritePtr[1].pos.x = p2.x + dy; _VtxWritePtr[1].pos.y = p2.y - dx; _VtxWritePtr[1].uv = uv; _VtxWritePtr[1].col = col;
                _VtxWritePtr[2].pos.x = p2.x - dy; _VtxWritePtr[2].pos.y = p2.y + dx; _VtxWritePtr[2].uv = uv; _VtxWritePtr[2].col = col;
                _VtxWritePtr[3].pos.x = p1.x - dy; _VtxWritePtr[3].pos.y = p1.y + dx; _VtxWritePtr[3].uv = uv; _VtxWritePtr[3].col = col;
                _VtxWritePtr += 4;

                _IdxWritePtr[0] = cast(ImDrawIdx)(_VtxCurrentIdx); _IdxWritePtr[1] = cast(ImDrawIdx)(_VtxCurrentIdx+1); _IdxWritePtr[2] = cast(ImDrawIdx)(_VtxCurrentIdx+2);
                _IdxWritePtr[3] = cast(ImDrawIdx)(_VtxCurrentIdx); _IdxWritePtr[4] = cast(ImDrawIdx)(_VtxCurrentIdx+2); _IdxWritePtr[5] = cast(ImDrawIdx)(_VtxCurrentIdx+3);
                _IdxWritePtr += 6;
                _VtxCurrentIdx += 4;
            }
        }
    }
    
    void  AddConvexPolyFilled(const ImVec2* points, int points_count, ImU32 col) // Note: Anti-aliased filling requires points to be in clockwise order.
    {
        if (points_count < 3)
            return;

        const ImVec2 uv = _Data.TexUvWhitePixel;

        if (Flags & ImDrawListFlags.AntiAliasedFill)
        {
            // Anti-aliased Fill
            const float AA_SIZE = 1.0f;
            const ImU32 col_trans = col & ~IM_COL32_A_MASK;
            const int idx_count = (points_count-2)*3 + points_count*6;
            const int vtx_count = (points_count*2);
            PrimReserve(idx_count, vtx_count);

            // Add indexes for fill
            uint vtx_inner_idx = _VtxCurrentIdx;
            uint vtx_outer_idx = _VtxCurrentIdx+1;
            for (int i = 2; i < points_count; i++)
            {
                _IdxWritePtr[0] = cast(ImDrawIdx)(vtx_inner_idx); _IdxWritePtr[1] = cast(ImDrawIdx)(vtx_inner_idx+((i-1)<<1)); _IdxWritePtr[2] = cast(ImDrawIdx)(vtx_inner_idx+(i<<1));
                _IdxWritePtr += 3;
            }

            // Compute normals
            ImVec2* temp_normals = cast(ImVec2*)alloca(points_count * (ImVec2).sizeof); //-V630
            for (int i0 = points_count-1, i1 = 0; i1 < points_count; i0 = i1++)
            {
                const ImVec2/*&*/ p0 = points[i0];
                const ImVec2/*&*/ p1 = points[i1];
                float dx = p1.x - p0.x;
                float dy = p1.y - p0.y;
                IM_NORMALIZE2F_OVER_ZERO(dx, dy);
                temp_normals[i0].x = dy;
                temp_normals[i0].y = -dx;
            }

            for (int i0 = points_count-1, i1 = 0; i1 < points_count; i0 = i1++)
            {
                // Average normals
                const ImVec2/*&*/ n0 = temp_normals[i0];
                const ImVec2/*&*/ n1 = temp_normals[i1];
                float dm_x = (n0.x + n1.x) * 0.5f;
                float dm_y = (n0.y + n1.y) * 0.5f;
                IM_FIXNORMAL2F(dm_x, dm_y);
                dm_x *= AA_SIZE * 0.5f;
                dm_y *= AA_SIZE * 0.5f;

                // Add vertices
                _VtxWritePtr[0].pos.x = (points[i1].x - dm_x); _VtxWritePtr[0].pos.y = (points[i1].y - dm_y); _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col;        // Inner
                _VtxWritePtr[1].pos.x = (points[i1].x + dm_x); _VtxWritePtr[1].pos.y = (points[i1].y + dm_y); _VtxWritePtr[1].uv = uv; _VtxWritePtr[1].col = col_trans;  // Outer
                _VtxWritePtr += 2;

                // Add indexes for fringes
                _IdxWritePtr[0] = cast(ImDrawIdx)(vtx_inner_idx+(i1<<1)); _IdxWritePtr[1] = cast(ImDrawIdx)(vtx_inner_idx+(i0<<1)); _IdxWritePtr[2] = cast(ImDrawIdx)(vtx_outer_idx+(i0<<1));
                _IdxWritePtr[3] = cast(ImDrawIdx)(vtx_outer_idx+(i0<<1)); _IdxWritePtr[4] = cast(ImDrawIdx)(vtx_outer_idx+(i1<<1)); _IdxWritePtr[5] = cast(ImDrawIdx)(vtx_inner_idx+(i1<<1));
                _IdxWritePtr += 6;
            }
            _VtxCurrentIdx += cast(ImDrawIdx)vtx_count;
        }
        else
        {
            // Non Anti-aliased Fill
            const int idx_count = (points_count-2)*3;
            const int vtx_count = points_count;
            PrimReserve(idx_count, vtx_count);
            for (int i = 0; i < vtx_count; i++)
            {
                _VtxWritePtr[0].pos = points[i]; _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col;
                _VtxWritePtr++;
            }
            for (int i = 2; i < points_count; i++)
            {
                _IdxWritePtr[0] = cast(ImDrawIdx)(_VtxCurrentIdx); _IdxWritePtr[1] = cast(ImDrawIdx)(_VtxCurrentIdx+i-1); _IdxWritePtr[2] = cast(ImDrawIdx)(_VtxCurrentIdx+i);
                _IdxWritePtr += 3;
            }
            _VtxCurrentIdx += cast(ImDrawIdx)vtx_count;
        }
    }
    
    void  AddBezierCurve(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col, float thickness, int num_segments = 0)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        PathLineTo(p1);
        PathBezierCurveTo(p2, p3, p4, num_segments);
        PathStroke(col, false, thickness);
    }

    // Image primitives
    // - Read FAQ to understand what ImTextureID is.
    // - "p_min" and "p_max" represent the upper-left and lower-right corners of the rectangle.
    // - "uv_min" and "uv_max" represent the normalized texture coordinates to use for those corners. Using (0,0)->(1,1) texture coordinates will generally display the entire texture.
    void  AddImage(ImTextureID user_texture_id, const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, const ImVec2/*&*/ uv_min = ImVec2(0, 0), const ImVec2/*&*/ uv_max = ImVec2(1, 1), ImU32 col = IM_COL32_WHITE)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        const bool push_texture_id = _TextureIdStack.empty() || user_texture_id != _TextureIdStack.back();
        if (push_texture_id)
            PushTextureID(user_texture_id);

        PrimReserve(6, 4);
        PrimRectUV(p_min, p_max, uv_min, uv_max, col);

        if (push_texture_id)
            PopTextureID();
    }
    
    void  AddImageQuad(ImTextureID user_texture_id, const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, const ImVec2/*&*/ uv1 = ImVec2(0, 0), const ImVec2/*&*/ uv2 = ImVec2(1, 0), const ImVec2/*&*/ uv3 = ImVec2(1, 1), const ImVec2/*&*/ uv4 = ImVec2(0, 1), ImU32 col = IM_COL32_WHITE)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        const bool push_texture_id = _TextureIdStack.empty() || user_texture_id != _TextureIdStack.back();
        if (push_texture_id)
            PushTextureID(user_texture_id);

        PrimReserve(6, 4);
        PrimQuadUV(p1, p2, p3, p4, uv1, uv2, uv3, uv4, col);

        if (push_texture_id)
            PopTextureID();
    }
    
    void  AddImageRounded(ImTextureID user_texture_id, const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, const ImVec2/*&*/ uv_min, const ImVec2/*&*/ uv_max, ImU32 col, float rounding, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags.All)
    {
        if ((col & IM_COL32_A_MASK) == 0)
            return;

        if (rounding <= 0.0f || (rounding_corners & ImDrawCornerFlags.All) == 0)
        {
            AddImage(user_texture_id, p_min, p_max, uv_min, uv_max, col);
            return;
        }

        const bool push_texture_id = _TextureIdStack.empty() || user_texture_id != _TextureIdStack.back();
        if (push_texture_id)
            PushTextureID(user_texture_id);

        int vert_start_idx = VtxBuffer.Size;
        PathRect(p_min, p_max, rounding, rounding_corners);
        PathFillConvex(col);
        int vert_end_idx = VtxBuffer.Size;
        ShadeVertsLinearUV(&this, vert_start_idx, vert_end_idx, p_min, p_max, uv_min, uv_max, true);

        if (push_texture_id)
            PopTextureID();
    }

    // Stateful path API, add points then finish with PathFillConvex() or PathStroke()
    pragma(inline, true)    void  PathClear()                                                 { _Path.Size = 0; }
    pragma(inline, true)    void  PathLineTo(const ImVec2/*&*/ pos)                               { _Path.push_back(pos); }
    pragma(inline, true)    void  PathLineToMergeDuplicate(const ImVec2/*&*/ pos)                 { if (_Path.Size == 0 || memcmp(&_Path.Data[_Path.Size-1], &pos, 8) != 0) _Path.push_back(pos); }
    pragma(inline, true)    void  PathFillConvex(ImU32 col)                                   { AddConvexPolyFilled(_Path.Data, _Path.Size, col); _Path.Size = 0; }  // Note: Anti-aliased filling requires points to be in clockwise order.
    pragma(inline, true)    void  PathStroke(ImU32 col, bool closed, float thickness = 1.0f)  { AddPolyline(_Path.Data, _Path.Size, col, closed, thickness); _Path.Size = 0; }
    
    void  PathArcTo(const ImVec2/*&*/ center, float radius, float a_min, float a_max, int num_segments = 10)
    {
        if (radius == 0.0f)
        {
            _Path.push_back(center);
            return;
        }
    
        // Note that we are adding a point at both a_min and a_max.
        // If you are trying to draw a full closed circle you don't want the overlapping points!
        _Path.reserve(_Path.Size + (num_segments + 1));
        for (int i = 0; i <= num_segments; i++)
        {
            const float a = a_min + (cast(float)i / cast(float)num_segments) * (a_max - a_min);
            _Path.push_back(ImVec2(center.x + ImCos(a) * radius, center.y + ImSin(a) * radius));
        }
    }
    
    void  PathArcToFast(const ImVec2/*&*/ center, float radius, int a_min_of_12, int a_max_of_12)                                            // Use precomputed angles for a 12 steps circle
    {
        if (radius == 0.0f || a_min_of_12 > a_max_of_12)
        {
            _Path.push_back(center);
            return;
        }
        
        // For legacy reason the PathArcToFast() always takes angles where 2*PI is represented by 12,
        // but it is possible to set IM_DRAWLIST_ARCFAST_TESSELATION_MULTIPLIER to a higher value. This should compile to a no-op otherwise.
        static if (IM_DRAWLIST_ARCFAST_TESSELLATION_MULTIPLIER != 1) {
            a_min_of_12 *= IM_DRAWLIST_ARCFAST_TESSELLATION_MULTIPLIER;
            a_max_of_12 *= IM_DRAWLIST_ARCFAST_TESSELLATION_MULTIPLIER;
        }

        _Path.reserve(_Path.Size + (a_max_of_12 - a_min_of_12 + 1));
        for (int a = a_min_of_12; a <= a_max_of_12; a++)
        {
            const ImVec2/*&*/ c = _Data.ArcFastVtx[a % IM_ARRAYSIZE(_Data.ArcFastVtx)];
            _Path.push_back(ImVec2(center.x + c.x * radius, center.y + c.y * radius));
        }
    }
    
    void  PathBezierCurveTo(const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, int num_segments = 0)
    {
        ImVec2 p1 = _Path.back();
        if (num_segments == 0)
        {
            PathBezierToCasteljau(&_Path, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, _Data.CurveTessellationTol, 0); // Auto-tessellated
        }
        else
        {
            float t_step = 1.0f / cast(float)num_segments;
            for (int i_step = 1; i_step <= num_segments; i_step++)
                _Path.push_back(ImBezierCalc(p1, p2, p3, p4, t_step * i_step));
        }
    }
    
    void  PathRect(const ImVec2/*&*/ a, const ImVec2/*&*/ b, float rounding = 0.0f, ImDrawCornerFlags rounding_corners = ImDrawCornerFlags.All)
    {
        rounding = ImMin(rounding, ImFabs(b.x - a.x) * ( ((rounding_corners & ImDrawCornerFlags.Top)  == ImDrawCornerFlags.Top)  || ((rounding_corners & ImDrawCornerFlags.Bot)   == ImDrawCornerFlags.Bot)   ? 0.5f : 1.0f ) - 1.0f);
        rounding = ImMin(rounding, ImFabs(b.y - a.y) * ( ((rounding_corners & ImDrawCornerFlags.Left) == ImDrawCornerFlags.Left) || ((rounding_corners & ImDrawCornerFlags.Right) == ImDrawCornerFlags.Right) ? 0.5f : 1.0f ) - 1.0f);

        if (rounding <= 0.0f || rounding_corners == 0) {
            PathLineTo(a);
            PathLineTo(ImVec2(b.x, a.y));
            PathLineTo(b);
            PathLineTo(ImVec2(a.x, b.y));
        }
        else
        {
            const float rounding_tl = (rounding_corners & ImDrawCornerFlags.TopLeft) ? rounding : 0.0f;
            const float rounding_tr = (rounding_corners & ImDrawCornerFlags.TopRight) ? rounding : 0.0f;
            const float rounding_br = (rounding_corners & ImDrawCornerFlags.BotRight) ? rounding : 0.0f;
            const float rounding_bl = (rounding_corners & ImDrawCornerFlags.BotLeft) ? rounding : 0.0f;
            PathArcToFast(ImVec2(a.x + rounding_tl, a.y + rounding_tl), rounding_tl, 6, 9);
            PathArcToFast(ImVec2(b.x - rounding_tr, a.y + rounding_tr), rounding_tr, 9, 12);
            PathArcToFast(ImVec2(b.x - rounding_br, b.y - rounding_br), rounding_br, 0, 3);
            PathArcToFast(ImVec2(a.x + rounding_bl, b.y - rounding_bl), rounding_bl, 3, 6);
        }
    }

    // Advanced
    void  AddCallback(ImDrawCallback callback, void* callback_data)  // Your rendering function must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles.
    {
        ImDrawCmd* current_cmd = CmdBuffer.Size ? &CmdBuffer.back() : NULL;
        if (!current_cmd || current_cmd.ElemCount != 0 || current_cmd.UserCallback != NULL)
        {
            AddDrawCmd();
            current_cmd = &CmdBuffer.back();
        }
        current_cmd.UserCallback = callback;
        current_cmd.UserCallbackData = callback_data;

        AddDrawCmd(); // Force a new command after us (see comment below)
    }
    
    private pragma(inline, true) ImVec4 GetCurrentClipRect() { return (_ClipRectStack.Size ? _ClipRectStack.Data[_ClipRectStack.Size-1]  : _Data.ClipRectFullscreen); }
    private pragma(inline, true) ImTextureID GetCurrentTextureId() { return (_TextureIdStack.Size ? _TextureIdStack.Data[_TextureIdStack.Size-1] : cast(ImTextureID)NULL); }

    void  AddDrawCmd()                                               // This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
    {
        ImDrawCmd draw_cmd;
        draw_cmd.ClipRect = GetCurrentClipRect();
        draw_cmd.TextureId = GetCurrentTextureId();
        draw_cmd.VtxOffset = _VtxCurrentOffset;
        draw_cmd.IdxOffset = IdxBuffer.Size;

        IM_ASSERT(draw_cmd.ClipRect.x <= draw_cmd.ClipRect.z && draw_cmd.ClipRect.y <= draw_cmd.ClipRect.w);
        CmdBuffer.push_back(draw_cmd);
    }
    
    ImDrawList* CloneOutput() const                                  // Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.
    {
        ImDrawList* dst = IM_NEW!ImDrawList(_Data);
        dst.CmdBuffer = cast(ImVector!(ImDrawCmd))CmdBuffer;
        dst.IdxBuffer = cast(ImVector!(ushort))IdxBuffer;
        dst.VtxBuffer = cast(ImVector!(ImDrawVert))VtxBuffer;
        dst.Flags = Flags;
        return dst;
    }

    // Advanced: Channels
    // - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
    // - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
    // - FIXME-OBSOLETE: This API shouldn't have been in ImDrawList in the first place!
    //   Prefer using your own persistent copy of ImDrawListSplitter as you can stack them.
    //   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
    pragma(inline, true) void     ChannelsSplit(int count)    { _Splitter.Split(&this, count); }
    pragma(inline, true) void     ChannelsMerge()             { _Splitter.Merge(&this); }
    pragma(inline, true) void     ChannelsSetCurrent(int n)   { _Splitter.SetCurrentChannel(&this, n); }

    // Internal helpers
    // NB: all primitives needs to be reserved via PrimReserve() beforehand!
    void  Clear()
    {
        CmdBuffer.resize(0);
        IdxBuffer.resize(0);
        VtxBuffer.resize(0);
        Flags = _Data ? _Data.InitialFlags : ImDrawListFlags.None;
        _VtxCurrentOffset = 0;
        _VtxCurrentIdx = 0;
        _VtxWritePtr = NULL;
        _IdxWritePtr = NULL;
        _ClipRectStack.resize(0);
        _TextureIdStack.resize(0);
        _Path.resize(0);
        _Splitter.Clear();
    }
    
    void  ClearFreeMemory()
    {
        CmdBuffer.clear();
        IdxBuffer.clear();
        VtxBuffer.clear();
        _VtxCurrentIdx = 0;
        _VtxWritePtr = NULL;
        _IdxWritePtr = NULL;
        _ClipRectStack.clear();
        _TextureIdStack.clear();
        _Path.clear();
        _Splitter.ClearFreeMemory();
    }
    
    void  PrimReserve(int idx_count, int vtx_count)
    {
        // Large mesh support (when enabled)
        IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0);
        if ((ImDrawIdx).sizeof == 2 && (_VtxCurrentIdx + vtx_count >= (1 << 16)) && (Flags & ImDrawListFlags.AllowVtxOffset))
        {
            _VtxCurrentOffset = VtxBuffer.Size;
            _VtxCurrentIdx = 0;
            AddDrawCmd();
        }

        ImDrawCmd* draw_cmd = &CmdBuffer.Data[CmdBuffer.Size - 1];
        draw_cmd.ElemCount += idx_count;

        int vtx_buffer_old_size = VtxBuffer.Size;
        VtxBuffer.resize(vtx_buffer_old_size + vtx_count);
        _VtxWritePtr = VtxBuffer.Data + vtx_buffer_old_size;

        int idx_buffer_old_size = IdxBuffer.Size;
        IdxBuffer.resize(idx_buffer_old_size + idx_count);
        _IdxWritePtr = IdxBuffer.Data + idx_buffer_old_size;
    }
    
    void  PrimUnreserve(int idx_count, int vtx_count)
    {
        IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0);

        ImDrawCmd* draw_cmd = &CmdBuffer.Data[CmdBuffer.Size - 1];
        draw_cmd.ElemCount -= idx_count;
        VtxBuffer.shrink(VtxBuffer.Size - vtx_count);
        IdxBuffer.shrink(IdxBuffer.Size - idx_count);
    }
    
    void  PrimRect(const ImVec2/*&*/ a, const ImVec2/*&*/ c, ImU32 col)      // Axis aligned rectangle (composed of two triangles)
    {
        ImVec2 b = ImVec2(c.x, a.y), d = ImVec2(a.x, c.y), uv = _Data.TexUvWhitePixel;
        ImDrawIdx idx = cast(ImDrawIdx)_VtxCurrentIdx;
        _IdxWritePtr[0] = idx; _IdxWritePtr[1] = cast(ImDrawIdx)(idx+1); _IdxWritePtr[2] = cast(ImDrawIdx)(idx+2);
        _IdxWritePtr[3] = idx; _IdxWritePtr[4] = cast(ImDrawIdx)(idx+2); _IdxWritePtr[5] = cast(ImDrawIdx)(idx+3);
        _VtxWritePtr[0].pos = a; _VtxWritePtr[0].uv = uv; _VtxWritePtr[0].col = col;
        _VtxWritePtr[1].pos = b; _VtxWritePtr[1].uv = uv; _VtxWritePtr[1].col = col;
        _VtxWritePtr[2].pos = c; _VtxWritePtr[2].uv = uv; _VtxWritePtr[2].col = col;
        _VtxWritePtr[3].pos = d; _VtxWritePtr[3].uv = uv; _VtxWritePtr[3].col = col;
        _VtxWritePtr += 4;
        _VtxCurrentIdx += 4;
        _IdxWritePtr += 6;
    }
    
    void  PrimRectUV(const ImVec2/*&*/ a, const ImVec2/**/ c, const ImVec2/*&*/ uv_a, const ImVec2/*&*/ uv_c, ImU32 col)
    {
        ImVec2 b = ImVec2(c.x, a.y), d = ImVec2(a.x, c.y), uv_b = ImVec2(uv_c.x, uv_a.y), uv_d = ImVec2(uv_a.x, uv_c.y);
        ImDrawIdx idx = cast(ImDrawIdx)_VtxCurrentIdx;
        _IdxWritePtr[0] = idx; _IdxWritePtr[1] = cast(ImDrawIdx)(idx+1); _IdxWritePtr[2] = cast(ImDrawIdx)(idx+2);
        _IdxWritePtr[3] = idx; _IdxWritePtr[4] = cast(ImDrawIdx)(idx+2); _IdxWritePtr[5] = cast(ImDrawIdx)(idx+3);
        _VtxWritePtr[0].pos = a; _VtxWritePtr[0].uv = uv_a; _VtxWritePtr[0].col = col;
        _VtxWritePtr[1].pos = b; _VtxWritePtr[1].uv = uv_b; _VtxWritePtr[1].col = col;
        _VtxWritePtr[2].pos = c; _VtxWritePtr[2].uv = uv_c; _VtxWritePtr[2].col = col;
        _VtxWritePtr[3].pos = d; _VtxWritePtr[3].uv = uv_d; _VtxWritePtr[3].col = col;
        _VtxWritePtr += 4;
        _VtxCurrentIdx += 4;
        _IdxWritePtr += 6;
    }
    
    void  PrimQuadUV(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c, const ImVec2/*&*/ d, const ImVec2/*&*/ uv_a, const ImVec2/*&*/ uv_b, const ImVec2/*&*/ uv_c, const ImVec2/*&*/ uv_d, ImU32 col)
    {
        ImDrawIdx idx = cast(ImDrawIdx)_VtxCurrentIdx;
        _IdxWritePtr[0] = idx; _IdxWritePtr[1] = cast(ImDrawIdx)(idx+1); _IdxWritePtr[2] = cast(ImDrawIdx)(idx+2);
        _IdxWritePtr[3] = idx; _IdxWritePtr[4] = cast(ImDrawIdx)(idx+2); _IdxWritePtr[5] = cast(ImDrawIdx)(idx+3);
        _VtxWritePtr[0].pos = a; _VtxWritePtr[0].uv = uv_a; _VtxWritePtr[0].col = col;
        _VtxWritePtr[1].pos = b; _VtxWritePtr[1].uv = uv_b; _VtxWritePtr[1].col = col;
        _VtxWritePtr[2].pos = c; _VtxWritePtr[2].uv = uv_c; _VtxWritePtr[2].col = col;
        _VtxWritePtr[3].pos = d; _VtxWritePtr[3].uv = uv_d; _VtxWritePtr[3].col = col;
        _VtxWritePtr += 4;
        _VtxCurrentIdx += 4;
        _IdxWritePtr += 6;
    }
    
    pragma(inline, true)    void  PrimWriteVtx(const ImVec2/*&*/ pos, const ImVec2/*&*/ uv, ImU32 col){ _VtxWritePtr.pos = pos; _VtxWritePtr.uv = uv; _VtxWritePtr.col = col; _VtxWritePtr++; _VtxCurrentIdx++; }
    pragma(inline, true)    void  PrimWriteIdx(ImDrawIdx idx)                                 { *_IdxWritePtr = idx; _IdxWritePtr++; }
    pragma(inline, true)    void  PrimVtx(const ImVec2/*&*/ pos, const ImVec2/*&*/ uv, ImU32 col)     { PrimWriteIdx(cast(ImDrawIdx)_VtxCurrentIdx); PrimWriteVtx(pos, uv, col); }
    
    void  UpdateClipRect()
    {
        // If current command is used with different settings we need to add a new command
        const ImVec4 curr_clip_rect = GetCurrentClipRect();
        ImDrawCmd* curr_cmd = CmdBuffer.Size > 0 ? &CmdBuffer[CmdBuffer.Size-1] : NULL;
        if (!curr_cmd || (curr_cmd.ElemCount != 0 && memcmp(&curr_cmd.ClipRect, &curr_clip_rect, (ImVec4).sizeof) != 0) || curr_cmd.UserCallback != NULL)
        {
            AddDrawCmd();
            return;
        }

        // Try to merge with previous command if it matches, else use current command
        ImDrawCmd* prev_cmd = CmdBuffer.Size > 1 ? curr_cmd - 1 : NULL;
        if (curr_cmd.ElemCount == 0 && prev_cmd && memcmp(&prev_cmd.ClipRect, &curr_clip_rect, (ImVec4).sizeof) == 0 && prev_cmd.TextureId == GetCurrentTextureId() && prev_cmd.UserCallback == NULL)
            CmdBuffer.pop_back();
        else
            curr_cmd.ClipRect = curr_clip_rect;
    }
    
    void  UpdateTextureID()
    {
        // If current command is used with different settings we need to add a new command
        const ImTextureID curr_texture_id = GetCurrentTextureId();
        ImDrawCmd* curr_cmd = CmdBuffer.Size ? &CmdBuffer.back() : NULL;
        if (!curr_cmd || (curr_cmd.ElemCount != 0 && curr_cmd.TextureId != curr_texture_id) || curr_cmd.UserCallback != NULL)
        {
            AddDrawCmd();
            return;
        }

        // Try to merge with previous command if it matches, else use current command
        ImDrawCmd* prev_cmd = CmdBuffer.Size > 1 ? curr_cmd - 1 : NULL;
        ImVec4 current_rect = GetCurrentClipRect();
        if (curr_cmd.ElemCount == 0 && prev_cmd && prev_cmd.TextureId == curr_texture_id && memcmp(&prev_cmd.ClipRect, &current_rect, ImVec4.sizeof) == 0 && prev_cmd.UserCallback == NULL)
            CmdBuffer.pop_back();
        else
            curr_cmd.TextureId = curr_texture_id;
    }
}

// All draw data to render a Dear ImGui frame
// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
struct ImDrawData
{
    nothrow:
    @nogc:

    bool            Valid;                  // Only valid after Render() is called and before the next NewFrame() is called.
    ImDrawList**    CmdLists;               // Array of ImDrawList* to render. The ImDrawList are owned by ImGuiContext and only pointed to from here.
    int             CmdListsCount;          // Number of ImDrawList* to render
    int             TotalIdxCount;          // For convenience, sum of all ImDrawList's IdxBuffer.Size
    int             TotalVtxCount;          // For convenience, sum of all ImDrawList's VtxBuffer.Size
    ImVec2          DisplayPos;             // Upper-left position of the viewport to render (== upper-left of the orthogonal projection matrix to use)
    ImVec2          DisplaySize;            // Size of the viewport to render (== io.DisplaySize for the main viewport) (DisplayPos + DisplaySize == lower-right of the orthogonal projection matrix to use)
    ImVec2          FramebufferScale;       // Amount of pixels for each unit of DisplaySize. Based on io.DisplayFramebufferScale. Generally (1,1) on normal display, (2,2) on OSX with Retina display.

    // Functions
    // this()    { Valid = false; Clear(); }
    void destroy()   { Clear(); }
    void Clear()    { Valid = false; CmdLists = NULL; CmdListsCount = TotalVtxCount = TotalIdxCount = 0; DisplayPos = DisplaySize = FramebufferScale = ImVec2(0.0f, 0.0f); } // The ImDrawList are owned by ImGuiContext!
    
    void  DeIndexAllBuffers()                    // Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
    {
        ImVector!ImDrawVert new_vtx_buffer;
        scope(exit) new_vtx_buffer.destroy();
        TotalVtxCount = TotalIdxCount = 0;
        for (int i = 0; i < CmdListsCount; i++)
        {
            ImDrawList* cmd_list = CmdLists[i];
            if (cmd_list.IdxBuffer.empty())
                continue;
            new_vtx_buffer.resize(cmd_list.IdxBuffer.Size);
            for (int j = 0; j < cmd_list.IdxBuffer.Size; j++)
                new_vtx_buffer[j] = cmd_list.VtxBuffer[cmd_list.IdxBuffer[j]];
            cmd_list.VtxBuffer.swap(&new_vtx_buffer);
            cmd_list.IdxBuffer.resize(0);
            TotalVtxCount += cmd_list.VtxBuffer.Size;
        }
    }
    
    void  ScaleClipRects(const ImVec2/*&*/ fb_scale) // Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
    {
        for (int i = 0; i < CmdListsCount; i++)
        {
            ImDrawList* cmd_list = CmdLists[i];
            for (int cmd_i = 0; cmd_i < cmd_list.CmdBuffer.Size; cmd_i++)
            {
                ImDrawCmd* cmd = &cmd_list.CmdBuffer[cmd_i];
                cmd.ClipRect = ImVec4(cmd.ClipRect.x * fb_scale.x, cmd.ClipRect.y * fb_scale.y, cmd.ClipRect.z * fb_scale.x, cmd.ClipRect.w * fb_scale.y);
            }
        }
    }
}

//-----------------------------------------------------------------------------
// Font API (ImFontConfig, ImFontGlyph, ImFontAtlasFlags, ImFontAtlas, ImFontGlyphRangesBuilder, ImFont)
//-----------------------------------------------------------------------------

struct ImFontConfig
{
    nothrow:
    @nogc:

    void*           FontData;               //          // TTF/OTF data
    int             FontDataSize;           //          // TTF/OTF data size
    bool            FontDataOwnedByAtlas;   // true     // TTF/OTF data ownership taken by the container ImFontAtlas (will delete memory itself).
    int             FontNo;                 // 0        // Index of font within TTF/OTF file
    float           SizePixels;             //          // Size in pixels for rasterizer (more or less maps to the resulting font height).
    int             OversampleH;            // 3        // Rasterize at higher quality for sub-pixel positioning. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
    int             OversampleV;            // 1        // Rasterize at higher quality for sub-pixel positioning. We don't use sub-pixel positions on the Y axis.
    bool            PixelSnapH;             // false    // Align every glyph to pixel boundary. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
    ImVec2          GlyphExtraSpacing;      // 0, 0     // Extra spacing (in pixels) between glyphs. Only X axis is supported for now.
    ImVec2          GlyphOffset;            // 0, 0     // Offset all glyphs from this font input.
    const (ImWchar)*  GlyphRanges;            // NULL     // Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list). THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE.
    float           GlyphMinAdvanceX;       // 0        // Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font
    float           GlyphMaxAdvanceX;       // FLT_MAX  // Maximum AdvanceX for glyphs
    bool            MergeMode;              // false    // Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
    uint    RasterizerFlags;        // 0x00     // Settings for custom font rasterizer (e.g. ImGuiFreeType). Leave as zero if you aren't using one.
    float           RasterizerMultiply;     // 1.0f     // Brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable.
    ImWchar         EllipsisChar;           // -1       // Explicitly specify unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.

    // [Internal]
    char[40]            Name;               // Name (strictly to ease debugging)
    ImFont*         DstFont;

    @disable this();
    this(bool dummy)
    {
        FontData = NULL;
        FontDataSize = 0;
        FontDataOwnedByAtlas = true;
        FontNo = 0;
        SizePixels = 0.0f;
        OversampleH = 3; // FIXME: 2 may be a better default?
        OversampleV = 1;
        PixelSnapH = false;
        GlyphExtraSpacing = ImVec2(0.0f, 0.0f);
        GlyphOffset = ImVec2(0.0f, 0.0f);
        GlyphRanges = NULL;
        GlyphMinAdvanceX = 0.0f;
        GlyphMaxAdvanceX = FLT_MAX;
        MergeMode = false;
        RasterizerFlags = 0x00;
        RasterizerMultiply = 1.0f;
        EllipsisChar = cast(ImWchar)-1;
        memset(Name.ptr, 0, (Name).sizeof);
        DstFont = NULL;
    }
}

// Hold rendering data for one glyph.
// (Note: some language parsers may fail to convert the 31+1 bitfield members, in this case maybe drop store a single u32 or we can rework this)
struct ImFontGlyph
{
    nothrow:
    @nogc:

    uint _Codepoint;
    // D_IMGUI: Using inline properties instead of a bitfield.
    @property pragma(inline, true) uint Codepoint() const {return _Codepoint & 0x7FFFFFFF;} // 0x0000..0xFFFF
    @property pragma(inline, true) uint Visible() const {return _Codepoint >> 31;} // Flag to allow early out when rendering
    @property pragma(inline, true) void Codepoint(uint c) {_Codepoint = (_Codepoint & 0x80000000) | c;}
    @property pragma(inline, true) void Visible(uint v) {_Codepoint = (_Codepoint & 0x7FFFFFFF) | (v << 31);}
    float           AdvanceX;           // Distance to next character (= data from font + ImFontConfig::GlyphExtraSpacing.x baked in)
    float           X0, Y0, X1, Y1;     // Glyph corners
    float           U0, V0, U1, V1;     // Texture coordinates
}

// Helper to build glyph ranges from text/string data. Feed your application strings/characters to it then call BuildRanges().
// This is essentially a tightly packed of vector of 64k booleans = 8KB storage.
struct ImFontGlyphRangesBuilder
{
    nothrow:
    @nogc:

    ImVector!ImU32 UsedChars;            // Store 1-bit per Unicode code point (0=unused, 1=used)
    
    @disable this();
    this(bool dummy)              { Clear(); }
    void destroy() { UsedChars.destroy(); }
    pragma(inline, true) void     Clear()                 { int size_in_bytes = (IM_UNICODE_CODEPOINT_MAX + 1) / 8; UsedChars.resize(size_in_bytes / cast(int)(ImU32).sizeof); memset(UsedChars.Data, 0, cast(size_t)size_in_bytes); }
    pragma(inline, true) bool     GetBit(size_t n) const  { int off = cast(int)(n >> 5); ImU32 mask = 1u << (n & 31); return (UsedChars[off] & mask) != 0; }  // Get bit n in the array
    pragma(inline, true) void     SetBit(size_t n)        { int off = cast(int)(n >> 5); ImU32 mask = 1u << (n & 31); UsedChars[off] |= mask; }               // Set bit n in the array
    pragma(inline, true) void     AddChar(ImWchar c)      { SetBit(c); }                      // Add character
    
    void  AddText(string text)     // Add string (each character of the UTF-8 string are added)
    {
        size_t index = 0;
        while (index < text.length) {
            uint c = 0;
            int c_len = ImTextCharFromUtf8(&c, text[index..$]);
            index += c_len;
            if (c_len == 0)
                break;
            AddChar(cast(ImWchar)c);
        }
    }
    
    void  AddRanges(const (ImWchar)* ranges)                           // Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
    {
        for (; ranges[0]; ranges += 2)
            for (ImWchar c = ranges[0]; c <= ranges[1]; c++)
                AddChar(c);
    }
    
    void  BuildRanges(ImVector!ImWchar* out_ranges)                 // Output new ranges
    {
        const int max_codepoint = IM_UNICODE_CODEPOINT_MAX;
        for (int n = 0; n <= max_codepoint; n++)
            if (GetBit(n))
            {
                out_ranges.push_back(cast(ImWchar)n);
                while (n < max_codepoint && GetBit(n + 1))
                    n++;
                out_ranges.push_back(cast(ImWchar)n);
            }
        out_ranges.push_back(0);
    }
}

// See ImFontAtlas::AddCustomRectXXX functions.
struct ImFontAtlasCustomRect
{
    nothrow:
    @nogc:

    uint            ID;             // Input    // User ID. Use < 0x110000 to map into a font glyph, >= 0x110000 for other/internal/custom texture data.
    ushort          Width, Height;  // Input    // Desired rectangle dimension
    ushort          X, Y;           // Output   // Packed position in Atlas
    float           GlyphAdvanceX;  // Input    // For custom font glyphs only (ID < 0x110000): glyph xadvance
    ImVec2          GlyphOffset;    // Input    // For custom font glyphs only (ID < 0x110000): glyph display offset
    ImFont*         Font;           // Input    // For custom font glyphs only (ID < 0x110000): target font
    
    @disable this();
    this(bool dummy)         { ID = 0xFFFFFFFF; Width = Height = 0; X = Y = 0xFFFF; GlyphAdvanceX = 0.0f; GlyphOffset = ImVec2(0,0); Font = NULL; }
    bool IsPacked() const           { return X != 0xFFFF; }
}

enum ImFontAtlasFlags : int
{
    None               = 0,
    NoPowerOfTwoHeight = 1 << 0,   // Don't round the height to next power of two
    NoMouseCursors     = 1 << 1    // Don't build software mouse cursors into the atlas
}

// Load and rasterize multiple TTF/OTF fonts into a same texture. The font atlas will build a single texture holding:
//  - One or more fonts.
//  - Custom graphics data needed to render the shapes needed by Dear ImGui.
//  - Mouse cursor shapes for software cursor rendering (unless setting 'Flags |= ImFontAtlasFlags_NoMouseCursors' in the font atlas).
// It is the user-code responsibility to setup/build the atlas, then upload the pixel data into a texture accessible by your graphics api.
//  - Optionally, call any of the AddFont*** functions. If you don't call any, the default font embedded in the code will be loaded for you.
//  - Call GetTexDataAsAlpha8() or GetTexDataAsRGBA32() to build and retrieve pixels data.
//  - Upload the pixels data into a texture within your graphics system (see imgui_impl_xxxx.cpp examples)
//  - Call SetTexID(my_tex_id); and pass the pointer/identifier to your texture in a format natural to your graphics API.
//    This value will be passed back to you during rendering to identify the texture. Read FAQ entry about ImTextureID for more details.
// Common pitfalls:
// - If you pass a 'glyph_ranges' array to AddFont*** functions, you need to make sure that your array persist up until the
//   atlas is build (when calling GetTexData*** or Build()). We only copy the pointer, not the data.
// - Important: By default, AddFontFromMemoryTTF() takes ownership of the data. Even though we are not writing to it, we will free the pointer on destruction.
//   You can set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed,
// - Even though many functions are suffixed with "TTF", OTF data is supported just as well.
// - This is an old API and it is currently awkward for those and and various other reasons! We will address them in the future!
struct ImFontAtlas
{
    nothrow:
    @nogc:
    
    @disable this();
    this(bool dummy) {
        Locked = false;
        Flags = ImFontAtlasFlags.None;
        TexID = cast(ImTextureID)NULL;
        TexDesiredWidth = 0;
        TexGlyphPadding = 1;

        TexPixelsAlpha8 = NULL;
        TexPixelsRGBA32 = NULL;
        TexWidth = TexHeight = 0;
        TexUvScale = ImVec2(0.0f, 0.0f);
        TexUvWhitePixel = ImVec2(0.0f, 0.0f);
        for (int n = 0; n < IM_ARRAYSIZE(CustomRectIds); n++)
            CustomRectIds[n] = -1;
    }

    void destroy()
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        Clear();
    }
    
    ImFont*           AddFont(const ImFontConfig* font_cfg)
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        IM_ASSERT(font_cfg.FontData != NULL && font_cfg.FontDataSize > 0);
        IM_ASSERT(font_cfg.SizePixels > 0.0f);

        // Create new font
        if (!font_cfg.MergeMode)
            Fonts.push_back(IM_NEW!ImFont(false));
        else
            IM_ASSERT(!Fonts.empty(), "Cannot use MergeMode for the first font"); // When using MergeMode make sure that a font has already been added before. You can use ImGui.GetIO().Fonts.AddFontDefault() to add the default imgui font.

        ConfigData.push_back(*font_cfg);
        ImFontConfig* new_font_cfg = &ConfigData.back();
        if (new_font_cfg.DstFont == NULL)
            new_font_cfg.DstFont = Fonts.back();
        if (!new_font_cfg.FontDataOwnedByAtlas)
        {
            new_font_cfg.FontData = IM_ALLOC!ubyte(new_font_cfg.FontDataSize).ptr;
            new_font_cfg.FontDataOwnedByAtlas = true;
            memcpy(new_font_cfg.FontData, font_cfg.FontData, cast(size_t)new_font_cfg.FontDataSize);
        }

        if (new_font_cfg.DstFont.EllipsisChar == cast(ImWchar)-1)
            new_font_cfg.DstFont.EllipsisChar = font_cfg.EllipsisChar;

        // Invalidate texture
        ClearTexData();
        return new_font_cfg.DstFont;
    }
    
    ImFont*           AddFontDefault(const ImFontConfig* font_cfg_template = NULL)
    {
        ImFontConfig font_cfg = font_cfg_template ? cast(ImFontConfig)*font_cfg_template : ImFontConfig(false);
        if (!font_cfg_template)
        {
            font_cfg.OversampleH = font_cfg.OversampleV = 1;
            font_cfg.PixelSnapH = true;
        }
        if (font_cfg.SizePixels <= 0.0f)
            font_cfg.SizePixels = 13.0f * 1.0f;
        if (font_cfg.Name[0] == '\0')
            ImFormatString(font_cfg.Name, "ProggyClean.ttf, %dpx", cast(int)font_cfg.SizePixels);
        font_cfg.EllipsisChar = cast(ImWchar)0x0085;

        string ttf_compressed_base85 = GetDefaultCompressedFontDataTTFBase85();
        const (ImWchar)* glyph_ranges = font_cfg.GlyphRanges != NULL ? font_cfg.GlyphRanges : GetGlyphRangesDefault();
        ImFont* font = AddFontFromMemoryCompressedBase85TTF(ttf_compressed_base85, font_cfg.SizePixels, &font_cfg, glyph_ranges);
        font.DisplayOffset.y = 1.0f;
        return font;
    }
    
    ImFont*           AddFontFromFileTTF(string filename, float size_pixels, const ImFontConfig* font_cfg_template = NULL, const ImWchar* glyph_ranges = NULL)
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        ubyte[] data = ImFileLoadToMemory(filename, "rb", 0);
        if (data is NULL)
        {
            IM_ASSERT_USER_ERROR(0, "Could not load font file!");
            return NULL;
        }
        ImFontConfig font_cfg = font_cfg_template ? cast(ImFontConfig)*font_cfg_template : ImFontConfig(false);
        if (font_cfg.Name[0] == '\0')
        {
            // Store a short copy of filename into into the font name for convenience
            size_t p;
            for (p = filename.length; p > 0 && filename[p - 1] != '/' && filename[p - 1] != '\\'; p--) {}
            ImFormatString(font_cfg.Name, "%s, %.0fpx", filename[p..$], size_pixels);
        }
        return AddFontFromMemoryTTF(data, size_pixels, &font_cfg, glyph_ranges);
    }
    
    ImFont*           AddFontFromMemoryTTF(ubyte[] ttf_data, float size_pixels, const ImFontConfig* font_cfg_template = NULL, const ImWchar* glyph_ranges = NULL) // Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");    
        ImFontConfig font_cfg = font_cfg_template ? cast(ImFontConfig)*font_cfg_template : ImFontConfig(false);
        IM_ASSERT(font_cfg.FontData == NULL);
        font_cfg.FontData = ttf_data.ptr;
        font_cfg.FontDataSize = cast(int)ttf_data.length;
        font_cfg.SizePixels = size_pixels;
        if (glyph_ranges)
            font_cfg.GlyphRanges = glyph_ranges;
        return AddFont(&font_cfg);
    }
    
    ImFont*           AddFontFromMemoryCompressedTTF(const ubyte[] compressed_ttf_data, float size_pixels, const ImFontConfig* font_cfg_template = NULL, const ImWchar* glyph_ranges = NULL) // 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
    {
        const uint buf_decompressed_size = stb_decompress_length(compressed_ttf_data.ptr);
        ubyte[] buf_decompressed_data = IM_ALLOC!ubyte(buf_decompressed_size);
        stb_decompress(buf_decompressed_data.ptr, compressed_ttf_data.ptr, cast(uint)compressed_ttf_data.length);

        ImFontConfig font_cfg = font_cfg_template ? cast(ImFontConfig)*font_cfg_template : ImFontConfig(false);
        IM_ASSERT(font_cfg.FontData == NULL);
        font_cfg.FontDataOwnedByAtlas = true;
        return AddFontFromMemoryTTF(buf_decompressed_data, size_pixels, &font_cfg, glyph_ranges);
    }

    ImFont*           AddFontFromMemoryCompressedBase85TTF(string compressed_ttf_data_base85, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL)              // 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
    {
        int compressed_ttf_size = ((cast(int)compressed_ttf_data_base85.length + 4) / 5) * 4;
        ubyte[] compressed_ttf = IM_ALLOC!ubyte(compressed_ttf_size);
        Decode85(cast(const ubyte[])compressed_ttf_data_base85, compressed_ttf);
        ImFont* font = AddFontFromMemoryCompressedTTF(compressed_ttf, size_pixels, font_cfg, glyph_ranges);
        IM_FREE(compressed_ttf);
        return font;
    }

    void              ClearInputData()           // Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        for (int i = 0; i < ConfigData.Size; i++)
            if (ConfigData[i].FontData && ConfigData[i].FontDataOwnedByAtlas)
            {
                IM_FREE(ConfigData[i].FontData);
                ConfigData[i].FontData = NULL;
            }

        // When clearing this we lose access to the font name and other information used to build the font.
        for (int i = 0; i < Fonts.Size; i++)
            if (Fonts[i].ConfigData >= ConfigData.Data && Fonts[i].ConfigData < ConfigData.Data + ConfigData.Size)
            {
                Fonts[i].ConfigData = NULL;
                Fonts[i].ConfigDataCount = 0;
            }
        ConfigData.clear();
        CustomRects.clear();
        for (int n = 0; n < IM_ARRAYSIZE(CustomRectIds); n++)
            CustomRectIds[n] = -1;
    }
    
    void              ClearTexData()             // Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        if (TexPixelsAlpha8)
            IM_FREE(TexPixelsAlpha8);
        if (TexPixelsRGBA32)
            IM_FREE(TexPixelsRGBA32);
        TexPixelsAlpha8 = NULL;
        TexPixelsRGBA32 = NULL;
    }
    
    void              ClearFonts()               // Clear output font data (glyphs storage, UV coordinates).
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        for (int i = 0; i < Fonts.Size; i++)
            IM_DELETE(Fonts[i]);
        Fonts.clear();
    }
    
    void              Clear()                    // Clear all input and output.
    {
        ClearInputData();
        ClearTexData();
        ClearFonts();
    }

    // Build atlas, retrieve pixel data.
    // User is in charge of copying the pixels into graphics memory (e.g. create a texture with your engine). Then store your texture handle with SetTexID().
    // The pitch is always = Width * BytesPerPixels (1 or 4)
    // Building in RGBA32 format is provided for convenience and compatibility, but note that unless you manually manipulate or copy color data into
    // the texture (e.g. when using the AddCustomRect*** api), then the RGB pixels emitted will always be white (~75% of memory/bandwidth waste.
    bool              Build()                    // Build pixels data. This is called automatically for you by the GetTexData*** functions.
    {
        IM_ASSERT(!Locked, "Cannot modify a locked ImFontAtlas between NewFrame() and EndFrame/Render()!");
        return ImFontAtlasBuildWithStbTruetype(&this);
    }
    
    void              GetTexDataAsAlpha8(ubyte[]* out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel = NULL)  // 1 byte per-pixel
    {
        // Build atlas on demand
        if (TexPixelsAlpha8 == NULL)
        {
            if (ConfigData.empty())
                AddFontDefault();
            Build();
        }

        *out_pixels = TexPixelsAlpha8;
        if (out_width) *out_width = TexWidth;
        if (out_height) *out_height = TexHeight;
        if (out_bytes_per_pixel) *out_bytes_per_pixel = 1;
    }
    
    void              GetTexDataAsRGBA32(ubyte[]* out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel = NULL)  // 4 bytes-per-pixel
    {
        // Convert to RGBA32 format on demand
        // Although it is likely to be the most commonly used format, our font rendering is 1 channel / 8 bpp
        if (!TexPixelsRGBA32)
        {
            ubyte[] pixels = NULL;
            GetTexDataAsAlpha8(&pixels, NULL, NULL);
            if (pixels)
            {
                TexPixelsRGBA32 = IM_ALLOC!uint(cast(size_t)TexWidth * cast(size_t)TexHeight);
                const (ubyte)* src = pixels.ptr;
                uint* dst = TexPixelsRGBA32.ptr;
                for (int n = TexWidth * TexHeight; n > 0; n--)
                    *dst++ = IM_COL32(255, 255, 255, cast(uint)(*src++));
            }
        }

        *out_pixels = cast(ubyte[])TexPixelsRGBA32;
        if (out_width) *out_width = TexWidth;
        if (out_height) *out_height = TexHeight;
        if (out_bytes_per_pixel) *out_bytes_per_pixel = 4;
    }
    
    bool                        IsBuilt() const             { return Fonts.Size > 0 && (TexPixelsAlpha8 != NULL || TexPixelsRGBA32 != NULL); }
    void                        SetTexID(ImTextureID id)    { TexID = id; }

    //-------------------------------------------
    // Glyph Ranges
    //-------------------------------------------

    // Helpers to retrieve list of common Unicode ranges (2 value per range, values are inclusive, zero-terminated list)
    // NB: Make sure that your string are UTF-8 and NOT in your local code page. In C++11, you can create UTF-8 string literal using the u8"Hello world" syntax. See FAQ for details.
    // NB: Consider using ImFontGlyphRangesBuilder to build glyph ranges from textual data.
    const (ImWchar)*    GetGlyphRangesDefault()                // Basic Latin, Extended Latin
    {
        __gshared const ImWchar[] ranges =
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0,
        ];
        return &ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesKorean()                 // Default + Korean characters
    {
        __gshared const ImWchar[] ranges =
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x3131, 0x3163, // Korean alphabets
            0xAC00, 0xD79D, // Korean characters
            0,
        ];
        return &ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesJapanese()               // Default + Hiragana, Katakana, Half-Width, Selection of 1946 Ideographs
    {
        // 1946 common ideograms code points for Japanese
        // Sourced from http://theinstructionlimit.com/common-kanji-character-ranges-for-xna-spritefont-rendering
        // FIXME: Source a list of the revised 2136 Joyo Kanji list from 2010 and rebuild this.
        // You can use ImFontGlyphRangesBuilder to create your own ranges derived from this, by merging existing ranges or adding new characters.
        // (Stored as accumulative offsets from the initial unicode codepoint 0x4E00. This encoding is designed to helps us compact the source code size.)
        __gshared const short[1946] accumulative_offsets_from_0x4E00 =
        [
            0,1,2,4,1,1,1,1,2,1,6,2,2,1,8,5,7,11,1,2,10,10,8,2,4,20,2,11,8,2,1,2,1,6,2,1,7,5,3,7,1,1,13,7,9,1,4,6,1,2,1,10,1,1,9,2,2,4,5,6,14,1,1,9,3,18,
            5,4,2,2,10,7,1,1,1,3,2,4,3,23,2,10,12,2,14,2,4,13,1,6,10,3,1,7,13,6,4,13,5,2,3,17,2,2,5,7,6,4,1,7,14,16,6,13,9,15,1,1,7,16,4,7,1,19,9,2,7,15,
            2,6,5,13,25,4,14,13,11,25,1,1,1,2,1,2,2,3,10,11,3,3,1,1,4,4,2,1,4,9,1,4,3,5,5,2,7,12,11,15,7,16,4,5,16,2,1,1,6,3,3,1,1,2,7,6,6,7,1,4,7,6,1,1,
            2,1,12,3,3,9,5,8,1,11,1,2,3,18,20,4,1,3,6,1,7,3,5,5,7,2,2,12,3,1,4,2,3,2,3,11,8,7,4,17,1,9,25,1,1,4,2,2,4,1,2,7,1,1,1,3,1,2,6,16,1,2,1,1,3,12,
            20,2,5,20,8,7,6,2,1,1,1,1,6,2,1,2,10,1,1,6,1,3,1,2,1,4,1,12,4,1,3,1,1,1,1,1,10,4,7,5,13,1,15,1,1,30,11,9,1,15,38,14,1,32,17,20,1,9,31,2,21,9,
            4,49,22,2,1,13,1,11,45,35,43,55,12,19,83,1,3,2,3,13,2,1,7,3,18,3,13,8,1,8,18,5,3,7,25,24,9,24,40,3,17,24,2,1,6,2,3,16,15,6,7,3,12,1,9,7,3,3,
            3,15,21,5,16,4,5,12,11,11,3,6,3,2,31,3,2,1,1,23,6,6,1,4,2,6,5,2,1,1,3,3,22,2,6,2,3,17,3,2,4,5,1,9,5,1,1,6,15,12,3,17,2,14,2,8,1,23,16,4,2,23,
            8,15,23,20,12,25,19,47,11,21,65,46,4,3,1,5,6,1,2,5,26,2,1,1,3,11,1,1,1,2,1,2,3,1,1,10,2,3,1,1,1,3,6,3,2,2,6,6,9,2,2,2,6,2,5,10,2,4,1,2,1,2,2,
            3,1,1,3,1,2,9,23,9,2,1,1,1,1,5,3,2,1,10,9,6,1,10,2,31,25,3,7,5,40,1,15,6,17,7,27,180,1,3,2,2,1,1,1,6,3,10,7,1,3,6,17,8,6,2,2,1,3,5,5,8,16,14,
            15,1,1,4,1,2,1,1,1,3,2,7,5,6,2,5,10,1,4,2,9,1,1,11,6,1,44,1,3,7,9,5,1,3,1,1,10,7,1,10,4,2,7,21,15,7,2,5,1,8,3,4,1,3,1,6,1,4,2,1,4,10,8,1,4,5,
            1,5,10,2,7,1,10,1,1,3,4,11,10,29,4,7,3,5,2,3,33,5,2,19,3,1,4,2,6,31,11,1,3,3,3,1,8,10,9,12,11,12,8,3,14,8,6,11,1,4,41,3,1,2,7,13,1,5,6,2,6,12,
            12,22,5,9,4,8,9,9,34,6,24,1,1,20,9,9,3,4,1,7,2,2,2,6,2,28,5,3,6,1,4,6,7,4,2,1,4,2,13,6,4,4,3,1,8,8,3,2,1,5,1,2,2,3,1,11,11,7,3,6,10,8,6,16,16,
            22,7,12,6,21,5,4,6,6,3,6,1,3,2,1,2,8,29,1,10,1,6,13,6,6,19,31,1,13,4,4,22,17,26,33,10,4,15,12,25,6,67,10,2,3,1,6,10,2,6,2,9,1,9,4,4,1,2,16,2,
            5,9,2,3,8,1,8,3,9,4,8,6,4,8,11,3,2,1,1,3,26,1,7,5,1,11,1,5,3,5,2,13,6,39,5,1,5,2,11,6,10,5,1,15,5,3,6,19,21,22,2,4,1,6,1,8,1,4,8,2,4,2,2,9,2,
            1,1,1,4,3,6,3,12,7,1,14,2,4,10,2,13,1,17,7,3,2,1,3,2,13,7,14,12,3,1,29,2,8,9,15,14,9,14,1,3,1,6,5,9,11,3,38,43,20,7,7,8,5,15,12,19,15,81,8,7,
            1,5,73,13,37,28,8,8,1,15,18,20,165,28,1,6,11,8,4,14,7,15,1,3,3,6,4,1,7,14,1,1,11,30,1,5,1,4,14,1,4,2,7,52,2,6,29,3,1,9,1,21,3,5,1,26,3,11,14,
            11,1,17,5,1,2,1,3,2,8,1,2,9,12,1,1,2,3,8,3,24,12,7,7,5,17,3,3,3,1,23,10,4,4,6,3,1,16,17,22,3,10,21,16,16,6,4,10,2,1,1,2,8,8,6,5,3,3,3,39,25,
            15,1,1,16,6,7,25,15,6,6,12,1,22,13,1,4,9,5,12,2,9,1,12,28,8,3,5,10,22,60,1,2,40,4,61,63,4,1,13,12,1,4,31,12,1,14,89,5,16,6,29,14,2,5,49,18,18,
            5,29,33,47,1,17,1,19,12,2,9,7,39,12,3,7,12,39,3,1,46,4,12,3,8,9,5,31,15,18,3,2,2,66,19,13,17,5,3,46,124,13,57,34,2,5,4,5,8,1,1,1,4,3,1,17,5,
            3,5,3,1,8,5,6,3,27,3,26,7,12,7,2,17,3,7,18,78,16,4,36,1,2,1,6,2,1,39,17,7,4,13,4,4,4,1,10,4,2,4,6,3,10,1,19,1,26,2,4,33,2,73,47,7,3,8,2,4,15,
            18,1,29,2,41,14,1,21,16,41,7,39,25,13,44,2,2,10,1,13,7,1,7,3,5,20,4,8,2,49,1,10,6,1,6,7,10,7,11,16,3,12,20,4,10,3,1,2,11,2,28,9,2,4,7,2,15,1,
            27,1,28,17,4,5,10,7,3,24,10,11,6,26,3,2,7,2,2,49,16,10,16,15,4,5,27,61,30,14,38,22,2,7,5,1,3,12,23,24,17,17,3,3,2,4,1,6,2,7,5,1,1,5,1,1,9,4,
            1,3,6,1,8,2,8,4,14,3,5,11,4,1,3,32,1,19,4,1,13,11,5,2,1,8,6,8,1,6,5,13,3,23,11,5,3,16,3,9,10,1,24,3,198,52,4,2,2,5,14,5,4,22,5,20,4,11,6,41,
            1,5,2,2,11,5,2,28,35,8,22,3,18,3,10,7,5,3,4,1,5,3,8,9,3,6,2,16,22,4,5,5,3,3,18,23,2,6,23,5,27,8,1,33,2,12,43,16,5,2,3,6,1,20,4,2,9,7,1,11,2,
            10,3,14,31,9,3,25,18,20,2,5,5,26,14,1,11,17,12,40,19,9,6,31,83,2,7,9,19,78,12,14,21,76,12,113,79,34,4,1,1,61,18,85,10,2,2,13,31,11,50,6,33,159,
            179,6,6,7,4,4,2,4,2,5,8,7,20,32,22,1,3,10,6,7,28,5,10,9,2,77,19,13,2,5,1,4,4,7,4,13,3,9,31,17,3,26,2,6,6,5,4,1,7,11,3,4,2,1,6,2,20,4,1,9,2,6,
            3,7,1,1,1,20,2,3,1,6,2,3,6,2,4,8,1,5,13,8,4,11,23,1,10,6,2,1,3,21,2,2,4,24,31,4,10,10,2,5,192,15,4,16,7,9,51,1,2,1,1,5,1,1,2,1,3,5,3,1,3,4,1,
            3,1,3,3,9,8,1,2,2,2,4,4,18,12,92,2,10,4,3,14,5,25,16,42,4,14,4,2,21,5,126,30,31,2,1,5,13,3,22,5,6,6,20,12,1,14,12,87,3,19,1,8,2,9,9,3,3,23,2,
            3,7,6,3,1,2,3,9,1,3,1,6,3,2,1,3,11,3,1,6,10,3,2,3,1,2,1,5,1,1,11,3,6,4,1,7,2,1,2,5,5,34,4,14,18,4,19,7,5,8,2,6,79,1,5,2,14,8,2,9,2,1,36,28,16,
            4,1,1,1,2,12,6,42,39,16,23,7,15,15,3,2,12,7,21,64,6,9,28,8,12,3,3,41,59,24,51,55,57,294,9,9,2,6,2,15,1,2,13,38,90,9,9,9,3,11,7,1,1,1,5,6,3,2,
            1,2,2,3,8,1,4,4,1,5,7,1,4,3,20,4,9,1,1,1,5,5,17,1,5,2,6,2,4,1,4,5,7,3,18,11,11,32,7,5,4,7,11,127,8,4,3,3,1,10,1,1,6,21,14,1,16,1,7,1,3,6,9,65,
            51,4,3,13,3,10,1,1,12,9,21,110,3,19,24,1,1,10,62,4,1,29,42,78,28,20,18,82,6,3,15,6,84,58,253,15,155,264,15,21,9,14,7,58,40,39,
        ];
        __gshared const ImWchar[8] base_ranges = // not zero-terminated
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, // Katakana Phonetic Extensions
            0xFF00, 0xFFEF  // Half-width characters
        ];
        __gshared ImWchar[IM_ARRAYSIZE(base_ranges) + IM_ARRAYSIZE(accumulative_offsets_from_0x4E00) * 2 + 1] full_ranges = 0;
        if (!full_ranges[0])
        {
            memcpy(full_ranges.ptr, base_ranges.ptr, (base_ranges).sizeof);
            UnpackAccumulativeOffsetsIntoRanges(0x4E00, accumulative_offsets_from_0x4E00.ptr, IM_ARRAYSIZE(accumulative_offsets_from_0x4E00), full_ranges.ptr + IM_ARRAYSIZE(base_ranges));
        }
        return &full_ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesChineseFull()            // Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
    {
        __gshared const ImWchar[] ranges =
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x2000, 0x206F, // General Punctuation
            0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, // Katakana Phonetic Extensions
            0xFF00, 0xFFEF, // Half-width characters
            0x4e00, 0x9FAF, // CJK Ideograms
            0,
        ];
        return &ranges[0];
    }

    private static void UnpackAccumulativeOffsetsIntoRanges(int base_codepoint, const short* accumulative_offsets, int accumulative_offsets_count, ImWchar* out_ranges) {
        for (int n = 0; n < accumulative_offsets_count; n++, out_ranges += 2) {
            out_ranges[0] = out_ranges[1] = cast(ImWchar)(base_codepoint + accumulative_offsets[n]);
            base_codepoint += accumulative_offsets[n];
        }
        out_ranges[0] = 0;
    }

    const (ImWchar)*    GetGlyphRangesChineseSimplifiedCommon()// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
    {
        // Store 2500 regularly used characters for Simplified Chinese.
        // Sourced from https://zh.wiktionary.org/wiki/%E9%99%84%E5%BD%95:%E7%8E%B0%E4%BB%A3%E6%B1%89%E8%AF%AD%E5%B8%B8%E7%94%A8%E5%AD%97%E8%A1%A8
        // This table covers 97.97% of all characters used during the month in July, 1987.
        // You can use ImFontGlyphRangesBuilder to create your own ranges derived from this, by merging existing ranges or adding new characters.
        // (Stored as accumulative offsets from the initial unicode codepoint 0x4E00. This encoding is designed to helps us compact the source code size.)
        __gshared const short[2500] accumulative_offsets_from_0x4E00 =
        [
            0,1,2,4,1,1,1,1,2,1,3,2,1,2,2,1,1,1,1,1,5,2,1,2,3,3,3,2,2,4,1,1,1,2,1,5,2,3,1,2,1,2,1,1,2,1,1,2,2,1,4,1,1,1,1,5,10,1,2,19,2,1,2,1,2,1,2,1,2,
            1,5,1,6,3,2,1,2,2,1,1,1,4,8,5,1,1,4,1,1,3,1,2,1,5,1,2,1,1,1,10,1,1,5,2,4,6,1,4,2,2,2,12,2,1,1,6,1,1,1,4,1,1,4,6,5,1,4,2,2,4,10,7,1,1,4,2,4,
            2,1,4,3,6,10,12,5,7,2,14,2,9,1,1,6,7,10,4,7,13,1,5,4,8,4,1,1,2,28,5,6,1,1,5,2,5,20,2,2,9,8,11,2,9,17,1,8,6,8,27,4,6,9,20,11,27,6,68,2,2,1,1,
            1,2,1,2,2,7,6,11,3,3,1,1,3,1,2,1,1,1,1,1,3,1,1,8,3,4,1,5,7,2,1,4,4,8,4,2,1,2,1,1,4,5,6,3,6,2,12,3,1,3,9,2,4,3,4,1,5,3,3,1,3,7,1,5,1,1,1,1,2,
            3,4,5,2,3,2,6,1,1,2,1,7,1,7,3,4,5,15,2,2,1,5,3,22,19,2,1,1,1,1,2,5,1,1,1,6,1,1,12,8,2,9,18,22,4,1,1,5,1,16,1,2,7,10,15,1,1,6,2,4,1,2,4,1,6,
            1,1,3,2,4,1,6,4,5,1,2,1,1,2,1,10,3,1,3,2,1,9,3,2,5,7,2,19,4,3,6,1,1,1,1,1,4,3,2,1,1,1,2,5,3,1,1,1,2,2,1,1,2,1,1,2,1,3,1,1,1,3,7,1,4,1,1,2,1,
            1,2,1,2,4,4,3,8,1,1,1,2,1,3,5,1,3,1,3,4,6,2,2,14,4,6,6,11,9,1,15,3,1,28,5,2,5,5,3,1,3,4,5,4,6,14,3,2,3,5,21,2,7,20,10,1,2,19,2,4,28,28,2,3,
            2,1,14,4,1,26,28,42,12,40,3,52,79,5,14,17,3,2,2,11,3,4,6,3,1,8,2,23,4,5,8,10,4,2,7,3,5,1,1,6,3,1,2,2,2,5,28,1,1,7,7,20,5,3,29,3,17,26,1,8,4,
            27,3,6,11,23,5,3,4,6,13,24,16,6,5,10,25,35,7,3,2,3,3,14,3,6,2,6,1,4,2,3,8,2,1,1,3,3,3,4,1,1,13,2,2,4,5,2,1,14,14,1,2,2,1,4,5,2,3,1,14,3,12,
            3,17,2,16,5,1,2,1,8,9,3,19,4,2,2,4,17,25,21,20,28,75,1,10,29,103,4,1,2,1,1,4,2,4,1,2,3,24,2,2,2,1,1,2,1,3,8,1,1,1,2,1,1,3,1,1,1,6,1,5,3,1,1,
            1,3,4,1,1,5,2,1,5,6,13,9,16,1,1,1,1,3,2,3,2,4,5,2,5,2,2,3,7,13,7,2,2,1,1,1,1,2,3,3,2,1,6,4,9,2,1,14,2,14,2,1,18,3,4,14,4,11,41,15,23,15,23,
            176,1,3,4,1,1,1,1,5,3,1,2,3,7,3,1,1,2,1,2,4,4,6,2,4,1,9,7,1,10,5,8,16,29,1,1,2,2,3,1,3,5,2,4,5,4,1,1,2,2,3,3,7,1,6,10,1,17,1,44,4,6,2,1,1,6,
            5,4,2,10,1,6,9,2,8,1,24,1,2,13,7,8,8,2,1,4,1,3,1,3,3,5,2,5,10,9,4,9,12,2,1,6,1,10,1,1,7,7,4,10,8,3,1,13,4,3,1,6,1,3,5,2,1,2,17,16,5,2,16,6,
            1,4,2,1,3,3,6,8,5,11,11,1,3,3,2,4,6,10,9,5,7,4,7,4,7,1,1,4,2,1,3,6,8,7,1,6,11,5,5,3,24,9,4,2,7,13,5,1,8,82,16,61,1,1,1,4,2,2,16,10,3,8,1,1,
            6,4,2,1,3,1,1,1,4,3,8,4,2,2,1,1,1,1,1,6,3,5,1,1,4,6,9,2,1,1,1,2,1,7,2,1,6,1,5,4,4,3,1,8,1,3,3,1,3,2,2,2,2,3,1,6,1,2,1,2,1,3,7,1,8,2,1,2,1,5,
            2,5,3,5,10,1,2,1,1,3,2,5,11,3,9,3,5,1,1,5,9,1,2,1,5,7,9,9,8,1,3,3,3,6,8,2,3,2,1,1,32,6,1,2,15,9,3,7,13,1,3,10,13,2,14,1,13,10,2,1,3,10,4,15,
            2,15,15,10,1,3,9,6,9,32,25,26,47,7,3,2,3,1,6,3,4,3,2,8,5,4,1,9,4,2,2,19,10,6,2,3,8,1,2,2,4,2,1,9,4,4,4,6,4,8,9,2,3,1,1,1,1,3,5,5,1,3,8,4,6,
            2,1,4,12,1,5,3,7,13,2,5,8,1,6,1,2,5,14,6,1,5,2,4,8,15,5,1,23,6,62,2,10,1,1,8,1,2,2,10,4,2,2,9,2,1,1,3,2,3,1,5,3,3,2,1,3,8,1,1,1,11,3,1,1,4,
            3,7,1,14,1,2,3,12,5,2,5,1,6,7,5,7,14,11,1,3,1,8,9,12,2,1,11,8,4,4,2,6,10,9,13,1,1,3,1,5,1,3,2,4,4,1,18,2,3,14,11,4,29,4,2,7,1,3,13,9,2,2,5,
            3,5,20,7,16,8,5,72,34,6,4,22,12,12,28,45,36,9,7,39,9,191,1,1,1,4,11,8,4,9,2,3,22,1,1,1,1,4,17,1,7,7,1,11,31,10,2,4,8,2,3,2,1,4,2,16,4,32,2,
            3,19,13,4,9,1,5,2,14,8,1,1,3,6,19,6,5,1,16,6,2,10,8,5,1,2,3,1,5,5,1,11,6,6,1,3,3,2,6,3,8,1,1,4,10,7,5,7,7,5,8,9,2,1,3,4,1,1,3,1,3,3,2,6,16,
            1,4,6,3,1,10,6,1,3,15,2,9,2,10,25,13,9,16,6,2,2,10,11,4,3,9,1,2,6,6,5,4,30,40,1,10,7,12,14,33,6,3,6,7,3,1,3,1,11,14,4,9,5,12,11,49,18,51,31,
            140,31,2,2,1,5,1,8,1,10,1,4,4,3,24,1,10,1,3,6,6,16,3,4,5,2,1,4,2,57,10,6,22,2,22,3,7,22,6,10,11,36,18,16,33,36,2,5,5,1,1,1,4,10,1,4,13,2,7,
            5,2,9,3,4,1,7,43,3,7,3,9,14,7,9,1,11,1,1,3,7,4,18,13,1,14,1,3,6,10,73,2,2,30,6,1,11,18,19,13,22,3,46,42,37,89,7,3,16,34,2,2,3,9,1,7,1,1,1,2,
            2,4,10,7,3,10,3,9,5,28,9,2,6,13,7,3,1,3,10,2,7,2,11,3,6,21,54,85,2,1,4,2,2,1,39,3,21,2,2,5,1,1,1,4,1,1,3,4,15,1,3,2,4,4,2,3,8,2,20,1,8,7,13,
            4,1,26,6,2,9,34,4,21,52,10,4,4,1,5,12,2,11,1,7,2,30,12,44,2,30,1,1,3,6,16,9,17,39,82,2,2,24,7,1,7,3,16,9,14,44,2,1,2,1,2,3,5,2,4,1,6,7,5,3,
            2,6,1,11,5,11,2,1,18,19,8,1,3,24,29,2,1,3,5,2,2,1,13,6,5,1,46,11,3,5,1,1,5,8,2,10,6,12,6,3,7,11,2,4,16,13,2,5,1,1,2,2,5,2,28,5,2,23,10,8,4,
            4,22,39,95,38,8,14,9,5,1,13,5,4,3,13,12,11,1,9,1,27,37,2,5,4,4,63,211,95,2,2,2,1,3,5,2,1,1,2,2,1,1,1,3,2,4,1,2,1,1,5,2,2,1,1,2,3,1,3,1,1,1,
            3,1,4,2,1,3,6,1,1,3,7,15,5,3,2,5,3,9,11,4,2,22,1,6,3,8,7,1,4,28,4,16,3,3,25,4,4,27,27,1,4,1,2,2,7,1,3,5,2,28,8,2,14,1,8,6,16,25,3,3,3,14,3,
            3,1,1,2,1,4,6,3,8,4,1,1,1,2,3,6,10,6,2,3,18,3,2,5,5,4,3,1,5,2,5,4,23,7,6,12,6,4,17,11,9,5,1,1,10,5,12,1,1,11,26,33,7,3,6,1,17,7,1,5,12,1,11,
            2,4,1,8,14,17,23,1,2,1,7,8,16,11,9,6,5,2,6,4,16,2,8,14,1,11,8,9,1,1,1,9,25,4,11,19,7,2,15,2,12,8,52,7,5,19,2,16,4,36,8,1,16,8,24,26,4,6,2,9,
            5,4,36,3,28,12,25,15,37,27,17,12,59,38,5,32,127,1,2,9,17,14,4,1,2,1,1,8,11,50,4,14,2,19,16,4,17,5,4,5,26,12,45,2,23,45,104,30,12,8,3,10,2,2,
            3,3,1,4,20,7,2,9,6,15,2,20,1,3,16,4,11,15,6,134,2,5,59,1,2,2,2,1,9,17,3,26,137,10,211,59,1,2,4,1,4,1,1,1,2,6,2,3,1,1,2,3,2,3,1,3,4,4,2,3,3,
            1,4,3,1,7,2,2,3,1,2,1,3,3,3,2,2,3,2,1,3,14,6,1,3,2,9,6,15,27,9,34,145,1,1,2,1,1,1,1,2,1,1,1,1,2,2,2,3,1,2,1,1,1,2,3,5,8,3,5,2,4,1,3,2,2,2,12,
            4,1,1,1,10,4,5,1,20,4,16,1,15,9,5,12,2,9,2,5,4,2,26,19,7,1,26,4,30,12,15,42,1,6,8,172,1,1,4,2,1,1,11,2,2,4,2,1,2,1,10,8,1,2,1,4,5,1,2,5,1,8,
            4,1,3,4,2,1,6,2,1,3,4,1,2,1,1,1,1,12,5,7,2,4,3,1,1,1,3,3,6,1,2,2,3,3,3,2,1,2,12,14,11,6,6,4,12,2,8,1,7,10,1,35,7,4,13,15,4,3,23,21,28,52,5,
            26,5,6,1,7,10,2,7,53,3,2,1,1,1,2,163,532,1,10,11,1,3,3,4,8,2,8,6,2,2,23,22,4,2,2,4,2,1,3,1,3,3,5,9,8,2,1,2,8,1,10,2,12,21,20,15,105,2,3,1,1,
            3,2,3,1,1,2,5,1,4,15,11,19,1,1,1,1,5,4,5,1,1,2,5,3,5,12,1,2,5,1,11,1,1,15,9,1,4,5,3,26,8,2,1,3,1,1,15,19,2,12,1,2,5,2,7,2,19,2,20,6,26,7,5,
            2,2,7,34,21,13,70,2,128,1,1,2,1,1,2,1,1,3,2,2,2,15,1,4,1,3,4,42,10,6,1,49,85,8,1,2,1,1,4,4,2,3,6,1,5,7,4,3,211,4,1,2,1,2,5,1,2,4,2,2,6,5,6,
            10,3,4,48,100,6,2,16,296,5,27,387,2,2,3,7,16,8,5,38,15,39,21,9,10,3,7,59,13,27,21,47,5,21,6
        ];
        __gshared const ImWchar[10] base_ranges = // not zero-terminated
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x2000, 0x206F, // General Punctuation
            0x3000, 0x30FF, // CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, // Katakana Phonetic Extensions
            0xFF00, 0xFFEF  // Half-width characters
        ];
        __gshared ImWchar[IM_ARRAYSIZE(base_ranges) + IM_ARRAYSIZE(accumulative_offsets_from_0x4E00) * 2 + 1] full_ranges = 0;
        if (!full_ranges[0])
        {
            memcpy(full_ranges.ptr, base_ranges.ptr, (base_ranges).sizeof);
            UnpackAccumulativeOffsetsIntoRanges(0x4E00, accumulative_offsets_from_0x4E00.ptr, IM_ARRAYSIZE(accumulative_offsets_from_0x4E00), full_ranges.ptr + IM_ARRAYSIZE(base_ranges));
        }
        return &full_ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesCyrillic()               // Default + about 400 Cyrillic characters
    {
        __gshared const ImWchar[9] ranges =
        [
            0x0020, 0x00FF, // Basic Latin + Latin Supplement
            0x0400, 0x052F, // Cyrillic + Cyrillic Supplement
            0x2DE0, 0x2DFF, // Cyrillic Extended-A
            0xA640, 0xA69F, // Cyrillic Extended-B
            0,
        ];
        return &ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesThai()                   // Default + Thai characters
    {
        __gshared const ImWchar[7] ranges =
        [
            0x0020, 0x00FF, // Basic Latin
            0x2010, 0x205E, // Punctuations
            0x0E00, 0x0E7F, // Thai
            0,
        ];
        return &ranges[0];
    }

    const (ImWchar)*    GetGlyphRangesVietnamese()             // Default + Vietnamese characters
    {
        __gshared const ImWchar[17] ranges =
        [
            0x0020, 0x00FF, // Basic Latin
            0x0102, 0x0103,
            0x0110, 0x0111,
            0x0128, 0x0129,
            0x0168, 0x0169,
            0x01A0, 0x01A1,
            0x01AF, 0x01B0,
            0x1EA0, 0x1EF9,
            0,
        ];
        return &ranges[0];
    }

    //-------------------------------------------
    // [BETA] Custom Rectangles/Glyphs API
    //-------------------------------------------

    // You can request arbitrary rectangles to be packed into the atlas, for your own purposes.
    // After calling Build(), you can query the rectangle position and render your pixels.
    // You can also request your rectangles to be mapped as font glyph (given a font + Unicode point),
    // so you can render e.g. custom colorful icons and use them as regular glyphs.
    // Read docs/FONTS.txt for more details about using colorful icons.
    int               AddCustomRectRegular(uint id, int width, int height)                                                                   // Id needs to be >= 0x110000. Id >= 0x80000000 are reserved for ImGui and ImDrawList
    {
        // Breaking change on 2019/11/21 (1.74): ImFontAtlas::AddCustomRectRegular() now requires an ID >= 0x110000 (instead of >= 0x10000)
        IM_ASSERT(id >= 0x110000);                                                                // Id needs to be >= 0x11000. Id >= 0x80000000 are reserved for ImGui and ImDrawList
        IM_ASSERT(width > 0 && width <= 0xFFFF);
        IM_ASSERT(height > 0 && height <= 0xFFFF);
        ImFontAtlasCustomRect r = ImFontAtlasCustomRect(false);
        r.ID = id;
        r.Width = cast(ushort)width;
        r.Height = cast(ushort)height;
        CustomRects.push_back(r);
        return CustomRects.Size - 1; // Return index
    }
    
    int               AddCustomRectFontGlyph(ImFont* font, ImWchar id, int width, int height, float advance_x, const ImVec2/*&*/ offset = ImVec2(0,0))   // Id needs to be < 0x110000 to register a rectangle to map into a specific font.
    {
        IM_ASSERT(font != NULL);
        IM_ASSERT(width > 0 && width <= 0xFFFF);
        IM_ASSERT(height > 0 && height <= 0xFFFF);
        ImFontAtlasCustomRect r = ImFontAtlasCustomRect(false);
        r.ID = id;
        r.Width = cast(ushort)width;
        r.Height = cast(ushort)height;
        r.GlyphAdvanceX = advance_x;
        r.GlyphOffset = offset;
        r.Font = font;
        CustomRects.push_back(r);
        return CustomRects.Size - 1; // Return index
    }

    const (ImFontAtlasCustomRect)* GetCustomRectByIndex(int index) const { if (index < 0) return NULL; return &CustomRects[index]; }

    // [Internal]
    void              CalcCustomRectUV(const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max) const
    {
        IM_ASSERT(TexWidth > 0 && TexHeight > 0);   // Font atlas needs to be built before we can calculate UV coordinates
        IM_ASSERT(rect.IsPacked());                // Make sure the rectangle has been packed
        *out_uv_min = ImVec2(cast(float)rect.X * TexUvScale.x, cast(float)rect.Y * TexUvScale.y);
        *out_uv_max = ImVec2(cast(float)(rect.X + rect.Width) * TexUvScale.x, cast(float)(rect.Y + rect.Height) * TexUvScale.y);
    }
    
    bool              GetMouseCursorTexData(ImGuiMouseCursor cursor_type, ImVec2* out_offset, ImVec2* out_size, ImVec2[2] out_uv_border, ImVec2[2] out_uv_fill)
    {
        if (cursor_type <= ImGuiMouseCursor.None || cursor_type >= ImGuiMouseCursor.COUNT)
            return false;
        if (Flags & ImFontAtlasFlags.NoMouseCursors)
            return false;

        IM_ASSERT(CustomRectIds[0] != -1);
        ImFontAtlasCustomRect* r = &CustomRects[CustomRectIds[0]];
        IM_ASSERT(r.ID == FONT_ATLAS_DEFAULT_TEX_DATA_ID);
        ImVec2 pos = FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][0] + ImVec2(cast(float)r.X, cast(float)r.Y);
        ImVec2 size = FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][1];
        *out_size = size;
        *out_offset = FONT_ATLAS_DEFAULT_TEX_CURSOR_DATA[cursor_type][2];
        out_uv_border[0] = (pos) * TexUvScale;
        out_uv_border[1] = (pos + size) * TexUvScale;
        pos.x += FONT_ATLAS_DEFAULT_TEX_DATA_W_HALF + 1;
        out_uv_fill[0] = (pos) * TexUvScale;
        out_uv_fill[1] = (pos + size) * TexUvScale;
        return true;
    }

    //-------------------------------------------
    // Members
    //-------------------------------------------

    bool                        Locked;             // Marked as Locked by ImGui::NewFrame() so attempt to modify the atlas will assert.
    ImFontAtlasFlags            Flags;              // Build flags (see ImFontAtlasFlags_)
    ImTextureID                 TexID;              // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
    int                         TexDesiredWidth;    // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
    int                         TexGlyphPadding;    // Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0.

    // [Internal]
    // NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
    ubyte[]              TexPixelsAlpha8;    // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
    uint[]               TexPixelsRGBA32;    // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
    int                         TexWidth;           // Texture width calculated during Build().
    int                         TexHeight;          // Texture height calculated during Build().
    ImVec2                      TexUvScale;         // = (1.0f/TexWidth, 1.0f/TexHeight)
    ImVec2                      TexUvWhitePixel;    // Texture coordinates to a white pixel
    ImVector!(ImFont*)           Fonts;              // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
    ImVector!ImFontAtlasCustomRect CustomRects;    // Rectangles for packing custom texture data into the atlas.
    ImVector!ImFontConfig      ConfigData;         // Internal data
    int[1]                         CustomRectIds;   // Identifiers of custom texture rectangle used by ImFontAtlas/ImDrawList

    static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
        alias CustomRect    = ImFontAtlasCustomRect;         // OBSOLETED in 1.72+
        alias GlyphRangesBuilder = ImFontGlyphRangesBuilder; // OBSOLETED in 1.67+
    }
}

// Font runtime data and rendering
// ImFontAtlas automatically loads a default embedded font for you when you call GetTexDataAsAlpha8() or GetTexDataAsRGBA32().
struct ImFont
{
    nothrow:
    @nogc:

    // Members: Hot ~20/24 bytes (for CalcTextSize)
    ImVector!float             IndexAdvanceX;      // 12-16 // out //            // Sparse. Glyphs->AdvanceX in a directly indexable way (cache-friendly for CalcTextSize functions which only this this info, and are often bottleneck in large UI).
    float                       FallbackAdvanceX;   // 4     // out // = FallbackGlyph->AdvanceX
    float                       FontSize;           // 4     // in  //            // Height of characters/line, set during loading (don't change after loading)

    // Members: Hot ~36/48 bytes (for CalcTextSize + render loop)
    ImVector!ImWchar           IndexLookup;        // 12-16 // out //            // Sparse. Index glyphs by Unicode code-point.
    ImVector!ImFontGlyph       Glyphs;             // 12-16 // out //            // All glyphs.
    const (ImFontGlyph)*          FallbackGlyph;      // 4-8   // out // = FindGlyph(FontFallbackChar)
    ImVec2                      DisplayOffset;      // 8     // in  // = (0,0)    // Offset font rendering by xx pixels

    // Members: Cold ~32/40 bytes
    ImFontAtlas*                ContainerAtlas;     // 4-8   // out //            // What we has been loaded into
    const (ImFontConfig)*         ConfigData;         // 4-8   // in  //            // Pointer within ContainerAtlas->ConfigData
    short                       ConfigDataCount;    // 2     // in  // ~ 1        // Number of ImFontConfig involved in creating this font. Bigger than 1 when merging multiple font sources into one ImFont.
    ImWchar                     FallbackChar;       // 2     // in  // = '?'      // Replacement character if a glyph isn't found. Only set via SetFallbackChar()
    ImWchar                     EllipsisChar;       // 2     // out // = -1       // Character used for ellipsis rendering.
    bool                        DirtyLookupTables;  // 1     // out //
    float                       Scale;              // 4     // in  // = 1.f      // Base font scale, multiplied by the per-window font scale which you can adjust with SetWindowFontScale()
    float                       Ascent, Descent;    // 4+4   // out //            // Ascent: distance from top to bottom of e.g. 'A' [0..FontSize]
    int                         MetricsTotalSurface;// 4     // out //            // Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
    ImU8[(IM_UNICODE_CODEPOINT_MAX+1)/4096/8]                        Used4kPagesMap; // 2 bytes if ImWchar=ImWchar16, 34 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations accross all used codepoints.

    // Methods
    @disable this();
    this(bool dummy)
    {
        FontSize = 0.0f;
        FallbackAdvanceX = 0.0f;
        FallbackChar = cast(ImWchar)'?';
        EllipsisChar = cast(ImWchar)-1;
        DisplayOffset = ImVec2(0.0f, 0.0f);
        ClearOutputData();
        FallbackGlyph = NULL;
        ContainerAtlas = NULL;
        ConfigData = NULL;
        ConfigDataCount = 0;
        DirtyLookupTables = false;
        Scale = 1.0f;
        Ascent = Descent = 0.0f;
        MetricsTotalSurface = 0;
        memset(Used4kPagesMap.ptr, 0, (Used4kPagesMap).sizeof);
    }
    
    void destroy()
    {
        ClearOutputData();
    }
    
    const (ImFontGlyph)* FindGlyph(ImWchar c) const
    {
        if (c >= cast(size_t)IndexLookup.Size)
            return FallbackGlyph;
        const ImWchar i = IndexLookup.Data[c];
        if (i == cast(ImWchar)-1)
            return FallbackGlyph;
        return &Glyphs.Data[i];
    }
    
    const (ImFontGlyph)* FindGlyphNoFallback(ImWchar c) const
    {
        if (c >= cast(size_t)IndexLookup.Size)
            return NULL;
        const ImWchar i = IndexLookup.Data[c];
        if (i == cast(ImWchar)-1)
            return NULL;
        return &Glyphs.Data[i];
    }
    
    float                       GetCharAdvance(ImWchar c) const     { return (cast(int)c < IndexAdvanceX.Size) ? IndexAdvanceX[cast(int)c] : FallbackAdvanceX; }
    bool                        IsLoaded() const                    { return ContainerAtlas != NULL; }
    string                 GetDebugName() const                { return ConfigData ? ImCstring(ConfigData.Name) : "<unknown>"; }

    // 'max_width' stops rendering after a certain width (could be turned into a 2d size). FLT_MAX to disable.
    // 'wrap_width' enable automatic word-wrapping across multiple lines to fit into given width. 0.0f to disable.
    ImVec2            CalcTextSizeA(float size, float max_width, float wrap_width, string text, string* remaining = NULL) const // utf8
    {
        const float line_height = size;
        const float scale = size / FontSize;

        ImVec2 text_size = ImVec2(0,0);
        float line_width = 0.0f;

        const bool word_wrap_enabled = (wrap_width > 0.0f);
        size_t word_wrap_eol = 0;

        size_t s = 0;
        while (s < text.length)
        {
            if (word_wrap_enabled)
            {
                // Calculate how far we can render. Requires two passes on the string data but keeps the code simple and not intrusive for what's essentially an uncommon feature.
                if (word_wrap_eol == 0)
                {
                    word_wrap_eol = s + CalcWordWrapPositionA(scale, text[s..$], wrap_width - line_width);
                    if (word_wrap_eol == s) // Wrap_width is too small to fit anything. Force displaying 1 character to minimize the height discontinuity.
                        word_wrap_eol++;    // +1 may not be a character start point in UTF-8 but it's ok because we use s >= word_wrap_eol below
                }

                if (s >= word_wrap_eol)
                {
                    if (text_size.x < line_width)
                        text_size.x = line_width;
                    text_size.y += line_height;
                    line_width = 0.0f;
                    word_wrap_eol = 0;

                    // Wrapping skips upcoming blanks
                    while (s < text.length)
                    {
                        char c = text[s];
                        if (ImCharIsBlankA(c)) { s++; } else if (c == '\n') { s++; break; } else { break; }
                    }
                    continue;
                }
            }

            // Decode and advance source
            size_t prev_s = s;
            uint c = cast(uint)text[s];
            if (c < 0x80)
            {
                s += 1;
            }
            else
            {
                s += ImTextCharFromUtf8(&c, text[s..$]);
                if (c == 0) // Malformed UTF-8?
                    break;
            }

            if (c < 32)
            {
                if (c == '\n')
                {
                    text_size.x = ImMax(text_size.x, line_width);
                    text_size.y += line_height;
                    line_width = 0.0f;
                    continue;
                }
                if (c == '\r')
                    continue;
            }

            const float char_width = (cast(int)c < IndexAdvanceX.Size ? IndexAdvanceX[c] : FallbackAdvanceX) * scale;
            if (line_width + char_width >= max_width)
            {
                s = prev_s;
                break;
            }

            line_width += char_width;
        }

        if (text_size.x < line_width)
            text_size.x = line_width;

        if (line_width > 0 || text_size.y == 0.0f)
            text_size.y += line_height;

        if (remaining)
            *remaining = text[s..$];

        return text_size;
    }
    
    size_t       CalcWordWrapPositionA(float scale, string text, float wrap_width) const
    {
        // Simple word-wrapping for English, not full-featured. Please submit failing cases!
        // FIXME: Much possible improvements (don't cut things like "word !", "word!!!" but cut within "word,,,,", more sensible support for punctuations, support for Unicode punctuations, etc.)

        // For references, possible wrap point marked with ^
        //  "aaa bbb, ccc,ddd. eee   fff. ggg!"
        //      ^    ^    ^   ^   ^__    ^    ^

        // List of hardcoded separators: .,;!?'"

        // Skip extra blanks after a line returns (that includes not counting them in width computation)
        // e.g. "Hello    world" -. "Hello" "World"

        // Cut words that cannot possibly fit within one line.
        // e.g.: "The tropical fish" with ~5 characters worth of width -. "The tr" "opical" "fish"

        float line_width = 0.0f;
        float word_width = 0.0f;
        float blank_width = 0.0f;
        wrap_width /= scale; // We work with unscaled widths to avoid scaling every characters

        size_t word_end = 0;
        size_t prev_word_end = 0;
        bool inside_word = true;

        size_t s = 0;
        while (s < text.length)
        {
            uint c = cast(uint)text[s];
            size_t next_s;
            if (c < 0x80)
                next_s = s + 1;
            else
                next_s = s + ImTextCharFromUtf8(&c, text[s..$]);
            if (c == 0)
                break;

            if (c < 32)
            {
                if (c == '\n')
                {
                    line_width = word_width = blank_width = 0.0f;
                    inside_word = true;
                    s = next_s;
                    continue;
                }
                if (c == '\r')
                {
                    s = next_s;
                    continue;
                }
            }

            const float char_width = (cast(int)c < IndexAdvanceX.Size ? IndexAdvanceX[c] : FallbackAdvanceX);
            if (ImCharIsBlankW(c))
            {
                if (inside_word)
                {
                    line_width += blank_width;
                    blank_width = 0.0f;
                    word_end = s;
                }
                blank_width += char_width;
                inside_word = false;
            }
            else
            {
                word_width += char_width;
                if (inside_word)
                {
                    word_end = next_s;
                }
                else
                {
                    prev_word_end = word_end;
                    line_width += word_width + blank_width;
                    word_width = blank_width = 0.0f;
                }

                // Allow wrapping after punctuation.
                inside_word = !(c == '.' || c == ',' || c == ';' || c == '!' || c == '?' || c == '\"');
            }

            // We ignore blank width at the end of the line (they can be skipped)
            if (line_width + word_width > wrap_width)
            {
                // Words that cannot possibly fit within an entire line will be cut anywhere.
                if (word_width < wrap_width)
                    s = prev_word_end ? prev_word_end : word_end;
                break;
            }

            s = next_s;
        }

        return s;
    }
    
    void              RenderChar(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, ImWchar c) const
    {
        const ImFontGlyph* glyph = FindGlyph(c);
        if (!glyph || !glyph.Visible)
            return;
        float scale = (size >= 0.0f) ? (size / FontSize) : 1.0f;
        pos.x = IM_FLOOR(pos.x + DisplayOffset.x);
        pos.y = IM_FLOOR(pos.y + DisplayOffset.y);
        draw_list.PrimReserve(6, 4);
        draw_list.PrimRectUV(ImVec2(pos.x + glyph.X0 * scale, pos.y + glyph.Y0 * scale), ImVec2(pos.x + glyph.X1 * scale, pos.y + glyph.Y1 * scale), ImVec2(glyph.U0, glyph.V0), ImVec2(glyph.U1, glyph.V1), col);
    }

    void              RenderText(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, const ImVec4/*&*/ clip_rect, string text, float wrap_width = 0.0f, bool cpu_fine_clip = false) const
    {
        // Align to be pixel perfect
        pos.x = IM_FLOOR(pos.x + DisplayOffset.x);
        pos.y = IM_FLOOR(pos.y + DisplayOffset.y);
        float x = pos.x;
        float y = pos.y;
        if (y > clip_rect.w)
            return;

        const float scale = size / FontSize;
        const float line_height = FontSize * scale;
        const bool word_wrap_enabled = (wrap_width > 0.0f);
        size_t word_wrap_eol = 0;

        // Fast-forward to first visible line
        size_t s = 0;
        if (y + line_height < clip_rect.y && !word_wrap_enabled)
            while (y + line_height < clip_rect.y && s < text.length)
            {
                ptrdiff_t index = ImIndexOf(text[s..$], '\n'); // TODO D_IMGUI replace indexof
                s = index >= 0 ? index + s + 1 : text.length;
                y += line_height;
            }

        // For large text, scan for the last visible line in order to avoid over-reserving in the call to PrimReserve()
        // Note that very large horizontal line will still be affected by the issue (e.g. a one megabyte string buffer without a newline will likely crash atm)
        if (text.length - s > 10000 && !word_wrap_enabled)
        {
            size_t s_end = s;
            float y_end = y;
            while (y_end < clip_rect.w && s_end < text.length)
            {
                ptrdiff_t index = ImIndexOf(text[s_end..$], '\n'); // TODO D_IMGUI replace indexof
                s_end = index >= 0 ? s_end + index + 1 : text.length;
                y_end += line_height;
            }
            text = text[0..s_end];
        }
        if (s == text.length)
            return;

        // Reserve vertices for remaining worse case (over-reserving is useful and easily amortized)
        const int vtx_count_max = cast(int)(text.length - s) * 4;
        const int idx_count_max = cast(int)(text.length - s) * 6;
        const int idx_expected_size = draw_list.IdxBuffer.Size + idx_count_max;
        draw_list.PrimReserve(idx_count_max, vtx_count_max);

        ImDrawVert* vtx_write = draw_list._VtxWritePtr;
        ImDrawIdx* idx_write = draw_list._IdxWritePtr;
        uint vtx_current_idx = draw_list._VtxCurrentIdx;

        while (s < text.length)
        {
            if (word_wrap_enabled)
            {
                // Calculate how far we can render. Requires two passes on the string data but keeps the code simple and not intrusive for what's essentially an uncommon feature.
                if (!word_wrap_eol)
                {
                    word_wrap_eol = s + CalcWordWrapPositionA(scale, text[s..$], wrap_width - (x - pos.x));
                    if (word_wrap_eol == s) // Wrap_width is too small to fit anything. Force displaying 1 character to minimize the height discontinuity.
                        word_wrap_eol++;    // +1 may not be a character start point in UTF-8 but it's ok because we use s >= word_wrap_eol below
                }

                if (s >= word_wrap_eol)
                {
                    x = pos.x;
                    y += line_height;
                    word_wrap_eol = 0;

                    // Wrapping skips upcoming blanks
                    while (s < text.length)
                    {
                        char c = text[s];
                        if (ImCharIsBlankA(c)) { s++; } else if (c == '\n') { s++; break; } else { break; }
                    }
                    continue;
                }
            }

            // Decode and advance source
            uint c = cast(uint)text[s];
            if (c < 0x80)
            {
                s += 1;
            }
            else
            {
                s += ImTextCharFromUtf8(&c, text[s..$]);
                if (c == 0) // Malformed UTF-8?
                    break;
            }

            if (c < 32)
            {
                if (c == '\n')
                {
                    x = pos.x;
                    y += line_height;
                    if (y > clip_rect.w)
                        break; // break out of main loop
                    continue;
                }
                if (c == '\r')
                    continue;
            }

            const ImFontGlyph* glyph = FindGlyph(cast(ImWchar)c);
            if (glyph == NULL)
                continue;

            float char_width = glyph.AdvanceX * scale;
            if (glyph.Visible)
            {
                // We don't do a second finer clipping test on the Y axis as we've already skipped anything before clip_rect.y and exit once we pass clip_rect.w
                float x1 = x + glyph.X0 * scale;
                float x2 = x + glyph.X1 * scale;
                float y1 = y + glyph.Y0 * scale;
                float y2 = y + glyph.Y1 * scale;
                if (x1 <= clip_rect.z && x2 >= clip_rect.x) {
                    // Render a character
                    float u1 = glyph.U0;
                    float v1 = glyph.V0;
                    float u2 = glyph.U1;
                    float v2 = glyph.V1;

                    // CPU side clipping used to fit text in their frame when the frame is too small. Only does clipping for axis aligned quads.
                    if (cpu_fine_clip)
                    {
                        if (x1 < clip_rect.x)
                        {
                            u1 = u1 + (1.0f - (x2 - clip_rect.x) / (x2 - x1)) * (u2 - u1);
                            x1 = clip_rect.x;
                        }
                        if (y1 < clip_rect.y)
                        {
                            v1 = v1 + (1.0f - (y2 - clip_rect.y) / (y2 - y1)) * (v2 - v1);
                            y1 = clip_rect.y;
                        }
                        if (x2 > clip_rect.z)
                        {
                            u2 = u1 + ((clip_rect.z - x1) / (x2 - x1)) * (u2 - u1);
                            x2 = clip_rect.z;
                        }
                        if (y2 > clip_rect.w)
                        {
                            v2 = v1 + ((clip_rect.w - y1) / (y2 - y1)) * (v2 - v1);
                            y2 = clip_rect.w;
                        }
                        if (y1 >= y2)
                        {
                            x += char_width;
                            continue;
                        }
                    }

                    // We are NOT calling PrimRectUV() here because non-inlined causes too much overhead in a debug builds. Inlined here:
                    {
                        idx_write[0] = cast(ImDrawIdx)(vtx_current_idx); idx_write[1] = cast(ImDrawIdx)(vtx_current_idx+1); idx_write[2] = cast(ImDrawIdx)(vtx_current_idx+2);
                        idx_write[3] = cast(ImDrawIdx)(vtx_current_idx); idx_write[4] = cast(ImDrawIdx)(vtx_current_idx+2); idx_write[5] = cast(ImDrawIdx)(vtx_current_idx+3);
                        vtx_write[0].pos.x = x1; vtx_write[0].pos.y = y1; vtx_write[0].col = col; vtx_write[0].uv.x = u1; vtx_write[0].uv.y = v1;
                        vtx_write[1].pos.x = x2; vtx_write[1].pos.y = y1; vtx_write[1].col = col; vtx_write[1].uv.x = u2; vtx_write[1].uv.y = v1;
                        vtx_write[2].pos.x = x2; vtx_write[2].pos.y = y2; vtx_write[2].col = col; vtx_write[2].uv.x = u2; vtx_write[2].uv.y = v2;
                        vtx_write[3].pos.x = x1; vtx_write[3].pos.y = y2; vtx_write[3].col = col; vtx_write[3].uv.x = u1; vtx_write[3].uv.y = v2;
                        vtx_write += 4;
                        vtx_current_idx += 4;
                        idx_write += 6;
                    }
                }
            }

            x += char_width;
        }

        // Give back unused vertices (clipped ones, blanks) ~ this is essentially a PrimUnreserve() action.
        draw_list.VtxBuffer.Size = cast(int)(vtx_write - draw_list.VtxBuffer.Data); // Same as calling shrink()
        draw_list.IdxBuffer.Size = cast(int)(idx_write - draw_list.IdxBuffer.Data);
        draw_list.CmdBuffer[draw_list.CmdBuffer.Size-1].ElemCount -= (idx_expected_size - draw_list.IdxBuffer.Size);
        draw_list._VtxWritePtr = vtx_write;
        draw_list._IdxWritePtr = idx_write;
        draw_list._VtxCurrentIdx = vtx_current_idx;
    }

    // [Internal] Don't use!
    void              BuildLookupTable()
    {
        int max_codepoint = 0;
        for (int i = 0; i != Glyphs.Size; i++)
            max_codepoint = ImMax(max_codepoint, cast(int)Glyphs[i].Codepoint);

        // Build lookup table
        IM_ASSERT(Glyphs.Size < 0xFFFF); // -1 is reserved
        IndexAdvanceX.clear();
        IndexLookup.clear();
        DirtyLookupTables = false;
        memset(Used4kPagesMap.ptr, 0, (Used4kPagesMap).sizeof);
        GrowIndex(max_codepoint + 1);
        for (int i = 0; i < Glyphs.Size; i++)
        {
            int codepoint = cast(int)Glyphs[i].Codepoint;
            IndexAdvanceX[codepoint] = Glyphs[i].AdvanceX;
            IndexLookup[codepoint] = cast(ImWchar)i;
            
            // Mark 4K page as used
            const int page_n = codepoint / 4096;
            Used4kPagesMap[page_n >> 3] |= 1 << (page_n & 7);
        }

        // Create a glyph to handle TAB
        // FIXME: Needs proper TAB handling but it needs to be contextualized (or we could arbitrary say that each string starts at "column 0" ?)
        if (FindGlyph(cast(ImWchar)' '))
        {
            if (Glyphs.back().Codepoint != '\t')   // So we can call this function multiple times (FIXME: Flaky)
                Glyphs.resize(Glyphs.Size + 1);
            ImFontGlyph* tab_glyph = &Glyphs.back();
            *tab_glyph = *FindGlyph(cast(ImWchar)' ');
            tab_glyph.Codepoint = '\t';
            tab_glyph.AdvanceX *= IM_TABSIZE;
            IndexAdvanceX[cast(int)tab_glyph.Codepoint] = cast(float)tab_glyph.AdvanceX;
            IndexLookup[cast(int)tab_glyph.Codepoint] = cast(ImWchar)(Glyphs.Size-1);
        }

        // Mark special glyphs as not visible (note that AddGlyph already mark as non-visible glyphs with zero-size polygons)
        SetGlyphVisible(cast(ImWchar)' ', false);
        SetGlyphVisible(cast(ImWchar)'\t', false);

        // Setup fall-backs
        FallbackGlyph = FindGlyphNoFallback(FallbackChar);
        FallbackAdvanceX = FallbackGlyph ? FallbackGlyph.AdvanceX : 0.0f;
        for (int i = 0; i < max_codepoint + 1; i++)
            if (IndexAdvanceX[i] < 0.0f)
                IndexAdvanceX[i] = FallbackAdvanceX;
    }
    
    void              ClearOutputData()
    {
        FontSize = 0.0f;
        FallbackAdvanceX = 0.0f;
        Glyphs.clear();
        IndexAdvanceX.clear();
        IndexLookup.clear();
        FallbackGlyph = NULL;
        ContainerAtlas = NULL;
        DirtyLookupTables = true;
        Ascent = Descent = 0.0f;
        MetricsTotalSurface = 0;
    }
    
    void              GrowIndex(int new_size)
    {
        IM_ASSERT(IndexAdvanceX.Size == IndexLookup.Size);
        if (new_size <= IndexLookup.Size)
            return;
        IndexAdvanceX.resize(new_size, -1.0f);
        IndexLookup.resize(new_size, cast(ImWchar)-1);
    }
    
    void              AddGlyph(ImWchar codepoint, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float advance_x)
    {
        Glyphs.resize(Glyphs.Size + 1);
        ImFontGlyph* glyph = &Glyphs.back();
        glyph.Codepoint = cast(uint)codepoint;
        glyph.Visible = (x0 != x1) && (y0 != y1);
        glyph.X0 = x0;
        glyph.Y0 = y0;
        glyph.X1 = x1;
        glyph.Y1 = y1;
        glyph.U0 = u0;
        glyph.V0 = v0;
        glyph.U1 = u1;
        glyph.V1 = v1;
        glyph.AdvanceX = advance_x + ConfigData.GlyphExtraSpacing.x;  // Bake spacing into AdvanceX

        if (ConfigData.PixelSnapH)
            glyph.AdvanceX = IM_ROUND(glyph.AdvanceX);

        // Compute rough surface usage metrics (+1 to account for average padding, +0.99 to round)
        DirtyLookupTables = true;
        MetricsTotalSurface += cast(int)((glyph.U1 - glyph.U0) * ContainerAtlas.TexWidth + 1.99f) * cast(int)((glyph.V1 - glyph.V0) * ContainerAtlas.TexHeight + 1.99f);
    }
    
    void              AddRemapChar(ImWchar dst, ImWchar src, bool overwrite_dst = true) // Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
    {
        IM_ASSERT(IndexLookup.Size > 0);    // Currently this can only be called AFTER the font has been built, aka after calling ImFontAtlas.GetTexDataAs*() function.
        uint index_size = cast(uint)IndexLookup.Size;

        if (dst < index_size && IndexLookup.Data[dst] == cast(ImWchar)-1 && !overwrite_dst) // 'dst' already exists
            return;
        if (src >= index_size && dst >= index_size) // both 'dst' and 'src' don't exist . no-op
            return;

        GrowIndex(dst + 1);
        IndexLookup[dst] = (src < index_size) ? IndexLookup.Data[src] : cast(ImWchar)-1;
        IndexAdvanceX[dst] = (src < index_size) ? IndexAdvanceX.Data[src] : 1.0f;
    }
    
    void              SetGlyphVisible(ImWchar c, bool visible)
    {
        if (ImFontGlyph* glyph = cast(ImFontGlyph*)FindGlyph(cast(ImWchar)c))
            glyph.Visible = visible ? 1 : 0;
    }
    
    void              SetFallbackChar(ImWchar c)
    {
        FallbackChar = c;
        BuildLookupTable();
    }
    
    bool              IsGlyphRangeUnused(uint c_begin, uint c_last)
    {
        uint page_begin = (c_begin / 4096);
        uint page_last = (c_last / 4096);
        for (uint page_n = page_begin; page_n <= page_last; page_n++)
            if ((page_n >> 3) < (Used4kPagesMap).sizeof)
                if (Used4kPagesMap[page_n >> 3] & (1 << (page_n & 7)))
                    return false;
        return true;
    }
}

// #if defined(__clang__)
// #pragma clang diagnostic pop
// #elif defined(__GNUC__)
// #pragma GCC diagnostic pop
// #endif

// Include imgui_user.h at the end of imgui.h (convenient for user to only explicitly include vanilla imgui.h)
// #ifdef IMGUI_INCLUDE_IMGUI_USER_H
// #include "imgui_user.h"
// #endif

// #endif // #ifndef IMGUI_DISABLE
