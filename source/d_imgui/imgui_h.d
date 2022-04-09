// dear imgui, v1.85
// (headers)
module d_imgui.imgui_h;

// Help:
// - Read FAQ at http://dearimgui.org/faq
// - Newcomers, read 'Programmer guide' in imgui.cpp for notes on how to setup Dear ImGui in your codebase.
// - Call and read ImGui::ShowDemoWindow() in imgui_demo.cpp. All applications in examples/ are doing that.
// Read imgui.cpp for details, links and comments.

// Resources:
// - FAQ                   http://dearimgui.org/faq
// - Homepage & latest     https://github.com/ocornut/imgui
// - Releases & changelog  https://github.com/ocornut/imgui/releases
// - Gallery               https://github.com/ocornut/imgui/issues/4451 (please post your screenshots/video there!)
// - Wiki                  https://github.com/ocornut/imgui/wiki (lots of good stuff there)
// - Glossary              https://github.com/ocornut/imgui/wiki/Glossary
// - Issues & support      https://github.com/ocornut/imgui/issues

// Getting Started?
// - For first-time users having issues compiling/linking/running or issues loading fonts:
//   please post in https://github.com/ocornut/imgui/discussions if you cannot find a solution in resources above.

/*

Index of this file:
// [SECTION] Header mess
// [SECTION] Forward declarations and basic types
// [SECTION] Dear ImGui end-user API functions
// [SECTION] Flags & Enumerations
// [SECTION] Helpers: Memory allocations macros, ImVector<>
// [SECTION] ImGuiStyle
// [SECTION] ImGuiIO
// [SECTION] Misc data structures (ImGuiInputTextCallbackData, ImGuiSizeCallbackData, ImGuiPayload, ImGuiTableSortSpecs, ImGuiTableColumnSortSpecs)
// [SECTION] Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, ImColor)
// [SECTION] Drawing API (ImDrawCallback, ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawFlags, ImDrawListFlags, ImDrawList, ImDrawData)
// [SECTION] Font API (ImFontConfig, ImFontGlyph, ImFontGlyphRangesBuilder, ImFontAtlasFlags, ImFontAtlas, ImFont)
// [SECTION] Viewports (ImGuiViewportFlags, ImGuiViewport)
// [SECTION] Obsolete functions and types

*/

// #pragma once

// Configuration file with compile-time options (edit imconfig.h or '#define IMGUI_USER_CONFIG "myfilename.h" from your build system')
// #ifdef IMGUI_USER_CONFIG
// #include IMGUI_USER_CONFIG
// #endif
// #if !defined(IMGUI_DISABLE_INCLUDE_IMCONFIG_H) || defined(IMGUI_INCLUDE_IMCONFIG_H)
import d_imgui.imconfig;
// #endif

// #ifndef IMGUI_DISABLE

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

// Includes
// #include <float.h>                  // FLT_MIN, FLT_MAX
immutable float FLT_MIN = float.min_normal;
immutable float FLT_MAX = float.max;
immutable float DBL_MAX = double.max;
immutable int INT_MIN = int.min;
immutable int INT_MAX = int.max;
immutable uint UINT_MAX = uint.max;
immutable long LLONG_MIN = long.min;
immutable long LLONG_MAX = long.max;
immutable ulong ULLONG_MAX = ulong.max;
import d_snprintf.vararg;                 // va_list, va_start, va_end
// #include <stddef.h>                 // ptrdiff_t, NULL
enum NULL = null;
// #include <string.h>                 // memset, memmove, memcpy, strlen, strchr, strcpy, strcmp
public import core.stdc.string : memset, memmove, memcpy, memcmp, strncmp;
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
enum IMGUI_VERSION              = "1.85";
enum IMGUI_VERSION_NUM          = 18500;
pragma(inline, true) void IMGUI_CHECKVERSION()        { DebugCheckVersionAndDataLayout(IMGUI_VERSION, sizeof!(ImGuiIO), sizeof!(ImGuiStyle), sizeof!(ImVec2), sizeof!(ImVec4), sizeof!(ImDrawVert), sizeof!(ImDrawIdx));}
version = IMGUI_HAS_TABLE;

pragma(inline, true) int sizeof(T)() {return cast(int)T.sizeof;}
pragma(inline, true) int sizeof(T)(T t) {return cast(int)T.sizeof;}
pragma(inline, true) void* memset(T)(T[] arr, int i, size_t count) { return memset(arr.ptr, i, count); }
pragma(inline, true) void* memcpy(T)(T[] dst, const T[] src, size_t count) { return memcpy(dst.ptr, src.ptr, count); }
pragma(inline, true) void* memcpy(T)(T[] dst, const void* src, size_t count) { return memcpy(dst.ptr, src, count); }
pragma(inline, true) int memcmp(T)(const T[] lhs, const T[] rhs, size_t count) { return memcmp(lhs.ptr, rhs.ptr, count); }
pragma(inline, true) int memcmp(T)(const T[] lhs, const void* rhs, size_t count) { return memcmp(lhs.ptr, rhs, count); }
pragma(inline, true) size_t strlen(const char[] str) { return ImCstring(str).length; }
pragma(inline, true) int strcmp(const char[] a, const char[] b) { return strncmp(a.ptr, b.ptr, ImMin(a.length, b.length)); }

// Define attributes of all API symbols declarations (e.g. for DLL under Windows)
// IMGUI_API is used for core imgui functions, IMGUI_IMPL_API is used for the default backends files (imgui_impl_xxx.h)
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
pragma(inline, true) int IM_ARRAYSIZE(T, size_t N)(T[N] _ARR) { return cast(int)N;}       // Size of a static C-style array. Don't use on pointers!
pragma(inline, true) void IM_UNUSED(T)(T _VAR) {}                              // Used to silence "unused variable warnings". Often useful as asserts may be stripped out from final builds.
/+
#if (__cplusplus >= 201100) || (defined(_MSVC_LANG) && _MSVC_LANG >= 201100)
#define IM_OFFSETOF(_TYPE,_MEMBER)  offsetof(_TYPE, _MEMBER)                    // Offset of _MEMBER within _TYPE. Standardized as offsetof() in C++11
#else
#define IM_OFFSETOF(_TYPE,_MEMBER)  (cast(size_t)&(((_TYPE*)0)._MEMBER))           // Offset of _MEMBER within _TYPE. Old style macro.
#endif
+/

// Helper Macros - IM_FMTARGS, IM_FMTLIST: Apply printf-style warnings to our formatting functions.
/+
#if !defined(IMGUI_USE_STB_SPRINTF) && defined(__MINGW32__) && !defined(__clang__)
#define IM_FMTARGS(FMT)             __attribute__((format(gnu_printf, FMT, FMT+1)))
#define IM_FMTLIST(FMT)             __attribute__((format(gnu_printf, FMT, 0)))
#elif !defined(IMGUI_USE_STB_SPRINTF) && (defined(__clang__) || defined(__GNUC__))
#define IM_FMTARGS(FMT)             __attribute__((format(printf, FMT, FMT+1)))
#define IM_FMTLIST(FMT)             __attribute__((format(printf, FMT, 0)))
#else
#define IM_FMTARGS(FMT)
#define IM_FMTLIST(FMT)
#endif
+/

// Disable some of MSVC most aggressive Debug runtime checks in function header/footer (used in some simple/low-level functions)
/+
#if defined(_MSC_VER) && !defined(__clang__) && !defined(IMGUI_DEBUG_PARANOID)
#define IM_MSVC_RUNTIME_CHECKS_OFF      __pragma(runtime_checks("",off))     __pragma(check_stack(off)) __pragma(strict_gs_check(push,off))
#define IM_MSVC_RUNTIME_CHECKS_RESTORE  __pragma(runtime_checks("",restore)) __pragma(check_stack())    __pragma(strict_gs_check(pop))
#else
#define IM_MSVC_RUNTIME_CHECKS_OFF
#define IM_MSVC_RUNTIME_CHECKS_RESTORE
#endif
+/

// Warnings
/+
#ifdef _MSC_VER
#pragma warning (push)
#pragma warning (disable: 26495)    // [Static Analyzer] Variable 'XXX' is uninitialized. Always initialize a member variable (type.6).
#endif
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wold-style-cast"
#if __has_warning("-Wzero-as-null-pointer-constant")
#pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
#endif
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpragmas"          // warning: unknown option after '#pragma GCC diagnostic' kind
#pragma GCC diagnostic ignored "-Wclass-memaccess"  // [__GNUC__ >= 8] warning: 'memset/memcpy' clearing/writing an object of type 'xxxx' with no trivial copy-assignment; use assignment or value-initialization instead
#endif
+/

//-----------------------------------------------------------------------------
// [SECTION] Forward declarations and basic types
//-----------------------------------------------------------------------------

// Forward declarations
/+
struct ImDrawChannel;               // Temporary storage to output draw commands out of order, used by ImDrawListSplitter and ImDrawList::ChannelsSplit()
struct ImDrawCmd;                   // A single draw command within a parent ImDrawList (generally maps to 1 GPU draw call, unless it is a callback)
struct ImDrawData;                  // All draw command lists required to render the frame + pos/size coordinates to use for the projection matrix.
struct ImDrawList;                  // A single draw command list (generally one per window, conceptually you may see this as a dynamic "mesh" builder)
struct ImDrawListSharedData;        // Data shared among multiple draw lists (typically owned by parent ImGui context, but you may create one yourself)
struct ImDrawListSplitter;          // Helper to split a draw list into different layers which can be drawn into out of order, then flattened back.
struct ImDrawVert;                  // A single vertex (pos + uv + col = 20 bytes by default. Override layout with IMGUI_OVERRIDE_DRAWVERT_STRUCT_LAYOUT)
struct ImFont;                      // Runtime data for a single font within a parent ImFontAtlas
struct ImFontAtlas;                 // Runtime data for multiple fonts, bake multiple fonts into a single texture, TTF/OTF font loader
struct ImFontBuilderIO;             // Opaque interface to a font builder (stb_truetype or FreeType).
struct ImFontConfig;                // Configuration data when adding a font or merging fonts
struct ImFontGlyph;                 // A single font glyph (code point + coordinates within in ImFontAtlas + offset)
struct ImFontGlyphRangesBuilder;    // Helper to build glyph ranges from text/string data
struct ImColor;                     // Helper functions to create a color that can be converted to either u32 or float4 (*OBSOLETE* please avoid using)
struct ImGuiContext;                // Dear ImGui context (opaque structure, unless including imgui_internal.h)
struct ImGuiIO;                     // Main configuration and I/O between your application and ImGui
struct ImGuiInputTextCallbackData;  // Shared state of InputText() when using custom ImGuiInputTextCallback (rare/advanced use)
struct ImGuiListClipper;            // Helper to manually clip large list of items
struct ImGuiOnceUponAFrame;         // Helper for running a block of code not more than once a frame, used by IMGUI_ONCE_UPON_A_FRAME macro
struct ImGuiPayload;                // User data payload for drag and drop operations
struct ImGuiSizeCallbackData;       // Callback data when using SetNextWindowSizeConstraints() (rare/advanced use)
struct ImGuiStorage;                // Helper for key->value storage
struct ImGuiStyle;                  // Runtime data for styling/colors
struct ImGuiTableSortSpecs;         // Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
struct ImGuiTableColumnSortSpecs;   // Sorting specification for one column of a table
struct ImGuiTextBuffer;             // Helper to hold and append into a text buffer (~string builder)
struct ImGuiTextFilter;             // Helper to parse and apply text filters (e.g. "aaaaa[,bbbbb][,ccccc]")
struct ImGuiViewport;               // A Platform Window (always only one in 'master' branch), in the future may represent Platform Monitor
+/

// Enums/Flags (declared as int for compatibility with old C++, to allow using as flags without overhead, and to not pollute the top of this file)
// - Tip: Use your programming IDE navigation facilities on the names in the _central column_ below to find the actual flags/enum lists!
//   In Visual Studio IDE: CTRL+comma ("Edit.NavigateTo") can follow symbols in comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   With Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols in comments.
/+
typedef int ImGuiCol;               // -> enum ImGuiCol_             // Enum: A color identifier for styling
typedef int ImGuiCond;              // -> enum ImGuiCond_            // Enum: A condition for many Set*() functions
typedef int ImGuiDataType;          // -> enum ImGuiDataType_        // Enum: A primary data type
typedef int ImGuiDir;               // -> enum ImGuiDir_             // Enum: A cardinal direction
typedef int ImGuiKey;               // -> enum ImGuiKey_             // Enum: A key identifier (ImGui-side enum)
typedef int ImGuiNavInput;          // -> enum ImGuiNavInput_        // Enum: An input identifier for navigation
typedef int ImGuiMouseButton;       // -> enum ImGuiMouseButton_     // Enum: A mouse button identifier (0=left, 1=right, 2=middle)
typedef int ImGuiMouseCursor;       // -> enum ImGuiMouseCursor_     // Enum: A mouse cursor identifier
typedef int ImGuiSortDirection;     // -> enum ImGuiSortDirection_   // Enum: A sorting direction (ascending or descending)
typedef int ImGuiStyleVar;          // -> enum ImGuiStyleVar_        // Enum: A variable identifier for styling
typedef int ImGuiTableBgTarget;     // -> enum ImGuiTableBgTarget_   // Enum: A color target for TableSetBgColor()
typedef int ImDrawFlags;            // -> enum ImDrawFlags_          // Flags: for ImDrawList functions
typedef int ImDrawListFlags;        // -> enum ImDrawListFlags_      // Flags: for ImDrawList instance
typedef int ImFontAtlasFlags;       // -> enum ImFontAtlasFlags_     // Flags: for ImFontAtlas build
typedef int ImGuiBackendFlags;      // -> enum ImGuiBackendFlags_    // Flags: for io.BackendFlags
typedef int ImGuiButtonFlags;       // -> enum ImGuiButtonFlags_     // Flags: for InvisibleButton()
typedef int ImGuiColorEditFlags;    // -> enum ImGuiColorEditFlags_  // Flags: for ColorEdit4(), ColorPicker4() etc.
typedef int ImGuiConfigFlags;       // -> enum ImGuiConfigFlags_     // Flags: for io.ConfigFlags
typedef int ImGuiComboFlags;        // -> enum ImGuiComboFlags_      // Flags: for BeginCombo()
typedef int ImGuiDragDropFlags;     // -> enum ImGuiDragDropFlags_   // Flags: for BeginDragDropSource(), AcceptDragDropPayload()
typedef int ImGuiFocusedFlags;      // -> enum ImGuiFocusedFlags_    // Flags: for IsWindowFocused()
typedef int ImGuiHoveredFlags;      // -> enum ImGuiHoveredFlags_    // Flags: for IsItemHovered(), IsWindowHovered() etc.
typedef int ImGuiInputTextFlags;    // -> enum ImGuiInputTextFlags_  // Flags: for InputText(), InputTextMultiline()
typedef int ImGuiKeyModFlags;       // -> enum ImGuiKeyModFlags_     // Flags: for io.KeyMods (Ctrl/Shift/Alt/Super)
typedef int ImGuiPopupFlags;        // -> enum ImGuiPopupFlags_      // Flags: for OpenPopup*(), BeginPopupContext*(), IsPopupOpen()
typedef int ImGuiSelectableFlags;   // -> enum ImGuiSelectableFlags_ // Flags: for Selectable()
typedef int ImGuiSliderFlags;       // -> enum ImGuiSliderFlags_     // Flags: for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
typedef int ImGuiTabBarFlags;       // -> enum ImGuiTabBarFlags_     // Flags: for BeginTabBar()
typedef int ImGuiTabItemFlags;      // -> enum ImGuiTabItemFlags_    // Flags: for BeginTabItem()
typedef int ImGuiTableFlags;        // -> enum ImGuiTableFlags_      // Flags: For BeginTable()
typedef int ImGuiTableColumnFlags;  // -> enum ImGuiTableColumnFlags_// Flags: For TableSetupColumn()
typedef int ImGuiTableRowFlags;     // -> enum ImGuiTableRowFlags_   // Flags: For TableNextRow()
typedef int ImGuiTreeNodeFlags;     // -> enum ImGuiTreeNodeFlags_   // Flags: for TreeNode(), TreeNodeEx(), CollapsingHeader()
typedef int ImGuiViewportFlags;     // -> enum ImGuiViewportFlags_   // Flags: for ImGuiViewport
typedef int ImGuiWindowFlags;       // -> enum ImGuiWindowFlags_     // Flags: for Begin(), BeginChild()
+/

// ImTexture: user data for renderer backend to identify a texture [Compile-time configurable type]
// - To use something else than an opaque void* pointer: override with e.g. '#define ImTextureID MyTextureType*' in your imconfig.h file.
// - This can be whatever to you want it to be! read the FAQ about ImTextureID for details.
//#ifndef ImTextureID
//typedef void* ImTextureID;          // Default: store a pointer or an integer fitting in a pointer (most renderer backends are ok with that)
//#endif

// ImDrawIdx: vertex index. [Compile-time configurable type]
// - To use 16-bit indices + allow large meshes: backend need to set 'io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset' and handle ImDrawCmd::VtxOffset (recommended).
// - To use 32-bit indices: override with '#define ImDrawIdx unsigned int' in your imconfig.h file.
// TODO D_IMGUI add to imconfig
//#ifndef ImDrawIdx
alias ImDrawIdx = ushort;   // Default: 16-bit (for maximum compatibility with renderer backends)
//#endif

// Scalar data types
alias ImGuiID = uint;// A unique ID used by widgets (typically the result of hashing a stack of string)
alias ImS8 = byte;   // 8-bit signed integer
alias ImU8 = ubyte;   // 8-bit unsigned integer
alias ImS16 = short;  // 16-bit signed integer
alias ImU16 = ushort;  // 16-bit unsigned integer
alias ImS32 = int;  // 32-bit signed integer == int
alias ImU32 = uint;  // 32-bit unsigned integer (often used to store packed colors)
alias ImS64 = long;  // 64-bit signed integer
alias ImU64 = ulong;  // 64-bit unsigned integer

// Character types
// (we generally use UTF-8 encoded string in the API. This is storage specifically for a decoded character used for keyboard input and display)
alias ImWchar16 = ushort;   // A single decoded U16 character/code point. We encode them as multi bytes UTF-8 when used in strings.
alias ImWchar32 = uint;     // A single decoded U32 character/code point. We encode them as multi bytes UTF-8 when used in strings.
static if (IMGUI_USE_WCHAR32) {            // ImWchar [configurable type: override in imconfig.h with '#define IMGUI_USE_WCHAR32' to support Unicode planes 1-16]
alias ImWchar = ImWchar32;
} else {
}
alias ImWchar = ImWchar16; // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905

// Callback and functions types
alias ImGuiInputTextCallback = int function(ImGuiInputTextCallbackData* data);    // Callback function for ImGui::InputText()
alias ImGuiSizeCallback = void function(ImGuiSizeCallbackData* data);              // Callback function for ImGui::SetNextWindowSizeConstraints()
alias ImGuiMemAllocFunc = void* function(size_t sz, void* user_data);               // Function signature for ImGui::SetAllocatorFunctions()
alias ImGuiMemFreeFunc = void function(void* ptr, void* user_data);                // Function signature for ImGui::SetAllocatorFunctions()

// ImVec2: 2D vector used to store positions, sizes etc. [Compile-time configurable type]
// This is a frequently used type in the API. Consider using IM_VEC2_CLASS_EXTRA to create implicit cast from/to our preferred type.
// IM_MSVC_RUNTIME_CHECKS_OFF
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

// ImVec4: 4D vector used to store clipping rectangles, colors etc. [Compile-time configurable type]
struct ImVec4
{
    nothrow:
    @nogc:
// IM_MSVC_RUNTIME_CHECKS_RESTORE

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
// [SECTION] Dear ImGui end-user API functions
// (Note that ImGui:: being a namespace, you can add extra ImGui:: functions in your own separate file. Please don't modify imgui source files!)
//-----------------------------------------------------------------------------

/+
namespace ImGui
{
    // Context creation and access
    // - Each context create its own ImFontAtlas by default. You may instance one yourself and pass it to CreateContext() to share a font atlas between contexts.
    // - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
    //   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for details.
    ImGuiContext* CreateContext(ImFontAtlas* shared_font_atlas = NULL);
    void          DestroyContext(ImGuiContext* ctx = NULL);   // NULL = destroy current context
    ImGuiContext* GetCurrentContext();
    void          SetCurrentContext(ImGuiContext* ctx);

    // Main
    ImGuiIO&      GetIO();                                    // access the IO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
    ImGuiStyle&   GetStyle();                                 // access the Style structure (colors, sizes). Always use PushStyleCol(), PushStyleVar() to modify style mid-frame!
    void          NewFrame();                                 // start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
    void          EndFrame();                                 // ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
    void          Render();                                   // ends the Dear ImGui frame, finalize the draw data. You can then get call GetDrawData().
    ImDrawData*   GetDrawData();                              // valid after Render() and until the next call to NewFrame(). this is what you have to render.

    // Demo, Debug, Information
    void          ShowDemoWindow(bool* p_open = NULL);        // create Demo window. demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
    void          ShowMetricsWindow(bool* p_open = NULL);     // create Metrics/Debugger window. display Dear ImGui internals: windows, draw commands, various internal state, etc.
    void          ShowStackToolWindow(bool* p_open = NULL);   // create Stack Tool window. hover items with mouse to query information about the source of their unique ID.
    void          ShowAboutWindow(bool* p_open = NULL);       // create About window. display Dear ImGui version, credits and build/system information.
    void          ShowStyleEditor(ImGuiStyle* ref = NULL);    // add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
    bool          ShowStyleSelector(string label);       // add style selector block (not a window), essentially a combo listing the default styles.
    void          ShowFontSelector(string label);        // add font selector block (not a window), essentially a combo listing the loaded fonts.
    void          ShowUserGuide();                            // add basic help/info block (not a window): how to manipulate ImGui as a end-user (mouse/keyboard controls).
    string   GetVersion();                               // get the compiled version string e.g. "1.80 WIP" (essentially the value for IMGUI_VERSION from the compiled version of imgui.cpp)

    // Styles
    void          StyleColorsDark(ImGuiStyle* dst = NULL);    // new, recommended style (default)
    void          StyleColorsLight(ImGuiStyle* dst = NULL);   // best used with borders and a custom, thicker font
    void          StyleColorsClassic(ImGuiStyle* dst = NULL); // classic imgui style

    // Windows
    // - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
    // - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
    //   which clicking will set the boolean to false when clicked.
    // - You may append multiple times to the same window during the same frame by calling Begin()/End() pairs multiple times.
    //   Some information such as 'flags' or 'p_open' will only be considered by the first call to Begin().
    // - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
    //   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
    //   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
    //    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
    //    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
    // - Note that the bottom of window stack always contains a window called "Debug".
    bool          Begin(string name, bool* p_open = NULL, ImGuiWindowFlags flags = 0);
    void          End();

    // Child Windows
    // - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
    // - For each independent axis of 'size': ==0.0f: use remaining host window size / >0.0f: fixed size / <0.0f: use remaining window size minus abs(size) / Each axis can use a different mode, e.g. ImVec2(0,400).
    // - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.
    //   Always call a matching EndChild() for each BeginChild() call, regardless of its return value.
    //   [Important: due to legacy reason, this is inconsistent with most other functions such as BeginMenu/EndMenu,
    //    BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding BeginXXX function
    //    returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
    bool          BeginChild(string str_id, const ImVec2/*&*/ size = ImVec2(0, 0), bool border = false, ImGuiWindowFlags flags = 0);
    bool          BeginChild(ImGuiID id, const ImVec2/*&*/ size = ImVec2(0, 0), bool border = false, ImGuiWindowFlags flags = 0);
    void          EndChild();

    // Windows Utilities
    // - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
    bool          IsWindowAppearing();
    bool          IsWindowCollapsed();
    bool          IsWindowFocused(ImGuiFocusedFlags flags=0); // is current window focused? or its root/child, depending on flags. see flags for options.
    bool          IsWindowHovered(ImGuiHoveredFlags flags=0); // is current window hovered (and typically: not blocked by a popup/modal)? see flags for options. NB: If you are trying to check whether your mouse should be dispatched to imgui or to your app, you should use the 'io.WantCaptureMouse' boolean for that! Please read the FAQ!
    ImDrawList*   GetWindowDrawList();                        // get draw list associated to the current window, to append your own drawing primitives
    ImVec2        GetWindowPos();                             // get current window position in screen space (useful if you want to do your own drawing via the DrawList API)
    ImVec2        GetWindowSize();                            // get current window size
    float         GetWindowWidth();                           // get current window width (shortcut for GetWindowSize().x)
    float         GetWindowHeight();                          // get current window height (shortcut for GetWindowSize().y)

    // Window manipulation
    // - Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
    void          SetNextWindowPos(const ImVec2/*&*/ pos, ImGuiCond cond = 0, const ImVec2/*&*/ pivot = ImVec2(0, 0)); // set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
    void          SetNextWindowSize(const ImVec2/*&*/ size, ImGuiCond cond = 0);                  // set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
    void          SetNextWindowSizeConstraints(const ImVec2/*&*/ size_min, const ImVec2/*&*/ size_max, ImGuiSizeCallback custom_callback = NULL, void* custom_callback_data = NULL); // set next window size limits. use -1,-1 on either X/Y axis to preserve the current size. Sizes will be rounded down. Use callback to apply non-trivial programmatic constraints.
    void          SetNextWindowContentSize(const ImVec2/*&*/ size);                               // set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
    void          SetNextWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                 // set next window collapsed state. call before Begin()
    void          SetNextWindowFocus();                                                       // set next window to be focused / top-most. call before Begin()
    void          SetNextWindowBgAlpha(float alpha);                                          // set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
    void          SetWindowPos(const ImVec2/*&*/ pos, ImGuiCond cond = 0);                        // (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
    void          SetWindowSize(const ImVec2/*&*/ size, ImGuiCond cond = 0);                      // (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0, 0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
    void          SetWindowCollapsed(bool collapsed, ImGuiCond cond = 0);                     // (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
    void          SetWindowFocus();                                                           // (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
    void          SetWindowFontScale(float scale);                                            // [OBSOLETE] set font scale. Adjust IO.FontGlobalScale if you want to scale all windows. This is an old API! For correct scaling, prefer to reload font + rebuild ImFontAtlas + call style.ScaleAllSizes().
    void          SetWindowPos(string name, const ImVec2/*&*/ pos, ImGuiCond cond = 0);      // set named window position.
    void          SetWindowSize(string name, const ImVec2/*&*/ size, ImGuiCond cond = 0);    // set named window size. set axis to 0.0f to force an auto-fit on this axis.
    void          SetWindowCollapsed(string name, bool collapsed, ImGuiCond cond = 0);   // set named window collapsed state
    void          SetWindowFocus(string name);                                           // set named window to be focused / top-most. use NULL to remove focus.

    // Content region
    // - Retrieve available space from a given point. GetContentRegionAvail() is frequently useful.
    // - Those functions are bound to be redesigned (they are confusing, incomplete and the Min/Max return values are in local window coordinates which increases confusion)
    ImVec2        GetContentRegionAvail();                                        // == GetContentRegionMax() - GetCursorPos()
    ImVec2        GetContentRegionMax();                                          // current content boundaries (typically window boundaries including scrolling, or current column boundaries), in windows coordinates
    ImVec2        GetWindowContentRegionMin();                                    // content boundaries min for the full window (roughly (0,0)-Scroll), in window coordinates
    ImVec2        GetWindowContentRegionMax();                                    // content boundaries max for the full window (roughly (0,0)+Size-Scroll) where Size can be override with SetNextWindowContentSize(), in window coordinates

    // Windows Scrolling
    float         GetScrollX();                                                   // get scrolling amount [0 .. GetScrollMaxX()]
    float         GetScrollY();                                                   // get scrolling amount [0 .. GetScrollMaxY()]
    void          SetScrollX(float scroll_x);                                     // set scrolling amount [0 .. GetScrollMaxX()]
    void          SetScrollY(float scroll_y);                                     // set scrolling amount [0 .. GetScrollMaxY()]
    float         GetScrollMaxX();                                                // get maximum scrolling amount ~~ ContentSize.x - WindowSize.x - DecorationsSize.x
    float         GetScrollMaxY();                                                // get maximum scrolling amount ~~ ContentSize.y - WindowSize.y - DecorationsSize.y
    void          SetScrollHereX(float center_x_ratio = 0.5f);                    // adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void          SetScrollHereY(float center_y_ratio = 0.5f);                    // adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    void          SetScrollFromPosX(float local_x, float center_x_ratio = 0.5f);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
    void          SetScrollFromPosY(float local_y, float center_y_ratio = 0.5f);  // adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.

    // Parameters stacks (shared)
    void          PushFont(ImFont* font);                                         // use NULL as a shortcut to push default font
    void          PopFont();
    void          PushStyleColor(ImGuiCol idx, ImU32 col);                        // modify a style color. always use this if you modify the style after NewFrame().
    void          PushStyleColor(ImGuiCol idx, const ImVec4/*&*/ col);
    void          PopStyleColor(int count = 1);
    void          PushStyleVar(ImGuiStyleVar idx, float val);                     // modify a style float variable. always use this if you modify the style after NewFrame().
    void          PushStyleVar(ImGuiStyleVar idx, const ImVec2/*&*/ val);             // modify a style ImVec2 variable. always use this if you modify the style after NewFrame().
    void          PopStyleVar(int count = 1);
    void          PushAllowKeyboardFocus(bool allow_keyboard_focus);              // == tab stop enable. Allow focusing using TAB/Shift-TAB, enabled by default but you can disable it for certain widgets
    void          PopAllowKeyboardFocus();
    void          PushButtonRepeat(bool repeat);                                  // in 'repeat' mode, Button*() functions return repeated true in a typematic manner (using io.KeyRepeatDelay/io.KeyRepeatRate setting). Note that you can call IsItemActive() after any Button() to tell if the button is held in the current frame.
    void          PopButtonRepeat();

    // Parameters stacks (current window)
    void          PushItemWidth(float item_width);                                // push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side).
    void          PopItemWidth();
    void          SetNextItemWidth(float item_width);                             // set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side)
    float         CalcItemWidth();                                                // width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
    void          PushTextWrapPos(float wrap_local_pos_x = 0.0f);                 // push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
    void          PopTextWrapPos();

    // Style read access
    // - Use the style editor (ShowStyleEditor() function) to interactively see what the colors are)
    ImFont*       GetFont();                                                      // get current font
    float         GetFontSize();                                                  // get current font size (= height in pixels) of current font with current scale applied
    ImVec2        GetFontTexUvWhitePixel();                                       // get UV coordinate for a while pixel, useful to draw custom shapes via the ImDrawList API
    ImU32         GetColorU32(ImGuiCol idx, float alpha_mul = 1.0f);              // retrieve given style color with style alpha applied and optional extra alpha multiplier, packed as a 32-bit value suitable for ImDrawList
    ImU32         GetColorU32(const ImVec4/*&*/ col);                                 // retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    ImU32         GetColorU32(ImU32 col);                                         // retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
    const ImVec4/*&*/ GetStyleColorVec4(ImGuiCol idx);                                // retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.

    // Cursor / Layout
    // - By "cursor" we mean the current output position.
    // - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
    // - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceding widget.
    // - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
    //    Window-local coordinates:   SameLine(), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), GetContentRegionMax(), GetWindowContentRegion*(), PushTextWrapPos()
    //    Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions.
    void          Separator();                                                    // separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
    void          SameLine(float offset_from_start_x=0.0f, float spacing=-1.0f);  // call between widgets or groups to layout them horizontally. X position given in window coordinates.
    void          NewLine();                                                      // undo a SameLine() or force a new line when in an horizontal-layout context.
    void          Spacing();                                                      // add vertical spacing.
    void          Dummy(const ImVec2/*&*/ size);                                      // add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
    void          Indent(float indent_w = 0.0f);                                  // move content position toward the right, by indent_w, or style.IndentSpacing if indent_w <= 0
    void          Unindent(float indent_w = 0.0f);                                // move content position back to the left, by indent_w, or style.IndentSpacing if indent_w <= 0
    void          BeginGroup();                                                   // lock horizontal starting position
    void          EndGroup();                                                     // unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
    ImVec2        GetCursorPos();                                                 // cursor position in window coordinates (relative to window position)
    float         GetCursorPosX();                                                //   (some functions are using window-relative coordinates, such as: GetCursorPos, GetCursorStartPos, GetContentRegionMax, GetWindowContentRegion* etc.
    float         GetCursorPosY();                                                //    other functions such as GetCursorScreenPos or everything in ImDrawList::
    void          SetCursorPos(const ImVec2/*&*/ local_pos);                          //    are using the main, absolute coordinate system.
    void          SetCursorPosX(float local_x);                                   //    GetWindowPos() + GetCursorPos() == GetCursorScreenPos() etc.)
    void          SetCursorPosY(float local_y);                                   //
    ImVec2        GetCursorStartPos();                                            // initial cursor position in window coordinates
    ImVec2        GetCursorScreenPos();                                           // cursor position in absolute coordinates (useful to work with ImDrawList API). generally top-left == GetMainViewport()->Pos == (0,0) in single viewport mode, and bottom-right == GetMainViewport()->Pos+Size == io.DisplaySize in single-viewport mode.
    void          SetCursorScreenPos(const ImVec2/*&*/ pos);                          // cursor position in absolute coordinates
    void          AlignTextToFramePadding();                                      // vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
    float         GetTextLineHeight();                                            // ~ FontSize
    float         GetTextLineHeightWithSpacing();                                 // ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
    float         GetFrameHeight();                                               // ~ FontSize + style.FramePadding.y * 2
    float         GetFrameHeightWithSpacing();                                    // ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)

    // ID stack/scopes
    // Read the FAQ (docs/FAQ.md or http://dearimgui.org/faq) for more details about how ID are handled in dear imgui.
    // - Those questions are answered and impacted by understanding of the ID stack system:
    //   - "Q: Why is my widget not reacting when I click on it?"
    //   - "Q: How can I have widgets with an empty label?"
    //   - "Q: How can I have multiple widgets with the same label?"
    // - Short version: ID are hashes of the entire ID stack. If you are creating widgets in a loop you most likely
    //   want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
    // - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
    // - In this header file we use the "label"/"name" terminology to denote a string that will be displayed + used as an ID,
    //   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
    void          PushID(string str_id);                                     // push string into the ID stack (will hash string).
    void          PushID(string str_id_begin, string str_id_end);       // push string into the ID stack (will hash string).
    void          PushID(const void* ptr_id);                                     // push pointer into the ID stack (will hash pointer).
    void          PushID(int int_id);                                             // push integer into the ID stack (will hash integer).
    void          PopID();                                                        // pop from the ID stack.
    ImGuiID       GetID(string str_id);                                      // calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
    ImGuiID       GetID(string str_id_begin, string str_id_end);
    ImGuiID       GetID(const void* ptr_id);

    // Widgets: Text
    void          TextUnformatted(string text, string text_end = NULL); // raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
    void          Text(string fmt, ...)                                      IM_FMTARGS(1); // formatted text
    void          TextV(string fmt, va_list args)                            IM_FMTLIST(1);
    void          TextColored(const ImVec4/*&*/ col, string fmt, ...)            IM_FMTARGS(2); // shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
    void          TextColoredV(const ImVec4/*&*/ col, string fmt, va_list args)  IM_FMTLIST(2);
    void          TextDisabled(string fmt, ...)                              IM_FMTARGS(1); // shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
    void          TextDisabledV(string fmt, va_list args)                    IM_FMTLIST(1);
    void          TextWrapped(string fmt, ...)                               IM_FMTARGS(1); // shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
    void          TextWrappedV(string fmt, va_list args)                     IM_FMTLIST(1);
    void          LabelText(string label, string fmt, ...)              IM_FMTARGS(2); // display text+label aligned the same way as value+label widgets
    void          LabelTextV(string label, string fmt, va_list args)    IM_FMTLIST(2);
    void          BulletText(string fmt, ...)                                IM_FMTARGS(1); // shortcut for Bullet()+Text()
    void          BulletTextV(string fmt, va_list args)                      IM_FMTLIST(1);

    // Widgets: Main
    // - Most widgets return true when the value has been changed or when pressed/selected
    // - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
    bool          Button(string label, const ImVec2/*&*/ size = ImVec2(0, 0));   // button
    bool          SmallButton(string label);                                 // button with FramePadding=(0,0) to easily embed within text
    bool          InvisibleButton(string str_id, const ImVec2/*&*/ size, ImGuiButtonFlags flags = 0); // flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
    bool          ArrowButton(string str_id, ImGuiDir dir);                  // square button with an arrow shape
    void          Image(ImTextureID user_texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0 = ImVec2(0, 0), const ImVec2/*&*/ uv1 = ImVec2(1,1), const ImVec4/*&*/ tint_col = ImVec4(1,1,1,1), const ImVec4/*&*/ border_col = ImVec4(0,0,0,0));
    bool          ImageButton(ImTextureID user_texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0 = ImVec2(0, 0),  const ImVec2/*&*/ uv1 = ImVec2(1,1), int frame_padding = -1, const ImVec4/*&*/ bg_col = ImVec4(0,0,0,0), const ImVec4/*&*/ tint_col = ImVec4(1,1,1,1));    // <0 frame_padding uses default frame padding settings. 0 for no padding
    bool          Checkbox(string label, bool* v);
    bool          CheckboxFlags(string label, int* flags, int flags_value);
    bool          CheckboxFlags(string label, uint* flags, uint flags_value);
    bool          RadioButton(string label, bool active);                    // use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
    bool          RadioButton(string label, int* v, int v_button);           // shortcut to handle the above pattern when value is an integer
    void          ProgressBar(float fraction, const ImVec2/*&*/ size_arg = ImVec2(-FLT_MIN, 0), string overlay = NULL);
    void          Bullet();                                                       // draw a small circle + keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses

    // Widgets: Combo Box
    // - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
    // - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose. This is analogous to how ListBox are created.
    bool          BeginCombo(string label, string preview_value, ImGuiComboFlags flags = 0);
    void          EndCombo(); // only call EndCombo() if BeginCombo() returns true!
    bool          Combo(string label, int* current_item, string const items[], int items_count, int popup_max_height_in_items = -1);
    bool          Combo(string label, int* current_item, string items_separated_by_zeros, int popup_max_height_in_items = -1);      // Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
    bool          Combo(string label, int* current_item, bool(*items_getter)(void* data, int idx, string* out_text), void* data, int items_count, int popup_max_height_in_items = -1);

    // Widgets: Drag Sliders
    // - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
    // - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every functions, note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    // - Format string may also be set to NULL or use the default format ("%f" or "%d").
    // - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For gamepad/keyboard navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
    // - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits if ImGuiSliderFlags_AlwaysClamp is not used.
    // - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
    // - We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
    // - Legacy: Pre-1.78 there are DragXXX() function signatures that takes a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
    //   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
    bool          DragFloat(string label, float* v, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = 0);     // If v_min >= v_max we have no bound
    bool          DragFloat2(string label, float v[2], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          DragFloat3(string label, float v[3], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          DragFloat4(string label, float v[4], float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          DragFloatRange2(string label, float* v_current_min, float* v_current_max, float v_speed = 1.0f, float v_min = 0.0f, float v_max = 0.0f, string format = "%.3f", string format_max = NULL, ImGuiSliderFlags flags = 0);
    bool          DragInt(string label, int* v, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = 0);  // If v_min >= v_max we have no bound
    bool          DragInt2(string label, int v[2], float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragInt3(string label, int v[3], float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragInt4(string label, int v[4], float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          DragIntRange2(string label, int* v_current_min, int* v_current_max, float v_speed = 1.0f, int v_min = 0, int v_max = 0, string format = "%d", string format_max = NULL, ImGuiSliderFlags flags = 0);
    bool          DragScalar(string label, ImGuiDataType data_type, void* p_data, float v_speed = 1.0f, const void* p_min = NULL, const void* p_max = NULL, string format = NULL, ImGuiSliderFlags flags = 0);
    bool          DragScalarN(string label, ImGuiDataType data_type, void* p_data, int components, float v_speed = 1.0f, const void* p_min = NULL, const void* p_max = NULL, string format = NULL, ImGuiSliderFlags flags = 0);

    // Widgets: Regular Sliders
    // - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
    // - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
    // - Format string may also be set to NULL or use the default format ("%f" or "%d").
    // - Legacy: Pre-1.78 there are SliderXXX() function signatures that takes a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
    //   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
    bool          SliderFloat(string label, float* v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = 0);     // adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display.
    bool          SliderFloat2(string label, float v[2], float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          SliderFloat3(string label, float v[3], float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          SliderFloat4(string label, float v[4], float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          SliderAngle(string label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = +360.0f, string format = "%.0f deg", ImGuiSliderFlags flags = 0);
    bool          SliderInt(string label, int* v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt2(string label, int v[2], int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt3(string label, int v[3], int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderInt4(string label, int v[4], int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          SliderScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format = NULL, ImGuiSliderFlags flags = 0);
    bool          SliderScalarN(string label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, string format = NULL, ImGuiSliderFlags flags = 0);
    bool          VSliderFloat(string label, const ImVec2/*&*/ size, float* v, float v_min, float v_max, string format = "%.3f", ImGuiSliderFlags flags = 0);
    bool          VSliderInt(string label, const ImVec2/*&*/ size, int* v, int v_min, int v_max, string format = "%d", ImGuiSliderFlags flags = 0);
    bool          VSliderScalar(string label, const ImVec2/*&*/ size, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format = NULL, ImGuiSliderFlags flags = 0);

    // Widgets: Input with Keyboard
    // - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
    // - Most of the ImGuiInputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
    bool          InputText(string label, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    bool          InputTextMultiline(string label, char* buf, size_t buf_size, const ImVec2/*&*/ size = ImVec2(0, 0), ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    bool          InputTextWithHint(string label, string hint, char* buf, size_t buf_size, ImGuiInputTextFlags flags = 0, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    bool          InputFloat(string label, float* v, float step = 0.0f, float step_fast = 0.0f, string format = "%.3f", ImGuiInputTextFlags flags = 0);
    bool          InputFloat2(string label, float v[2], string format = "%.3f", ImGuiInputTextFlags flags = 0);
    bool          InputFloat3(string label, float v[3], string format = "%.3f", ImGuiInputTextFlags flags = 0);
    bool          InputFloat4(string label, float v[4], string format = "%.3f", ImGuiInputTextFlags flags = 0);
    bool          InputInt(string label, int* v, int step = 1, int step_fast = 100, ImGuiInputTextFlags flags = 0);
    bool          InputInt2(string label, int v[2], ImGuiInputTextFlags flags = 0);
    bool          InputInt3(string label, int v[3], ImGuiInputTextFlags flags = 0);
    bool          InputInt4(string label, int v[4], ImGuiInputTextFlags flags = 0);
    bool          InputDouble(string label, double* v, double step = 0.0, double step_fast = 0.0, string format = "%.6f", ImGuiInputTextFlags flags = 0);
    bool          InputScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_step = NULL, const void* p_step_fast = NULL, string format = NULL, ImGuiInputTextFlags flags = 0);
    bool          InputScalarN(string label, ImGuiDataType data_type, void* p_data, int components, const void* p_step = NULL, const void* p_step_fast = NULL, string format = NULL, ImGuiInputTextFlags flags = 0);

    // Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
    // - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
    // - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
    bool          ColorEdit3(string label, float col[3], ImGuiColorEditFlags flags = 0);
    bool          ColorEdit4(string label, float col[4], ImGuiColorEditFlags flags = 0);
    bool          ColorPicker3(string label, float col[3], ImGuiColorEditFlags flags = 0);
    bool          ColorPicker4(string label, float col[4], ImGuiColorEditFlags flags = 0, const float* ref_col = NULL);
    bool          ColorButton(string desc_id, const ImVec4/*&*/ col, ImGuiColorEditFlags flags = 0, ImVec2 size = ImVec2(0, 0)); // display a color square/button, hover for details, return true when pressed.
    void          SetColorEditOptions(ImGuiColorEditFlags flags);                     // initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.

    // Widgets: Trees
    // - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
    bool          TreeNode(string label);
    bool          TreeNode(string str_id, string fmt, ...) IM_FMTARGS(2);   // helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
    bool          TreeNode(const void* ptr_id, string fmt, ...) IM_FMTARGS(2);   // "
    bool          TreeNodeV(string str_id, string fmt, va_list args) IM_FMTLIST(2);
    bool          TreeNodeV(const void* ptr_id, string fmt, va_list args) IM_FMTLIST(2);
    bool          TreeNodeEx(string label, ImGuiTreeNodeFlags flags = 0);
    bool          TreeNodeEx(string str_id, ImGuiTreeNodeFlags flags, string fmt, ...) IM_FMTARGS(3);
    bool          TreeNodeEx(const void* ptr_id, ImGuiTreeNodeFlags flags, string fmt, ...) IM_FMTARGS(3);
    bool          TreeNodeExV(string str_id, ImGuiTreeNodeFlags flags, string fmt, va_list args) IM_FMTLIST(3);
    bool          TreeNodeExV(const void* ptr_id, ImGuiTreeNodeFlags flags, string fmt, va_list args) IM_FMTLIST(3);
    void          TreePush(string str_id);                                       // ~ Indent()+PushId(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
    void          TreePush(const void* ptr_id = NULL);                                // "
    void          TreePop();                                                          // ~ Unindent()+PopId()
    float         GetTreeNodeToLabelSpacing();                                        // horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
    bool          CollapsingHeader(string label, ImGuiTreeNodeFlags flags = 0);  // if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
    bool          CollapsingHeader(string label, bool* p_visible, ImGuiTreeNodeFlags flags = 0); // when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
    void          SetNextItemOpen(bool is_open, ImGuiCond cond = 0);                  // set next TreeNode/CollapsingHeader open state.

    // Widgets: Selectables
    // - A selectable highlights when hovered, and can display another color when selected.
    // - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
    bool          Selectable(string label, bool selected = false, ImGuiSelectableFlags flags = 0, const ImVec2/*&*/ size = ImVec2(0, 0)); // "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
    bool          Selectable(string label, bool* p_selected, ImGuiSelectableFlags flags = 0, const ImVec2/*&*/ size = ImVec2(0, 0));      // "bool* p_selected" point to the selection state (read-write), as a convenient helper.

    // Widgets: List Boxes
    // - This is essentially a thin wrapper to using BeginChild/EndChild with some stylistic changes.
    // - The BeginListBox()/EndListBox() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() or any items.
    // - The simplified/old ListBox() api are helpers over BeginListBox()/EndListBox() which are kept available for convenience purpose. This is analoguous to how Combos are created.
    // - Choose frame width:   size.x > 0.0f: custom  /  size.x < 0.0f or -FLT_MIN: right-align   /  size.x = 0.0f (default): use current ItemWidth
    // - Choose frame height:  size.y > 0.0f: custom  /  size.y < 0.0f or -FLT_MIN: bottom-align  /  size.y = 0.0f (default): arbitrary default height which can fit ~7 items
    bool          BeginListBox(string label, const ImVec2/*&*/ size = ImVec2(0, 0)); // open a framed scrolling region
    void          EndListBox();                                                       // only call EndListBox() if BeginListBox() returned true!
    bool          ListBox(string label, int* current_item, string const items[], int items_count, int height_in_items = -1);
    bool          ListBox(string label, int* current_item, bool (*items_getter)(void* data, int idx, string* out_text), void* data, int items_count, int height_in_items = -1);

    // Widgets: Data Plotting
    // - Consider using ImPlot (https://github.com/epezent/implot) which is much better!
    void          PlotLines(string label, const float* values, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof(float));
    void          PlotLines(string label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0));
    void          PlotHistogram(string label, const float* values, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0), int stride = sizeof(float));
    void          PlotHistogram(string label, float(*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, string overlay_text = NULL, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0, 0));

    // Widgets: Value() Helpers.
    // - Those are merely shortcut to calling Text() with a format string. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
    void          Value(string prefix, bool b);
    void          Value(string prefix, int v);
    void          Value(string prefix, uint v);
    void          Value(string prefix, float v, string float_format = NULL);

    // Widgets: Menus
    // - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
    // - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
    // - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
    // - Not that MenuItem() keyboardshortcuts are displayed as a convenience but _not processed_ by Dear ImGui at the moment.
    bool          BeginMenuBar();                                                     // append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
    void          EndMenuBar();                                                       // only call EndMenuBar() if BeginMenuBar() returns true!
    bool          BeginMainMenuBar();                                                 // create and append to a full screen menu-bar.
    void          EndMainMenuBar();                                                   // only call EndMainMenuBar() if BeginMainMenuBar() returns true!
    bool          BeginMenu(string label, bool enabled = true);                  // create a sub-menu entry. only call EndMenu() if this returns true!
    void          EndMenu();                                                          // only call EndMenu() if BeginMenu() returns true!
    bool          MenuItem(string label, string shortcut = NULL, bool selected = false, bool enabled = true);  // return true when activated.
    bool          MenuItem(string label, string shortcut, bool* p_selected, bool enabled = true);              // return true when activated + toggle (*p_selected) if p_selected != NULL

    // Tooltips
    // - Tooltip are windows following the mouse. They do not take focus away.
    void          BeginTooltip();                                                     // begin/append a tooltip window. to create full-featured tooltip (with any kind of items).
    void          EndTooltip();
    void          SetTooltip(string fmt, ...) IM_FMTARGS(1);                     // set a text-only tooltip, typically use with ImGui::IsItemHovered(). override any previous call to SetTooltip().
    void          SetTooltipV(string fmt, va_list args) IM_FMTLIST(1);

    // Popups, Modals
    //  - They block normal mouse hovering detection (and therefore most mouse interactions) behind them.
    //  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    //  - Their visibility state (~bool) is held internally instead of being held by the programmer as we are used to with regular Begin*() calls.
    //  - The 3 properties above are related: we need to retain popup visibility state in the library because popups may be closed as any time.
    //  - You can bypass the hovering restriction by using ImGuiHoveredFlags_AllowWhenBlockedByPopup when calling IsItemHovered() or IsWindowHovered().
    //  - IMPORTANT: Popup identifiers are relative to the current ID stack, so OpenPopup and BeginPopup generally needs to be at the same level of the stack.
    //    This is sometimes leading to confusing mistakes. May rework this in the future.

    // Popups: begin/end functions
    //  - BeginPopup(): query popup state, if open start appending into the window. Call EndPopup() afterwards. ImGuiWindowFlags are forwarded to the window.
    //  - BeginPopupModal(): block every interactions behind the window, cannot be closed by user, add a dimming background, has a title bar.
    bool          BeginPopup(string str_id, ImGuiWindowFlags flags = 0);                         // return true if the popup is open, and you can start outputting to it.
    bool          BeginPopupModal(string name, bool* p_open = NULL, ImGuiWindowFlags flags = 0); // return true if the modal is open, and you can start outputting to it.
    void          EndPopup();                                                                         // only call EndPopup() if BeginPopupXXX() returns true!

    // Popups: open/close functions
    //  - OpenPopup(): set popup state to open. ImGuiPopupFlags are available for opening options.
    //  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
    //  - CloseCurrentPopup(): use inside the BeginPopup()/EndPopup() scope to close manually.
    //  - CloseCurrentPopup() is called by default by Selectable()/MenuItem() when activated (FIXME: need some options).
    //  - Use ImGuiPopupFlags_NoOpenOverExistingPopup to avoid opening a popup if there's already one at the same level. This is equivalent to e.g. testing for !IsAnyPopupOpen() prior to OpenPopup().
    //  - Use IsWindowAppearing() after BeginPopup() to tell if a window just opened.
    void          OpenPopup(string str_id, ImGuiPopupFlags popup_flags = 0);                     // call to mark popup as open (don't call every frame!).
    void          OpenPopup(ImGuiID id, ImGuiPopupFlags popup_flags = 0);                             // id overload to facilitate calling from nested stacks
    void          OpenPopupOnItemClick(string str_id = NULL, ImGuiPopupFlags popup_flags = 1);   // helper to open popup when clicked on last item. Default to ImGuiPopupFlags_MouseButtonRight == 1. (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors)
    void          CloseCurrentPopup();                                                                // manually close the popup we have begin-ed into.

    // Popups: open+begin combined functions helpers
    //  - Helpers to do OpenPopup+BeginPopup where the Open action is triggered by e.g. hovering an item and right-clicking.
    //  - They are convenient to easily create context menus, hence the name.
    //  - IMPORTANT: Notice that BeginPopupContextXXX takes ImGuiPopupFlags just like OpenPopup() and unlike BeginPopup(). For full consistency, we may add ImGuiWindowFlags to the BeginPopupContextXXX functions in the future.
    //  - IMPORTANT: we exceptionally default their flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter, so if you add other flags remember to re-add the ImGuiPopupFlags_MouseButtonRight.
    bool          BeginPopupContextItem(string str_id = NULL, ImGuiPopupFlags popup_flags = 1);  // open+begin popup when clicked on last item. Use str_id==NULL to associate the popup to previous item. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
    bool          BeginPopupContextWindow(string str_id = NULL, ImGuiPopupFlags popup_flags = 1);// open+begin popup when clicked on current window.
    bool          BeginPopupContextVoid(string str_id = NULL, ImGuiPopupFlags popup_flags = 1);  // open+begin popup when clicked in void (where there are no windows).

    // Popups: query functions
    //  - IsPopupOpen(): return true if the popup is open at the current BeginPopup() level of the popup stack.
    //  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId: return true if any popup is open at the current BeginPopup() level of the popup stack.
    //  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId + ImGuiPopupFlags_AnyPopupLevel: return true if any popup is open.
    bool          IsPopupOpen(string str_id, ImGuiPopupFlags flags = 0);                         // return true if the popup is open.

    // Tables
    // [BETA API] API may evolve slightly! If you use this, please update to the next version when it comes out!
    // - Full-featured replacement for old Columns API.
    // - See Demo->Tables for demo code.
    // - See top of imgui_tables.cpp for general commentary.
    // - See ImGuiTableFlags_ and ImGuiTableColumnFlags_ enums for a description of available flags.
    // The typical call flow is:
    // - 1. Call BeginTable().
    // - 2. Optionally call TableSetupColumn() to submit column name/flags/defaults.
    // - 3. Optionally call TableSetupScrollFreeze() to request scroll freezing of columns/rows.
    // - 4. Optionally call TableHeadersRow() to submit a header row. Names are pulled from TableSetupColumn() data.
    // - 5. Populate contents:
    //    - In most situations you can use TableNextRow() + TableSetColumnIndex(N) to start appending into a column.
    //    - If you are using tables as a sort of grid, where every columns is holding the same type of contents,
    //      you may prefer using TableNextColumn() instead of TableNextRow() + TableSetColumnIndex().
    //      TableNextColumn() will automatically wrap-around into the next row if needed.
    //    - IMPORTANT: Comparatively to the old Columns() API, we need to call TableNextColumn() for the first column!
    //    - Summary of possible call flow:
    //        --------------------------------------------------------------------------------------------------------
    //        TableNextRow() -> TableSetColumnIndex(0) -> Text("Hello 0") -> TableSetColumnIndex(1) -> Text("Hello 1")  // OK
    //        TableNextRow() -> TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK
    //                          TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK: TableNextColumn() automatically gets to next row!
    //        TableNextRow()                           -> Text("Hello 0")                                               // Not OK! Missing TableSetColumnIndex() or TableNextColumn()! Text will not appear!
    //        --------------------------------------------------------------------------------------------------------
    // - 5. Call EndTable()
    bool          BeginTable(string str_id, int column, ImGuiTableFlags flags = 0, const ImVec2/*&*/ outer_size = ImVec2(0.0f, 0.0f), float inner_width = 0.0f);
    void          EndTable();                                 // only call EndTable() if BeginTable() returns true!
    void          TableNextRow(ImGuiTableRowFlags row_flags = 0, float min_row_height = 0.0f); // append into the first cell of a new row.
    bool          TableNextColumn();                          // append into the next column (or first column of next row if currently in last column). Return true when column is visible.
    bool          TableSetColumnIndex(int column_n);          // append into the specified column. Return true when column is visible.

    // Tables: Headers & Columns declaration
    // - Use TableSetupColumn() to specify label, resizing policy, default width/weight, id, various other flags etc.
    // - Use TableHeadersRow() to create a header row and automatically submit a TableHeader() for each column.
    //   Headers are required to perform: reordering, sorting, and opening the context menu.
    //   The context menu can also be made available in columns body using ImGuiTableFlags_ContextMenuInBody.
    // - You may manually submit headers using TableNextRow() + TableHeader() calls, but this is only useful in
    //   some advanced use cases (e.g. adding custom widgets in header row).
    // - Use TableSetupScrollFreeze() to lock columns/rows so they stay visible when scrolled.
    void          TableSetupColumn(string label, ImGuiTableColumnFlags flags = 0, float init_width_or_weight = 0.0f, ImGuiID user_id = 0);
    void          TableSetupScrollFreeze(int cols, int rows); // lock columns/rows so they stay visible when scrolled.
    void          TableHeadersRow();                          // submit all headers cells based on data provided to TableSetupColumn() + submit context menu
    void          TableHeader(string label);             // submit one header cell manually (rarely used)

    // Tables: Sorting
    // - Call TableGetSortSpecs() to retrieve latest sort specs for the table. NULL when not sorting.
    // - When 'SpecsDirty == true' you should sort your data. It will be true when sorting specs have changed
    //   since last call, or the first time. Make sure to set 'SpecsDirty = false' after sorting, else you may
    //   wastefully sort your data every frame!
    // - Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
    ImGuiTableSortSpecs*  TableGetSortSpecs();                        // get latest sort specs for the table (NULL if not sorting).

    // Tables: Miscellaneous functions
    // - Functions args 'int column_n' treat the default value of -1 as the same as passing the current column index.
    int                   TableGetColumnCount();                      // return number of columns (value passed to BeginTable)
    int                   TableGetColumnIndex();                      // return current column index.
    int                   TableGetRowIndex();                         // return current row index.
    string           TableGetColumnName(int column_n = -1);      // return "" if column didn't have a name declared by TableSetupColumn(). Pass -1 to use current column.
    ImGuiTableColumnFlags TableGetColumnFlags(int column_n = -1);     // return column flags so you can query their Enabled/Visible/Sorted/Hovered status flags. Pass -1 to use current column.
    void                  TableSetColumnEnabled(int column_n, bool v);// change user accessible enabled/disabled state of a column. Set to false to hide the column. User can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
    void                  TableSetBgColor(ImGuiTableBgTarget target, ImU32 color, int column_n = -1);  // change the color of a cell, row, or column. See ImGuiTableBgTarget_ flags for details.

    // Legacy Columns API (prefer using Tables!)
    // - You can also use SameLine(pos_x) to mimic simplified columns.
    void          Columns(int count = 1, string id = NULL, bool border = true);
    void          NextColumn();                                                       // next column, defaults to current row or next row if the current row is finished
    int           GetColumnIndex();                                                   // get current column index
    float         GetColumnWidth(int column_index = -1);                              // get column width (in pixels). pass -1 to use current column
    void          SetColumnWidth(int column_index, float width);                      // set column width (in pixels). pass -1 to use current column
    float         GetColumnOffset(int column_index = -1);                             // get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
    void          SetColumnOffset(int column_index, float offset_x);                  // set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
    int           GetColumnsCount();

    // Tab Bars, Tabs
    bool          BeginTabBar(string str_id, ImGuiTabBarFlags flags = 0);        // create and append into a TabBar
    void          EndTabBar();                                                        // only call EndTabBar() if BeginTabBar() returns true!
    bool          BeginTabItem(string label, bool* p_open = NULL, ImGuiTabItemFlags flags = 0); // create a Tab. Returns true if the Tab is selected.
    void          EndTabItem();                                                       // only call EndTabItem() if BeginTabItem() returns true!
    bool          TabItemButton(string label, ImGuiTabItemFlags flags = 0);      // create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.
    void          SetTabItemClosed(string tab_or_docked_window_label);           // notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.

    // Logging/Capture
    // - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
    void          LogToTTY(int auto_open_depth = -1);                                 // start logging to tty (stdout)
    void          LogToFile(int auto_open_depth = -1, string filename = NULL);   // start logging to file
    void          LogToClipboard(int auto_open_depth = -1);                           // start logging to OS clipboard
    void          LogFinish();                                                        // stop logging (close file, etc.)
    void          LogButtons();                                                       // helper to display buttons for logging to tty/file/clipboard
    void          LogText(string fmt, ...) IM_FMTARGS(1);                        // pass text data straight to log (without being displayed)
    void          LogTextV(string fmt, va_list args) IM_FMTLIST(1);

    // Drag and Drop
    // - On source items, call BeginDragDropSource(), if it returns true also call SetDragDropPayload() + EndDragDropSource().
    // - On target candidates, call BeginDragDropTarget(), if it returns true also call AcceptDragDropPayload() + EndDragDropTarget().
    // - If you stop calling BeginDragDropSource() the payload is preserved however it won't have a preview tooltip (we currently display a fallback "..." tooltip, see #1725)
    // - An item can be both drag source and drop target.
    bool          BeginDragDropSource(ImGuiDragDropFlags flags = 0);                                      // call after submitting an item which may be dragged. when this return true, you can call SetDragDropPayload() + EndDragDropSource()
    bool          SetDragDropPayload(string type, const void* data, size_t sz, ImGuiCond cond = 0);  // type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui.
    void          EndDragDropSource();                                                                    // only call EndDragDropSource() if BeginDragDropSource() returns true!
    bool                  BeginDragDropTarget();                                                          // call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
    const ImGuiPayload*   AcceptDragDropPayload(string type, ImGuiDragDropFlags flags = 0);          // accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
    void                  EndDragDropTarget();                                                            // only call EndDragDropTarget() if BeginDragDropTarget() returns true!
    const ImGuiPayload*   GetDragDropPayload();                                                           // peek directly into the current payload from anywhere. may return NULL. use ImGuiPayload::IsDataType() to test for the payload type.

    // Disabling [BETA API]
    // - Disable all user interactions and dim items visuals (applying style.DisabledAlpha over current colors)
    // - Those can be nested but it cannot be used to enable an already disabled section (a single BeginDisabled(true) in the stack is enough to keep everything disabled)
    // - BeginDisabled(false) essentially does nothing useful but is provided to facilitate use of boolean expressions. If you can avoid calling BeginDisabled(False)/EndDisabled() best to avoid it.
    void          BeginDisabled(bool disabled = true);
    void          EndDisabled();

    // Clipping
    // - Mouse hovering is affected by ImGui::PushClipRect() calls, unlike direct calls to ImDrawList::PushClipRect() which are render only.
    void          PushClipRect(const ImVec2/*&*/ clip_rect_min, const ImVec2/*&*/ clip_rect_max, bool intersect_with_current_clip_rect);
    void          PopClipRect();

    // Focus, Activation
    // - Prefer using "SetItemDefaultFocus()" over "if (IsWindowAppearing()) SetScrollHereY()" when applicable to signify "this is the default item"
    void          SetItemDefaultFocus();                                              // make last item the default focused item of a window.
    void          SetKeyboardFocusHere(int offset = 0);                               // focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.

    // Item/Widgets Utilities and Query Functions
    // - Most of the functions are referring to the previous Item that has been submitted.
    // - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
    bool          IsItemHovered(ImGuiHoveredFlags flags = 0);                         // is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
    bool          IsItemActive();                                                     // is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
    bool          IsItemFocused();                                                    // is the last item focused for keyboard/gamepad navigation?
    bool          IsItemClicked(ImGuiMouseButton mouse_button = 0);                   // is the last item hovered and mouse clicked on? (**)  == IsMouseClicked(mouse_button) && IsItemHovered()Important. (**) this it NOT equivalent to the behavior of e.g. Button(). Read comments in function definition.
    bool          IsItemVisible();                                                    // is the last item visible? (items may be out of sight because of clipping/scrolling)
    bool          IsItemEdited();                                                     // did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
    bool          IsItemActivated();                                                  // was the last item just made active (item was previously inactive).
    bool          IsItemDeactivated();                                                // was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that requires continuous editing.
    bool          IsItemDeactivatedAfterEdit();                                       // was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that requires continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
    bool          IsItemToggledOpen();                                                // was the last item open state toggled? set by TreeNode().
    bool          IsAnyItemHovered();                                                 // is any item hovered?
    bool          IsAnyItemActive();                                                  // is any item active?
    bool          IsAnyItemFocused();                                                 // is any item focused?
    ImVec2        GetItemRectMin();                                                   // get upper-left bounding rectangle of the last item (screen space)
    ImVec2        GetItemRectMax();                                                   // get lower-right bounding rectangle of the last item (screen space)
    ImVec2        GetItemRectSize();                                                  // get size of last item
    void          SetItemAllowOverlap();                                              // allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.

    // Viewports
    // - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
    // - In 'docking' branch with multi-viewport enabled, we extend this concept to have multiple active viewports.
    // - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
    ImGuiViewport* GetMainViewport();                                                 // return primary/default viewport. This can never be NULL.

    // Miscellaneous Utilities
    bool          IsRectVisible(const ImVec2/*&*/ size);                                  // test if rectangle (of given size, starting from cursor position) is visible / not clipped.
    bool          IsRectVisible(const ImVec2/*&*/ rect_min, const ImVec2/*&*/ rect_max);      // test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
    double        GetTime();                                                          // get global imgui time. incremented by io.DeltaTime every frame.
    int           GetFrameCount();                                                    // get global imgui frame count. incremented by 1 every frame.
    ImDrawList*   GetBackgroundDrawList();                                            // this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
    ImDrawList*   GetForegroundDrawList();                                            // this draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.
    ImDrawListSharedData* GetDrawListSharedData();                                    // you may use this when creating your own ImDrawList instances.
    string   GetStyleColorName(ImGuiCol idx);                                    // get a string corresponding to the enum value (for display, saving, etc.).
    void          SetStateStorage(ImGuiStorage* storage);                             // replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
    ImGuiStorage* GetStateStorage();
    void          CalcListClipping(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);    // calculate coarse clipping for large list of evenly sized items. Prefer using the ImGuiListClipper higher-level helper if you can.
    bool          BeginChildFrame(ImGuiID id, const ImVec2/*&*/ size, ImGuiWindowFlags flags = 0); // helper to create a child window / scrolling region that looks like a normal widget frame
    void          EndChildFrame();                                                    // always call EndChildFrame() regardless of BeginChildFrame() return values (which indicates a collapsed/clipped window)

    // Text Utilities
    ImVec2        CalcTextSize(string text, string text_end = NULL, bool hide_text_after_double_hash = false, float wrap_width = -1.0f);

    // Color Utilities
    ImVec4        ColorConvertU32ToFloat4(ImU32 in);
    ImU32         ColorConvertFloat4ToU32(const ImVec4/*&*/ in);
    void          ColorConvertRGBtoHSV(float r, float g, float b, float& out_h, float& out_s, float& out_v);
    void          ColorConvertHSVtoRGB(float h, float s, float v, float& out_r, float& out_g, float& out_b);

    // Inputs Utilities: Keyboard
    // - For 'int user_key_index' you can use your own indices/enums according to how your backend/engine stored them in io.KeysDown[].
    // - We don't know the meaning of those value. You can use GetKeyIndex() to map a ImGuiKey_ value into the user index.
    int           GetKeyIndex(ImGuiKey imgui_key);                                    // map ImGuiKey_* values into user's key index. == io.KeyMap[key]
    bool          IsKeyDown(int user_key_index);                                      // is key being held. == io.KeysDown[user_key_index].
    bool          IsKeyPressed(int user_key_index, bool repeat = true);               // was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
    bool          IsKeyReleased(int user_key_index);                                  // was key released (went from Down to !Down)?
    int           GetKeyPressedAmount(int key_index, float repeat_delay, float rate); // uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
    void          CaptureKeyboardFromApp(bool want_capture_keyboard_value = true);    // attention: misleading name! manually override io.WantCaptureKeyboard flag next frame (said flag is entirely left for your application to handle). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard_value"; after the next NewFrame() call.

    // Inputs Utilities: Mouse
    // - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
    // - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
    // - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
    bool          IsMouseDown(ImGuiMouseButton button);                               // is mouse button held?
    bool          IsMouseClicked(ImGuiMouseButton button, bool repeat = false);       // did mouse button clicked? (went from !Down to Down)
    bool          IsMouseReleased(ImGuiMouseButton button);                           // did mouse button released? (went from Down to !Down)
    bool          IsMouseDoubleClicked(ImGuiMouseButton button);                      // did mouse button double-clicked? (note that a double-click will also report IsMouseClicked() == true)
    bool          IsMouseHoveringRect(const ImVec2/*&*/ r_min, const ImVec2/*&*/ r_max, bool clip = true);// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
    bool          IsMousePosValid(const ImVec2* mouse_pos = NULL);                    // by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
    bool          IsAnyMouseDown();                                                   // is any mouse button held?
    ImVec2        GetMousePos();                                                      // shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
    ImVec2        GetMousePosOnOpeningCurrentPopup();                                 // retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
    bool          IsMouseDragging(ImGuiMouseButton button, float lock_threshold = -1.0f);         // is mouse dragging? (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
    ImVec2        GetMouseDragDelta(ImGuiMouseButton button = 0, float lock_threshold = -1.0f);   // return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold)
    void          ResetMouseDragDelta(ImGuiMouseButton button = 0);                   //
    ImGuiMouseCursor GetMouseCursor();                                                // get desired cursor type, reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
    void          SetMouseCursor(ImGuiMouseCursor cursor_type);                       // set desired cursor type
    void          CaptureMouseFromApp(bool want_capture_mouse_value = true);          // attention: misleading name! manually override io.WantCaptureMouse flag next frame (said flag is entirely left for your application to handle). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse_value;" after the next NewFrame() call.

    // Clipboard Utilities
    // - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
    string   GetClipboardText();
    void          SetClipboardText(string text);

    // Settings/.Ini Utilities
    // - The disk functions are automatically called if io.IniFilename != NULL (default is "imgui.ini").
    // - Set io.IniFilename to NULL to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
    // - Important: default value "imgui.ini" is relative to current working dir! Most apps will want to lock this to an absolute path (e.g. same path as executables).
    void          LoadIniSettingsFromDisk(string ini_filename);                  // call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
    void          LoadIniSettingsFromMemory(string ini_data, size_t ini_size=0); // call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
    void          SaveIniSettingsToDisk(string ini_filename);                    // this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
    string   SaveIniSettingsToMemory(size_t* out_ini_size = NULL);               // return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.

    // Debug Utilities
    // - This is used by the IMGUI_CHECKVERSION() macro.
    bool          DebugCheckVersionAndDataLayout(string version_str, size_t sz_io, size_t sz_style, size_t sz_vec2, size_t sz_vec4, size_t sz_drawvert, size_t sz_drawidx); // This is called by IMGUI_CHECKVERSION() macro.

    // Memory Allocators
    // - Those functions are not reliant on the current context.
    // - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
    //   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for more details.
    void          SetAllocatorFunctions(ImGuiMemAllocFunc alloc_func, ImGuiMemFreeFunc free_func, void* user_data = NULL);
    void          GetAllocatorFunctions(ImGuiMemAllocFunc* p_alloc_func, ImGuiMemFreeFunc* p_free_func, void** p_user_data);
    void*         MemAlloc(size_t size);
    void          MemFree(void* ptr);

} // namespace ImGui
+/

//-----------------------------------------------------------------------------
// [SECTION] Flags & Enumerations
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
    UnsavedDocument        = 1 << 20,  // Display a dot next to the title. When used in a tab/docking context, tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    NoNav                  = ImGuiWindowFlags.NoNavInputs | ImGuiWindowFlags.NoNavFocus,
    NoDecoration           = ImGuiWindowFlags.NoTitleBar | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoCollapse,
    NoInputs               = ImGuiWindowFlags.NoMouseInputs | ImGuiWindowFlags.NoNavInputs | ImGuiWindowFlags.NoNavFocus,

    // [Internal]
    NavFlattened           = 1 << 23,  // [BETA] Allow gamepad/keyboard navigation to cross over parent border to this child (only use on child that have no scrolling!)
    ChildWindow            = 1 << 24,  // Don't use! For internal use by BeginChild()
    Tooltip                = 1 << 25,  // Don't use! For internal use by BeginTooltip()
    Popup                  = 1 << 26,  // Don't use! For internal use by BeginPopup()
    Modal                  = 1 << 27,  // Don't use! For internal use by BeginPopupModal()
    ChildMenu              = 1 << 28   // Don't use! For internal use by BeginMenu()

    // [Obsolete]
    //ImGuiWindowFlags_ResizeFromAnySide    = 1 << 17,  // --> Set io.ConfigWindowsResizeFromEdges=true and make sure mouse cursors are supported by backend (io.BackendFlags & ImGuiBackendFlags_HasMouseCursors)
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
    AlwaysOverwrite     = 1 << 13,  // Overwrite mode
    ReadOnly            = 1 << 14,  // Read-only mode
    Password            = 1 << 15,  // Password mode, display all characters as '*'
    NoUndoRedo          = 1 << 16,  // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
    CharsScientific     = 1 << 17,  // Allow 0123456789.+-*/eE (Scientific notation input)
    CallbackResize      = 1 << 18,  // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
    CallbackEdit        = 1 << 19   // Callback on any edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)

    // Obsolete names (will be removed soon)
//#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
//    , ImGuiInputTextFlags.AlwaysInsertMode    = ImGuiInputTextFlags.AlwaysOverwrite   // [renamed in 1.82] name was not matching behavior
//#endif

    // [Internal]
    , Multiline           = 1 << 26,  // For internal use by InputTextMultiline()
    NoMarkEdited        = 1 << 27,  // For internal use by functions using InputText() before reformatting data
    MergedItem = 1 << 28 // For internal use by TempInputText(), will skip calling ItemAdd(). Require bounding-box to strictly match.
}

// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
enum ImGuiTreeNodeFlags : int
{
    None                 = 0,
    Selected             = 1 << 0,   // Draw as selected
    Framed               = 1 << 1,   // Draw frame with background (e.g. for CollapsingHeader)
    AllowItemOverlap     = 1 << 2,   // Hit testing to allow subsequent widgets to overlap this one
    NoTreePushOnOpen     = 1 << 3,   // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
    NoAutoOpenOnLog      = 1 << 4,   // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
    DefaultOpen          = 1 << 5,   // Default node to be open
    OpenOnDoubleClick    = 1 << 6,   // Need double-click to open node
    OpenOnArrow          = 1 << 7,   // Only open when clicking on the arrow part. If ImGuiTreeNodeFlags_OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
    Leaf                 = 1 << 8,   // No collapsing, no arrow (use as a convenience for leaf nodes).
    Bullet               = 1 << 9,   // Display a bullet instead of arrow
    FramePadding         = 1 << 10,  // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
    SpanAvailWidth       = 1 << 11,  // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line. In the future we may refactor the hit system to be front-to-back, allowing natural overlaps and then this can become the default.
    SpanFullWidth        = 1 << 12,  // Extend hit box to the left-most and right-most edges (bypass the indented area).
    NavLeftJumpsBackHere = 1 << 13,  // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
    //ImGuiTreeNodeFlags_NoScrollOnOpen     = 1 << 14,  // FIXME: TODO: Disable automatic scroll on TreePop() if node got just open and contents is not visible
    CollapsingHeader     = ImGuiTreeNodeFlags.Framed | ImGuiTreeNodeFlags.NoTreePushOnOpen | ImGuiTreeNodeFlags.NoAutoOpenOnLog
    
    // [Internal]
    , ClipLabelForTrailingButton = 1 << 20
}

// Flags for OpenPopup*(), BeginPopupContext*(), IsPopupOpen() functions.
// - To be backward compatible with older API which took an 'int mouse_button = 1' argument, we need to treat
//   small flags values as a mouse button index, so we encode the mouse button in the first few bits of the flags.
//   It is therefore guaranteed to be legal to pass a mouse button index in ImGuiPopupFlags.
// - For the same reason, we exceptionally default the ImGuiPopupFlags argument of BeginPopupContextXXX functions to 1 instead of 0.
//   IMPORTANT: because the default parameter is 1 (==ImGuiPopupFlags_MouseButtonRight), if you rely on the default parameter
//   and want to another another flag, you need to pass in the ImGuiPopupFlags_MouseButtonRight flag.
// - Multiple buttons currently cannot be combined/or-ed in those functions (we could allow it later).
enum ImGuiPopupFlags : int
{
    None                    = 0,
    MouseButtonLeft         = 0,        // For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGuiMouseButton_Left)
    MouseButtonRight        = 1,        // For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGuiMouseButton_Right)
    MouseButtonMiddle       = 2,        // For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGuiMouseButton_Middle)
    MouseButtonMask_        = 0x1F,
    MouseButtonDefault_     = 1,
    NoOpenOverExistingPopup = 1 << 5,   // For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack
    NoOpenOverItems         = 1 << 6,   // For BeginPopupContextWindow(): don't return true when hovering items, only when hovering empty space
    AnyPopupId              = 1 << 7,   // For IsPopupOpen(): ignore the ImGuiID parameter and test for any popup.
    AnyPopupLevel           = 1 << 8,   // For IsPopupOpen(): search/test at any level of the popup stack (default test in the current level)
    AnyPopup                = ImGuiPopupFlags.AnyPopupId | ImGuiPopupFlags.AnyPopupLevel
}

// Flags for ImGui::Selectable()
enum ImGuiSelectableFlags : int
{
    None               = 0,
    DontClosePopups    = 1 << 0,   // Clicking this don't close parent popup window
    SpanAllColumns     = 1 << 1,   // Selectable frame can span all columns (text will still fit in current column)
    AllowDoubleClick   = 1 << 2,   // Generate press events on double clicks too
    Disabled           = 1 << 3,   // Cannot be selected, display grayed out text
    AllowItemOverlap   = 1 << 4    // (WIP) Hit testing to allow subsequent widgets to overlap this one

    , // [Internal]
    NoHoldingActiveID      = 1 << 20,
    SelectOnNav            = 1 << 21,  // (WIP) Auto-select when moved into. This is not exposed in public API as to handle multi-select and modifiers we will need user to explicitly control focus scope. May be replaced with a BeginSelection() API.
    SelectOnClick          = 1 << 22,  // Override button behavior to react on Click (default is Click+Release)
    SelectOnRelease        = 1 << 23,  // Override button behavior to react on Release (default is Click+Release)
    SpanAvailWidth         = 1 << 24,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    DrawHoveredWhenHeld    = 1 << 25,  // Always show active when held, even is not hovered. This concept could probably be renamed/formalized somehow.
    SetNavIdOnHover        = 1 << 26,  // Set Nav/Focus ID on mouse hover (used by MenuItem)
    NoPadWithHalfSpacing   = 1 << 27   // Disable padding each side with ItemSpacing * 0.5f
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
    HeightMask_             = ImGuiComboFlags.HeightSmall | ImGuiComboFlags.HeightRegular | ImGuiComboFlags.HeightLarge | ImGuiComboFlags.HeightLargest

    , // [Internal]
    CustomPreview           = 1 << 20   // enable BeginComboPreview()
}

// Flags for ImGui::BeginTabBar()
enum ImGuiTabBarFlags : int
{
    None                           = 0,
    Reorderable                    = 1 << 0,   // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
    AutoSelectNewTabs              = 1 << 1,   // Automatically select new tabs when they appear
    TabListPopupButton             = 1 << 2,   // Disable buttons to open the tab list popup
    NoCloseWithMiddleMouseButton   = 1 << 3,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoTabListScrollingButtons      = 1 << 4,   // Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags_FittingPolicyScroll)
    NoTooltip                      = 1 << 5,   // Disable tooltips when hovering a tab
    FittingPolicyResizeDown        = 1 << 6,   // Resize tabs when they don't fit
    FittingPolicyScroll            = 1 << 7,   // Add scroll buttons when tabs don't fit
    FittingPolicyMask_             = ImGuiTabBarFlags.FittingPolicyResizeDown | ImGuiTabBarFlags.FittingPolicyScroll,
    FittingPolicyDefault_          = ImGuiTabBarFlags.FittingPolicyResizeDown

    , // [Internal]
    DockNode                   = 1 << 20,  // Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
    IsFocused                  = 1 << 21,
    SaveSettings               = 1 << 22   // FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
}

// Flags for ImGui::BeginTabItem()
enum ImGuiTabItemFlags : int
{
    None                          = 0,
    UnsavedDocument               = 1 << 0,   // Display a dot next to the title + tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
    SetSelected                   = 1 << 1,   // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
    NoCloseWithMiddleMouseButton  = 1 << 2,   // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
    NoPushId                      = 1 << 3,   // Don't call PushID(tab->ID)/PopID() on BeginTabItem()/EndTabItem()
    NoTooltip                     = 1 << 4,   // Disable tooltip for the given tab
    NoReorder                     = 1 << 5,   // Disable reordering this tab or having another tab cross over this tab
    Leading                       = 1 << 6,   // Enforce the tab position to the left of the tab bar (after the tab list popup button)
    Trailing                      = 1 << 7    // Enforce the tab position to the right of the tab bar (before the scrolling buttons)

    , // [internal]
    SectionMask_              = ImGuiTabItemFlags.Leading | ImGuiTabItemFlags.Trailing,
    NoCloseButton             = 1 << 20,  // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
    Button = 1 << 21 // Used by TabItemButton, change the tab item behavior to mimic a button
}

// Flags for ImGui::BeginTable()
// [BETA API] API may evolve slightly! If you use this, please update to the next version when it comes out!
// - Important! Sizing policies have complex and subtle side effects, more so than you would expect.
//   Read comments/demos carefully + experiment with live demos to get acquainted with them.
// - The DEFAULT sizing policies are:
//    - Default to ImGuiTableFlags_SizingFixedFit    if ScrollX is on, or if host window has ImGuiWindowFlags_AlwaysAutoResize.
//    - Default to ImGuiTableFlags_SizingStretchSame if ScrollX is off.
// - When ScrollX is off:
//    - Table defaults to ImGuiTableFlags_SizingStretchSame -> all Columns defaults to ImGuiTableColumnFlags_WidthStretch with same weight.
//    - Columns sizing policy allowed: Stretch (default), Fixed/Auto.
//    - Fixed Columns will generally obtain their requested width (unless the table cannot fit them all).
//    - Stretch Columns will share the remaining width.
//    - Mixed Fixed/Stretch columns is possible but has various side-effects on resizing behaviors.
//      The typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.
//      (this is because the visible order of columns have subtle but necessary effects on how they react to manual resizing).
// - When ScrollX is on:
//    - Table defaults to ImGuiTableFlags_SizingFixedFit -> all Columns defaults to ImGuiTableColumnFlags_WidthFixed
//    - Columns sizing policy allowed: Fixed/Auto mostly.
//    - Fixed Columns can be enlarged as needed. Table will show an horizontal scrollbar if needed.
//    - When using auto-resizing (non-resizable) fixed columns, querying the content width to use item right-alignment e.g. SetNextItemWidth(-FLT_MIN) doesn't make sense, would create a feedback loop.
//    - Using Stretch columns OFTEN DOES NOT MAKE SENSE if ScrollX is on, UNLESS you have specified a value for 'inner_width' in BeginTable().
//      If you specify a value for 'inner_width' then effectively the scrolling space is known and Stretch or mixed Fixed/Stretch columns become meaningful again.
// - Read on documentation at the top of imgui_tables.cpp for details.
enum ImGuiTableFlags : int
{
    // Features
    None                       = 0,
    Resizable                  = 1 << 0,   // Enable resizing columns.
    Reorderable                = 1 << 1,   // Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
    Hideable                   = 1 << 2,   // Enable hiding/disabling columns in context menu.
    Sortable                   = 1 << 3,   // Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
    NoSavedSettings            = 1 << 4,   // Disable persisting columns order, width and sort settings in the .ini file.
    ContextMenuInBody          = 1 << 5,   // Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
    // Decorations
    RowBg                      = 1 << 6,   // Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
    BordersInnerH              = 1 << 7,   // Draw horizontal borders between rows.
    BordersOuterH              = 1 << 8,   // Draw horizontal borders at the top and bottom.
    BordersInnerV              = 1 << 9,   // Draw vertical borders between columns.
    BordersOuterV              = 1 << 10,  // Draw vertical borders on the left and right sides.
    BordersH                   = ImGuiTableFlags.BordersInnerH | ImGuiTableFlags.BordersOuterH, // Draw horizontal borders.
    BordersV                   = ImGuiTableFlags.BordersInnerV | ImGuiTableFlags.BordersOuterV, // Draw vertical borders.
    BordersInner               = ImGuiTableFlags.BordersInnerV | ImGuiTableFlags.BordersInnerH, // Draw inner borders.
    BordersOuter               = ImGuiTableFlags.BordersOuterV | ImGuiTableFlags.BordersOuterH, // Draw outer borders.
    Borders                    = ImGuiTableFlags.BordersInner | ImGuiTableFlags.BordersOuter,   // Draw all borders.
    NoBordersInBody            = 1 << 11,  // [ALPHA] Disable vertical borders in columns Body (borders will always appears in Headers). -> May move to style
    NoBordersInBodyUntilResize = 1 << 12,  // [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appears in Headers). -> May move to style
    // Sizing Policy (read above for defaults)
    SizingFixedFit             = 1 << 13,  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
    SizingFixedSame            = 2 << 13,  // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
    SizingStretchProp          = 3 << 13,  // Columns default to _WidthStretch with default weights proportional to each columns contents widths.
    SizingStretchSame          = 4 << 13,  // Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
    // Sizing Extra Options
    NoHostExtendX              = 1 << 16,  // Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
    NoHostExtendY              = 1 << 17,  // Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
    NoKeepColumnsVisible       = 1 << 18,  // Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
    PreciseWidths              = 1 << 19,  // Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
    // Clipping
    NoClip                     = 1 << 20,  // Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
    // Padding
    PadOuterX                  = 1 << 21,  // Default if BordersOuterV is on. Enable outer-most padding. Generally desirable if you have headers.
    NoPadOuterX                = 1 << 22,  // Default if BordersOuterV is off. Disable outer-most padding.
    NoPadInnerX                = 1 << 23,  // Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
    // Scrolling
    ScrollX                    = 1 << 24,  // Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this create a child window, ScrollY is currently generally recommended when using ScrollX.
    ScrollY                    = 1 << 25,  // Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
    // Sorting
    SortMulti                  = 1 << 26,  // Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
    SortTristate               = 1 << 27,  // Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).

    // [Internal] Combinations and masks
    SizingMask_                = ImGuiTableFlags.SizingFixedFit | ImGuiTableFlags.SizingFixedSame | ImGuiTableFlags.SizingStretchProp | ImGuiTableFlags.SizingStretchSame

    // Obsolete names (will be removed soon)
//#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    //, ImGuiTableFlags_ColumnsWidthFixed = ImGuiTableFlags_SizingFixedFit, ImGuiTableFlags_ColumnsWidthStretch = ImGuiTableFlags_SizingStretchSame   // WIP Tables 2020/12
    //, ImGuiTableFlags_SizingPolicyFixed = ImGuiTableFlags_SizingFixedFit, ImGuiTableFlags_SizingPolicyStretch = ImGuiTableFlags_SizingStretchSame   // WIP Tables 2021/01
//#endif
}

// Flags for ImGui::TableSetupColumn()
enum ImGuiTableColumnFlags : int
{
    // Input configuration flags
    None                  = 0,
    Disabled              = 1 << 0,   // Overriding/master disable flag: hide column, won't show in context menu (unlike calling TableSetColumnEnabled() which manipulates the user accessible state)
    DefaultHide           = 1 << 1,   // Default as a hidden/disabled column.
    DefaultSort           = 1 << 2,   // Default as a sorting column.
    WidthStretch          = 1 << 3,   // Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
    WidthFixed            = 1 << 4,   // Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
    NoResize              = 1 << 5,   // Disable manual resizing.
    NoReorder             = 1 << 6,   // Disable manual reordering this column, this will also prevent other columns from crossing over this column.
    NoHide                = 1 << 7,   // Disable ability to hide/disable this column.
    NoClip                = 1 << 8,   // Disable clipping for this column (all NoClip columns will render in a same draw command).
    NoSort                = 1 << 9,   // Disable ability to sort on this field (even if ImGuiTableFlags_Sortable is set on the table).
    NoSortAscending       = 1 << 10,  // Disable ability to sort in the ascending direction.
    NoSortDescending      = 1 << 11,  // Disable ability to sort in the descending direction.
    NoHeaderLabel         = 1 << 12,  // TableHeadersRow() will not submit label for this column. Convenient for some small columns. Name will still appear in context menu.
    NoHeaderWidth         = 1 << 13,  // Disable header text width contribution to automatic column width.
    PreferSortAscending   = 1 << 14,  // Make the initial sort direction Ascending when first sorting on this column (default).
    PreferSortDescending  = 1 << 15,  // Make the initial sort direction Descending when first sorting on this column.
    IndentEnable          = 1 << 16,  // Use current Indent value when entering cell (default for column 0).
    IndentDisable         = 1 << 17,  // Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.

    // Output status flags, read-only via TableGetColumnFlags()
    IsEnabled             = 1 << 24,  // Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
    IsVisible             = 1 << 25,  // Status: is visible == is enabled AND not clipped by scrolling.
    IsSorted              = 1 << 26,  // Status: is currently part of the sort specs
    IsHovered             = 1 << 27,  // Status: is hovered by mouse

    // [Internal] Combinations and masks
    WidthMask_            = ImGuiTableColumnFlags.WidthStretch | ImGuiTableColumnFlags.WidthFixed,
    IndentMask_           = ImGuiTableColumnFlags.IndentEnable | ImGuiTableColumnFlags.IndentDisable,
    StatusMask_           = ImGuiTableColumnFlags.IsEnabled | ImGuiTableColumnFlags.IsVisible | ImGuiTableColumnFlags.IsSorted | ImGuiTableColumnFlags.IsHovered,
    NoDirectResize_       = 1 << 30   // [Internal] Disable user resizing this column directly (it may however we resized indirectly from its left edge)

    // Obsolete names (will be removed soon)
//#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    //ImGuiTableColumnFlags_WidthAuto           = ImGuiTableColumnFlags_WidthFixed | ImGuiTableColumnFlags_NoResize, // Column will not stretch and keep resizing based on submitted contents.
//#endif
}

// Flags for ImGui::TableNextRow()
enum ImGuiTableRowFlags : int
{
    None                         = 0,
    Headers                      = 1 << 0    // Identify header row (set default background color + width of its contents accounted different for auto column width)
}

// Enum for ImGui::TableSetBgColor()
// Background colors are rendering in 3 layers:
//  - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.
//  - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.
//  - Layer 2: draw with CellBg color if set.
// The purpose of the two row/columns layers is to let you decide if a background color changes should override or blend with the existing color.
// When using ImGuiTableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.
// If you set the color of RowBg0 target, your color will override the existing RowBg0 color.
// If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
enum ImGuiTableBgTarget : int
{
    None                         = 0,
    RowBg0                       = 1,        // Set row background color 0 (generally used for background, automatically set when ImGuiTableFlags_RowBg is used)
    RowBg1                       = 2,        // Set row background color 1 (generally used for selection marking)
    CellBg                       = 3         // Set cell background color (top-most color)
}

// Flags for ImGui::IsWindowFocused()
enum ImGuiFocusedFlags : int
{
    None                          = 0,
    ChildWindows                  = 1 << 0,   // Return true if any children of the window is focused
    RootWindow                    = 1 << 1,   // Test from root window (top most parent of the current hierarchy)
    AnyWindow                     = 1 << 2,   // Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
    NoPopupHierarchy              = 1 << 3,   // Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
    //ImGuiFocusedFlags_DockHierarchy               = 1 << 4,   // Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
    RootAndChildWindows           = ImGuiFocusedFlags.RootWindow | ImGuiFocusedFlags.ChildWindows
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
    NoPopupHierarchy              = 1 << 3,   // IsWindowHovered() only: Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
    //ImGuiHoveredFlags_DockHierarchy               = 1 << 4,   // IsWindowHovered() only: Consider docking hierarchy (treat dockspace host as parent of docked window) (when used with _ChildWindows or _RootWindow)
    AllowWhenBlockedByPopup       = 1 << 5,   // Return true even if a popup window is normally blocking access to this item/window
    //ImGuiHoveredFlags_AllowWhenBlockedByModal     = 1 << 6,   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
    AllowWhenBlockedByActiveItem  = 1 << 7,   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
    AllowWhenOverlapped           = 1 << 8,   // IsItemHovered() only: Return true even if the position is obstructed or overlapped by another window
    AllowWhenDisabled             = 1 << 9,   // IsItemHovered() only: Return true even if the item is disabled
    RectOnly                      = ImGuiHoveredFlags.AllowWhenBlockedByPopup | ImGuiHoveredFlags.AllowWhenBlockedByActiveItem | ImGuiHoveredFlags.AllowWhenOverlapped,
    RootAndChildWindows           = ImGuiHoveredFlags.RootWindow | ImGuiHoveredFlags.ChildWindows
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
    AcceptPeekOnly               = ImGuiDragDropFlags.AcceptBeforeDelivery | ImGuiDragDropFlags.AcceptNoDrawDefaultRect  // For peeking ahead and inspecting the payload before delivery.
}

// Standard Drag and Drop payload types. You can define you own payload types using short strings. Types starting with '_' are defined by Dear ImGui.
enum IMGUI_PAYLOAD_TYPE_COLOR_3F     = "_COL3F";    // float[3]: Standard type for colors, without alpha. User code may use this type.
enum IMGUI_PAYLOAD_TYPE_COLOR_4F     = "_COL4F";    // float[4]: Standard type for colors. User code may use this type.

// A primary data type
enum ImGuiDataType : int
{
    S8,       // signed char / char (with sensible compilers)
    U8,       // unsigned char
    S16,      // short
    U16,      // unsigned short
    S32,      // int
    U32,      // unsigned int
    S64,      // long long / __int64
    U64,      // unsigned long long / unsigned __int64
    Float,    // float
    Double,   // double
    COUNT
    
    , // [Internal]
    String = COUNT + 1,
    Pointer,
    ID
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

// A sorting direction
enum ImGuiSortDirection : int
{
    None         = 0,
    Ascending    = 1,    // Ascending = 0->9, A->Z etc.
    Descending   = 2     // Descending = 9->0, Z->A etc.
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

// To test io.KeyMods (which is a combination of individual fields io.KeyCtrl, io.KeyShift, io.KeyAlt set by user/backend)
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
// Gamepad:  Set io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad to enable. Backend: set ImGuiBackendFlags_HasGamepad and fill the io.NavInputs[] fields before calling NewFrame(). Note that io.NavInputs[] is cleared by EndFrame().
// Read instructions in imgui.cpp for more details. Download PNG/PSD at http://dearimgui.org/controls_sheets.
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
    KeyLeft_,      // move left                                    // = Arrow keys
    KeyRight_,     // move right
    KeyUp_,        // move up
    KeyDown_,      // move down
    COUNT,
    InternalStart_ = ImGuiNavInput.KeyLeft_
}

// Configuration flags stored in io.ConfigFlags. Set by user/application.
enum ImGuiConfigFlags : int
{
    None                   = 0,
    NavEnableKeyboard      = 1 << 0,   // Master keyboard navigation enable flag. NewFrame() will automatically fill io.NavInputs[] based on io.KeysDown[].
    NavEnableGamepad       = 1 << 1,   // Master gamepad navigation enable flag. This is mostly to instruct your imgui backend to fill io.NavInputs[]. Backend also needs to set ImGuiBackendFlags_HasGamepad.
    NavEnableSetMousePos   = 1 << 2,   // Instruct navigation to move the mouse cursor. May be useful on TV/console systems where moving a virtual mouse is awkward. Will update io.MousePos and set io.WantSetMousePos=true. If enabled you MUST honor io.WantSetMousePos requests in your backend, otherwise ImGui will react as if the mouse is jumping around back and forth.
    NavNoCaptureKeyboard   = 1 << 3,   // Instruct navigation to not set the io.WantCaptureKeyboard flag when io.NavActive is set.
    NoMouse                = 1 << 4,   // Instruct imgui to clear mouse position/buttons in NewFrame(). This allows ignoring the mouse information set by the backend.
    NoMouseCursorChange    = 1 << 5,   // Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.

    // User storage (to allow your backend/engine to communicate to code that may be shared between multiple projects. Those flags are not used by core Dear ImGui)
    IsSRGB                 = 1 << 20,  // Application is SRGB-aware.
    IsTouchScreen          = 1 << 21   // Application is using a touch screen instead of a mouse.
}

// Backend capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom backend.
enum ImGuiBackendFlags : int
{
    None                  = 0,
    HasGamepad            = 1 << 0,   // Backend Platform supports gamepad and currently has one connected.
    HasMouseCursors       = 1 << 1,   // Backend Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
    HasSetMousePos        = 1 << 2,   // Backend Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if ImGuiConfigFlags_NavEnableSetMousePos is set).
    RendererHasVtxOffset  = 1 << 3    // Backend Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.
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
    TableHeaderBg,         // Table header background
    TableBorderStrong,     // Table outer and header borders (prefer using Alpha=1.0 here)
    TableBorderLight,      // Table inner borders (prefer using Alpha=1.0 here)
    TableRowBg,            // Table row background (even rows)
    TableRowBgAlt,         // Table row background (odd rows)
    TextSelectedBg,
    DragDropTarget,
    NavHighlight,          // Gamepad/keyboard: current highlighted item
    NavWindowingHighlight, // Highlight window when using CTRL+TAB
    NavWindowingDimBg,     // Darken/colorize entire screen behind the CTRL+TAB window list, when active
    ModalWindowDimBg,      // Darken/colorize entire screen behind a modal window, when one is active
    COUNT
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
    DisabledAlpha,       // float     DisabledAlpha
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
    CellPadding,         // ImVec2    CellPadding
    ScrollbarSize,       // float     ScrollbarSize
    ScrollbarRounding,   // float     ScrollbarRounding
    GrabMinSize,         // float     GrabMinSize
    GrabRounding,        // float     GrabRounding
    TabRounding,         // float     TabRounding
    ButtonTextAlign,     // ImVec2    ButtonTextAlign
    SelectableTextAlign, // ImVec2    SelectableTextAlign
    COUNT
}

// Flags for InvisibleButton() [extended in imgui_internal.h]
enum ImGuiButtonFlags : int
{
    None                   = 0,
    MouseButtonLeft        = 1 << 0,   // React on left mouse button (default)
    MouseButtonRight       = 1 << 1,   // React on right mouse button
    MouseButtonMiddle      = 1 << 2,   // React on center mouse button

    // [Internal]
    MouseButtonMask_       = ImGuiButtonFlags.MouseButtonLeft | ImGuiButtonFlags.MouseButtonRight | ImGuiButtonFlags.MouseButtonMiddle,
    MouseButtonDefault_    = ImGuiButtonFlags.MouseButtonLeft
    
    ,PressedOnClick         = 1 << 4,   // return true on click (mouse down event)
    PressedOnClickRelease  = 1 << 5,   // [Default] return true on click + release on same item <-- this is what the majority of Button are using
    PressedOnClickReleaseAnywhere = 1 << 6, // return true on click + release even if the release event is not done while hovering the item
    PressedOnRelease       = 1 << 7,   // return true on release (default requires click+release)
    PressedOnDoubleClick   = 1 << 8,   // return true on double-click (default requires click+release)
    PressedOnDragDropHold  = 1 << 9,   // return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
    Repeat                 = 1 << 10,  // hold to repeat
    FlattenChildren        = 1 << 11,  // allow interactions even if a child window is overlapping
    AllowItemOverlap       = 1 << 12,  // require previous frame HoveredId to either match id or be null before being usable, use along with SetItemAllowOverlap()
    DontClosePopups        = 1 << 13,  // disable automatically closing parent popup on press // [UNUSED]
    Disabled               = 1 << 14,  // disable interactions
    AlignTextBaseLine      = 1 << 15,  // vertically align button to match text baseline - ButtonEx() only // FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
    NoKeyModifiers         = 1 << 16,  // disable mouse interaction if a key modifier is held
    NoHoldingActiveId      = 1 << 17,  // don't set ActiveId while holding the mouse (PressedOnClick only)
    NoNavFocus             = 1 << 18,  // don't override navigation focus when activated
    NoHoveredOnFocus       = 1 << 19,  // don't report as hovered when nav focus is on this item
    PressedOnMask_         = PressedOnClick | PressedOnClickRelease | PressedOnClickReleaseAnywhere | PressedOnRelease | PressedOnDoubleClick | PressedOnDragDropHold,
    PressedOnDefault_      = PressedOnClickRelease
}

// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
enum ImGuiColorEditFlags : int
{
    None            = 0,
    NoAlpha         = 1 << 1,   //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
    NoPicker        = 1 << 2,   //              // ColorEdit: disable picker when clicking on color square.
    NoOptions       = 1 << 3,   //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
    NoSmallPreview  = 1 << 4,   //              // ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
    NoInputs        = 1 << 5,   //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
    NoTooltip       = 1 << 6,   //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
    NoLabel         = 1 << 7,   //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
    NoSidePreview   = 1 << 8,   //              // ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
    NoDragDrop      = 1 << 9,   //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
    NoBorder        = 1 << 10,  //              // ColorButton: disable border (which is enforced by default)

    // User Options (right-click on widget to change some of them).
    AlphaBar        = 1 << 16,  //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
    AlphaPreview    = 1 << 17,  //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
    AlphaPreviewHalf= 1 << 18,  //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
    HDR             = 1 << 19,  //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
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
    DefaultOptions_ = ImGuiColorEditFlags.Uint8 | ImGuiColorEditFlags.DisplayRGB | ImGuiColorEditFlags.InputRGB | ImGuiColorEditFlags.PickerHueBar,

    // [Internal] Masks
    DisplayMask_    = ImGuiColorEditFlags.DisplayRGB | ImGuiColorEditFlags.DisplayHSV | ImGuiColorEditFlags.DisplayHex,
    DataTypeMask_   = ImGuiColorEditFlags.Uint8 | ImGuiColorEditFlags.Float,
    PickerMask_     = ImGuiColorEditFlags.PickerHueWheel | ImGuiColorEditFlags.PickerHueBar,
    InputMask_      = ImGuiColorEditFlags.InputRGB | ImGuiColorEditFlags.InputHSV
}

    // Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiColorEditFlags_RGB = ImGuiColorEditFlags.DisplayRGB;
    deprecated enum ImGuiColorEditFlags_HSV = ImGuiColorEditFlags.DisplayHSV;
    deprecated enum ImGuiColorEditFlags_HEX = ImGuiColorEditFlags.DisplayHex;  // [renamed in 1.69]
}

// Flags for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
// We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
enum ImGuiSliderFlags : int
{
    None                   = 0,
    AlwaysClamp            = 1 << 4,       // Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
    Logarithmic            = 1 << 5,       // Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
    NoRoundToFormat        = 1 << 6,       // Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits)
    NoInput                = 1 << 7,       // Disable CTRL+Click or Enter key allowing to input text directly into the widget
    InvalidMask_           = 0x7000000F    // [Internal] We treat using those bits as being potentially a 'float power' argument from the previous API that has got miscast to this enum, and will trigger an assert if needed.

    , // [internal]
    Vertical               = 1 << 20,  // Should this slider be orientated vertically?
    ReadOnly               = 1 << 21
}

    // Obsolete names (will be removed)
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated enum ImGuiSliderFlags_ClampOnInput = ImGuiSliderFlags.AlwaysClamp; // [renamed in 1.79]
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
// User code may request backend to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
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
    COUNT
}

// Enumeration for ImGui::SetWindow***(), SetNextWindow***(), SetNextItem***() functions
// Represent a condition.
// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
enum ImGuiCond : int
{
    None          = 0,        // No condition (always set the variable), same as _Always
    Always        = 1 << 0,   // No condition (always set the variable)
    Once          = 1 << 1,   // Set the variable once per runtime session (only the first call will succeed)
    FirstUseEver  = 1 << 2,   // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
    Appearing     = 1 << 3    // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
}

//-----------------------------------------------------------------------------
// [SECTION] Helpers: Memory allocations macros, ImVector<>
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// IM_MALLOC(), IM_FREE(), IM_NEW(), IM_PLACEMENT_NEW(), IM_DELETE()
// We call C++ constructor on own allocated memory via the placement "new(ptr) Type()" syntax.
// Defining a custom placement new() with a custom parameter allows us to bypass including <new> which on some platforms complains when user has disabled exceptions.
//-----------------------------------------------------------------------------

// struct ImNewWrapper {};
// inline void* operator new(size_t, ImNewWrapper, void* ptr) { return ptr; }
// inline void  operator delete(void*, ImNewWrapper, void*)   {} // This is only required so we can use the symmetrical new()
pragma(inline) T[] IM_ALLOC(T)(size_t amount) {
    return (cast(T*)MemAlloc(amount * sizeof!(T)))[0..amount];
}
alias IM_FREE = MemFree;
pragma(inline) void IM_PLACEMENT_NEW(T)(T* ptr, T value) {
    *ptr = value;
}
pragma(inline) T* IM_NEW(T, A...)(A args) {
    import std.conv : emplace;
    T* result = cast(T*)MemAlloc(sizeof!(T));
    emplace(result, args);
    return result;
}
pragma(inline) void IM_DELETE(T)(T* p)   { if (p) { p.destroy(); MemFree(p); } }
// D_IMGUI separate definition for string
pragma(inline) void IM_DELETE(string s)   { if (s !is NULL) { MemFree(cast(char*)s.ptr); } }

//-----------------------------------------------------------------------------
// ImVector<>
// Lightweight std::vector<>-like class to avoid dragging dependencies (also, some implementations of STL with debug enabled are absurdly slow, we bypass it so our code runs fast in debug).
//-----------------------------------------------------------------------------
// - You generally do NOT need to care or use this ever. But we need to make it available in imgui.h because some of our public structures are relying on it.
// - We use std-like naming convention here, which is a little unusual for this codebase.
// - Important: clear() frees memory, resize(0) keep the allocated buffer. We use resize(0) a lot to intentionally recycle allocated buffers across frames and amortize our costs.
// - Important: our implementation does NOT call C++ constructors/destructors, we treat everything as raw data! This is intentional but be extra mindful of that,
//   Do NOT use this class as a std::vector replacement in your own code! Many of the structures used by dear imgui can be safely initialized by a zero-memset.
//-----------------------------------------------------------------------------

//IM_MSVC_RUNTIME_CHECKS_OFF
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
    pragma(inline, true) ref ImVector!T opAssign(const ImVector!T* src)   { clear(); resize(src.Size); memcpy(Data, src.Data, cast(size_t)Size * sizeof!(T)); return this; }
    pragma(inline, true) void destroy()                                      { if (Data) IM_FREE(Data); } // Important: does not destruct anything
    // D_IMGUI function to get an array representation of the vector
    pragma(inline, true) inout (T)[] asArray() inout                         { return Data ? Data[0..Size] : NULL; }

    pragma(inline, true) void         clear()                             { if (Data) { Size = Capacity = 0; IM_FREE(Data); Data = NULL; } }  // Important: does not destruct anything
    static if (is(T == U*, U)) {
    pragma(inline, true) void         clear_delete()                      { for (int n = 0; n < Size; n++) IM_DELETE(Data[n]); clear(); }     // Important: never called automatically! always explicit.
    }
    pragma(inline, true) void         clear_destruct()                    { for (int n = 0; n < Size; n++) Data[n].destroy(); clear(); }           // Important: never called automatically! always explicit.

    pragma(inline, true) bool         empty() const                       { return Size == 0; }
    pragma(inline, true) int          size() const                        { return Size; }
    pragma(inline, true) int          size_in_bytes() const               { return Size * cast(int)sizeof!(T); }
    pragma(inline, true) int          max_size() const                    { return 0x7FFFFFFF / cast(int)sizeof!(T); }
    pragma(inline, true) int          capacity() const                    { return Capacity; }
    pragma(inline, true) ref inout (T)     opIndex(int i) inout             { IM_ASSERT(i >= 0 && i < Size); return Data[i]; }

    pragma(inline, true) inout (T)*     begin() inout                       { return Data; }
    pragma(inline, true) inout (T)*     end() inout                         { return Data + Size; }
    pragma(inline, true) ref inout (T)     front() inout                       { IM_ASSERT(Size > 0); return Data[0]; }
    pragma(inline, true) ref inout (T)     back() inout                        { IM_ASSERT(Size > 0); return Data[Size - 1]; }
    pragma(inline, true) void         swap(ref ImVector!T rhs)              { int rhs_size = rhs.Size; rhs.Size = Size; Size = rhs_size; int rhs_cap = rhs.Capacity; rhs.Capacity = Capacity; Capacity = rhs_cap; T* rhs_data = rhs.Data; rhs.Data = Data; Data = rhs_data; }

    pragma(inline, true) int          _grow_capacity(int sz) const        { int new_capacity = Capacity ? (Capacity + Capacity / 2) : 8; return new_capacity > sz ? new_capacity : sz; }
    pragma(inline, true) void         resize(int new_size)                { if (new_size > Capacity) reserve(_grow_capacity(new_size)); Size = new_size; }
    pragma(inline, true) void         resize(int new_size, const T/*&*/ v)    { if (new_size > Capacity) reserve(_grow_capacity(new_size)); if (new_size > Size) for (int n = Size; n < new_size; n++) memcpy(&Data[n], &v, sizeof(v)); Size = new_size; }
    pragma(inline, true) void         shrink(int new_size)                { IM_ASSERT(new_size <= Size); Size = new_size; } // Resize a vector to a smaller size, guaranteed not to cause a reallocation
    pragma(inline, true) void         reserve(int new_capacity)           { if (new_capacity <= Capacity) return; T* new_data = IM_ALLOC!T(cast(size_t)new_capacity).ptr; if (Data) { memcpy(new_data, Data, cast(size_t)Size * sizeof!(T)); IM_FREE(Data); } Data = new_data; Capacity = new_capacity; }

    // NB: It is illegal to call push_back/push_front/insert with a reference pointing inside the ImVector data itself! e.g. v.push_back(v[10]) is forbidden.
    pragma(inline, true) void         push_back(const T/*&*/ v)               { if (Size == Capacity) reserve(_grow_capacity(Size + 1)); memcpy(&Data[Size], &v, sizeof(v)); Size++; }
    pragma(inline, true) void         pop_back()                          { IM_ASSERT(Size > 0); Size--; }
    pragma(inline, true) void         push_front(const T/*&*/ v)              { if (Size == 0) push_back(v); else insert(Data, v); }
    pragma(inline, true) T*           erase(const T* it)                  { IM_ASSERT(it >= Data && it < Data + Size); const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + 1, (cast(size_t)Size - cast(size_t)off - 1) * sizeof!(T)); Size--; return Data + off; }
    pragma(inline, true) T*           erase(const T* it, const T* it_last){ IM_ASSERT(it >= Data && it < Data + Size && it_last > it && it_last <= Data + Size); const ptrdiff_t count = it_last - it; const ptrdiff_t off = it - Data; memmove(Data + off, Data + off + count, (cast(size_t)Size - cast(size_t)off - count) * sizeof!(T)); Size -= cast(int)count; return Data + off; }
    pragma(inline, true) T*           erase_unsorted(const T* it)         { IM_ASSERT(it >= Data && it < Data + Size);  const ptrdiff_t off = it - Data; if (it < Data + Size - 1) memcpy(Data + off, Data + Size - 1, sizeof!(T)); Size--; return Data + off; }
    pragma(inline, true) T*           insert(const T* it, const T/*&*/ v)     { IM_ASSERT(it >= Data && it <= Data + Size); const ptrdiff_t off = it - Data; if (Size == Capacity) reserve(_grow_capacity(Size + 1)); if (off < cast(int)Size) memmove(Data + off + 1, Data + off, (cast(size_t)Size - cast(size_t)off) * sizeof!(T)); memcpy(&Data[off], &v, sizeof(v)); Size++; return Data + off; }
    pragma(inline, true) bool         contains(const T/*&*/ v) const          { const (T)* data = Data;  const T* data_end = Data + Size; while (data < data_end) if (*data++ == v) return true; return false; }
    pragma(inline, true) inout (T)*     find(const T/*&*/ v) inout              { inout (T)* data = Data;  const T* data_end = Data + Size; while (data < data_end) if (*data == v) break; else ++data; return data; }

    pragma(inline, true) bool         find_erase(const T/*&*/ v)              { const T* it = find(v); if (it < Data + Size) { erase(it); return true; } return false; }
    pragma(inline, true) bool         find_erase_unsorted(const T/*&*/ v)     { const T* it = find(v); if (it < Data + Size) { erase_unsorted(it); return true; } return false; }
    pragma(inline, true) int          index_from_ptr(const T* it) const   { IM_ASSERT(it >= Data && it < Data + Size); const ptrdiff_t off = it - Data; return cast(int)off; }
}
//IM_MSVC_RUNTIME_CHECKS_RESTORE

//-----------------------------------------------------------------------------
// [SECTION] ImGuiStyle
//-----------------------------------------------------------------------------
// You may modify the ImGui::GetStyle() main instance during initialization and before NewFrame().
// During the frame, use ImGui::PushStyleVar(ImGuiStyleVar_XXXX)/PopStyleVar() to alter the main style values,
// and ImGui::PushStyleColor(ImGuiCol_XXX)/PopStyleColor() for colors.
//-----------------------------------------------------------------------------

struct ImGuiStyle
{
    nothrow:
    @nogc:

    float       Alpha;                      // Global alpha applies to everything in Dear ImGui.
    float       DisabledAlpha;              // Additional alpha multiplier applied by BeginDisabled(). Multiply over current value of Alpha.
    ImVec2      WindowPadding;              // Padding within a window.
    float       WindowRounding;             // Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.
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
    ImVec2      CellPadding;                // Padding within a table cell
    ImVec2      TouchExtraPadding;          // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
    float       IndentSpacing;              // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
    float       ColumnsMinSpacing;          // Minimum horizontal spacing between two columns. Preferably > (FramePadding.x + 1).
    float       ScrollbarSize;              // Width of the vertical scrollbar, Height of the horizontal scrollbar.
    float       ScrollbarRounding;          // Radius of grab corners for scrollbar.
    float       GrabMinSize;                // Minimum width/height of a grab box for slider/scrollbar.
    float       GrabRounding;               // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
    float       LogSliderDeadzone;          // The size in pixels of the dead-zone around zero on logarithmic sliders that cross zero.
    float       TabRounding;                // Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
    float       TabBorderSize;              // Thickness of border around tabs.
    float       TabMinWidthForCloseButton;  // Minimum width for close button to appears on an unselected tab when hovered. Set to 0.0f to always show when hovering, set to FLT_MAX to never show close button unless selected.
    ImGuiDir    ColorButtonPosition;        // Side of the color button in the ColorEdit4 widget (left/right). Defaults to ImGuiDir_Right.
    ImVec2      ButtonTextAlign;            // Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
    ImVec2      SelectableTextAlign;        // Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
    ImVec2      DisplayWindowPadding;       // Window position are clamped to be visible within the display area or monitors by at least this amount. Only applies to regular windows.
    ImVec2      DisplaySafeAreaPadding;     // If you cannot see the edges of your screen (e.g. on a TV) increase the safe area padding. Apply to popups/tooltips as well regular windows. NB: Prefer configuring your TV sets correctly!
    float       MouseCursorScale;           // Scale software rendered mouse cursor (when io.MouseDrawCursor is enabled). May be removed later.
    bool        AntiAliasedLines;           // Enable anti-aliased lines/borders. Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
    bool        AntiAliasedLinesUseTex;     // Enable anti-aliased lines/borders using textures where possible. Require backend to render with bilinear filtering. Latched at the beginning of the frame (copied to ImDrawList).
    bool        AntiAliasedFill;            // Enable anti-aliased edges around filled shapes (rounded rectangles, circles, etc.). Disable if you are really tight on CPU/GPU. Latched at the beginning of the frame (copied to ImDrawList).
    float       CurveTessellationTol;       // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
    float       CircleTessellationMaxError; // Maximum error (in pixels) allowed when using AddCircle()/AddCircleFilled() or drawing rounded corner rectangles with no explicit segment count specified. Decrease for higher quality but more geometry.
    ImVec4[ImGuiCol.COUNT]      Colors;

    @disable this();
    this(bool dummy) { (cast(ImGuiStyle_Wrapper*)&this).__ctor(dummy); }
    void ScaleAllSizes(float scale_factor) { (cast(ImGuiStyle_Wrapper*)&this).ScaleAllSizes(scale_factor); }
}

//-----------------------------------------------------------------------------
// [SECTION] ImGuiIO
//-----------------------------------------------------------------------------
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

    ImGuiConfigFlags   ConfigFlags;             // = 0              // See ImGuiConfigFlags_ enum. Set by user/application. Gamepad/keyboard navigation options, etc.
    ImGuiBackendFlags  BackendFlags;            // = 0              // See ImGuiBackendFlags_ enum. Set by backend (imgui_impl_xxx files or custom backend) to communicate features supported by the backend.
    ImVec2      DisplaySize;                    // <unset>          // Main display size, in pixels (generally == GetMainViewport()->Size)
    float       DeltaTime;                      // = 1.0f/60.0f     // Time elapsed since last frame, in seconds.
    float       IniSavingRate;                  // = 5.0f           // Minimum time between saving positions/sizes to .ini file, in seconds.
    string IniFilename;                    // = "imgui.ini"    // Path to .ini file (important: default "imgui.ini" is relative to current working dir!). Set NULL to disable automatic .ini loading/saving or if you want to manually call LoadIniSettingsXXX() / SaveIniSettingsXXX() functions.
    string LogFilename;                    // = "imgui_log.txt"// Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
    float       MouseDoubleClickTime;           // = 0.30f          // Time for a double-click, in seconds.
    float       MouseDoubleClickMaxDist;        // = 6.0f           // Distance threshold to stay in to validate a double-click, in pixels.
    float       MouseDragThreshold;             // = 6.0f           // Distance threshold before considering we are dragging.
    int[ImGuiKey.COUNT]         KeyMap;         // <unset>          // Map of indices into the KeysDown[512] entries array which represent your "native" keyboard state.
    float       KeyRepeatDelay;                 // = 0.250f         // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
    float       KeyRepeatRate;                  // = 0.050f         // When holding a key/button, rate at which it repeats, in seconds.
    void*       UserData;                       // = NULL           // Store your own data for retrieval by callbacks.

    ImFontAtlas*Fonts;                          // <auto>           // Font atlas: load, rasterize and pack one or more fonts into a single texture.
    float       FontGlobalScale;                // = 1.0f           // Global scale all fonts
    bool        FontAllowUserScaling;           // = false          // Allow user scaling text of individual window with CTRL+Wheel.
    ImFont*     FontDefault;                    // = NULL           // Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
    ImVec2      DisplayFramebufferScale;        // = (1, 1)         // For retina display or other situations where window coordinates are different from framebuffer coordinates. This generally ends up in ImDrawData::FramebufferScale.

    // Miscellaneous options
    bool        MouseDrawCursor;                // = false          // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor). Cannot be easily renamed to 'io.ConfigXXX' because this is frequently used by backend implementations.
    bool        ConfigMacOSXBehaviors;          // = defined(__APPLE__) // OS X style: Text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl.
    bool        ConfigInputTextCursorBlink;     // = true           // Enable blinking cursor (optional as some users consider it to be distracting).
    bool        ConfigDragClickToInputText;     // = false          // [BETA] Enable turning DragXXX widgets into text input with a simple mouse click-release (without moving). Not desirable on devices without a keyboard.
    bool        ConfigWindowsResizeFromEdges;   // = true           // Enable resizing of windows from their edges and from the lower-left corner. This requires (io.BackendFlags & ImGuiBackendFlags_HasMouseCursors) because it needs mouse cursor feedback. (This used to be a per-window ImGuiWindowFlags_ResizeFromAnySide flag)
    bool        ConfigWindowsMoveFromTitleBarOnly; // = false       // Enable allowing to move windows only when clicking on their title bar. Does not apply to windows without a title bar.
    float       ConfigMemoryCompactTimer;       // = 60.0f          // Timer (in seconds) to free transient windows/tables memory buffers when unused. Set to -1.0f to disable.

    //------------------------------------------------------------------
    // Platform Functions
    // (the imgui_impl_xxxx backend files are setting those up for you)
    //------------------------------------------------------------------

    // Optional: Platform/Renderer backend name (informational only! will be displayed in About Window) + User data for backend/wrappers to store their own stuff.
    string BackendPlatformName;            // = NULL
    string BackendRendererName;            // = NULL
    void*       BackendPlatformUserData;        // = NULL           // User data for platform backend
    void*       BackendRendererUserData;        // = NULL           // User data for renderer backend
    void*       BackendLanguageUserData;        // = NULL           // User data for non C++ programming language backend

    // Optional: Access OS clipboard
    // (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
    string function(void* user_data) GetClipboardTextFn;
    void        function(void* user_data, string text) SetClipboardTextFn;
    void*       ClipboardUserData;

    // Optional: Notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME on Windows)
    // (default to use native imm32 api on Windows)
    void        function(int x, int y) ImeSetInputScreenPosFn;
    void*       ImeWindowHandle;                // = NULL           // (Windows) Set this to your HWND to get automatic IME cursor positioning.

    //------------------------------------------------------------------
    // Input - Fill before calling NewFrame()
    //------------------------------------------------------------------

    ImVec2      MousePos;                       // Mouse position, in pixels. Set to ImVec2(-FLT_MAX, -FLT_MAX) if mouse is unavailable (on another screen, etc.)
    bool[5]        MouseDown;                   // Mouse buttons: 0=left, 1=right, 2=middle + extras (ImGuiMouseButton_COUNT == 5). Dear ImGui mostly uses left and right buttons. Others buttons allows us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
    float       MouseWheel;                     // Mouse wheel Vertical: 1 unit scrolls about 5 lines text.
    float       MouseWheelH;                    // Mouse wheel Horizontal. Most users don't have a mouse with an horizontal wheel, may not be filled by all backends.
    bool        KeyCtrl;                        // Keyboard modifier pressed: Control
    bool        KeyShift;                       // Keyboard modifier pressed: Shift
    bool        KeyAlt;                         // Keyboard modifier pressed: Alt
    bool        KeySuper;                       // Keyboard modifier pressed: Cmd/Super/Windows
    bool[512]        KeysDown;                  // Keyboard keys that are pressed (ideally left in the "native" order your engine has access to keyboard keys, so you can use your own defines/enums for keys).
    float[ImGuiNavInput.COUNT]       NavInputs; // Gamepad inputs. Cleared back to zero by EndFrame(). Keyboard keys will be auto-mapped and be written here by NewFrame().

    // Functions
    void  AddInputCharacter(uint c) { (cast(ImGuiIO_Wrapper*)&this).AddInputCharacter(c); }          // Queue new character input
    void  AddInputCharacterUTF16(ImWchar16 c) { (cast(ImGuiIO_Wrapper*)&this).AddInputCharacterUTF16(c); }        // Queue new character input from an UTF-16 character, it can be a surrogate
    void  AddInputCharactersUTF8(string str) { (cast(ImGuiIO_Wrapper*)&this).AddInputCharactersUTF8(str); }    // Queue new characters input from an UTF-8 string
    void  AddFocusEvent(bool focused) { (cast(ImGuiIO_Wrapper*)&this).AddFocusEvent(focused); }                // Notifies Dear ImGui when hosting platform windows lose or gain input focus
    void  ClearInputCharacters() { (cast(ImGuiIO_Wrapper*)&this).ClearInputCharacters(); }                     // [Internal] Clear the text input buffer manually
    void  ClearInputKeys() { (cast(ImGuiIO_Wrapper*)&this).ClearInputKeys(); }                           // [Internal] Release all keys

    //------------------------------------------------------------------
    // Output - Updated by NewFrame() or EndFrame()/Render()
    // (when reading from the io.WantCaptureMouse, io.WantCaptureKeyboard flags to dispatch your inputs, it is
    //  generally easier and more correct to use their state BEFORE calling NewFrame(). See FAQ for details!)
    //------------------------------------------------------------------

    bool        WantCaptureMouse;               // Set when Dear ImGui will use mouse inputs, in this case do not dispatch them to your main game/application (either way, always pass on mouse inputs to imgui). (e.g. unclicked mouse is hovering over an imgui window, widget is active, mouse was clicked over an imgui window, etc.).
    bool        WantCaptureKeyboard;            // Set when Dear ImGui will use keyboard inputs, in this case do not dispatch them to your main game/application (either way, always pass keyboard inputs to imgui). (e.g. InputText active, or an imgui window is focused and navigation is enabled, etc.).
    bool        WantTextInput;                  // Mobile/console: when set, you may display an on-screen keyboard. This is set by Dear ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
    bool        WantSetMousePos;                // MousePos has been altered, backend should reposition mouse on next frame. Rarely used! Set only when ImGuiConfigFlags_NavEnableSetMousePos flag is enabled.
    bool        WantSaveIniSettings;            // When manual .ini load/save is active (io.IniFilename == NULL), this will be set to notify your application that you can call SaveIniSettingsToMemory() and save yourself. Important: clear io.WantSaveIniSettings yourself after saving!
    bool        NavActive;                      // Keyboard/Gamepad navigation is currently allowed (will handle ImGuiKey_NavXXX events) = a window is focused and it doesn't use the ImGuiWindowFlags_NoNavInputs flag.
    bool        NavVisible;                     // Keyboard/Gamepad navigation is visible and allowed (will handle ImGuiKey_NavXXX events).
    float       Framerate;                      // Rough estimate of application framerate, in frame per second. Solely for convenience. Rolling average estimation based on io.DeltaTime over 120 frames.
    int         MetricsRenderVertices;          // Vertices output during last call to Render()
    int         MetricsRenderIndices;           // Indices output during last call to Render() = number of triangles * 3
    int         MetricsRenderWindows;           // Number of visible windows
    int         MetricsActiveWindows;           // Number of active windows
    int         MetricsActiveAllocations;       // Number of active allocations, updated by MemAlloc/MemFree based on current context. May be off if you have multiple imgui contexts.
    ImVec2      MouseDelta;                     // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.

    //------------------------------------------------------------------
    // [Internal] Dear ImGui will maintain those fields. Forward compatibility not guaranteed!
    //------------------------------------------------------------------

    bool        WantCaptureMouseUnlessPopupClose;// Alternative to WantCaptureMouse: (WantCaptureMouse == true && WantCaptureMouseUnlessPopupClose == false) when a click over void is expected to close a popup.
    ImGuiKeyModFlags KeyMods;                   // Key mods flags (same as io.KeyCtrl/KeyShift/KeyAlt/KeySuper but merged into flags), updated by NewFrame()
    ImGuiKeyModFlags KeyModsPrev;               // Previous key mods
    ImVec2      MousePosPrev;                   // Previous mouse position (note that MouseDelta is not necessary == MousePos-MousePosPrev, in case either position is invalid)
    ImVec2[5]      MouseClickedPos;             // Position at time of clicking
    double[5]      MouseClickedTime;            // Time of last click (used to figure out double-click)
    bool[5]        MouseClicked;                // Mouse button went from !Down to Down
    bool[5]        MouseDoubleClicked;          // Has mouse button been double-clicked?
    bool[5]        MouseReleased;               // Mouse button went from Down to !Down
    bool[5]        MouseDownOwned;              // Track if button was clicked inside a dear imgui window or over void blocked by a popup. We don't request mouse capture from the application if click started outside ImGui bounds.
    bool[5]        MouseDownOwnedUnlessPopupClose;//Track if button was clicked inside a dear imgui window.
    bool[5]        MouseDownWasDoubleClick;     // Track if button down was a double-click
    float[5]       MouseDownDuration;           // Duration the mouse button has been down (0.0f == just clicked)
    float[5]       MouseDownDurationPrev;       // Previous time the mouse button has been down
    ImVec2[5]      MouseDragMaxDistanceAbs;     // Maximum distance, absolute, on each axis, of how much mouse has traveled from the clicking point
    float[5]       MouseDragMaxDistanceSqr;     // Squared maximum distance of how much mouse has traveled from the clicking point
    float[512]       KeysDownDuration;          // Duration the keyboard key has been down (0.0f == just pressed)
    float[512]       KeysDownDurationPrev;      // Previous duration the key has been down
    float[ImGuiNavInput.COUNT]       NavInputsDownDuration;
    float[ImGuiNavInput.COUNT]       NavInputsDownDurationPrev;
    float       PenPressure;                    // Touch/Pen pressure (0.0f to 1.0f, should be >0.0f only when MouseDown[0] == true). Helper storage currently unused by Dear ImGui.
    bool        AppFocusLost;
    ImWchar16   InputQueueSurrogate;            // For AddInputCharacterUTF16
    ImVector!ImWchar InputQueueCharacters;     // Queue of _characters_ input (obtained by platform backend). Fill using AddInputCharacter() helper.

    @disable this();
    this(bool dummy) { (cast(ImGuiIO_Wrapper*)&this).__ctor(dummy); }
    
    void destroy() {
        InputQueueCharacters.destroy();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Misc data structures
//-----------------------------------------------------------------------------

// Shared state of InputText(), passed as an argument to your callback when a ImGuiInputTextFlags_Callback* flag is used.
// The callback function should return 0 by default.
// Callbacks (follow a flag name and see comments in ImGuiInputTextFlags_ declarations for more details)
// - ImGuiInputTextFlags_CallbackEdit:        Callback on buffer edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)
// - ImGuiInputTextFlags_CallbackAlways:      Callback on each iteration
// - ImGuiInputTextFlags_CallbackCompletion:  Callback on pressing TAB
// - ImGuiInputTextFlags_CallbackHistory:     Callback on pressing Up/Down arrows
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
    char[]               Buf;            // Text buffer                          // Read-write   // [Resize] Can replace pointer / [Completion,History,Always] Only write to pointed data, don't replace the actual pointer!
    int                 BufTextLen;     // Text length (in bytes)               // Read-write   // [Resize,Completion,History,Always] Exclude zero-terminator storage. In C land: == strlen(some_text), in C++ land: string.length()
    int                 BufSize;        // Buffer size (in bytes) = capacity+1  // Read-only    // [Resize,Completion,History,Always] Include zero-terminator storage. In C land == ARRAYSIZE(my_char_array), in C++ land: string.capacity()+1
    bool                BufDirty;       // Set if you modify Buf/BufTextLen!    // Write        // [Completion,History,Always]
    int                 CursorPos;      //                                      // Read-write   // [Completion,History,Always]
    int                 SelectionStart; //                                      // Read-write   // [Completion,History,Always] == to SelectionEnd when no selection)
    int                 SelectionEnd;   //                                      // Read-write   // [Completion,History,Always]

    // Helper functions for text manipulation.
    // Use those function to benefit from the CallbackResize behaviors. Calling those function reset the selection.
    @disable this(); this(bool dummy) { (cast(ImGuiInputTextCallbackData_Wrapper*)&this).__ctor(dummy); }
    void      DeleteChars(int pos, int bytes_count) { (cast(ImGuiInputTextCallbackData_Wrapper*)&this).DeleteChars(pos, bytes_count); }
    void      InsertChars(int pos, string new_text) { (cast(ImGuiInputTextCallbackData_Wrapper*)&this).InsertChars(pos, new_text); }
    void                SelectAll()             { SelectionStart = 0; SelectionEnd = BufTextLen; }
    void                ClearSelection()        { SelectionStart = SelectionEnd = BufTextLen; }
    bool                HasSelection() const    { return SelectionStart != SelectionEnd; }
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
    char[32]            DataType = 0;   // Data type tag (short user-supplied string, 32 characters max)
    bool            Preview;            // Set when AcceptDragDropPayload() was called and mouse has been hovering the target item (nb: handle overlapping drag targets)
    bool            Delivery;           // Set when AcceptDragDropPayload() was called and mouse button is released over the target item.
    size_t          DataTypeLength;

    //ImGuiPayload()  { Clear(); }
    void Clear()    { SourceId = SourceParentId = 0; Data = NULL; DataSize = 0; memset(DataType, 0, sizeof(DataType)); DataFrameCount = -1; Preview = Delivery = false; }
    bool IsDataType(string type) const { return DataFrameCount != -1 && type == cast(string)DataType[0..DataTypeLength]; }
    bool IsPreview() const                  { return Preview; }
    bool IsDelivery() const                 { return Delivery; }
}

// Sorting specification for one column of a table (sizeof == 12 bytes)
struct ImGuiTableColumnSortSpecs
{
    ImGuiID                     ColumnUserID;       // User id of the column (if specified by a TableSetupColumn() call)
    ImS16                       ColumnIndex;        // Index of the column
    ImS16                       SortOrder;          // Index within parent ImGuiTableSortSpecs (always stored in order starting from 0, tables sorted on a single criteria will always have a 0 here)
    ImGuiSortDirection          SortDirection/* : 8*/;  // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending (you can use this or SortSign, whichever is more convenient for your sort function)

    //ImGuiTableColumnSortSpecs() { memset(&this, 0, sizeof(this)); }
}

// Sorting specifications for a table (often handling sort specs for a single column, occasionally more)
// Obtained by calling TableGetSortSpecs().
// When 'SpecsDirty == true' you can sort your data. It will be true with sorting specs have changed since last call, or the first time.
// Make sure to set 'SpecsDirty = false' after sorting, else you may wastefully sort your data every frame!
struct ImGuiTableSortSpecs
{
    const (ImGuiTableColumnSortSpecs)* Specs;     // Pointer to sort spec array.
    int                         SpecsCount;     // Sort spec count. Most often 1. May be > 1 when ImGuiTableFlags_SortMulti is enabled. May be == 0 when ImGuiTableFlags_SortTristate is enabled.
    bool                        SpecsDirty;     // Set to true when specs have changed since last time! Use this to sort again, then clear the flag.

    //ImGuiTableSortSpecs()       { memset(&this, 0, sizeof(this)); }
}

//-----------------------------------------------------------------------------
// [SECTION] Helpers (ImGuiOnceUponAFrame, ImGuiTextFilter, ImGuiTextBuffer, ImGuiStorage, ImGuiListClipper, ImColor)
//-----------------------------------------------------------------------------

// Helper: Unicode defines
enum IM_UNICODE_CODEPOINT_INVALID = 0xFFFD;     // Invalid Unicode code point (standard value).
static if (IMGUI_USE_WCHAR32) {
    enum IM_UNICODE_CODEPOINT_MAX     = 0x10FFFF;   // Maximum Unicode code point supported by this build.
} else {
} // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
    enum IM_UNICODE_CODEPOINT_MAX     = 0xFFFF;     // Maximum Unicode code point supported by this build.

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

              this(string default_filter) { (cast(ImGuiTextFilter_Wrapper*)&this).__ctor(default_filter); }
    bool      Draw(string label = "Filter (inc,-exc)", float width = 0.0f) { return (cast(ImGuiTextFilter_Wrapper*)&this).Draw(label, width); }  // Helper calling InputText+Build
    bool      PassFilter(string text) const { return (cast(ImGuiTextFilter_Wrapper*)&this).PassFilter(text); }
    void      Build() { (cast(ImGuiTextFilter_Wrapper*)&this).Build(); }
    void                Clear()          { InputBuf[0] = 0; Build(); }
    bool                IsActive() const { return !Filters.empty(); }

    void destroy() {
        Filters.destroy();
    }

    // [Internal]
    struct ImGuiTextRange
    {
        nothrow:
        @nogc:

        string     s;

        // this()                                { s = NULL; }
        this(string _s)  { s = _s; }
        bool            empty() const                   { return s.length == 0; }
        void  split(char separator, ImVector!ImGuiTextRange* _out) const { (cast(ImGuiTextFilter_Wrapper.ImGuiTextRange_Wrapper*)&this).split(separator, _out); }
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

    void      append(string str) { (cast(ImGuiTextBuffer_Wrapper*)&this).append(str); }

    void      appendf(A...)(string fmt, A a)
    {
        mixin va_start!a;
        appendfv(fmt, va_args);
        va_end(va_args);
    }

    void      appendfv(string fmt, va_list va_args) { (cast(ImGuiTextBuffer_Wrapper*)&this).appendfv(fmt, va_args); }
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

    void destroy() {
        Data.destroy();
    }

    // - Get***() functions find pair, never add/allocate. Pairs are sorted so a query is O(log N)
    // - Set***() functions find pair, insertion on demand if missing.
    // - Sorted insertion is costly, paid once. A typical frame shouldn't need to insert any new pair.
    void                Clear() { Data.clear(); }
    int       GetInt(ImGuiID key, int default_val = 0) const { return (cast(ImGuiStorage_Wrapper*)&this).GetInt(key, default_val); }
    void      SetInt(ImGuiID key, int val) { (cast(ImGuiStorage_Wrapper*)&this).SetInt(key, val); }
    bool      GetBool(ImGuiID key, bool default_val = false) const { return (cast(ImGuiStorage_Wrapper*)&this).GetBool(key, default_val); }
    void      SetBool(ImGuiID key, bool val) { (cast(ImGuiStorage_Wrapper*)&this).SetBool(key, val); }
    float     GetFloat(ImGuiID key, float default_val = 0.0f) const { return (cast(ImGuiStorage_Wrapper*)&this).GetFloat(key, default_val); }
    void      SetFloat(ImGuiID key, float val) { (cast(ImGuiStorage_Wrapper*)&this).SetFloat(key, val); }
    void*     GetVoidPtr(ImGuiID key) { return (cast(ImGuiStorage_Wrapper*)&this).GetVoidPtr(key); } // default_val is NULL
    void      SetVoidPtr(ImGuiID key, void* val) { (cast(ImGuiStorage_Wrapper*)&this).SetVoidPtr(key, val); }

    // - Get***Ref() functions finds pair, insert on demand if missing, return pointer. Useful if you intend to do Get+Set.
    // - References are only valid until a new value is added to the storage. Calling a Set***() function or a Get***Ref() function invalidates the pointer.
    // - A typical use case where this is convenient for quick hacking (e.g. add storage during a live Edit&Continue session if you can't modify existing struct)
    //      float* pvar = ImGui::GetFloatRef(key); ImGui::SliderFloat("var", pvar, 0, 100.0f); some_var += *pvar;
    int*      GetIntRef(ImGuiID key, int default_val = 0) { return (cast(ImGuiStorage_Wrapper*)&this).GetIntRef(key, default_val); }
    bool*     GetBoolRef(ImGuiID key, bool default_val = false) { return (cast(ImGuiStorage_Wrapper*)&this).GetBoolRef(key, default_val); }
    float*    GetFloatRef(ImGuiID key, float default_val = 0.0f) { return (cast(ImGuiStorage_Wrapper*)&this).GetFloatRef(key, default_val); }
    void**    GetVoidPtrRef(ImGuiID key, void* default_val = NULL) { return (cast(ImGuiStorage_Wrapper*)&this).GetVoidPtrRef(key, default_val); }

    // Use on your own storage if you know only integer are being stored (open/close all tree nodes)
    void      SetAllInt(int val) { (cast(ImGuiStorage_Wrapper*)&this).SetAllInt(val); }

    // For quicker full rebuild of a storage (instead of an incremental one), you may add all your contents and then sort once.
    void      BuildSortByKey() { (cast(ImGuiStorage_Wrapper*)&this).BuildSortByKey(); }
}

// Helper: Manually clip large list of items.
// If you are submitting lots of evenly spaced items and you have a random access to the list, you can perform coarse
// clipping based on visibility to save yourself from processing those items at all.
// The clipper calculates the range of visible items and advance the cursor to compensate for the non-visible items we have skipped.
// (Dear ImGui already clip items based on their bounds but it needs to measure text size to do so, whereas manual coarse clipping before submission makes this cost and your own data fetching/submission cost almost null)
// Usage:
//   ImGuiListClipper clipper;
//   clipper.Begin(1000);         // We have 1000 elements, evenly spaced.
//   while (clipper.Step())
//       for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
//           ImGui::Text("line number %d", i);
// Generally what happens is:
// - Clipper lets you process the first element (DisplayStart = 0, DisplayEnd = 1) regardless of it being visible or not.
// - User code submit one element.
// - Clipper can measure the height of the first element
// - Clipper calculate the actual range of elements to display based on the current clipping rectangle, position the cursor before the first visible element.
// - User code submit visible elements.
struct ImGuiListClipper
{
    nothrow:
    @nogc:

    int     DisplayStart;
    int     DisplayEnd;

    // [Internal]
    int     ItemsCount;
    int     StepNo;
    int     ItemsFrozen;
    float   ItemsHeight;
    float   StartPosY;

    @disable this();
    this(bool dummy) { (cast(ImGuiListClipper_Wrapper*)&this).__ctor(dummy); }
    void destroy() { return (cast(ImGuiListClipper_Wrapper*)&this).destroy(); }

    // items_count: Use INT_MAX if you don't know how many items you have (in which case the cursor won't be advanced in the final step)
    // items_height: Use -1.0f to be calculated automatically on first step. Otherwise pass in the distance between your items, typically GetTextLineHeightWithSpacing() or GetFrameHeightWithSpacing().
    void Begin(int items_count, float items_height = -1.0f) { (cast(ImGuiListClipper_Wrapper*)&this).Begin(items_count, items_height); }  // Automatically called by constructor if you passed 'items_count' or by Step() in Step 1.
    void End() { (cast(ImGuiListClipper_Wrapper*)&this).End(); }                                               // Automatically called on the last call of Step() that returns false.
    bool Step() { return (cast(ImGuiListClipper_Wrapper*)&this).Step(); }                                              // Call until it returns false. The DisplayStart/DisplayEnd fields will be set and you can process/draw those items.

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    deprecated pragma(inline, true) this(int items_count, float items_height = -1.0f) { memset(&this, 0, sizeof(this)); ItemsCount = -1; Begin(items_count, items_height); } // [removed in 1.79]
}
}

// Helpers macros to generate 32-bit encoded colors
static if (IMGUI_USE_BGRA_PACKED_COLOR) {
    enum IM_COL32_R_SHIFT    = 16;
    enum IM_COL32_G_SHIFT    = 8;
    enum IM_COL32_B_SHIFT    = 0;
    enum IM_COL32_A_SHIFT    = 24;
    enum IM_COL32_A_MASK     = 0xFF000000;
} else {
} // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
    enum IM_COL32_R_SHIFT    = 0;
    enum IM_COL32_G_SHIFT    = 8;
    enum IM_COL32_B_SHIFT    = 16;
    enum IM_COL32_A_SHIFT    = 24;
    enum IM_COL32_A_MASK     = 0xFF000000;
pragma(inline, true) ImU32 IM_COL32(ImU8 R, ImU8 G, ImU8 B, ImU8 A) { return ((cast(ImU32)(A)<<IM_COL32_A_SHIFT) | (cast(ImU32)(B)<<IM_COL32_B_SHIFT) | (cast(ImU32)(G)<<IM_COL32_G_SHIFT) | (cast(ImU32)(R)<<IM_COL32_R_SHIFT)); }
enum IM_COL32_WHITE       = IM_COL32(255,255,255,255);  // Opaque white = 0xFFFFFFFF
enum IM_COL32_BLACK       = IM_COL32(0,0,0,255);        // Opaque black
enum IM_COL32_BLACK_TRANS = IM_COL32(0,0,0,0);          // Transparent black = 0x00000000

// Helper: ImColor() implicitly converts colors to either ImU32 (packed 4x1 byte) or ImVec4 (4x1 float)
// Prefer using IM_COL32() macros if you want a guaranteed compile-time ImU32 for usage with ImDrawList API.
// **Avoid storing ImColor! Store either u32 of ImVec4. This is not a full-featured color class. MAY OBSOLETE.
// **None of the ImGui API are using ImColor directly but you can use it as a convenience to pass colors in either ImU32 or ImVec4 formats. Explicitly cast to ImU32 or ImVec4 if needed.
struct ImColor
{
    nothrow:
    @nogc:

    ImVec4              Value;

    // ImColor()                                                       { Value.x = Value.y = Value.z = Value.w = 0.0f; }
    this(int r, int g, int b, int a = 255)                       { float sc = 1.0f / 255.0f; Value.x = cast(float)r * sc; Value.y = cast(float)g * sc; Value.z = cast(float)b * sc; Value.w = cast(float)a * sc; }
    this(ImU32 rgba)                                             { float sc = 1.0f / 255.0f; Value.x = cast(float)((rgba >> IM_COL32_R_SHIFT) & 0xFF) * sc; Value.y = cast(float)((rgba >> IM_COL32_G_SHIFT) & 0xFF) * sc; Value.z = cast(float)((rgba >> IM_COL32_B_SHIFT) & 0xFF) * sc; Value.w = cast(float)((rgba >> IM_COL32_A_SHIFT) & 0xFF) * sc; }
    this(float r, float g, float b, float a = 1.0f)              { Value.x = r; Value.y = g; Value.z = b; Value.w = a; }
    this(const ImVec4/*&*/ col)                                      { Value = col; }
    pragma(inline, true) ImU32 opCast(T:ImU32)() const                                   { return ColorConvertFloat4ToU32(Value); }
    pragma(inline, true) ImVec4 opCast(T:ImVec4)() const                                  { return Value; }

    // FIXME-OBSOLETE: May need to obsolete/cleanup those helpers.
    pragma(inline, true) void    SetHSV(float h, float s, float v, float a = 1.0f){ ColorConvertHSVtoRGB(h, s, v, Value.x, Value.y, Value.z); Value.w = a; }
    static ImColor HSV(float h, float s, float v, float a = 1.0f)   { float r, g, b; ColorConvertHSVtoRGB(h, s, v, r, g, b); return ImColor(r, g, b, a); }
}

//-----------------------------------------------------------------------------
// [SECTION] Drawing API (ImDrawCmd, ImDrawIdx, ImDrawVert, ImDrawChannel, ImDrawListSplitter, ImDrawListFlags, ImDrawList, ImDrawData)
// Hold a series of drawing commands. The user provides a renderer for ImDrawData which essentially contains an array of ImDrawList.
//-----------------------------------------------------------------------------

// The maximum line width to bake anti-aliased textures for. Build atlas with ImFontAtlasFlags_NoBakedLines to disable baking.
//#ifndef IM_DRAWLIST_TEX_LINES_WIDTH_MAX
enum IM_DRAWLIST_TEX_LINES_WIDTH_MAX     = (63);
//#endif

// ImDrawCallback: Draw callbacks for advanced uses [configurable type: override in imconfig.h]
// NB: You most likely do NOT need to use draw callbacks just to create your own widget or customized UI rendering,
// you can poke into the draw list for that! Draw callback may be useful for example to:
//  A) Change your GPU render state,
//  B) render a complex 3D scene inside a UI element without an intermediate texture/render target, etc.
// The expected behavior from your rendering function is 'if (cmd.UserCallback != NULL) { cmd.UserCallback(parent_list, cmd); } else { RenderTriangles() }'
// If you want to override the signature of ImDrawCallback, you can simply use e.g. '#define ImDrawCallback MyDrawCallback' (in imconfig.h) + update rendering backend accordingly.
static if (!D_IMGUI_USER_DEFINED_DRAW_CALLBACK) {
}
    alias ImDrawCallback = void function(const ImDrawList* parent_list, const ImDrawCmd* cmd); // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905

// Special Draw callback value to request renderer backend to reset the graphics/render state.
// The renderer backend needs to handle this special value, otherwise it will crash trying to call a function at this address.
// This is useful for example if you submitted callbacks which you know have altered the render state and you want it to be restored.
// It is not done by default because they are many perfectly useful way of altering render state for imgui contents (e.g. changing shader/blending settings before an Image call).
enum ImDrawCallback_ResetRenderState     = cast(ImDrawCallback)(-1);

// Typically, 1 command = 1 GPU draw call (unless command is a callback)
// - VtxOffset/IdxOffset: When 'io.BackendFlags & ImGuiBackendFlags_RendererHasVtxOffset' is enabled,
//   those fields allow us to render meshes larger than 64K vertices while keeping 16-bit indices.
//   Pre-1.71 backends will typically ignore the VtxOffset/IdxOffset fields.
// - The ClipRect/TextureId/VtxOffset fields must be contiguous as we memcmp() them together (this is asserted for).
struct ImDrawCmd
{
    nothrow:
    @nogc:

    ImVec4          ClipRect;           // 4*4  // Clipping rectangle (x1, y1, x2, y2). Subtract ImDrawData->DisplayPos to get clipping rectangle in "viewport" coordinates
    ImTextureID     TextureId;          // 4-8  // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
    uint    VtxOffset;          // 4    // Start offset in vertex buffer. ImGuiBackendFlags_RendererHasVtxOffset: always 0, otherwise may be >0 to support meshes larger than 64K vertices with 16-bit indices.
    uint    IdxOffset;          // 4    // Start offset in index buffer. Always equal to sum of ElemCount drawn so far.
    uint    ElemCount;          // 4    // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
    ImDrawCallback  UserCallback;       // 4-8  // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
    void*           UserCallbackData;   // 4-8  // The draw callback code can access this.

    //ImDrawCmd() { memset(&this, 0, sizeof(this)); } // Also ensure our padding fields are zeroed

    // Since 1.83: returns ImTextureID associated with this draw call. Warning: DO NOT assume this is always same as 'TextureId' (we will change this function for an upcoming feature)
    pragma(inline, true) ImTextureID GetTexID() const { return TextureId; }
}

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

// [Internal] For use by ImDrawList
struct ImDrawCmdHeader
{
    ImVec4          ClipRect;
    ImTextureID     TextureId;
    uint    VtxOffset;
}

// [Internal] For use by ImDrawListSplitter
struct ImDrawChannel
{
    nothrow:
    @nogc:

    ImVector!ImDrawCmd         _CmdBuffer;
    ImVector!ImDrawIdx         _IdxBuffer;

    void destroy() {
        _CmdBuffer.destroy();
        _IdxBuffer.destroy();
    }
}


// Split/Merge functions are used to split the draw list into different layers which can be drawn into out of order.
// This is used by the Columns/Tables API, so items of each column can be batched together in a same draw call.
struct ImDrawListSplitter
{
    nothrow:
    @nogc:

    int                         _Current;    // Current channel number (0)
    int                         _Count;      // Number of active channels (1+)
    ImVector!ImDrawChannel     _Channels;   // Draw channels (not resized down so _Count might be < Channels.Size)

    //pragma(inline, true) ImDrawListSplitter()  { memset(&this, 0, sizeof(this)); }
    pragma(inline, true) void destroy() { ClearFreeMemory(); }
    pragma(inline, true) void                 Clear() { _Current = 0; _Count = 1; } // Do not clear Channels[] so our allocations are reused next frame
    void              ClearFreeMemory() { (cast(ImDrawListSplitter_Wrapper*)&this).ClearFreeMemory(); }
    void              Split(ImDrawList* draw_list, int count) { (cast(ImDrawListSplitter_Wrapper*)&this).Split(draw_list, count); }
    void              Merge(ImDrawList* draw_list) { (cast(ImDrawListSplitter_Wrapper*)&this).Merge(draw_list); }
    void              SetCurrentChannel(ImDrawList* draw_list, int channel_idx) { (cast(ImDrawListSplitter_Wrapper*)&this).SetCurrentChannel(draw_list, channel_idx); }
}

// Flags for ImDrawList functions
// (Legacy: bit 0 must always correspond to ImDrawFlags_Closed to be backward compatible with old API using a bool. Bits 1..3 must be unused)
enum ImDrawFlags : int
{
    None                        = 0,
    Closed                      = 1 << 0, // PathStroke(), AddPolyline(): specify that shape should be closed (Important: this is always == 1 for legacy reason)
    RoundCornersTopLeft         = 1 << 4, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-left corner only (when rounding > 0.0f, we default to all corners). Was 0x01.
    RoundCornersTopRight        = 1 << 5, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-right corner only (when rounding > 0.0f, we default to all corners). Was 0x02.
    RoundCornersBottomLeft      = 1 << 6, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners). Was 0x04.
    RoundCornersBottomRight     = 1 << 7, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners). Wax 0x08.
    RoundCornersNone            = 1 << 8, // AddRect(), AddRectFilled(), PathRect(): disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!
    RoundCornersTop             = ImDrawFlags.RoundCornersTopLeft | ImDrawFlags.RoundCornersTopRight,
    RoundCornersBottom          = ImDrawFlags.RoundCornersBottomLeft | ImDrawFlags.RoundCornersBottomRight,
    RoundCornersLeft            = ImDrawFlags.RoundCornersBottomLeft | ImDrawFlags.RoundCornersTopLeft,
    RoundCornersRight           = ImDrawFlags.RoundCornersBottomRight | ImDrawFlags.RoundCornersTopRight,
    RoundCornersAll             = ImDrawFlags.RoundCornersTopLeft | ImDrawFlags.RoundCornersTopRight | ImDrawFlags.RoundCornersBottomLeft | ImDrawFlags.RoundCornersBottomRight,
    RoundCornersDefault_        = ImDrawFlags.RoundCornersAll, // Default to ALL corners if none of the _RoundCornersXX flags are specified.
    RoundCornersMask_           = ImDrawFlags.RoundCornersAll | ImDrawFlags.RoundCornersNone
}

// Flags for ImDrawList instance. Those are set automatically by ImGui:: functions from ImGuiIO settings, and generally not manipulated directly.
// It is however possible to temporarily alter flags between calls to ImDrawList:: functions.
enum ImDrawListFlags : int
{
    None                    = 0,
    AntiAliasedLines        = 1 << 0,  // Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
    AntiAliasedLinesUseTex  = 1 << 1,  // Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering.
    AntiAliasedFill         = 1 << 2,  // Enable anti-aliased edge around filled shapes (rounded rectangles, circles).
    AllowVtxOffset          = 1 << 3   // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
}

// Draw command list
// This is the low-level list of polygons that ImGui:: functions are filling. At the end of the frame,
// all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
// Each dear imgui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to
// access the current window draw list and draw custom primitives.
// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
// In single viewport mode, top-left is == GetMainViewport()->Pos (generally 0,0), bottom-right is == GetMainViewport()->Pos+Size (generally io.DisplaySize).
// You are totally free to apply whatever transformation matrix to want to the data (depending on the use of the transformation you may want to apply it to ClipRect as well!)
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
    uint            _VtxCurrentIdx;     // [Internal] generally == VtxBuffer.Size unless we are past 64K vertices, in which case this gets reset to 0.
    const (ImDrawListSharedData)* _Data;          // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
    string             _OwnerName;         // Pointer to owner window's name for debugging
    ImDrawVert*             _VtxWritePtr;       // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    ImDrawIdx*              _IdxWritePtr;       // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    ImVector!ImVec4        _ClipRectStack;     // [Internal]
    ImVector!ImTextureID   _TextureIdStack;    // [Internal]
    ImVector!ImVec2        _Path;              // [Internal] current path building
    ImDrawCmdHeader         _CmdHeader;         // [Internal] template of active commands. Fields should match those of CmdBuffer.back().
    ImDrawListSplitter      _Splitter;          // [Internal] for channels api (note: prefer using your own persistent instance of ImDrawListSplitter!)
    float                   _FringeScale;       // [Internal] anti-alias fringe is scaled by this value, this helps to keep things sharp while zooming at vertex buffer content

    // If you want to create ImDrawList instances, pass them ImGui::GetDrawListSharedData() or create and use your own ImDrawListSharedData (so you can use ImDrawList without ImGui)
    this(const ImDrawListSharedData* shared_data) { memset(&this, 0, sizeof(this)); _Data = shared_data; }

    void destroy() { _ClearFreeMemory(); }
    void  PushClipRect(ImVec2 clip_rect_min, ImVec2 clip_rect_max, bool intersect_with_current_clip_rect = false) { (cast(ImDrawList_Wrapper*)&this).PushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect); }  // Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
    void  PushClipRectFullScreen() { (cast(ImDrawList_Wrapper*)&this).PushClipRectFullScreen(); }
    void  PopClipRect() { (cast(ImDrawList_Wrapper*)&this).PopClipRect(); }
    void  PushTextureID(ImTextureID texture_id) { (cast(ImDrawList_Wrapper*)&this).PushTextureID(texture_id); }
    void  PopTextureID() { (cast(ImDrawList_Wrapper*)&this).PopTextureID(); }
    pragma(inline, true) ImVec2   GetClipRectMin() const { const ImVec4/*&*/ cr = _ClipRectStack.back(); return ImVec2(cr.x, cr.y); }
    pragma(inline, true) ImVec2   GetClipRectMax() const { const ImVec4/*&*/ cr = _ClipRectStack.back(); return ImVec2(cr.z, cr.w); }

    // Primitives
    // - For rectangular primitives, "p_min" and "p_max" represent the upper-left and lower-right corners.
    // - For circle primitives, use "num_segments == 0" to automatically calculate tessellation (preferred).
    //   In older versions (until Dear ImGui 1.77) the AddCircle functions defaulted to num_segments == 12.
    //   In future versions we will use textures to provide cheaper and higher-quality circles.
    //   Use AddNgon() and AddNgonFilled() functions if you need to guaranteed a specific number of sides.
    void  AddLine(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, ImU32 col, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddLine(p1, p2, col, thickness); }
    void  AddRect(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddRect(p_min, p_max, col, rounding, flags, thickness); }   // a: upper-left, b: lower-right (== upper-left + size)
    void  AddRectFilled(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None) { (cast(ImDrawList_Wrapper*)&this).AddRectFilled(p_min, p_max, col, rounding, flags); }                     // a: upper-left, b: lower-right (== upper-left + size)
    void  AddRectFilledMultiColor(const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left) { (cast(ImDrawList_Wrapper*)&this).AddRectFilledMultiColor(p_min, p_max, col_upr_left, col_upr_right, col_bot_right, col_bot_left); }
    void  AddQuad(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddQuad(p1, p2, p3, p4, col, thickness); }
    void  AddQuadFilled(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).AddQuadFilled(p1, p2, p3, p4, col); }
    void  AddTriangle(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, ImU32 col, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddTriangle(p1, p2, p3, col, thickness); }
    void  AddTriangleFilled(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).AddTriangleFilled(p1, p2, p3, col); }
    void  AddCircle(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments = 0, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddCircle(center, radius, col, num_segments, thickness); }
    void  AddCircleFilled(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).AddCircleFilled(center, radius, col, num_segments); }
    void  AddNgon(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments, float thickness = 1.0f) { (cast(ImDrawList_Wrapper*)&this).AddNgon(center, radius, col, num_segments, thickness); }
    void  AddNgonFilled(const ImVec2/*&*/ center, float radius, ImU32 col, int num_segments) { (cast(ImDrawList_Wrapper*)&this).AddNgonFilled(center, radius, col, num_segments); }
    void  AddText(const ImVec2/*&*/ pos, ImU32 col, string text) { (cast(ImDrawList_Wrapper*)&this).AddText(pos, col, text); }
    void  AddText(const (ImFont)* font, float font_size, const ImVec2/*&*/ pos, ImU32 col, string text, float wrap_width = 0.0f, const ImVec4* cpu_fine_clip_rect = NULL) { (cast(ImDrawList_Wrapper*)&this).AddText(font, font_size, pos, col, text, wrap_width, cpu_fine_clip_rect); }
    void  AddPolyline(const ImVec2* points, int num_points, ImU32 col, ImDrawFlags flags, float thickness) { (cast(ImDrawList_Wrapper*)&this).AddPolyline(points, num_points, col, flags, thickness); }
    void  AddConvexPolyFilled(const ImVec2* points, int num_points, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).AddConvexPolyFilled(points, num_points, col); } // Note: Anti-aliased filling requires points to be in clockwise order.
    void  AddBezierCubic(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col, float thickness, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).AddBezierCubic(p1, p2, p3, p4, col, thickness, num_segments); }
    void  AddBezierQuadratic(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, ImU32 col, float thickness, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).AddBezierQuadratic(p1, p2, p3, col, thickness, num_segments); } // Quadratic Bezier (3 control points)

    // Image primitives
    // - Read FAQ to understand what ImTextureID is.
    // - "p_min" and "p_max" represent the upper-left and lower-right corners of the rectangle.
    // - "uv_min" and "uv_max" represent the normalized texture coordinates to use for those corners. Using (0,0)->(1,1) texture coordinates will generally display the entire texture.
    void  AddImage(ImTextureID user_texture_id, const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, const ImVec2/*&*/ uv_min = ImVec2(0, 0), const ImVec2/*&*/ uv_max = ImVec2(1, 1), ImU32 col = IM_COL32_WHITE) { (cast(ImDrawList_Wrapper*)&this).AddImage(user_texture_id, p_min, p_max, uv_min, uv_max, col); }
    void  AddImageQuad(ImTextureID user_texture_id, const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, const ImVec2/*&*/ uv1 = ImVec2(0, 0), const ImVec2/*&*/ uv2 = ImVec2(1, 0), const ImVec2/*&*/ uv3 = ImVec2(1, 1), const ImVec2/*&*/ uv4 = ImVec2(0, 1), ImU32 col = IM_COL32_WHITE) { (cast(ImDrawList_Wrapper*)&this).AddImageQuad(user_texture_id, p1, p2, p3, p4, uv1, uv2, uv3, uv4, col); }
    void  AddImageRounded(ImTextureID user_texture_id, const ImVec2/*&*/ p_min, const ImVec2/*&*/ p_max, const ImVec2/*&*/ uv_min, const ImVec2/*&*/ uv_max, ImU32 col, float rounding, ImDrawFlags flags = ImDrawFlags.None) { (cast(ImDrawList_Wrapper*)&this).AddImageRounded(user_texture_id, p_min, p_max, uv_min, uv_max, col, rounding, flags); }

    // Stateful path API, add points then finish with PathFillConvex() or PathStroke()
    pragma(inline, true)    void  PathClear()                                                 { _Path.Size = 0; }
    pragma(inline, true)    void  PathLineTo(const ImVec2/*&*/ pos)                               { _Path.push_back(pos); }
    pragma(inline, true)    void  PathLineToMergeDuplicate(const ImVec2/*&*/ pos)                 { if (_Path.Size == 0 || memcmp(&_Path.Data[_Path.Size - 1], &pos, 8) != 0) _Path.push_back(pos); }
    pragma(inline, true)    void  PathFillConvex(ImU32 col)                                   { AddConvexPolyFilled(_Path.Data, _Path.Size, col); _Path.Size = 0; }  // Note: Anti-aliased filling requires points to be in clockwise order.
    pragma(inline, true)    void  PathStroke(ImU32 col, ImDrawFlags flags = ImDrawFlags.None, float thickness = 1.0f) { AddPolyline(_Path.Data, _Path.Size, col, flags, thickness); _Path.Size = 0; }
    void  PathArcTo(const ImVec2/*&*/ center, float radius, float a_min, float a_max, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).PathArcTo(center, radius, a_min, a_max, num_segments); }
    void  PathArcToFast(const ImVec2/*&*/ center, float radius, int a_min_of_12, int a_max_of_12) { (cast(ImDrawList_Wrapper*)&this).PathArcToFast(center, radius, a_min_of_12, a_max_of_12); }                // Use precomputed angles for a 12 steps circle
    void  PathBezierCubicCurveTo(const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).PathBezierCubicCurveTo(p2, p3, p4, num_segments); } // Cubic Bezier (4 control points)
    void  PathBezierQuadraticCurveTo(const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, int num_segments = 0) { (cast(ImDrawList_Wrapper*)&this).PathBezierQuadraticCurveTo(p2, p3, num_segments); }               // Quadratic Bezier (3 control points)
    void  PathRect(const ImVec2/*&*/ rect_min, const ImVec2/*&*/ rect_max, float rounding = 0.0f, ImDrawFlags flags = ImDrawFlags.None) { (cast(ImDrawList_Wrapper*)&this).PathRect(rect_min, rect_max, rounding, flags); }

    // Advanced
    void  AddCallback(ImDrawCallback callback, void* callback_data) { (cast(ImDrawList_Wrapper*)&this).AddCallback(callback, callback_data); }  // Your rendering function must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles.
    void  AddDrawCmd() { (cast(ImDrawList_Wrapper*)&this).AddDrawCmd(); }                                               // This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
    ImDrawList* CloneOutput() const { return (cast(const ImDrawList_Wrapper*)&this).CloneOutput(); }                                  // Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.

    // Advanced: Channels
    // - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
    // - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
    // - FIXME-OBSOLETE: This API shouldn't have been in ImDrawList in the first place!
    //   Prefer using your own persistent instance of ImDrawListSplitter as you can stack them.
    //   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
    pragma(inline, true) void     ChannelsSplit(int count)    { _Splitter.Split(&this, count); }
    pragma(inline, true) void     ChannelsMerge()             { _Splitter.Merge(&this); }
    pragma(inline, true) void     ChannelsSetCurrent(int n)   { _Splitter.SetCurrentChannel(&this, n); }

    // Advanced: Primitives allocations
    // - We render triangles (three vertices)
    // - All primitives needs to be reserved via PrimReserve() beforehand.
    void  PrimReserve(int idx_count, int vtx_count) { (cast(ImDrawList_Wrapper*)&this).PrimReserve(idx_count, vtx_count); }
    void  PrimUnreserve(int idx_count, int vtx_count) { (cast(ImDrawList_Wrapper*)&this).PrimUnreserve(idx_count, vtx_count); }
    void  PrimRect(const ImVec2/*&*/ a, const ImVec2/*&*/ b, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).PrimRect(a, b, col); }      // Axis aligned rectangle (composed of two triangles)
    void  PrimRectUV(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ uv_a, const ImVec2/*&*/ uv_b, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).PrimRectUV(a, b, uv_a, uv_b, col); }
    void  PrimQuadUV(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c, const ImVec2/*&*/ d, const ImVec2/*&*/ uv_a, const ImVec2/*&*/ uv_b, const ImVec2/*&*/ uv_c, const ImVec2/*&*/ uv_d, ImU32 col) { (cast(ImDrawList_Wrapper*)&this).PrimQuadUV(a, b, c, d, uv_a, uv_b, uv_c, uv_d, col); }
    pragma(inline, true)    void  PrimWriteVtx(const ImVec2/*&*/ pos, const ImVec2/*&*/ uv, ImU32 col)    { _VtxWritePtr.pos = pos; _VtxWritePtr.uv = uv; _VtxWritePtr.col = col; _VtxWritePtr++; _VtxCurrentIdx++; }
    pragma(inline, true)    void  PrimWriteIdx(ImDrawIdx idx)                                     { *_IdxWritePtr = idx; _IdxWritePtr++; }
    pragma(inline, true)    void  PrimVtx(const ImVec2/*&*/ pos, const ImVec2/*&*/ uv, ImU32 col)         { PrimWriteIdx(cast(ImDrawIdx)_VtxCurrentIdx); PrimWriteVtx(pos, uv, col); }

version (IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    pragma(inline, true)    void  AddBezierCurve(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, ImU32 col, float thickness, int num_segments = 0) { AddBezierCubic(p1, p2, p3, p4, col, thickness, num_segments); }
    pragma(inline, true)    void  PathBezierCurveTo(const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, int num_segments = 0) { PathBezierCubicCurveTo(p2, p3, p4, num_segments); }
}

    // [Internal helpers]
    void  _ResetForNewFrame() { (cast(ImDrawList_Wrapper*)&this)._ResetForNewFrame(); }
    void  _ClearFreeMemory() { (cast(ImDrawList_Wrapper*)&this)._ClearFreeMemory(); }
    void  _PopUnusedDrawCmd() { (cast(ImDrawList_Wrapper*)&this)._PopUnusedDrawCmd(); }
    void  _TryMergeDrawCmds() { (cast(ImDrawList_Wrapper*)&this)._TryMergeDrawCmds(); }
    void  _OnChangedClipRect() { (cast(ImDrawList_Wrapper*)&this)._OnChangedClipRect(); }
    void  _OnChangedTextureID() { (cast(ImDrawList_Wrapper*)&this)._OnChangedTextureID(); }
    void  _OnChangedVtxOffset() { (cast(ImDrawList_Wrapper*)&this)._OnChangedVtxOffset(); }
    int   _CalcCircleAutoSegmentCount(float radius) const { return (cast(ImDrawList_Wrapper*)&this)._CalcCircleAutoSegmentCount(radius); }
    void  _PathArcToFastEx(const ImVec2/*&*/ center, float radius, int a_min_sample, int a_max_sample, int a_step) { (cast(ImDrawList_Wrapper*)&this)._PathArcToFastEx(center, radius, a_min_sample, a_max_sample, a_step); }
    void  _PathArcToN(const ImVec2/*&*/ center, float radius, float a_min, float a_max, int num_segments) { (cast(ImDrawList_Wrapper*)&this)._PathArcToN(center, radius, a_min, a_max, num_segments); }
}

// All draw data to render a Dear ImGui frame
// (NB: the style and the naming convention here is a little inconsistent, we currently preserve them for backward compatibility purpose,
// as this is one of the oldest structure exposed by the library! Basically, ImDrawList == CmdList)
struct ImDrawData
{
    nothrow:
    @nogc:

    bool            Valid;                  // Only valid after Render() is called and before the next NewFrame() is called.
    int             CmdListsCount;          // Number of ImDrawList* to render
    int             TotalIdxCount;          // For convenience, sum of all ImDrawList's IdxBuffer.Size
    int             TotalVtxCount;          // For convenience, sum of all ImDrawList's VtxBuffer.Size
    ImDrawList**    CmdLists;               // Array of ImDrawList* to render. The ImDrawList are owned by ImGuiContext and only pointed to from here.
    ImVec2          DisplayPos;             // Top-left position of the viewport to render (== top-left of the orthogonal projection matrix to use) (== GetMainViewport()->Pos for the main viewport, == (0.0) in most single-viewport applications)
    ImVec2          DisplaySize;            // Size of the viewport to render (== GetMainViewport()->Size for the main viewport, == io.DisplaySize in most single-viewport applications)
    ImVec2          FramebufferScale;       // Amount of pixels for each unit of DisplaySize. Based on io.DisplayFramebufferScale. Generally (1,1) on normal display, (2,2) on OSX with Retina display.

    // Functions
    //ImDrawData()    { Clear(); }
    void Clear()    { memset(&this, 0, sizeof(this)); }     // The ImDrawList are owned by ImGuiContext!
    void  DeIndexAllBuffers() { (cast(ImDrawData_Wrapper*)&this).DeIndexAllBuffers(); }                    // Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
    void  ScaleClipRects(const ImVec2/*&*/ fb_scale) { (cast(ImDrawData_Wrapper*)&this).ScaleClipRects(fb_scale); } // Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
}

//-----------------------------------------------------------------------------
// [SECTION] Font API (ImFontConfig, ImFontGlyph, ImFontAtlasFlags, ImFontAtlas, ImFontGlyphRangesBuilder, ImFont)
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
    int             OversampleH;            // 3        // Rasterize at higher quality for sub-pixel positioning. Note the difference between 2 and 3 is minimal so you can reduce this to 2 to save memory. Read https://github.com/nothings/stb/blob/master/tests/oversample/README.md for details.
    int             OversampleV;            // 1        // Rasterize at higher quality for sub-pixel positioning. This is not really useful as we don't use sub-pixel positions on the Y axis.
    bool            PixelSnapH;             // false    // Align every glyph to pixel boundary. Useful e.g. if you are merging a non-pixel aligned font with the default font. If enabled, you can set OversampleH/V to 1.
    ImVec2          GlyphExtraSpacing;      // 0, 0     // Extra spacing (in pixels) between glyphs. Only X axis is supported for now.
    ImVec2          GlyphOffset;            // 0, 0     // Offset all glyphs from this font input.
    const (ImWchar)*  GlyphRanges;            // NULL     // Pointer to a user-provided list of Unicode range (2 value per range, values are inclusive, zero-terminated list). THE ARRAY DATA NEEDS TO PERSIST AS LONG AS THE FONT IS ALIVE.
    float           GlyphMinAdvanceX;       // 0        // Minimum AdvanceX for glyphs, set Min to align font icons, set both Min/Max to enforce mono-space font
    float           GlyphMaxAdvanceX;       // FLT_MAX  // Maximum AdvanceX for glyphs
    bool            MergeMode;              // false    // Merge into previous ImFont, so you can combine multiple inputs font into one ImFont (e.g. ASCII font + icons + Japanese glyphs). You may want to use GlyphOffset.y when merge font of different heights.
    uint    FontBuilderFlags;       // 0        // Settings for custom font builder. THIS IS BUILDER IMPLEMENTATION DEPENDENT. Leave as zero if unsure.
    float           RasterizerMultiply;     // 1.0f     // Brighten (>1.0f) or darken (<1.0f) font output. Brightening small fonts may be a good workaround to make them more readable.
    ImWchar         EllipsisChar;           // -1       // Explicitly specify unicode codepoint of ellipsis character. When fonts are being merged first specified ellipsis will be used.

    // [Internal]
    char[40]            Name;               // Name (strictly to ease debugging)
    ImFont*         DstFont;

    @disable this();
    this(bool dummy) { (cast(ImFontConfig_Wrapper*)&this).__ctor(dummy); }
}

// Hold rendering data for one glyph.
// (Note: some language parsers may fail to convert the 31+1 bitfield members, in this case maybe drop store a single u32 or we can rework this)
struct ImFontGlyph
{
    nothrow:
    @nogc:

    uint _Codepoint;
    // D_IMGUI: Using inline properties instead of a bitfield.
    @property pragma(inline, true) uint Colored() const {return _Codepoint >> 31;} // Flag to indicate glyph is colored and should generally ignore tinting (make it usable with no shift on little-endian as this is used in loops)
    @property pragma(inline, true) uint Visible() const {return (_Codepoint >> 30) & 1;} // Flag to indicate glyph has no visible pixels (e.g. space). Allow early out when rendering.
    @property pragma(inline, true) uint Codepoint() const {return _Codepoint & 0x3FFFFFFF;} // 0x0000..0x10FFFF
    @property pragma(inline, true) void Colored(uint c) {_Codepoint = (_Codepoint & 0x7FFFFFFF) | (c << 31);}
    @property pragma(inline, true) void Visible(uint v) {_Codepoint = (_Codepoint & 0xBFFFFFFF) | (v << 30);}
    @property pragma(inline, true) void Codepoint(uint c) {_Codepoint = (_Codepoint & 0xC0000000) | c;}
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
    pragma(inline, true) void     Clear()                 { int size_in_bytes = (IM_UNICODE_CODEPOINT_MAX + 1) / 8; UsedChars.resize(size_in_bytes / sizeof!(ImU32)); memset(UsedChars.Data, 0, cast(size_t)size_in_bytes); }
    pragma(inline, true) bool     GetBit(size_t n) const  { int off = cast(int)(n >> 5); ImU32 mask = 1u << (n & 31); return (UsedChars[off] & mask) != 0; }  // Get bit n in the array
    pragma(inline, true) void     SetBit(size_t n)        { int off = cast(int)(n >> 5); ImU32 mask = 1u << (n & 31); UsedChars[off] |= mask; }               // Set bit n in the array
    pragma(inline, true) void     AddChar(ImWchar c)      { SetBit(c); }                      // Add character
    void  AddText(string text) { (cast(ImFontGlyphRangesBuilder_Wrapper*)&this).AddText(text); }     // Add string (each character of the UTF-8 string are added)
    void  AddRanges(const (ImWchar)* ranges) { (cast(ImFontGlyphRangesBuilder_Wrapper*)&this).AddRanges(ranges); }                           // Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
    void  BuildRanges(ImVector!ImWchar* out_ranges) { (cast(ImFontGlyphRangesBuilder_Wrapper*)&this).BuildRanges(out_ranges); }                 // Output new ranges
}

// See ImFontAtlas::AddCustomRectXXX functions.
struct ImFontAtlasCustomRect
{
    nothrow:
    @nogc:

    ushort  Width, Height;  // Input    // Desired rectangle dimension
    ushort  X, Y;           // Output   // Packed position in Atlas
    uint    GlyphID;        // Input    // For custom font glyphs only (ID < 0x110000)
    float           GlyphAdvanceX;  // Input    // For custom font glyphs only: glyph xadvance
    ImVec2          GlyphOffset;    // Input    // For custom font glyphs only: glyph display offset
    ImFont*         Font;           // Input    // For custom font glyphs only: target font
    @disable this();
    this(bool dummy)         { Width = Height = 0; X = Y = 0xFFFF; GlyphID = 0; GlyphAdvanceX = 0.0f; GlyphOffset = ImVec2(0,0); Font = NULL; }
    bool IsPacked() const           { return X != 0xFFFF; }
}

// Flags for ImFontAtlas build
enum ImFontAtlasFlags : int
{
    None               = 0,
    NoPowerOfTwoHeight = 1 << 0,   // Don't round the height to next power of two
    NoMouseCursors     = 1 << 1,   // Don't build software mouse cursors into the atlas (save a little texture memory)
    NoBakedLines       = 1 << 2    // Don't build thick line textures into the atlas (save a little texture memory). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
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
    this(bool dummy) { (cast(ImFontAtlas_Wrapper*)&this).__ctor(dummy); }
    void destroy() { (cast(ImFontAtlas_Wrapper*)&this).destroy(); }
    ImFont*           AddFont(const ImFontConfig* font_cfg) { return (cast(ImFontAtlas_Wrapper*)&this).AddFont(font_cfg); }
    ImFont*           AddFontDefault(const ImFontConfig* font_cfg = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).AddFontDefault(font_cfg); }
    ImFont*           AddFontFromFileTTF(string filename, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).AddFontFromFileTTF(filename, size_pixels, font_cfg, glyph_ranges); }
    ImFont*           AddFontFromMemoryTTF(ubyte[] ttf_data, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).AddFontFromMemoryTTF(ttf_data, size_pixels, font_cfg, glyph_ranges); } // Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
    ImFont*           AddFontFromMemoryCompressedTTF(const ubyte[] compressed_ttf_data, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).AddFontFromMemoryCompressedTTF(compressed_ttf_data, size_pixels, font_cfg, glyph_ranges); } // 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
    ImFont*           AddFontFromMemoryCompressedBase85TTF(string compressed_ttf_data_base85, float size_pixels, const ImFontConfig* font_cfg = NULL, const ImWchar* glyph_ranges = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).AddFontFromMemoryCompressedBase85TTF(compressed_ttf_data_base85, size_pixels, font_cfg, glyph_ranges); }              // 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
    void              ClearInputData() { (cast(ImFontAtlas_Wrapper*)&this).ClearInputData(); }           // Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
    void              ClearTexData() { (cast(ImFontAtlas_Wrapper*)&this).ClearTexData(); }             // Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
    void              ClearFonts() { (cast(ImFontAtlas_Wrapper*)&this).ClearFonts(); }               // Clear output font data (glyphs storage, UV coordinates).
    void              Clear() { (cast(ImFontAtlas_Wrapper*)&this).Clear(); }                    // Clear all input and output.

    // Build atlas, retrieve pixel data.
    // User is in charge of copying the pixels into graphics memory (e.g. create a texture with your engine). Then store your texture handle with SetTexID().
    // The pitch is always = Width * BytesPerPixels (1 or 4)
    // Building in RGBA32 format is provided for convenience and compatibility, but note that unless you manually manipulate or copy color data into
    // the texture (e.g. when using the AddCustomRect*** api), then the RGB pixels emitted will always be white (~75% of memory/bandwidth waste.
    bool              Build() { return (cast(ImFontAtlas_Wrapper*)&this).Build(); }                    // Build pixels data. This is called automatically for you by the GetTexData*** functions.
    void              GetTexDataAsAlpha8(ubyte[]* out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).GetTexDataAsAlpha8(out_pixels, out_width, out_height, out_bytes_per_pixel); }  // 1 byte per-pixel
    void              GetTexDataAsRGBA32(ubyte[]* out_pixels, int* out_width, int* out_height, int* out_bytes_per_pixel = NULL) { return (cast(ImFontAtlas_Wrapper*)&this).GetTexDataAsRGBA32(out_pixels, out_width, out_height, out_bytes_per_pixel); }  // 4 bytes-per-pixel
    bool                        IsBuilt() const             { return Fonts.Size > 0 && TexReady; } // Bit ambiguous: used to detect when user didn't built texture but effectively we should check TexID != 0 except that would be backend dependent...
    void                        SetTexID(ImTextureID id)    { TexID = id; }

    //-------------------------------------------
    // Glyph Ranges
    //-------------------------------------------

    // Helpers to retrieve list of common Unicode ranges (2 value per range, values are inclusive, zero-terminated list)
    // NB: Make sure that your string are UTF-8 and NOT in your local code page. In C++11, you can create UTF-8 string literal using the u8"Hello world" syntax. See FAQ for details.
    // NB: Consider using ImFontGlyphRangesBuilder to build glyph ranges from textual data.
    const (ImWchar)*    GetGlyphRangesDefault() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesDefault(); }                // Basic Latin, Extended Latin
    const (ImWchar)*    GetGlyphRangesKorean() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesKorean(); }                 // Default + Korean characters
    const (ImWchar)*    GetGlyphRangesJapanese() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesJapanese(); }               // Default + Hiragana, Katakana, Half-Width, Selection of 2999 Ideographs
    const (ImWchar)*    GetGlyphRangesChineseFull() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesChineseFull(); }            // Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
    const (ImWchar)*    GetGlyphRangesChineseSimplifiedCommon() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesChineseSimplifiedCommon(); }// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
    const (ImWchar)*    GetGlyphRangesCyrillic() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesCyrillic(); }               // Default + about 400 Cyrillic characters
    const (ImWchar)*    GetGlyphRangesThai() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesThai(); }                   // Default + Thai characters
    const (ImWchar)*    GetGlyphRangesVietnamese() { return (cast(ImFontAtlas_Wrapper2*)&this).GetGlyphRangesVietnamese(); }             // Default + Vietnamese characters

    //-------------------------------------------
    // [BETA] Custom Rectangles/Glyphs API
    //-------------------------------------------

    // You can request arbitrary rectangles to be packed into the atlas, for your own purposes.
    // - After calling Build(), you can query the rectangle position and render your pixels.
    // - If you render colored output, set 'atlas->TexPixelsUseColors = true' as this may help some backends decide of prefered texture format.
    // - You can also request your rectangles to be mapped as font glyph (given a font + Unicode point),
    //   so you can render e.g. custom colorful icons and use them as regular glyphs.
    // - Read docs/FONTS.md for more details about using colorful icons.
    // - Note: this API may be redesigned later in order to support multi-monitor varying DPI settings.
    int               AddCustomRectRegular(int width, int height) { return (cast(ImFontAtlas_Wrapper*)&this).AddCustomRectRegular(width, height); }
    int               AddCustomRectFontGlyph(ImFont* font, ImWchar id, int width, int height, float advance_x, const ImVec2/*&*/ offset = ImVec2(0,0)) { return (cast(ImFontAtlas_Wrapper*)&this).AddCustomRectFontGlyph(font, id, width, height, advance_x, offset); }
    ImFontAtlasCustomRect*      GetCustomRectByIndex(int index) { IM_ASSERT(index >= 0); return &CustomRects[index]; }

    // [Internal]
    void              CalcCustomRectUV(const ImFontAtlasCustomRect* rect, ImVec2* out_uv_min, ImVec2* out_uv_max) const { (cast(ImFontAtlas_Wrapper*)&this).CalcCustomRectUV(rect, out_uv_min, out_uv_max); }
    bool              GetMouseCursorTexData(ImGuiMouseCursor cursor, ImVec2* out_offset, ImVec2* out_size, ImVec2[2] out_uv_border, ImVec2[2] out_uv_fill) { return (cast(ImFontAtlas_Wrapper*)&this).GetMouseCursorTexData(cursor, out_offset, out_size, out_uv_border, out_uv_fill); }

    //-------------------------------------------
    // Members
    //-------------------------------------------

    ImFontAtlasFlags            Flags;              // Build flags (see ImFontAtlasFlags_)
    ImTextureID                 TexID;              // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
    int                         TexDesiredWidth;    // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
    int                         TexGlyphPadding;    // Padding between glyphs within texture in pixels. Defaults to 1. If your rendering method doesn't rely on bilinear filtering you may set this to 0.
    bool                        Locked;             // Marked as Locked by ImGui::NewFrame() so attempt to modify the atlas will assert.

    // [Internal]
    // NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
    bool                        TexReady;           // Set when texture was built matching current font input
    bool                        TexPixelsUseColors; // Tell whether our texture data is known to use colors (rather than just alpha channel), in order to help backend select a format.
    ubyte[]              TexPixelsAlpha8;    // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
    uint[]               TexPixelsRGBA32;    // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
    int                         TexWidth;           // Texture width calculated during Build().
    int                         TexHeight;          // Texture height calculated during Build().
    ImVec2                      TexUvScale;         // = (1.0f/TexWidth, 1.0f/TexHeight)
    ImVec2                      TexUvWhitePixel;    // Texture coordinates to a white pixel
    ImVector!(ImFont*)           Fonts;              // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
    ImVector!ImFontAtlasCustomRect CustomRects;    // Rectangles for packing custom texture data into the atlas.
    ImVector!ImFontConfig      ConfigData;         // Configuration data
    ImVec4[IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1]                      TexUvLines;  // UVs for baked anti-aliased lines

    // [Internal] Font builder
    const ImFontBuilderIO*      FontBuilderIO;      // Opaque interface to a font builder (default to stb_truetype, can be changed to use FreeType by defining IMGUI_ENABLE_FREETYPE).
    uint                FontBuilderFlags;   // Shared flags (for all fonts) for custom font builder. THIS IS BUILD IMPLEMENTATION DEPENDENT. Per-font override is also available in ImFontConfig.

    // [Internal] Packing data
    int                         PackIdMouseCursors; // Custom texture rectangle ID for white pixel and mouse cursors
    int                         PackIdLines;        // Custom texture rectangle ID for baked anti-aliased lines

static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    alias CustomRect    = ImFontAtlasCustomRect;         // OBSOLETED in 1.72+
    //typedef ImFontGlyphRangesBuilder GlyphRangesBuilder; // OBSOLETED in 1.67+
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

    // Members: Hot ~28/40 bytes (for CalcTextSize + render loop)
    ImVector!ImWchar           IndexLookup;        // 12-16 // out //            // Sparse. Index glyphs by Unicode code-point.
    ImVector!ImFontGlyph       Glyphs;             // 12-16 // out //            // All glyphs.
    const (ImFontGlyph)*          FallbackGlyph;      // 4-8   // out // = FindGlyph(FontFallbackChar)

    // Members: Cold ~32/40 bytes
    ImFontAtlas*                ContainerAtlas;     // 4-8   // out //            // What we has been loaded into
    const (ImFontConfig)*         ConfigData;         // 4-8   // in  //            // Pointer within ContainerAtlas->ConfigData
    short                       ConfigDataCount;    // 2     // in  // ~ 1        // Number of ImFontConfig involved in creating this font. Bigger than 1 when merging multiple font sources into one ImFont.
    ImWchar                     FallbackChar;       // 2     // out // = FFFD/'?' // Character used if a glyph isn't found.
    ImWchar                     EllipsisChar;       // 2     // out // = '...'    // Character used for ellipsis rendering.
    ImWchar                     DotChar;            // 2     // out // = '.'      // Character used for ellipsis rendering (if a single '...' character isn't found)
    bool                        DirtyLookupTables;  // 1     // out //
    float                       Scale;              // 4     // in  // = 1.f      // Base font scale, multiplied by the per-window font scale which you can adjust with SetWindowFontScale()
    float                       Ascent, Descent;    // 4+4   // out //            // Ascent: distance from top to bottom of e.g. 'A' [0..FontSize]
    int                         MetricsTotalSurface;// 4     // out //            // Total surface in pixels to get an idea of the font rasterization/texture cost (not exact, we approximate the cost of padding between glyphs)
    ImU8[(IM_UNICODE_CODEPOINT_MAX+1)/4096/8]                        Used4kPagesMap; // 2 bytes if ImWchar=ImWchar16, 34 bytes if ImWchar==ImWchar32. Store 1-bit for each block of 4K codepoints that has one active glyph. This is mainly used to facilitate iterations across all used codepoints.

    // Methods
    @disable this(); this(bool dummy) { (cast(ImFont_Wrapper*)&this).__ctor(dummy); }
    void destroy() { (cast(ImFont_Wrapper*)&this).destroy(); }
    const (ImFontGlyph)* FindGlyph(ImWchar c) const { return (cast(const ImFont_Wrapper*)&this).FindGlyph(c); }
    const (ImFontGlyph)* FindGlyphNoFallback(ImWchar c) const { return (cast(const ImFont_Wrapper*)&this).FindGlyphNoFallback(c); }
    float                       GetCharAdvance(ImWchar c) const     { return (cast(int)c < IndexAdvanceX.Size) ? IndexAdvanceX[cast(int)c] : FallbackAdvanceX; }
    bool                        IsLoaded() const                    { return ContainerAtlas != NULL; }
    string                 GetDebugName() const                { return ConfigData ? ImCstring(ConfigData.Name) : "<unknown>"; }

    // 'max_width' stops rendering after a certain width (could be turned into a 2d size). FLT_MAX to disable.
    // 'wrap_width' enable automatic word-wrapping across multiple lines to fit into given width. 0.0f to disable.
    ImVec2            CalcTextSizeA(float size, float max_width, float wrap_width, string text, string* remaining = NULL) const { return (cast(const ImFont_Wrapper*)&this).CalcTextSizeA(size, max_width, wrap_width, text, remaining); } // utf8
    size_t       CalcWordWrapPositionA(float scale, string text, float wrap_width) const { return (cast(const ImFont_Wrapper*)&this).CalcWordWrapPositionA(scale, text, wrap_width); }
    void              RenderChar(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, ImWchar c) const { (cast(const ImFont_Wrapper*)&this).RenderChar(draw_list, size, pos, col, c); }
    void              RenderText(ImDrawList* draw_list, float size, ImVec2 pos, ImU32 col, const ImVec4/*&*/ clip_rect, string text, float wrap_width = 0.0f, bool cpu_fine_clip = false) const { (cast(const ImFont_Wrapper*)&this).RenderText(draw_list, size, pos, col, clip_rect, text, wrap_width, cpu_fine_clip); }

    // [Internal] Don't use!
    void              BuildLookupTable() { (cast(ImFont_Wrapper*)&this).BuildLookupTable(); }
    void              ClearOutputData() { (cast(ImFont_Wrapper*)&this).ClearOutputData(); }
    void              GrowIndex(int new_size) { (cast(ImFont_Wrapper*)&this).GrowIndex(new_size); }
    void              AddGlyph(const ImFontConfig* src_cfg, ImWchar c, float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1, float advance_x) { (cast(ImFont_Wrapper*)&this).AddGlyph(src_cfg, c, x0, y0, x1, y1, u0, v0, u1, v1, advance_x); }
    void              AddRemapChar(ImWchar dst, ImWchar src, bool overwrite_dst = true) { (cast(ImFont_Wrapper*)&this).AddRemapChar(dst, src, overwrite_dst); } // Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
    void              SetGlyphVisible(ImWchar c, bool visible) { (cast(ImFont_Wrapper*)&this).SetGlyphVisible(c, visible); }
    bool              IsGlyphRangeUnused(uint c_begin, uint c_last) { return (cast(ImFont_Wrapper*)&this).IsGlyphRangeUnused(c_begin, c_last); }
}

//-----------------------------------------------------------------------------
// [SECTION] Viewports
//-----------------------------------------------------------------------------

// Flags stored in ImGuiViewport::Flags, giving indications to the platform backends.
enum ImGuiViewportFlags : int
{
    None                     = 0,
    IsPlatformWindow         = 1 << 0,   // Represent a Platform Window
    IsPlatformMonitor        = 1 << 1,   // Represent a Platform Monitor (unused yet)
    OwnedByApp               = 1 << 2    // Platform Window: is created/managed by the application (rather than a dear imgui backend)
}

// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
// - In 'docking' branch with multi-viewport enabled, we extend this concept to have multiple active viewports.
// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
// - About Main Area vs Work Area:
//   - Main Area = entire viewport.
//   - Work Area = entire viewport minus sections used by main menu bars (for platform windows), or by task bar (for platform monitor).
//   - Windows are generally trying to stay within the Work Area of their host viewport.
struct ImGuiViewport
{
    nothrow:
    @nogc:

    ImGuiViewportFlags  Flags;                  // See ImGuiViewportFlags_
    ImVec2              Pos;                    // Main Area: Position of the viewport (Dear ImGui coordinates are the same as OS desktop/native coordinates)
    ImVec2              Size;                   // Main Area: Size of the viewport.
    ImVec2              WorkPos;                // Work Area: Position of the viewport minus task bars, menus bars, status bars (>= Pos)
    ImVec2              WorkSize;               // Work Area: Size of the viewport minus task bars, menu bars, status bars (<= Size)

    //ImGuiViewport()     { memset(&this, 0, sizeof(this)); }

    // Helpers
    ImVec2              GetCenter() const       { return ImVec2(Pos.x + Size.x * 0.5f, Pos.y + Size.y * 0.5f); }
    ImVec2              GetWorkCenter() const   { return ImVec2(WorkPos.x + WorkSize.x * 0.5f, WorkPos.y + WorkSize.y * 0.5f); }
}

//-----------------------------------------------------------------------------
// [SECTION] Obsolete functions and types
// (Will be removed! Read 'API BREAKING CHANGES' section in imgui.cpp for details)
// Please keep your copy of dear imgui up to date! Occasionally set '#define IMGUI_DISABLE_OBSOLETE_FUNCTIONS' in imconfig.h to stay ahead.
//-----------------------------------------------------------------------------

/+
#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
namespace ImGui
{
    // OBSOLETED in 1.85 (from August 2021)
    static inline float GetWindowContentRegionWidth() { return GetWindowContentRegionMax().x - GetWindowContentRegionMin().x; }
    // OBSOLETED in 1.81 (from February 2021)
    bool      ListBoxHeader(string label, int items_count, int height_in_items = -1); // Helper to calculate size from items_count and height_in_items
    static inline bool  ListBoxHeader(string label, const ImVec2/*&*/ size = ImVec2(0, 0)) { return BeginListBox(label, size); }
    static inline void  ListBoxFooter() { EndListBox(); }
    // OBSOLETED in 1.79 (from August 2020)
    static inline void  OpenPopupContextItem(string str_id = NULL, ImGuiMouseButton mb = 1) { OpenPopupOnItemClick(str_id, mb); } // Bool return value removed. Use IsWindowAppearing() in BeginPopup() instead. Renamed in 1.77, renamed back in 1.79. Sorry!
    // OBSOLETED in 1.78 (from June 2020)
    // Old drag/sliders functions that took a 'float power = 1.0' argument instead of flags.
    // For shared code, you can version check at compile-time with `#if IMGUI_VERSION_NUM >= 17704`.
    bool      DragScalar(string label, ImGuiDataType data_type, void* p_data, float v_speed, const void* p_min, const void* p_max, string format, float power);
    bool      DragScalarN(string label, ImGuiDataType data_type, void* p_data, int components, float v_speed, const void* p_min, const void* p_max, string format, float power);
    static inline bool  DragFloat(string label, float* v, float v_speed, float v_min, float v_max, string format, float power)    { return DragScalar(label, ImGuiDataType.Float, v, v_speed, &v_min, &v_max, format, power); }
    static inline bool  DragFloat2(string label, float v[2], float v_speed, float v_min, float v_max, string format, float power) { return DragScalarN(label, ImGuiDataType.Float, v, 2, v_speed, &v_min, &v_max, format, power); }
    static inline bool  DragFloat3(string label, float v[3], float v_speed, float v_min, float v_max, string format, float power) { return DragScalarN(label, ImGuiDataType.Float, v, 3, v_speed, &v_min, &v_max, format, power); }
    static inline bool  DragFloat4(string label, float v[4], float v_speed, float v_min, float v_max, string format, float power) { return DragScalarN(label, ImGuiDataType.Float, v, 4, v_speed, &v_min, &v_max, format, power); }
    bool      SliderScalar(string label, ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max, string format, float power);
    bool      SliderScalarN(string label, ImGuiDataType data_type, void* p_data, int components, const void* p_min, const void* p_max, string format, float power);
    static inline bool  SliderFloat(string label, float* v, float v_min, float v_max, string format, float power)                 { return SliderScalar(label, ImGuiDataType.Float, v, &v_min, &v_max, format, power); }
    static inline bool  SliderFloat2(string label, float v[2], float v_min, float v_max, string format, float power)              { return SliderScalarN(label, ImGuiDataType.Float, v, 2, &v_min, &v_max, format, power); }
    static inline bool  SliderFloat3(string label, float v[3], float v_min, float v_max, string format, float power)              { return SliderScalarN(label, ImGuiDataType.Float, v, 3, &v_min, &v_max, format, power); }
    static inline bool  SliderFloat4(string label, float v[4], float v_min, float v_max, string format, float power)              { return SliderScalarN(label, ImGuiDataType.Float, v, 4, &v_min, &v_max, format, power); }
    // OBSOLETED in 1.77 (from June 2020)
    static inline bool  BeginPopupContextWindow(string str_id, ImGuiMouseButton mb, bool over_items) { return BeginPopupContextWindow(str_id, mb | (over_items ? 0 : ImGuiPopupFlags.NoOpenOverItems)); }
    // OBSOLETED in 1.72 (from April 2019)
    static inline void  TreeAdvanceToLabelPos()             { SetCursorPosX(GetCursorPosX() + GetTreeNodeToLabelSpacing()); }
    // OBSOLETED in 1.71 (from June 2019)
    static inline void  SetNextTreeNodeOpen(bool open, ImGuiCond cond = 0) { SetNextItemOpen(open, cond); }
    // OBSOLETED in 1.70 (from May 2019)
    static inline float GetContentRegionAvailWidth()        { return GetContentRegionAvail().x; }

    // Some of the older obsolete names along with their replacement (commented out so they are not reported in IDE)
    //static inline ImDrawList* GetOverlayDrawList()            { return GetForegroundDrawList(); }                         // OBSOLETED in 1.69 (from Mar 2019)
    //static inline void  SetScrollHere(float ratio = 0.5f)     { SetScrollHereY(ratio); }                                  // OBSOLETED in 1.66 (from Nov 2018)
    //static inline bool  IsItemDeactivatedAfterChange()        { return IsItemDeactivatedAfterEdit(); }                    // OBSOLETED in 1.63 (from Aug 2018)
    //static inline bool  IsAnyWindowFocused()                  { return IsWindowFocused(ImGuiFocusedFlags_AnyWindow); }    // OBSOLETED in 1.60 (from Apr 2018)
    //static inline bool  IsAnyWindowHovered()                  { return IsWindowHovered(ImGuiHoveredFlags_AnyWindow); }    // OBSOLETED in 1.60 (between Dec 2017 and Apr 2018)
    //static inline void  ShowTestWindow()                      { return ShowDemoWindow(); }                                // OBSOLETED in 1.53 (between Oct 2017 and Dec 2017)
    //static inline bool  IsRootWindowFocused()                 { return IsWindowFocused(ImGuiFocusedFlags_RootWindow); }   // OBSOLETED in 1.53 (between Oct 2017 and Dec 2017)
    //static inline bool  IsRootWindowOrAnyChildFocused()       { return IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows); } // OBSOLETED in 1.53 (between Oct 2017 and Dec 2017)
    //static inline void  SetNextWindowContentWidth(float w)    { SetNextWindowContentSize(ImVec2(w, 0.0f)); }              // OBSOLETED in 1.53 (between Oct 2017 and Dec 2017)
    //static inline float GetItemsLineHeightWithSpacing()       { return GetFrameHeightWithSpacing(); }                     // OBSOLETED in 1.53 (between Oct 2017 and Dec 2017)
}

// OBSOLETED in 1.82 (from Mars 2021): flags for AddRect(), AddRectFilled(), AddImageRounded(), PathRect()
typedef ImDrawFlags ImDrawCornerFlags;
enum ImDrawCornerFlags : int
{
    None      = ImDrawFlags.RoundCornersNone,         // Was == 0 prior to 1.82, this is now == ImDrawFlags_RoundCornersNone which is != 0 and not implicit
    TopLeft   = ImDrawFlags.RoundCornersTopLeft,      // Was == 0x01 (1 << 0) prior to 1.82. Order matches ImDrawFlags_NoRoundCorner* flag (we exploit this internally).
    TopRight  = ImDrawFlags.RoundCornersTopRight,     // Was == 0x02 (1 << 1) prior to 1.82.
    BotLeft   = ImDrawFlags.RoundCornersBottomLeft,   // Was == 0x04 (1 << 2) prior to 1.82.
    BotRight  = ImDrawFlags.RoundCornersBottomRight,  // Was == 0x08 (1 << 3) prior to 1.82.
    All       = ImDrawFlags.RoundCornersAll,          // Was == 0x0F prior to 1.82
    Top       = ImDrawCornerFlags.TopLeft | ImDrawCornerFlags.TopRight,
    Bot       = ImDrawCornerFlags.BotLeft | ImDrawCornerFlags.BotRight,
    Left      = ImDrawCornerFlags.TopLeft | ImDrawCornerFlags.BotLeft,
    Right     = ImDrawCornerFlags.TopRight | ImDrawCornerFlags.BotRight
}

#endif // #ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
+/

//-----------------------------------------------------------------------------

/+
#if defined(__clang__)
#pragma clang diagnostic pop
#elif defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#ifdef _MSC_VER
#pragma warning (pop)
#endif

// Include imgui_user.h at the end of imgui.h (convenient for user to only explicitly include vanilla imgui.h)
#ifdef IMGUI_INCLUDE_IMGUI_USER_H
#include "imgui_user.h"
#endif

#endif // #ifndef IMGUI_DISABLE
+/
