// dear imgui, v1.89.7
// (internal structures/api)
module d_imgui.imgui_internal;

// You may use this file to debug, understand or extend Dear ImGui features but we don't provide any guarantee of forward compatibility.
// To implement maths operators for ImVec2 (disabled by default to not conflict with using IM_VEC2_CLASS_EXTRA with your own math types+operators), use:
/*
#define IMGUI_DEFINE_MATH_OPERATORS
#include "imgui_internal.h"
*/

/*

Index of this file:

// [SECTION] Header mess
// [SECTION] Forward declarations
// [SECTION] Context pointer
// [SECTION] STB libraries includes
// [SECTION] Macros
// [SECTION] Generic helpers
// [SECTION] ImDrawList support
// [SECTION] Widgets support: flags, enums, data structures
// [SECTION] Inputs support
// [SECTION] Clipper support
// [SECTION] Navigation support
// [SECTION] Columns support
// [SECTION] Multi-select support
// [SECTION] Docking support
// [SECTION] Viewport support
// [SECTION] Settings support
// [SECTION] Localization support
// [SECTION] Metrics, Debug tools
// [SECTION] Generic context hooks
// [SECTION] ImGuiContext (main imgui context)
// [SECTION] ImGuiWindowTempData, ImGuiWindow
// [SECTION] Tab bar, Tab item support
// [SECTION] Table support
// [SECTION] ImGui internal API
// [SECTION] ImFontAtlas internal API
// [SECTION] Test Engine specific hooks (imgui_test_engine)

*/

// #pragma once
// #ifndef IMGUI_DISABLE

//-----------------------------------------------------------------------------
// [SECTION] Header mess
//-----------------------------------------------------------------------------

//#ifndef IMGUI_VERSION
//#include "imgui.h"
//}
import d_imgui.imconfig;
import d_imgui.imgui_h;
import d_imgui.imgui;

import d_imgui.imgui_draw;
import d_imgui.imgui_widgets;

import d_imgui.imstb_textedit;

//import core.stdc.string : memset, memcpy;
import d_snprintf.vararg;
import d_snprintf.snscanf : sscanf = snscanf;

nothrow:
@nogc:

/+
#include <stdio.h>      // FILE*, sscanf
#include <stdlib.h>     // NULL, malloc, free, qsort, atoi, atof
#include <math.h>       // sqrtf, fabsf, fmodf, powf, floorf, ceilf, cosf, sinf
#include <limits.h>     // INT_MIN, INT_MAX
+/

/+
// Enable SSE intrinsics if available
#if (defined __SSE__ || defined __x86_64__ || defined _M_X64 || (defined(_M_IX86_FP) && (_M_IX86_FP >= 1))) && !defined(IMGUI_DISABLE_SSE)
#define IMGUI_ENABLE_SSE
#include <immintrin.h>
}

// Visual Studio warnings
#ifdef _MSC_VER
#pragma warning (push)
#pragma warning (disable: 4251)     // class 'xxx' needs to have dll-interface to be used by clients of struct 'xxx' // when IMGUI_API is set to__declspec(dllexport)
#pragma warning (disable: 26812)    // The enum type 'xxx' is unscoped. Prefer 'enum class' over 'enum' (Enum.3). [MSVC Static Analyzer)
#pragma warning (disable: 26495)    // [Static Analyzer] Variable 'XXX' is uninitialized. Always initialize a member variable (type.6).
#if defined(_MSC_VER) && _MSC_VER >= 1922 // MSVC 2019 16.2 or later
#pragma warning (disable: 5054)     // operator '|': deprecated between enumerations of different types
}
}
+/

// Clang/GCC warnings with -Weverything
/+
#if defined(__clang__)
#pragma clang diagnostic push
#if __has_warning("-Wunknown-warning-option")
#pragma clang diagnostic ignored "-Wunknown-warning-option"         // warning: unknown warning group 'xxx'
}
#pragma clang diagnostic ignored "-Wunknown-pragmas"                // warning: unknown warning group 'xxx'
#pragma clang diagnostic ignored "-Wfloat-equal"                    // warning: comparing floating point with == or != is unsafe // storing and comparing against same constants ok, for ImFloorSigned()
#pragma clang diagnostic ignored "-Wunused-function"                // for stb_textedit.h
#pragma clang diagnostic ignored "-Wmissing-prototypes"             // for stb_textedit.h
#pragma clang diagnostic ignored "-Wold-style-cast"
#pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
#pragma clang diagnostic ignored "-Wdouble-promotion"
#pragma clang diagnostic ignored "-Wimplicit-int-float-conversion"  // warning: implicit conversion from 'xxx' to 'float' may lose precision
#pragma clang diagnostic ignored "-Wmissing-noreturn"               // warning: function 'xxx' could be declared with attribute 'noreturn'
#elif defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpragmas"              // warning: unknown option after '#pragma GCC diagnostic' kind
#pragma GCC diagnostic ignored "-Wclass-memaccess"      // [__GNUC__ >= 8] warning: 'memset/memcpy' clearing/writing an object of type 'xxxx' with no trivial copy-assignment; use assignment or value-initialization instead
}
+/

// In 1.89.4, we moved the implementation of "courtesy maths operators" from imgui_internal.h in imgui.h
// As they are frequently requested, we do not want to encourage to many people using imgui_internal.h
/*
#if defined(IMGUI_DEFINE_MATH_OPERATORS) && !defined(IMGUI_DEFINE_MATH_OPERATORS_IMPLEMENTED)
#error Please '#define IMGUI_DEFINE_MATH_OPERATORS' _BEFORE_ including imgui.h!
}
*/

// Legacy defines
/+
#ifdef IMGUI_DISABLE_FORMAT_STRING_FUNCTIONS            // Renamed in 1.74
#error Use IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS
}
#ifdef IMGUI_DISABLE_MATH_FUNCTIONS                     // Renamed in 1.74
#error Use IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS
}
+/

// Enable stb_truetype by default unless FreeType is enabled.
// You can compile with both by defining both IMGUI_ENABLE_FREETYPE and IMGUI_ENABLE_STB_TRUETYPE together.
/+
#ifndef IMGUI_ENABLE_FREETYPE
#define IMGUI_ENABLE_STB_TRUETYPE
}
+/
// D_IMGUI: We only support STB Truetype at the moment
enum IMGUI_ENABLE_FREETYPE = false;
enum IMGUI_ENABLE_STB_TRUETYPE = true;

//-----------------------------------------------------------------------------
// [SECTION] Forward declarations
//-----------------------------------------------------------------------------

/+
struct ImBitVector;                 // Store 1-bit per value
struct ImRect;                      // An axis-aligned rectangle (2 points)
struct ImDrawDataBuilder;           // Helper to build a ImDrawData instance
struct ImDrawListSharedData;        // Data shared between all ImDrawList instances
struct ImGuiColorMod;               // Stacked color modifier, backup of modified data so we can restore it
struct ImGuiContext;                // Main Dear ImGui context
struct ImGuiContextHook;            // Hook for extensions like ImGuiTestEngine
struct ImGuiDataVarInfo;            // Variable information (e.g. to avoid style variables from an enum)
struct ImGuiDataTypeInfo;           // Type information associated to a ImGuiDataType enum
struct ImGuiGroupData;              // Stacked storage data for BeginGroup()/EndGroup()
struct ImGuiInputTextState;         // Internal state of the currently focused/edited text input box
struct ImGuiInputTextDeactivateData;// Short term storage to backup text of a deactivating InputText() while another is stealing active id
struct ImGuiLastItemData;           // Status storage for last submitted items
struct ImGuiLocEntry;               // A localization entry.
struct ImGuiMenuColumns;            // Simple column measurement, currently used for MenuItem() only
struct ImGuiNavItemData;            // Result of a gamepad/keyboard directional navigation move query result
struct ImGuiMetricsConfig;          // Storage for ShowMetricsWindow() and DebugNodeXXX() functions
struct ImGuiNextWindowData;         // Storage for SetNextWindow** functions
struct ImGuiNextItemData;           // Storage for SetNextItem** functions
struct ImGuiOldColumnData;          // Storage data for a single column for legacy Columns() api
struct ImGuiOldColumns;             // Storage data for a columns set for legacy Columns() api
struct ImGuiPopupData;              // Storage for current popup stack
struct ImGuiSettingsHandler;        // Storage for one type registered in the .ini file
struct ImGuiStackSizes;             // Storage of stack sizes for debugging/asserting
struct ImGuiStyleMod;               // Stacked style modifier, backup of modified data so we can restore it
struct ImGuiTabBar;                 // Storage for a tab bar
struct ImGuiTabItem;                // Storage for a tab item (within a tab bar)
struct ImGuiTable;                  // Storage for a table
struct ImGuiTableColumn;            // Storage for one column of a table
struct ImGuiTableInstanceData;      // Storage for one instance of a same table
struct ImGuiTableTempData;          // Temporary storage for one table (one per table in the stack), shared between tables.
struct ImGuiTableSettings;          // Storage for a table .ini settings
struct ImGuiTableColumnsSettings;   // Storage for a column .ini settings
struct ImGuiWindow;                 // Storage for one window
struct ImGuiWindowTempData;         // Temporary storage for one window (that's the data which in theory we could ditch at the end of the frame, in practice we currently keep it for each window)
struct ImGuiWindowSettings;         // Storage for a window .ini settings (we keep one of those even if the actual window wasn't instanced during this session)
+/

// Enumerations
// Use your programming IDE "Go to definition" facility on the names of the center columns to find the actual flags/enum lists.
/+
enum ImGuiLocKey : int;                 // -> enum ImGuiLocKey              // Enum: a localization entry for translation.
typedef int ImGuiLayoutType;            // -> enum ImGuiLayoutType_         // Enum: Horizontal or vertical

// Flags
typedef int ImGuiActivateFlags;         // -> enum ImGuiActivateFlags_      // Flags: for navigation/focus function (will be for ActivateItem() later)
typedef int ImGuiDebugLogFlags;         // -> enum ImGuiDebugLogFlags_      // Flags: for ShowDebugLogWindow(), g.DebugLogFlags
typedef int ImGuiFocusRequestFlags;     // -> enum ImGuiFocusRequestFlags_  // Flags: for FocusWindow();
typedef int ImGuiInputFlags;            // -> enum ImGuiInputFlags_         // Flags: for IsKeyPressed(), IsMouseClicked(), SetKeyOwner(), SetItemKeyOwner() etc.
typedef int ImGuiItemFlags;             // -> enum ImGuiItemFlags_          // Flags: for PushItemFlag(), g.LastItemData.InFlags
typedef int ImGuiItemStatusFlags;       // -> enum ImGuiItemStatusFlags_    // Flags: for g.LastItemData.StatusFlags
typedef int ImGuiOldColumnFlags;        // -> enum ImGuiOldColumnFlags_     // Flags: for BeginColumns()
typedef int ImGuiNavHighlightFlags;     // -> enum ImGuiNavHighlightFlags_  // Flags: for RenderNavHighlight()
typedef int ImGuiNavMoveFlags;          // -> enum ImGuiNavMoveFlags_       // Flags: for navigation requests
typedef int ImGuiNextItemDataFlags;     // -> enum ImGuiNextItemDataFlags_  // Flags: for SetNextItemXXX() functions
typedef int ImGuiNextWindowDataFlags;   // -> enum ImGuiNextWindowDataFlags_// Flags: for SetNextWindowXXX() functions
typedef int ImGuiScrollFlags;           // -> enum ImGuiScrollFlags_        // Flags: for ScrollToItem() and navigation requests
typedef int ImGuiSeparatorFlags;        // -> enum ImGuiSeparatorFlags_     // Flags: for SeparatorEx()
typedef int ImGuiTextFlags;             // -> enum ImGuiTextFlags_          // Flags: for TextEx()
typedef int ImGuiTooltipFlags;          // -> enum ImGuiTooltipFlags_       // Flags: for BeginTooltipEx()
+/

alias ImGuiErrorLogCallback = void function(void* user_data, string fmt, va_list args);

//-----------------------------------------------------------------------------
// [SECTION] Context pointer
// See implementation of this variable in imgui.cpp for comments and details.
//-----------------------------------------------------------------------------

//#ifndef GImGui
//extern IMGUI_API ImGuiContext* GImGui;  // Current implicit context pointer
//#endif

//-------------------------------------------------------------------------
// [SECTION] STB libraries includes
//-------------------------------------------------------------------------

// namespace ImStb
// {

// #undef STB_TEXTEDIT_STRING
// #undef STB_TEXTEDIT_CHARTYPE
alias STB_TEXTEDIT_STRING             = ImGuiInputTextState;
alias STB_TEXTEDIT_CHARTYPE           = ImWchar;
enum STB_TEXTEDIT_GETWIDTH_NEWLINE   = (-1.0f);
enum STB_TEXTEDIT_UNDOSTATECOUNT     = 99;
enum STB_TEXTEDIT_UNDOCHARCOUNT      = 999;
import ImStb = d_imgui.imstb_textedit;

// } // namespace ImStb

//-----------------------------------------------------------------------------
// [SECTION] Macros
//-----------------------------------------------------------------------------

// Debug Printing Into TTY
// (since IMGUI_VERSION_NUM >= 18729: IMGUI_DEBUG_LOG was reworked into IMGUI_DEBUG_PRINTF (and removed framecount from it). If you were using a #define IMGUI_DEBUG_LOG please rename)
//#ifndef IMGUI_DEBUG_PRINTF
//#ifndef IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS
pragma(inline, true) void IMGUI_DEBUG_PRINTF(string _FMT, string data)    { ImFileWrite(data.ptr, data.length, ImGetStdout()); }
//} else {
//#define IMGUI_DEBUG_PRINTF(_FMT,...)    ((void)0)
//}
//}

// Debug Logging for ShowDebugLogWindow(). This is designed for relatively rare events so please don't spam.
//#ifndef IMGUI_DISABLE_DEBUG_TOOLS
pragma(inline, true) void IMGUI_DEBUG_LOG(A...)(string fmt, A a)            { mixin va_start!a; DebugLogV(fmt, va_args); };
//} else {
//#define IMGUI_DEBUG_LOG(...)            ((void)0)
//}
pragma(inline, true) void IMGUI_DEBUG_LOG_ACTIVEID(A...)(string fmt, A a)   { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventActiveId) DebugLogV(fmt, va_args); }
pragma(inline, true) void IMGUI_DEBUG_LOG_FOCUS(A...)(string fmt, A a)      { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventFocus)    DebugLogV(fmt, va_args); }
pragma(inline, true) void IMGUI_DEBUG_LOG_POPUP(A...)(string fmt, A a)      { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventPopup)    DebugLogV(fmt, va_args); }
pragma(inline, true) void IMGUI_DEBUG_LOG_NAV(A...)(string fmt, A a)        { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventNav)      DebugLogV(fmt, va_args); }
pragma(inline, true) void IMGUI_DEBUG_LOG_SELECTION(A...)(string fmt, A a)  { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventSelection)DebugLogV(__VA_ARGS__); }
pragma(inline, true) void IMGUI_DEBUG_LOG_CLIPPER(A...)(string fmt, A a)    { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventClipper)  DebugLogV(fmt, va_args); }
pragma(inline, true) void IMGUI_DEBUG_LOG_IO(A...)(string fmt, A a)         { mixin va_start!a; if (GImGui.DebugLogFlags & ImGuiDebugLogFlags.EventIO)       DebugLogV(fmt, va_args); }

// Static Asserts
void IM_STATIC_ASSERT(bool _COND)()         {static assert(_COND);}

// "Paranoid" Debug Asserts are meant to only be enabled during specific debugging/work, otherwise would slow down the code too much.
// We currently don't have many of those so the effect is currently negligible, but onward intent to add more aggressive ones in the code.
//#define IMGUI_DEBUG_PARANOID
static if (IMGUI_DEBUG_PARANOID) {
    alias IM_ASSERT_PARANOID = IM_ASSERT;
} else {
    pragma(inline, true) void IM_ASSERT_PARANOID(T)(T _EXPR) {}
}

// Error handling
// Down the line in some frameworks/languages we would like to have a way to redirect those to the programmer and recover from more faults.
static if (!D_IMGUI_USER_DEFINED_RECOVERABLE_ERROR) {
    alias IM_ASSERT_USER_ERROR = IM_ASSERT;   // Recoverable User Error
}

// Misc Macros
enum IM_PI                           = 3.14159265358979323846f;
static if (D_IMGUI_Windows && !D_IMGUI_NORMAL_NEWLINE_ON_WINDOWS) {
    enum IM_NEWLINE                      = "\r\n";   // Play it nice with Windows users (Update: since 2018-05, Notepad finally appears to support Unix-style carriage returns!)
} else {
    enum IM_NEWLINE                      = "\n";
}
//#ifndef IM_TABSIZE                      // Until we move this to runtime and/or add proper tab support, at least allow users to compile-time override
enum IM_TABSIZE                      = (4);
//}
pragma(inline, true) T IM_MEMALIGN(T)(T _OFF, int _ALIGN) {
    return (((_OFF) + ((_ALIGN) - 1)) & ~((_ALIGN) - 1));               // Memory align e.g. IM_ALIGN(0,4)=0, IM_ALIGN(1,4)=4, IM_ALIGN(4,4)=4, IM_ALIGN(5,4)=8
}
pragma(inline, true) int IM_F32_TO_INT8_UNBOUND(float _VAL) {
    return (cast(int)((_VAL) * 255.0f + ((_VAL)>=0 ? 0.5f : -0.5f)));   // Unsaturated, for display purpose
}
pragma(inline, true) ubyte IM_F32_TO_INT8_SAT(float _VAL) {
    return cast(ubyte)(cast(int)(ImSaturate(_VAL) * 255.0f + 0.5f));               // Saturated, always output 0..255
}
pragma(inline, true) float IM_FLOOR(float _VAL) {
    return (cast(float)cast(int)(_VAL));                                // ImFloor() is not inlined in MSVC debug builds
}
pragma(inline, true) float IM_ROUND(float _VAL) {
    return (cast(float)cast(int)((_VAL) + 0.5f)) ;                      //
}
//#define IM_STRINGIFY_HELPER(_X)         #_X
//#define IM_STRINGIFY(_X)                IM_STRINGIFY_HELPER(_X)                                 // Preprocessor idiom to stringify e.g. an integer.

/+
// Enforce cdecl calling convention for functions called by the standard library, in case compilation settings changed the default to e.g. __vectorcall
#ifdef _MSC_VER
#define IMGUI_CDECL __cdecl
#else
#define IMGUI_CDECL
#endif

// Warnings
#if defined(_MSC_VER) && !defined(__clang__)
#define IM_MSVC_WARNING_SUPPRESS(XXXX)  __pragma(warning(suppress: XXXX))
#else
#define IM_MSVC_WARNING_SUPPRESS(XXXX)
#endif
+/

// Debug Tools
// Use 'Metrics/Debugger->Tools->Item Picker' to break into the call-stack of a specific item.
// This will call IM_DEBUG_BREAK() which you may redefine yourself. See https://github.com/scottt/debugbreak for more reference.
static if (!D_IMGUI_USER_DEFINED_DEBUG_BREAK) {
    // It is expected that you define IM_DEBUG_BREAK() into something that will break nicely in a debugger!
    version (LDC) {
        pragma(inline, true) void IM_DEBUG_BREAK() {
            import ldc.llvmasm : __asm;
            __asm("int3", "");
        }
    } else {
        // On DMD asm cannot be inlined
        void IM_DEBUG_BREAK() {
            asm nothrow @nogc{
                int 3;
            }
        }
    }
} // #ifndef IM_DEBUG_BREAK
//-----------------------------------------------------------------------------
// [SECTION] Generic helpers
// Note that the ImXXX helpers functions are lower-level than ImGui functions.
// ImGui functions or the ImGui context are never called/used from other ImXXX functions.
//-----------------------------------------------------------------------------
// - Helpers: Hashing
// - Helpers: Sorting
// - Helpers: Bit manipulation
// - Helpers: String
// - Helpers: Formatting
// - Helpers: UTF-8 <> wchar conversions
// - Helpers: ImVec2/ImVec4 operators
// - Helpers: Maths
// - Helpers: Geometry
// - Helper: ImVec1
// - Helper: ImVec2ih
// - Helper: ImRect
// - Helper: ImBitArray
// - Helper: ImBitVector
// - Helper: ImSpan<>, ImSpanAllocator<>
// - Helper: ImPool<>
// - Helper: ImChunkStream<>
// - Helper: ImGuiTextIndex
//-----------------------------------------------------------------------------

// Helpers: Hashing
/*
ImGuiID       ImHashData(const void* data, size_t data_size, ImGuiID seed = 0);
ImGuiID       ImHashStr(string data, size_t data_size = 0, ImGuiID seed = 0);
*/

// Helpers: Sorting
// D_IMGUI: Dummy qsort implementation
void ImQsort(T)(T[] data, int function(const T*, const T*) nothrow @nogc comp) {
    if (data.length <= 1) return;
    ImQsortInternal(data,0, cast(int)data.length - 1, cast(int function(T*, T*) nothrow @nogc)comp);
}
void ImQsort(T)(T[] data, int function(T*, T*) nothrow @nogc comp) {
    if (data.length <= 1) return;
    ImQsortInternal(data, 0, cast(int)data.length - 1, comp);
}

void ImQsortInternal(T)(T[] data, int left, int right, int function(T*, T*) nothrow @nogc comp) {
    
    int i, last;
    void swap(T[] data, int a, int b) {
        T tmp = data[a];
        data[a] = data[b];
        data[b] = tmp;
    }

    if (left >= right)
        return;
    swap(data, left, (left + right)/2);
    last = left;
    for (i = left+1; i <= right; i++)
        if (comp(&data[i], &data[left]) < 0)
            swap(data, ++last, i);
    swap(data, left, last);
    ImQsortInternal(data, left, last-1, comp);
    ImQsortInternal(data, last+1, right, comp);
}
// ImU32         ImHashData(const void* data, size_t data_size, ImU32 seed = 0);
// ImU32         ImHashStr(const char* data, size_t data_size = 0, ImU32 seed = 0);
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    pragma(inline, true) ImU32     ImHash(const void* data, int size, ImU32 seed = 0) { return size ? ImHashData(data, cast(size_t)size, seed) : ImHashStr(ImCstring(cast(const char*)data), seed); } // [moved to ImHashStr/ImHashData in 1.68]
}

// Helpers: Color Blending
// IMGUI_API ImU32         ImAlphaBlendColors(ImU32 col_a, ImU32 col_b);

// Helpers: Bit manipulation
static pragma(inline, true) bool      ImIsPowerOfTwo(int v)           { return v != 0 && (v & (v - 1)) == 0; }
static pragma(inline, true) bool      ImIsPowerOfTwo(ImU64 v)         { return v != 0 && (v & (v - 1)) == 0; }
static pragma(inline, true) int       ImUpperPowerOfTwo(int v)        { v--; v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v++; return v; }

// Helpers: String
/+
int           ImStricmp(string str1, string str2);
int           ImStrnicmp(string str1, string str2, size_t count);
void          ImStrncpy(char* dst, string src, size_t count);
char*         ImStrdup(string str);
char*         ImStrdupcpy(char* dst, size_t* p_dst_size, string str);
string   ImStrchrRange(string str_begin, string str_end, char c);
int           ImStrlenW(const ImWchar* str);
string   ImStreolRange(string str, string str_end);                // End end-of-line
const ImWchar*ImStrbolW(const ImWchar* buf_mid_line, const ImWchar* buf_begin);   // Find beginning-of-line
string   ImStristr(string haystack, string haystack_end, string needle, string needle_end);
void          ImStrTrimBlanks(char* str);
string   ImStrSkipBlank(string str);
IM_MSVC_RUNTIME_CHECKS_OFF
+/
static pragma(inline, true) char      ImToUpper(char c)               { return (c >= 'a' && c <= 'z') ? c &= ~32 : c; }
static pragma(inline, true) bool      ImCharIsBlankA(char c)          { return c == ' ' || c == '\t'; }
static pragma(inline, true) bool      ImCharIsBlankW(uint c)  { return c == ' ' || c == '\t' || c == 0x3000; }
/+
IM_MSVC_RUNTIME_CHECKS_RESTORE

// Helpers: Formatting
int           ImFormatString(char* buf, size_t buf_size, string fmt, ...) IM_FMTARGS(3);
int           ImFormatStringV(char* buf, size_t buf_size, string fmt, va_list args) IM_FMTLIST(3);
void          ImFormatStringToTempBuffer(string* out_buf, string* out_buf_end, string fmt, ...) IM_FMTARGS(3);
void          ImFormatStringToTempBufferV(string* out_buf, string* out_buf_end, string fmt, va_list args) IM_FMTLIST(3);
string   ImParseFormatFindStart(string format);
string   ImParseFormatFindEnd(string format);
string   ImParseFormatTrimDecorations(string format, char* buf, size_t buf_size);
void          ImParseFormatSanitizeForPrinting(string fmt_in, char* fmt_out, size_t fmt_out_size);
string   ImParseFormatSanitizeForScanning(string fmt_in, char* fmt_out, size_t fmt_out_size);
int           ImParseFormatPrecision(string format, int default_value);
+/
/+

// Helpers: UTF-8 <> wchar conversions
string   ImTextCharToUtf8(char[5] out_buf, uint c);                                                      // return out_buf
int           ImTextStrToUtf8(char* out_buf, int out_buf_size, const ImWchar* in_text, const ImWchar* in_text_end);   // return output UTF-8 bytes count
int           ImTextCharFromUtf8(uint* out_char, string in_text, string in_text_end);               // read one character. return input UTF-8 bytes count
int           ImTextStrFromUtf8(ImWchar* out_buf, int out_buf_size, string in_text, string in_text_end, string* in_remaining = NULL);   // return input UTF-8 bytes count
int           ImTextCountCharsFromUtf8(string in_text, string in_text_end);                                 // return number of UTF-8 code-points (NOT bytes count)
int           ImTextCountUtf8BytesFromChar(string in_text, string in_text_end);                             // return number of bytes to express one char in UTF-8
int           ImTextCountUtf8BytesFromStr(const ImWchar* in_text, const ImWchar* in_text_end);                        // return number of bytes to express string in UTF-8
+/

// Helpers: File System
/+
version (IMGUI_DISABLE_FILE_FUNCTIONS) {
    // version = IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS;
    alias ImFileHandle = void*;
	static pragma(inline, true) ImFileHandle  ImFileOpen(string, string)                    { return NULL; }
	static pragma(inline, true) bool          ImFileClose(ImFileHandle)                               { return false; }
	static pragma(inline, true) ImU64         ImFileGetSize(ImFileHandle)                             { return (ImU64)-1; }
	static pragma(inline, true) ImU64         ImFileRead(void*, ImU64, ImFileHandle)           { return 0; }
	static pragma(inline, true) ImU64         ImFileWrite(const void*, ImU64, ImFileHandle)    { return 0; }
    // D_IMGUI: Encapsulate console handling.
    pragma(inline, true) ImFileHandle  ImGetStdout()                                           { return NULL; }
    pragma(inline, true) bool          ImFlushConsole(ImFileHandle)                            { return false; }
} else
+/
static if (!IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS) {
    // IMGUI_API ImFileHandle      ImFileOpen(string filename, string mode);
    // IMGUI_API bool              ImFileClose(ImFileHandle file);
    // IMGUI_API ImU64             ImFileGetSize(ImFileHandle file);
    // IMGUI_API ImU64             ImFileRead(void* data, ImU64 size, ImFileHandle file);
    // IMGUI_API ImU64             ImFileWrite(const void* data, ImU64 size, ImFileHandle file);
// #else
// #define IMGUI_DISABLE_TTY_FUNCTIONS // Can't use stdout, fflush if we are not using default file functions
}
    import core.stdc.stdio : FILE; // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
    alias ImFileHandle = FILE*;
// IMGUI_API void*             ImFileLoadToMemory(string filename, string mode, size_t* out_file_size = NULL, int padding_bytes = 0);

// Helpers: Maths
// IM_MSVC_RUNTIME_CHECKS_OFF
// - Wrapper for standard libs functions. (Note that imgui_demo.cpp does _not_ use them to keep the code easy to copy)
static if (!IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS) {
}
import core.stdc.math;
alias ImFabs = fabsf;
alias ImSqrt = sqrtf;
alias ImFmod = fmodf;
alias ImCos = cosf;
alias ImSin = sinf;
alias ImAcos = acosf;
alias ImAtan2 = atan2f;
double ImAtof(string str) {
    double result = 0.0;
    // ignore parse errors
    sscanf(str, "%lf", &result);
    return result;
}
pragma(inline, true) float  ImFloorStd(float X)     { return floorf(X); }           // We use our own, see ImFloor() and ImFloorSigned()
alias ImCeil = ceilf;
static pragma(inline, true) float  ImPow(float x, float y)    { return powf(x, y); }          // DragBehaviorT/SliderBehaviorT uses ImPow with either float/double and need the precision
static pragma(inline, true) double ImPow(double x, double y)  { return pow(x, y); } // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
static pragma(inline, true) float  ImLog(float x)             { return logf(x); }             // DragBehaviorT/SliderBehaviorT uses ImLog with either float/double and need the precision
static pragma(inline, true) double ImLog(double x)            { return log(x); }
static pragma(inline, true) int    ImAbs(int x)               { return x < 0 ? -x : x; }
static pragma(inline, true) float  ImAbs(float x)             { return fabsf(x); }
static pragma(inline, true) double ImAbs(double x)            { return fabs(x); }
static pragma(inline, true) float  ImSign(float x)            { return (x < 0.0f) ? -1.0f : (x > 0.0f) ? 1.0f : 0.0f; } // Sign operator - returns -1, 0 or 1 based on sign of argument
static pragma(inline, true) double ImSign(double x)           { return (x < 0.0) ? -1.0 : (x > 0.0) ? 1.0 : 0.0; }
version (IMGUI_ENABLE_SSE) {
static pragma(inline, true) float  ImRsqrt(float x)           { return _mm_cvtss_f32(_mm_rsqrt_ss(_mm_set_ss(x))); }
} else {
static pragma(inline, true) float  ImRsqrt(float x)           { return 1.0f / sqrtf(x); }
}
static pragma(inline, true) double ImRsqrt(double x)          { return 1.0 / sqrt(x); }

// - ImMin/ImMax/ImClamp/ImLerp/ImSwap are used by widgets which support variety of types: signed/unsigned int/long long float/double
// (Exceptionally using templates here but we could also redefine them for those types)
static pragma(inline, true) T ImMin(T)(T lhs, T rhs)                        { return lhs < rhs ? lhs : rhs; }
static pragma(inline, true) T ImMax(T)(T lhs, T rhs)                        { return lhs >= rhs ? lhs : rhs; }
static pragma(inline, true) T ImClamp(T)(T v, T mn, T mx)                   { return (v < mn) ? mn : (v > mx) ? mx : v; }
static pragma(inline, true) T ImLerp(T)(T a, T b, float t)                  { return cast(T)(a + (b - a) * t); }
static pragma(inline, true) void ImSwap(T)(ref T a, ref T b)                      { T tmp = a; a = b; b = tmp; }
static pragma(inline, true) T ImAddClampOverflow(T)(T a, T b, T mn, T mx)   { if (b < 0 && (a < mn - b)) return mn; if (b > 0 && (a > mx - b)) return mx; return cast(T)(a + b); }
static pragma(inline, true) T ImSubClampOverflow(T)(T a, T b, T mn, T mx)   { if (b > 0 && (a < mn + b)) return mn; if (b < 0 && (a > mx + b)) return mx; return cast(T)(a - b); }
// - Misc maths helpers
static pragma(inline, true) ImVec2 ImMin(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x < rhs.x ? lhs.x : rhs.x, lhs.y < rhs.y ? lhs.y : rhs.y); }
static pragma(inline, true) ImVec2 ImMax(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x >= rhs.x ? lhs.x : rhs.x, lhs.y >= rhs.y ? lhs.y : rhs.y); }
static pragma(inline, true) ImVec2 ImClamp(const ImVec2/*&*/ v, const ImVec2/*&*/ mn, ImVec2 mx)      { return ImVec2((v.x < mn.x) ? mn.x : (v.x > mx.x) ? mx.x : v.x, (v.y < mn.y) ? mn.y : (v.y > mx.y) ? mx.y : v.y); }
static pragma(inline, true) ImVec2 ImLerp(const ImVec2/*&*/ a, const ImVec2/*&*/ b, float t)          { return ImVec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t); }
static pragma(inline, true) ImVec2 ImLerp(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ t)  { return ImVec2(a.x + (b.x - a.x) * t.x, a.y + (b.y - a.y) * t.y); }
static pragma(inline, true) ImVec4 ImLerp(const ImVec4/*&*/ a, const ImVec4/*&*/ b, float t)          { return ImVec4(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t); }
static pragma(inline, true) float  ImSaturate(float f)                                        { return (f < 0.0f) ? 0.0f : (f > 1.0f) ? 1.0f : f; }
static pragma(inline, true) float  ImLengthSqr(const ImVec2/*&*/ lhs)                             { return (lhs.x * lhs.x) + (lhs.y * lhs.y); }
static pragma(inline, true) float  ImLengthSqr(const ImVec4/*&*/ lhs)                             { return (lhs.x * lhs.x) + (lhs.y * lhs.y) + (lhs.z * lhs.z) + (lhs.w * lhs.w); }
static pragma(inline, true) float  ImInvLength(const ImVec2/*&*/ lhs, float fail_value)           { float d = (lhs.x * lhs.x) + (lhs.y * lhs.y); if (d > 0.0f) return ImRsqrt(d); return fail_value; }
static pragma(inline, true) float  ImFloor(float f)                                           { return cast(float)cast(int)(f); }
static pragma(inline, true) float  ImFloorSigned(float f)                                     { return cast(float)((f >= 0 || cast(float)cast(int)f == f) ? cast(int)f : cast(int)f - 1); } // Decent replacement for floorf()
static pragma(inline, true) ImVec2 ImFloor(const ImVec2/*&*/ v)                                   { return ImVec2(cast(float)cast(int)(v.x), cast(float)cast(int)(v.y)); }
static pragma(inline, true) ImVec2 ImFloorSigned(const ImVec2/*&*/ v)                             { return ImVec2(ImFloorSigned(v.x), ImFloorSigned(v.y)); }
static pragma(inline, true) int    ImModPositive(int a, int b)                                { return (a + b) % b; }
static pragma(inline, true) float  ImDot(const ImVec2/*&*/ a, const ImVec2/*&*/ b)                    { return a.x * b.x + a.y * b.y; }
static pragma(inline, true) ImVec2 ImRotate(const ImVec2/*&*/ v, float cos_a, float sin_a)        { return ImVec2(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a); }
static pragma(inline, true) float  ImLinearSweep(float current, float target, float speed)    { if (current < target) return ImMin(current + speed, target); if (current > target) return ImMax(current - speed, target); return current; }
static pragma(inline, true) ImVec2 ImMul(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x * rhs.x, lhs.y * rhs.y); }
static pragma(inline, true) bool   ImIsFloatAboveGuaranteedIntegerPrecision(float f)          { return f <= -16777216 || f >= 16777216; }
static pragma(inline, true) float  ImExponentialMovingAverage(float avg, float sample, int n) { avg -= avg / n; avg += sample / n; return avg; }
//IM_MSVC_RUNTIME_CHECKS_RESTORE

// Helpers: Geometry
//ImVec2     ImBezierCubicCalc(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, float t);
//ImVec2     ImBezierCubicClosestPoint(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, const ImVec2/*&*/ p, int num_segments);       // For curves with explicit number of segments
//ImVec2     ImBezierCubicClosestPointCasteljau(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, const ImVec2/*&*/ p4, const ImVec2/*&*/ p, float tess_tol);// For auto-tessellated curves you can use tess_tol = style.CurveTessellationTol
//ImVec2     ImBezierQuadraticCalc(const ImVec2/*&*/ p1, const ImVec2/*&*/ p2, const ImVec2/*&*/ p3, float t);
//ImVec2     ImLineClosestPoint(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ p);
//bool       ImTriangleContainsPoint(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c, const ImVec2/*&*/ p);
//ImVec2     ImTriangleClosestPoint(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c, const ImVec2/*&*/ p);
//void       ImTriangleBarycentricCoords(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c, const ImVec2/*&*/ p, float& out_u, float& out_v, float& out_w);
pragma(inline, true) float         ImTriangleArea(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c) { return ImFabs((a.x * (b.y - c.y)) + (b.x * (c.y - a.y)) + (c.x * (a.y - b.y))) * 0.5f; }

// Helper: ImVec1 (1D vector)
// (this odd construct is used to facilitate the transition between 1D and 2D, and the maintenance of some branches/patches)
//IM_MSVC_RUNTIME_CHECKS_OFF
struct ImVec1
{
    nothrow:
    @nogc:

    float   x = 0.0f;
    this(bool dummy)         { x = 0.0f; }
    this(float _x) { x = _x; }
}

// Helper: ImVec2ih (2D vector, half-size integer, for long-term packed storage)
struct ImVec2ih
{
    nothrow:
    @nogc:

    short   x, y;
    //ImVec2ih()                           { x = y = 0; }
    this(short _x, short _y)         { x = _x; y = _y; }
    this(const ImVec2/*&*/ rhs) { x = cast(short)rhs.x; y = cast(short)rhs.y; }
}

// Helper: ImRect (2D axis aligned bounding-box)
// NB: we can't rely on ImVec2 math operators being available here!
struct ImRect
{
    nothrow:
    @nogc:

    ImVec2      Min;    // Upper-left
    ImVec2      Max;    // Lower-right

    //ImRect()                                        : Min(0.0f, 0.0f), Max(0.0f, 0.0f)  {}
    this(const ImVec2/*&*/ min, const ImVec2/*&*/ max)    { Min = min; Max = max; }
    this(const ImVec4/*&*/ v)                         { Min = ImVec2(v.x, v.y); Max = ImVec2(v.z, v.w); }
    this(float x1, float y1, float x2, float y2)  { Min = ImVec2(x1, y1); Max = ImVec2(x2, y2); }

    ImVec2      GetCenter() const                   { return ImVec2((Min.x + Max.x) * 0.5f, (Min.y + Max.y) * 0.5f); }
    ImVec2      GetSize() const                     { return ImVec2(Max.x - Min.x, Max.y - Min.y); }
    float       GetWidth() const                    { return Max.x - Min.x; }
    float       GetHeight() const                   { return Max.y - Min.y; }
    float       GetArea() const                     { return (Max.x - Min.x) * (Max.y - Min.y); }
    ImVec2      GetTL() const                       { return Min; }                   // Top-left
    ImVec2      GetTR() const                       { return ImVec2(Max.x, Min.y); }  // Top-right
    ImVec2      GetBL() const                       { return ImVec2(Min.x, Max.y); }  // Bottom-left
    ImVec2      GetBR() const                       { return Max; }                   // Bottom-right
    bool        Contains(const ImVec2/*&*/ p) const     { return p.x     >= Min.x && p.y     >= Min.y && p.x     <  Max.x && p.y     <  Max.y; }
    bool        Contains(const ImRect/*&*/ r) const     { return r.Min.x >= Min.x && r.Min.y >= Min.y && r.Max.x <= Max.x && r.Max.y <= Max.y; }
    bool        Overlaps(const ImRect/*&*/ r) const     { return r.Min.y <  Max.y && r.Max.y >  Min.y && r.Min.x <  Max.x && r.Max.x >  Min.x; }
    void        Add(const ImVec2/*&*/ p)                { if (Min.x > p.x)     Min.x = p.x;     if (Min.y > p.y)     Min.y = p.y;     if (Max.x < p.x)     Max.x = p.x;     if (Max.y < p.y)     Max.y = p.y; }
    void        Add(const ImRect/*&*/ r)                { if (Min.x > r.Min.x) Min.x = r.Min.x; if (Min.y > r.Min.y) Min.y = r.Min.y; if (Max.x < r.Max.x) Max.x = r.Max.x; if (Max.y < r.Max.y) Max.y = r.Max.y; }
    void        Expand(const float amount)          { Min.x -= amount;   Min.y -= amount;   Max.x += amount;   Max.y += amount; }
    void        Expand(const ImVec2/*&*/ amount)        { Min.x -= amount.x; Min.y -= amount.y; Max.x += amount.x; Max.y += amount.y; }
    void        Translate(const ImVec2/*&*/ d)          { Min.x += d.x; Min.y += d.y; Max.x += d.x; Max.y += d.y; }
    void        TranslateX(float dx)                { Min.x += dx; Max.x += dx; }
    void        TranslateY(float dy)                { Min.y += dy; Max.y += dy; }
    void        ClipWith(const ImRect/*&*/ r)           { Min = ImMax(Min, r.Min); Max = ImMin(Max, r.Max); }                   // Simple version, may lead to an inverted rectangle, which is fine for Contains/Overlaps test but not for display.
    void        ClipWithFull(const ImRect/*&*/ r)       { Min = ImClamp(Min, r.Min, r.Max); Max = ImClamp(Max, r.Min, r.Max); } // Full version, ensure both points are fully clipped.
    void        Floor()                             { Min.x = IM_FLOOR(Min.x); Min.y = IM_FLOOR(Min.y); Max.x = IM_FLOOR(Max.x); Max.y = IM_FLOOR(Max.y); }
    bool        IsInverted() const                  { return Min.x > Max.x || Min.y > Max.y; }
    ImVec4      ToVec4() const                      { return ImVec4(Min.x, Min.y, Max.x, Max.y); }
}

// Helper: ImBitArray
pragma(inline, true) bool         IM_BITARRAY_TESTBIT(const ImU32[] _ARRAY, int _N)                 { return IM_BITARRAY_TESTBIT(_ARRAY.ptr, _N); }
pragma(inline, true) bool         IM_BITARRAY_TESTBIT(const ImU32* _ARRAY, int _N)                 { return ((_ARRAY[(_N) >> 5] & (cast(ImU32)1 << ((_N) & 31))) != 0); } // Macro version of ImBitArrayTestBit(): ensure args have side-effect or are costly!
pragma(inline, true) void         IM_BITARRAY_CLEARBIT(ImU32* _ARRAY, int _N)                { ((_ARRAY[(_N) >> 5] &= ~(cast(ImU32)1 << ((_N) & 31)))); }    // Macro version of ImBitArrayClearBit(): ensure args have side-effect or are costly!
pragma(inline, true) size_t   ImBitArrayGetStorageSizeInBytes(int bitcount)   { return cast(size_t)((bitcount + 31) >> 5) << 2; }
pragma(inline, true) void     ImBitArrayClearAllBits(ImU32* arr, int bitcount){ memset(arr, 0, ImBitArrayGetStorageSizeInBytes(bitcount)); }
pragma(inline, true) bool     ImBitArrayTestBit(const ImU32[] arr, int n)      { return ImBitArrayTestBit(arr.ptr, n); }
pragma(inline, true) bool     ImBitArrayTestBit(const ImU32* arr, int n)      { ImU32 mask = cast(ImU32)1 << (n & 31); return (arr[n >> 5] & mask) != 0; }
pragma(inline, true) void     ImBitArrayClearBit(ImU32[] arr, int n)           { ImBitArrayClearBit(arr.ptr, n); }
pragma(inline, true) void     ImBitArrayClearBit(ImU32* arr, int n)           { ImU32 mask = cast(ImU32)1 << (n & 31); arr[n >> 5] &= ~mask; }
pragma(inline, true) void     ImBitArraySetBit(ImU32[] arr, int n)             { ImBitArraySetBit(arr.ptr, n); }
pragma(inline, true) void     ImBitArraySetBit(ImU32* arr, int n)             { ImU32 mask = cast(ImU32)1 << (n & 31); arr[n >> 5] |= mask; }
pragma(inline, true) void     ImBitArraySetBitRange(ImU32[] arr, int n, int n2) { ImBitArraySetBitRange(arr.ptr, n, n2); }
pragma(inline, true) void     ImBitArraySetBitRange(ImU32* arr, int n, int n2) // Works on range [n..n2)
{
    n2--;
    while (n <= n2)
    {
        int a_mod = (n & 31);
        int b_mod = (n2 > (n | 31) ? 31 : (n2 & 31)) + 1;
        ImU32 mask = cast(ImU32)((cast(ImU64)1 << b_mod) - 1) & ~cast(ImU32)((cast(ImU64)1 << a_mod) - 1);
        arr[n >> 5] |= mask;
        n = (n + 32) & ~31;
    }
}

alias ImBitArrayPtr = ImU32*; // Name for use in structs

// Helper: ImBitArray class (wrapper over ImBitArray functions)
// Store 1-bit per value.
struct ImBitArray(int BITCOUNT, int OFFSET = 0)
{
    nothrow:
    @nogc:

    ImU32[(BITCOUNT + 31) >> 5]           Storage;
    //ImBitArray()                                { ClearAllBits(); }
    void            ClearAllBits()              { memset(&Storage, 0, sizeof(Storage)); }
    void            SetAllBits()                { memset(&Storage, 255, sizeof(Storage)); }
    bool            TestBit(int n) const        { n += OFFSET; IM_ASSERT(n >= 0 && n < BITCOUNT); return ImBitArrayTestBit(Storage, n + OFFSET); }
    void            SetBit(int n)               { n += OFFSET; IM_ASSERT(n < BITCOUNT); ImBitArraySetBit(Storage, n); }
    void            ClearBit(int n)             { n += OFFSET; IM_ASSERT(n < BITCOUNT); ImBitArrayClearBit(Storage, n); }
    void            SetBitRange(int n, int n2)  { n += OFFSET; n2 += OFFSET; IM_ASSERT(n >= 0 && n < BITCOUNT && n2 > n && n2 <= BITCOUNT); ImBitArraySetBitRange(Storage, n, n2); } // Works on range [n..n2)
    bool            opIndex(int n) const     { n += OFFSET; IM_ASSERT(n >= 0 && n < BITCOUNT); return IM_BITARRAY_TESTBIT(Storage, n); }
}

// Helper: ImBitVector
// Store 1-bit per value.
struct ImBitVector
{
    nothrow:
    @nogc:

    ImVector!ImU32 Storage;
    void destroy() { Storage.destroy(); }
    void            Create(int sz)              { Storage.resize((sz + 31) >> 5); memset(Storage.Data, 0, cast(size_t)Storage.Size * sizeof(Storage.Data[0])); }
    void            Clear()                     { Storage.clear(); }
    bool            TestBit(int n) const        { IM_ASSERT(n < (Storage.Size << 5)); return IM_BITARRAY_TESTBIT(Storage.asArray(), n); }
    void            SetBit(int n)               { IM_ASSERT(n < (Storage.Size << 5)); ImBitArraySetBit(Storage.asArray(), n); }
    void            ClearBit(int n)             { IM_ASSERT(n < (Storage.Size << 5)); ImBitArrayClearBit(Storage.asArray(), n); }
}
//IM_MSVC_RUNTIME_CHECKS_RESTORE

// Helper: ImSpan<>
// Pointing to a span of data we don't own.
struct ImSpan(T)
{
    nothrow:
    @nogc:

    T*                  Data;
    T*                  DataEnd;

    // Constructors, destructor
    //pragma(inline, true) this(bool dummy)                                 { Data = DataEnd = NULL; }
    pragma(inline, true) this(T* data, int size)                { Data = data; DataEnd = data + size; }
    pragma(inline, true) this(T* data, T* data_end)             { Data = data; DataEnd = data_end; }

    pragma(inline, true) void         set(T* data, int size)      { Data = data; DataEnd = data + size; }
    pragma(inline, true) void         set(T* data, T* data_end)   { Data = data; DataEnd = data_end; }
    pragma(inline, true) int          size() const                { return cast(int)cast(ptrdiff_t)(DataEnd - Data); }
    pragma(inline, true) int          size_in_bytes() const       { return cast(int)cast(ptrdiff_t)(DataEnd - Data) * cast(int)sizeof!(T); }
    pragma(inline, true) ref T           opIndex(int i)           { T* p = Data + i; IM_ASSERT(p >= Data && p < DataEnd); return *p; }
    pragma(inline, true) ref const (T)     opIndex(int i) const     { const T* p = Data + i; IM_ASSERT(p >= Data && p < DataEnd); return *p; }

    pragma(inline, true) T*           begin()                     { return Data; }
    pragma(inline, true) const (T)*     begin() const               { return Data; }
    pragma(inline, true) T*           end()                       { return DataEnd; }
    pragma(inline, true) const (T)*     end() const                 { return DataEnd; }

    // Utilities
    pragma(inline, true) int  index_from_ptr(const T* it) const   { IM_ASSERT(it >= Data && it < DataEnd); const ptrdiff_t off = it - Data; return cast(int)off; }
}

// Helper: ImSpanAllocator<>
// Facilitate storing multiple chunks into a single large block (the "arena")
// - Usage: call Reserve() N times, allocate GetArenaSizeInBytes() worth, pass it to SetArenaBasePtr(), call GetSpan() N times to retrieve the aligned ranges.
struct ImSpanAllocator(int CHUNKS)
{
    nothrow:
    @nogc:

    char*   BasePtr;
    int     CurrOff;
    int     CurrIdx;
    int[CHUNKS]     Offsets;
    int[CHUNKS]     Sizes;

    this(bool dummy)                               { memset(&this, 0, sizeof(this)); }
    pragma(inline, true) void  Reserve(int n, size_t sz, int a=4) { IM_ASSERT(n == CurrIdx && n < CHUNKS); CurrOff = IM_MEMALIGN(CurrOff, a); Offsets[n] = CurrOff; Sizes[n] = cast(int)sz; CurrIdx++; CurrOff += cast(int)sz; }
    pragma(inline, true) int   GetArenaSizeInBytes()              { return CurrOff; }
    pragma(inline, true) void  SetArenaBasePtr(void* base_ptr)    { BasePtr = cast(char*)base_ptr; }
    pragma(inline, true) void* GetSpanPtrBegin(int n)             { IM_ASSERT(n >= 0 && n < CHUNKS && CurrIdx == CHUNKS); return cast(void*)(BasePtr + Offsets[n]); }
    pragma(inline, true) void* GetSpanPtrEnd(int n)               { IM_ASSERT(n >= 0 && n < CHUNKS && CurrIdx == CHUNKS); return cast(void*)(BasePtr + Offsets[n] + Sizes[n]); }
    pragma(inline, true) void  GetSpan(T)(int n, ImSpan!T* span)    { span.set(cast(T*)GetSpanPtrBegin(n), cast(T*)GetSpanPtrEnd(n)); }
}

// Helper: ImPool<>
// Basic keyed storage for contiguous instances, slow/amortized insertion, O(1) indexable, O(Log N) queries by ID over a dense/hot buffer,
// Honor constructor/destructor. Add/remove invalidate all pointers. Indexes have the same lifetime as the associated object.
alias ImPoolIdx = int;
struct ImPool(T)
{
    nothrow:
    @nogc:

    ImVector!T     Buf;        // Contiguous data
    ImGuiStorage    Map;        // ID->Index
    ImPoolIdx       FreeIdx;    // Next free idx to use
    ImPoolIdx       AliveCount; // Number of active/alive items (for display purpose)

    this(bool dummy)    { FreeIdx = AliveCount = 0; }
    void destroy()   { Clear(); }
    T*          GetByKey(ImGuiID key)               { int idx = Map.GetInt(key, -1); return (idx != -1) ? &Buf[idx] : NULL; }
    T*          GetByIndex(ImPoolIdx n)             { return &Buf[n]; }
    ImPoolIdx   GetIndex(const T* p) const          { IM_ASSERT(p >= Buf.Data && p < Buf.Data + Buf.Size); return cast(ImPoolIdx)(p - Buf.Data); }
    T*          GetOrAddByKey(ImGuiID key)          { int* p_idx = Map.GetIntRef(key, -1); if (*p_idx != -1) return &Buf[*p_idx]; *p_idx = FreeIdx; return Add(); }
    bool        Contains(const T* p) const          { return (p >= Buf.Data && p < Buf.Data + Buf.Size); }
    void        Clear()                             { for (int n = 0; n < Map.Data.Size; n++) { int idx = Map.Data[n].val_i; if (idx != -1) Buf[idx].destroy(); } Map.Clear(); Buf.clear(); FreeIdx = AliveCount = 0; }
    T*          Add()                               { int idx = FreeIdx; if (idx == Buf.Size) { Buf.resize(Buf.Size + 1); FreeIdx++; } else { FreeIdx = *cast(int*)&Buf[idx]; } IM_PLACEMENT_NEW(&Buf[idx], T(false)); AliveCount++; return &Buf[idx]; }
    void        Remove(ImGuiID key, const T* p)     { Remove(key, GetIndex(p)); }
    void        Remove(ImGuiID key, ImPoolIdx idx)  { Buf[idx].destroy(); *cast(int*)&Buf[idx] = FreeIdx; FreeIdx = idx; Map.SetInt(key, -1); AliveCount--; }
    void        Reserve(int capacity)               { Buf.reserve(capacity); Map.Data.reserve(capacity); }

    // To iterate a ImPool: for (int n = 0; n < pool.GetMapSize(); n++) if (T* t = pool.TryGetMapData(n)) { ... }
    // Can be avoided if you know .Remove() has never been called on the pool, or AliveCount == GetMapSize()
    int         GetAliveCount() const               { return AliveCount; }      // Number of active/alive items in the pool (for display purpose)
    int         GetBufSize() const                  { return Buf.Size; }
    int         GetMapSize() const                  { return Map.Data.Size; }   // It is the map we need iterate to find valid items, since we don't have "alive" storage anywhere
    T*          TryGetMapData(ImPoolIdx n)          { int idx = Map.Data[n].val_i; if (idx == -1) return NULL; return GetByIndex(idx); }
static if (IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    int         GetSize()                           { return GetMapSize(); } // For ImPlot: should use GetMapSize() from (IMGUI_VERSION_NUM >= 18304)
}
}

// Helper: ImChunkStream<>
// Build and iterate a contiguous stream of variable-sized structures.
// This is used by Settings to store persistent data while reducing allocation count.
// We store the chunk size first, and align the final size on 4 bytes boundaries.
// The tedious/zealous amount of casting is to avoid -Wcast-align warnings.
struct ImChunkStream(T)
{
    nothrow:
    @nogc:

    ImVector!char  Buf;

    void destroy() { Buf.destroy(); }
    void    clear()                     { Buf.clear(); }
    bool    empty() const               { return Buf.Size == 0; }
    int     size() const                { return Buf.Size; }
    T*      alloc_chunk(size_t sz)      { size_t HDR_SZ = 4; sz = IM_MEMALIGN(HDR_SZ + sz, 4u); int off = Buf.Size; Buf.resize(off + cast(int)sz); (cast(int*)cast(void*)(Buf.Data + off))[0] = cast(int)sz; return cast(T*)cast(void*)(Buf.Data + off + cast(int)HDR_SZ); }
    T*      begin()                     { size_t HDR_SZ = 4; if (!Buf.Data) return NULL; return cast(T*)cast(void*)(Buf.Data + HDR_SZ); }
    T*      next_chunk(T* p)            { size_t HDR_SZ = 4; IM_ASSERT(p >= begin() && p < end()); p = cast(T*)cast(void*)(cast(char*)cast(void*)p + chunk_size(p)); if (p == cast(T*)cast(void*)(cast(char*)end() + HDR_SZ)) return cast(T*)0; IM_ASSERT(p < end()); return p; }
    int     chunk_size(const T* p)      { return (cast(const int*)p)[-1]; }
    T*      end()                       { return cast(T*)cast(void*)(Buf.Data + Buf.Size); }
    int     offset_from_ptr(const T* p) { IM_ASSERT(p >= begin() && p < end()); const ptrdiff_t off = cast(const char*)p - Buf.Data; return cast(int)off; }
    T*      ptr_from_offset(int off)    { IM_ASSERT(off >= 4 && off < Buf.Size); return cast(T*)cast(void*)(Buf.Data + off); }
    void    swap(ref ImChunkStream!T rhs) { rhs.Buf.swap(Buf); }

}

// Helper: ImGuiTextIndex<>
// Maintain a line index for a text buffer. This is a strong candidate to be moved into the public API.
struct ImGuiTextIndex
{
    nothrow:
    @nogc:

    ImVector!int   LineOffsets;
    int             EndOffset = 0;                          // Because we don't own text buffer we need to maintain EndOffset (may bake in LineOffsets?)

    void destroy() { LineOffsets.destroy(); }
    void            clear()                                 { LineOffsets.clear(); EndOffset = 0; }
    int             size()                                  { return LineOffsets.Size; }
    string     get_line(string base, int n) { return base[LineOffsets[n] .. (n + 1 < LineOffsets.Size ? (LineOffsets[n + 1] - 1) : EndOffset)]; }
    void            append(string base, int old_size, int new_size) { (cast(ImGuiTextIndex_Wrapper*)&this).append(base, old_size, new_size); }
}

//-----------------------------------------------------------------------------
// [SECTION] ImDrawList support
//-----------------------------------------------------------------------------

// ImDrawList: Helper function to calculate a circle's segment count given its radius and a "maximum error" value.
// Estimation of number of circle segment based on error is derived using method described in https://stackoverflow.com/a/2244088/15194693
// Number of segments (N) is calculated using equation:
//   N = ceil ( pi / acos(1 - error / r) )     where r > 0, error <= r
// Our equation is significantly simpler that one in the post thanks for choosing segment that is
// perpendicular to X axis. Follow steps in the article from this starting condition and you will
// will get this result.
//
// Rendering circles with an odd number of segments, while mathematically correct will produce
// asymmetrical results on the raster grid. Therefore we're rounding N to next even number (7->8, 8->8, 9->10 etc.)
pragma(inline, true) int IM_ROUNDUP_TO_EVEN(int _V)                                  { return ((((_V) + 1) / 2) * 2); }
enum IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN                     = 4;
enum IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX                     = 512;
pragma(inline, true) int IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(float _RAD, float _MAXERROR)    { return ImClamp(IM_ROUNDUP_TO_EVEN(cast(int)ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX); }

// Raw equation from IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC rewritten for 'r' and 'error'.
pragma(inline, true) float IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(int _N, float _MAXERROR)    { return ((_MAXERROR) / (1 - ImCos(IM_PI / ImMax(cast(float)(_N), IM_PI)))); }
pragma(inline, true) float IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(int _N, float _RAD)     { return ((1 - ImCos(IM_PI / ImMax(cast(float)(_N), IM_PI))) / (_RAD)); }

// ImDrawList: Lookup table size for adaptive arc drawing, cover full circle.
//#ifndef IM_DRAWLIST_ARCFAST_TABLE_SIZE
enum IM_DRAWLIST_ARCFAST_TABLE_SIZE                          = 48; // Number of samples in lookup table.
//#endif
enum IM_DRAWLIST_ARCFAST_SAMPLE_MAX                          = IM_DRAWLIST_ARCFAST_TABLE_SIZE; // Sample index _PathArcToFastEx() for 360 angle.

// Data shared between all ImDrawList instances
// You may want to create your own instance of this if you want to use ImDrawList completely without ImGui. In that case, watch out for future changes to this structure.
struct ImDrawListSharedData
{
    nothrow:
    @nogc:

    ImVec2          TexUvWhitePixel;            // UV of white pixel in the atlas
    ImFont*         Font;                       // Current/default font (optional, for simplified AddText overload)
    float           FontSize;                   // Current/default font size (optional, for simplified AddText overload)
    float           CurveTessellationTol;       // Tessellation tolerance when using PathBezierCurveTo()
    float           CircleSegmentMaxError;      // Number of circle segments to use per pixel of radius for AddCircle() etc
    ImVec4          ClipRectFullscreen;         // Value for PushClipRectFullscreen()
    ImDrawListFlags InitialFlags;               // Initial flags at the beginning of the frame (it is possible to alter flags on a per-drawlist basis afterwards)

    // [Internal] Temp write buffer
    ImVector!ImVec2 TempBuffer;

    // [Internal] Lookup tables
    ImVec2[IM_DRAWLIST_ARCFAST_TABLE_SIZE]          ArcFastVtx; // Sample points on the quarter of the circle.
    float           ArcFastRadiusCutoff;                        // Cutoff radius after which arc drawing will fallback to slower PathArcTo()
    ImU8[64]            CircleSegmentCounts;    // Precomputed segment count for given radius before we calculate it dynamically (to avoid calculation overhead)
    const (ImVec4)*   TexUvLines;                 // UV of anti-aliased lines in the atlas

    @disable this();
    this(bool dummy) { (cast(ImDrawListSharedData_Wrapper*)&this).__ctor(dummy); }
    void destroy() { TempBuffer.destroy(); }
    void SetCircleTessellationMaxError(float max_error) { (cast(ImDrawListSharedData_Wrapper*)&this).SetCircleTessellationMaxError(max_error); }
}

struct ImDrawDataBuilder
{
    nothrow:
    @nogc:

    ImVector!(ImDrawList*)[2]   Layers;           // Global layers for: regular, tooltip

    void Clear()                    { for (int n = 0; n < IM_ARRAYSIZE(Layers); n++) Layers[n].resize(0); }
    void ClearFreeMemory()          { for (int n = 0; n < IM_ARRAYSIZE(Layers); n++) Layers[n].clear(); }
    int  GetDrawListCount() const   { int count = 0; for (int n = 0; n < IM_ARRAYSIZE(Layers); n++) count += Layers[n].Size; return count; }
    void FlattenIntoSingleLayer() { (cast(ImDrawDataBuilder_Wrapper*)&this).FlattenIntoSingleLayer(); }
}

//-----------------------------------------------------------------------------
// [SECTION] Widgets support: flags, enums, data structures
//-----------------------------------------------------------------------------

// Flags used by upcoming items
// - input: PushItemFlag() manipulates g.CurrentItemFlags, ItemAdd() calls may add extra flags.
// - output: stored in g.LastItemData.InFlags
// Current window shared by all windows.
// This is going to be exposed in imgui.h when stabilized enough.
enum ImGuiItemFlags : int
{
    // Controlled by user
    None                     = 0,
    NoTabStop                = 1 << 0,  // false     // Disable keyboard tabbing. This is a "lighter" version of ImGuiItemFlags_NoNav.
    ButtonRepeat             = 1 << 1,  // false     // Button() will return true multiple times based on io.KeyRepeatDelay and io.KeyRepeatRate settings.
    Disabled                 = 1 << 2,  // false     // Disable interactions but doesn't affect visuals. See BeginDisabled()/EndDisabled(). See github.com/ocornut/imgui/issues/211
    NoNav                    = 1 << 3,  // false     // Disable any form of focusing (keyboard/gamepad directional navigation and SetKeyboardFocusHere() calls)
    NoNavDefaultFocus        = 1 << 4,  // false     // Disable item being a candidate for default focus (e.g. used by title bar items)
    SelectableDontClosePopup = 1 << 5,  // false     // Disable MenuItem/Selectable() automatically closing their popup window
    MixedValue               = 1 << 6,  // false     // [BETA] Represent a mixed/indeterminate value, generally multi-selection where values differ. Currently only supported by Checkbox() (later should support all sorts of widgets)
    ReadOnly                 = 1 << 7,  // false     // [ALPHA] Allow hovering interactions but underlying value is not changed.
    NoWindowHoverableCheck   = 1 << 8,  // false     // Disable hoverable check in ItemHoverable()
    AllowOverlap             = 1 << 9,  // false     // Allow being overlapped by another widget. Not-hovered to Hovered transition deferred by a frame.

    // Controlled by widget code
    Inputable                = 1 << 10, // false     // [WIP] Auto-activate input mode when tab focused. Currently only used and supported by a few items before it becomes a generic feature.
}

// Status flags for an already submitted item
// - output: stored in g.LastItemData.StatusFlags
enum ImGuiItemStatusFlags : int
{
    None               = 0,
    HoveredRect        = 1 << 0,   // Mouse position is within item rectangle (does NOT mean that the window is in correct z-order and can be hovered!, this is only one part of the most-common IsItemHovered test)
    HasDisplayRect     = 1 << 1,   // g.LastItemData.DisplayRect is valid
    Edited             = 1 << 2,   // Value exposed by item was edited in the current frame (should match the bool return value of most widgets)
    ToggledSelection   = 1 << 3,   // Set when Selectable(), TreeNode() reports toggling a selection. We can't report "Selected", only state changes, in order to easily handle clipping with less issues.
    ToggledOpen        = 1 << 4,   // Set when TreeNode() reports toggling their open state.
    HasDeactivated     = 1 << 5,   // Set if the widget/group is able to provide data for the ImGuiItemStatusFlags_Deactivated flag.
    Deactivated        = 1 << 6,   // Only valid if ImGuiItemStatusFlags_HasDeactivated is set.
    HoveredWindow      = 1 << 7,   // Override the HoveredWindow test to allow cross-window hover testing.
    FocusedByTabbing   = 1 << 8,   // Set when the Focusable item just got focused by Tabbing (FIXME: to be removed soon)
    Visible            = 1 << 9,   // [WIP] Set when item is overlapping the current clipping rectangle (Used internally. Please don't use yet: API/system will change as we refactor Itemadd()).

    // Additional status + semantic for ImGuiTestEngine
// #ifdef IMGUI_ENABLE_TEST_ENGINE
    Openable           = 1 << 20,  // Item is an openable (e.g. TreeNode)
    Opened             = 1 << 21,  // Opened status
    Checkable          = 1 << 22,  // Item is a checkable (e.g. CheckBox, MenuItem)
    Checked            = 1 << 23,  // Checked status
    Inputable          = 1 << 24,  // Item is a text-inputable (e.g. InputText, SliderXXX, DragXXX)
// }
}

// Extend ImGuiHoveredFlags_
// D_IMGUI: Moved into ImGuiHoveredFlags
/+
enum ImGuiHoveredFlagsPrivate_
{
    DelayMask_                    = ImGuiHoveredFlags.DelayNone | ImGuiHoveredFlags.DelayShort | ImGuiHoveredFlags.DelayNormal | ImGuiHoveredFlags.NoSharedDelay,
    AllowedMaskForIsWindowHovered = ImGuiHoveredFlags.ChildWindows | ImGuiHoveredFlags.RootWindow | ImGuiHoveredFlags.AnyWindow | ImGuiHoveredFlags.NoPopupHierarchy | ImGuiHoveredFlags.AllowWhenBlockedByPopup | ImGuiHoveredFlags.AllowWhenBlockedByActiveItem | ImGuiHoveredFlags.ForTooltip | ImGuiHoveredFlags.Stationary,
    AllowedMaskForIsItemHovered   = ImGuiHoveredFlags.AllowWhenBlockedByPopup | ImGuiHoveredFlags.AllowWhenBlockedByActiveItem | ImGuiHoveredFlags.AllowWhenOverlapped | ImGuiHoveredFlags.AllowWhenDisabled | ImGuiHoveredFlags.NoNavOverride | ImGuiHoveredFlags.ForTooltip | ImGuiHoveredFlags.Stationary | ImGuiHoveredFlags.DelayMask_,
}
+/

// Extend ImGuiInputTextFlags_
// D_IMGUI: Moved into ImGuiInputTextFlags
/+
enum ImGuiInputTextFlagsPrivate_
{
    // [Internal]
    Multiline           = 1 << 26,  // For internal use by InputTextMultiline()
    NoMarkEdited        = 1 << 27,  // For internal use by functions using InputText() before reformatting data
    MergedItem          = 1 << 28,  // For internal use by TempInputText(), will skip calling ItemAdd(). Require bounding-box to strictly match.
}
+/

// Extend ImGuiButtonFlags_
// D_IMGUI: Moved into ImGuiButtonFlags
/+
enum ImGuiButtonFlagsPrivate_
{
    PressedOnClick         = 1 << 4,   // return true on click (mouse down event)
    PressedOnClickRelease  = 1 << 5,   // [Default] return true on click + release on same item <-- this is what the majority of Button are using
    PressedOnClickReleaseAnywhere = 1 << 6, // return true on click + release even if the release event is not done while hovering the item
    PressedOnRelease       = 1 << 7,   // return true on release (default requires click+release)
    PressedOnDoubleClick   = 1 << 8,   // return true on double-click (default requires click+release)
    PressedOnDragDropHold  = 1 << 9,   // return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
    Repeat                 = 1 << 10,  // hold to repeat
    FlattenChildren        = 1 << 11,  // allow interactions even if a child window is overlapping
    AllowOverlap           = 1 << 12,  // require previous frame HoveredId to either match id or be null before being usable.
    DontClosePopups        = 1 << 13,  // disable automatically closing parent popup on press // [UNUSED]
    //ImGuiButtonFlags_Disabled             = 1 << 14,  // disable interactions -> use BeginDisabled() or ImGuiItemFlags_Disabled
    AlignTextBaseLine      = 1 << 15,  // vertically align button to match text baseline - ButtonEx() only // FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
    NoKeyModifiers         = 1 << 16,  // disable mouse interaction if a key modifier is held
    NoHoldingActiveId      = 1 << 17,  // don't set ActiveId while holding the mouse (ImGuiButtonFlags_PressedOnClick only)
    NoNavFocus             = 1 << 18,  // don't override navigation focus when activated (FIXME: this is essentially used everytime an item uses ImGuiItemFlags_NoNav, but because legacy specs don't requires LastItemData to be set ButtonBehavior(), we can't poll g.LastItemData.InFlags)
    NoHoveredOnFocus       = 1 << 19,  // don't report as hovered when nav focus is on this item
    NoSetKeyOwner          = 1 << 20,  // don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
    NoTestKeyOwner         = 1 << 21,  // don't test key/input owner when polling the key (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
    PressedOnMask_         = ImGuiButtonFlags.PressedOnClick | ImGuiButtonFlags.PressedOnClickRelease | ImGuiButtonFlags.PressedOnClickReleaseAnywhere | ImGuiButtonFlags.PressedOnRelease | ImGuiButtonFlags.PressedOnDoubleClick | ImGuiButtonFlags.PressedOnDragDropHold,
    PressedOnDefault_      = ImGuiButtonFlags.PressedOnClickRelease,
}
+/

// Extend ImGuiComboFlags_
// D_IMGUI: Moved into ImGuiComboFlags_
/+
enum ImGuiComboFlagsPrivate_
{
    CustomPreview           = 1 << 20,  // enable BeginComboPreview()
}
+/

// Extend ImGuiSliderFlags_
// D_IMGUI: Moved into ImGuiSliderFlags
/+
enum ImGuiSliderFlagsPrivate_
{
    Vertical               = 1 << 20,  // Should this slider be orientated vertically?
    ReadOnly               = 1 << 21,
}
+/

// Extend ImGuiSelectableFlags_
// D_IMGUI: Moved into ImGuiSelectableFlags
/+
enum ImGuiSelectableFlagsPrivate_
{
    // NB: need to be in sync with last value of ImGuiSelectableFlags_
    NoHoldingActiveID      = 1 << 20,
    SelectOnNav            = 1 << 21,  // (WIP) Auto-select when moved into. This is not exposed in public API as to handle multi-select and modifiers we will need user to explicitly control focus scope. May be replaced with a BeginSelection() API.
    SelectOnClick          = 1 << 22,  // Override button behavior to react on Click (default is Click+Release)
    SelectOnRelease        = 1 << 23,  // Override button behavior to react on Release (default is Click+Release)
    SpanAvailWidth         = 1 << 24,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    SetNavIdOnHover        = 1 << 25,  // Set Nav/Focus ID on mouse hover (used by MenuItem)
    NoPadWithHalfSpacing   = 1 << 26,  // Disable padding each side with ItemSpacing * 0.5f
    NoSetKeyOwner          = 1 << 27,  // Don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
}
+/

// Extend ImGuiTreeNodeFlags_
// D_IMGUI: Moved into ImGuiTreeNodeFlags
/+
enum ImGuiTreeNodeFlagsPrivate_
{
    ClipLabelForTrailingButton = 1 << 20,
    UpsideDownArrow            = 1 << 21,// (FIXME-WIP) Turn Down arrow into an Up arrow, but reversed trees (#6517)
}
+/

enum ImGuiSeparatorFlags : int
{
    None                    = 0,
    Horizontal              = 1 << 0,   // Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
    Vertical                = 1 << 1,
    SpanAllColumns          = 1 << 2,   // Make separator cover all columns of a legacy Columns() set.
}

// Flags for FocusWindow(). This is not called ImGuiFocusFlags to avoid confusion with public-facing ImGuiFocusedFlags.
// FIXME: Once we finishing replacing more uses of GetTopMostPopupModal()+IsWindowWithinBeginStackOf()
// and FindBlockingModal() with this, we may want to change the flag to be opt-out instead of opt-in.
enum ImGuiFocusRequestFlags : int
{
    None                 = 0,
    RestoreFocusedChild  = 1 << 0,   // Find last focused child (if any) and focus it instead.
    UnlessBelowModal     = 1 << 1,   // Do not set focus if the window is below a modal.
}

enum ImGuiTextFlags : int
{
    None                         = 0,
    NoWidthForLargeClippedText   = 1 << 0,
}

enum ImGuiTooltipFlags : int
{
    None                      = 0,
    OverridePrevious          = 1 << 1,   // Clear/ignore previously submitted tooltip (defaults to append)
}

// FIXME: this is in development, not exposed/functional as a generic feature yet.
// Horizontal/Vertical enums are fixed to 0/1 so they may be used to index ImVec2
enum ImGuiLayoutType : int
{
    Horizontal = 0,
    Vertical = 1
}

enum ImGuiLogType : int
{
    None = 0,
    TTY,
    File,
    Buffer,
    Clipboard,
}

// X/Y enums are fixed to 0/1 so they may be used to index ImVec2
enum ImGuiAxis : int
{
    None = -1,
    X = 0,
    Y = 1
}

enum ImGuiPlotType : int
{
    Lines,
    Histogram,
}

enum ImGuiPopupPositionPolicy : int
{
    Default,
    ComboBox,
    Tooltip,
}

struct ImGuiDataVarInfo
{
    nothrow:
    @nogc:

    ImGuiDataType   Type;
    ImU32           Count;      // 1+
    ImU32           Offset;     // Offset in parent structure
    void* GetVarPtr(void* parent) const { return cast(void*)(cast(ubyte*)parent + Offset); }
}

struct ImGuiDataTypeTempStorage
{
    ImU8[8]        Data;        // Can fit any data up to ImGuiDataType_COUNT
}

// Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().
struct ImGuiDataTypeInfo
{
    size_t      Size;           // Size in bytes
    string Name;           // Short descriptive name for the type, for debugging
    string PrintFmt;       // Default printf format for the type
    string ScanFmt;        // Default scanf format for the type
}

// D_IMGUI: Moved into ImGuiDataType
/+
// Extend ImGuiDataType_
enum ImGuiDataTypePrivate_
{
    String = ImGuiDataType.COUNT + 1,
    Pointer,
    ID,
}
+/

// Stacked color modifier, backup of modified data so we can restore it
struct ImGuiColorMod
{
    ImGuiCol        Col;
    ImVec4          BackupValue;
}

// Stacked style modifier, backup of modified data so we can restore it. Data type inferred from the variable.
struct ImGuiStyleMod
{
    nothrow:
    @nogc:

    ImGuiStyleVar   VarIdx;
    union           { int[2] BackupInt; float[2] BackupFloat; }
    this(ImGuiStyleVar idx, int v)     { VarIdx = idx; BackupInt[0] = v; }
    this(ImGuiStyleVar idx, float v)   { VarIdx = idx; BackupFloat[0] = v; }
    this(ImGuiStyleVar idx, ImVec2 v)  { VarIdx = idx; BackupFloat[0] = v.x; BackupFloat[1] = v.y; }
}

// Storage data for BeginComboPreview()/EndComboPreview()
struct ImGuiComboPreviewData
{
    nothrow:
    @nogc:

    ImRect          PreviewRect;
    ImVec2          BackupCursorPos;
    ImVec2          BackupCursorMaxPos;
    ImVec2          BackupCursorPosPrevLine;
    float           BackupPrevLineTextBaseOffset;
    ImGuiLayoutType BackupLayout;

    @disable this();
    this(bool dummy) { memset(&this, 0, sizeof(this)); }
}

// Stacked storage data for BeginGroup()/EndGroup()
struct ImGuiGroupData
{
    ImGuiID     WindowID;
    ImVec2      BackupCursorPos;
    ImVec2      BackupCursorMaxPos;
    ImVec1      BackupIndent;
    ImVec1      BackupGroupOffset;
    ImVec2      BackupCurrLineSize;
    float       BackupCurrLineTextBaseOffset;
    ImGuiID     BackupActiveIdIsAlive;
    bool        BackupActiveIdPreviousFrameIsAlive;
    bool        BackupHoveredIdIsAlive;
    bool        EmitItem;
}

// Simple column measurement, currently used for MenuItem() only.. This is very short-sighted/throw-away code and NOT a generic helper.
struct ImGuiMenuColumns
{
    nothrow:
    @nogc:

    ImU32       TotalWidth;
    ImU32       NextTotalWidth;
    ImU16       Spacing;
    ImU16       OffsetIcon;         // Always zero for now
    ImU16       OffsetLabel;        // Offsets are locked in Update()
    ImU16       OffsetShortcut;
    ImU16       OffsetMark;
    ImU16[4]       Widths;          // Width of:   Icon, Label, Shortcut, Mark  (accumulators for current frame)

    @disable this();
    this(bool dummy) { memset(&this, 0, sizeof(this)); }
    void        Update(float spacing, bool window_reappearing) { (cast(ImGuiMenuColumns_Wrapper*)&this).Update(spacing, window_reappearing); }
    float       DeclColumns(float w_icon, float w_label, float w_shortcut, float w_mark) { return (cast(ImGuiMenuColumns_Wrapper*)&this).DeclColumns(w_icon, w_label, w_shortcut, w_mark); }
    void        CalcNextTotalWidth(bool update_offsets) { (cast(ImGuiMenuColumns_Wrapper*)&this).CalcNextTotalWidth(update_offsets); }
}

// Internal temporary state for deactivating InputText() instances.
struct ImGuiInputTextDeactivatedState
{
    nothrow:
    @nogc:

    ImGuiID            ID;              // widget id owning the text state (which just got deactivated)
    ImVector!char     TextA;           // text buffer

    //this(boool dummy)    { memset(&this, 0, sizeof(this)); }
    void    ClearFreeMemory()           { ID = 0; TextA.clear(); }
}
// Internal state of the currently focused/edited text input box
// For a given item ID, access with ImGui::GetInputTextState()
struct ImGuiInputTextState
{
    nothrow:
    @nogc:

    ImGuiContext*           Ctx;                    // parent UI context (needs to be set explicitly by parent).
    ImGuiID                 ID;                     // widget id owning the text state
    int                     CurLenW, CurLenA;       // we need to maintain our buffer length in both UTF-8 and wchar format. UTF-8 length is valid even if TextA is not.
    ImVector!ImWchar       TextW;                  // edit buffer, we need to persist but can't guarantee the persistence of the user-provided buffer. so we copy into own buffer.
    ImVector!char          TextA;                  // temporary UTF8 buffer for callbacks and other operations. this is not updated in every code-path! size=capacity.
    ImVector!char          InitialTextA;           // backup of end-user buffer at the time of focus (in UTF-8, unaltered)
    bool                    TextAIsValid;           // temporary UTF8 buffer is not initially valid before we make the widget active (until then we pull the data from user argument)
    int                     BufCapacityA;           // end-user buffer capacity
    float                   ScrollX = 0;                // horizontal scrolling/offset
    ImStb.STB_TexteditState Stb;                   // state for stb_textedit.h
    float                   CursorAnim = 0;             // timer for cursor blink, reset on every user action so the cursor reappears immediately
    bool                    CursorFollow;           // set when we want scrolling to follow the current cursor position (not always!)
    bool                    SelectedAllMouseLock;   // after a double-click to select all, we ignore further mouse drags to update selection
    bool                    Edited;                 // edited this frame
    ImGuiInputTextFlags     Flags;                  // copy of InputText() flags. may be used to check if e.g. ImGuiInputTextFlags_Password is set.

    @disable this();
    this(bool dummy)                   { memset(&this, 0, sizeof(this)); }
    void destroy() { ClearFreeMemory(); }
    void        ClearText()                 { CurLenW = CurLenA = 0; TextW[0] = 0; TextA[0] = 0; CursorClamp(); }
    void        ClearFreeMemory()           { TextW.clear(); TextA.clear(); InitialTextA.clear(); }
    int         GetUndoAvailCount() const   { return Stb.undostate.undo_point; }
    int         GetRedoAvailCount() const   { return STB_TEXTEDIT_UNDOSTATECOUNT - Stb.undostate.redo_point; }
    void        OnKeyPressed(int key) { (cast(ImGuiInputTextState_Wrapper*)&this).OnKeyPressed(key); }      // Cannot be inline because we call in code in stb_textedit.h implementation

    // Cursor & Selection
    void        CursorAnimReset()           { CursorAnim = -0.30f; }                                   // After a user-input the cursor stays on for a while without blinking
    void        CursorClamp()               { Stb.cursor = ImMin(Stb.cursor, CurLenW); Stb.select_start = ImMin(Stb.select_start, CurLenW); Stb.select_end = ImMin(Stb.select_end, CurLenW); }
    bool        HasSelection() const        { return Stb.select_start != Stb.select_end; }
    void        ClearSelection()            { Stb.select_start = Stb.select_end = Stb.cursor; }
    int         GetCursorPos() const        { return Stb.cursor; }
    int         GetSelectionStart() const   { return Stb.select_start; }
    int         GetSelectionEnd() const     { return Stb.select_end; }
    void        SelectAll()                 { Stb.select_start = 0; Stb.cursor = Stb.select_end = CurLenW; Stb.has_preferred_x = 0; }
}

// Storage for current popup stack
struct ImGuiPopupData
{
    nothrow:
    @nogc:

    ImGuiID             PopupId;        // Set on OpenPopup()
    ImGuiWindow*        Window;         // Resolved on BeginPopup() - may stay unresolved if user never calls OpenPopup()
    ImGuiWindow*        BackupNavWindow;// Set on OpenPopup(), a NavWindow that will be restored on popup close
    int                 ParentNavLayer = -1; // Resolved on BeginPopup(). Actually a ImGuiNavLayer type (declared down below), initialized to -1 which is not part of an enum, but serves well-enough as "not any of layers" value
    int                 OpenFrameCount = -1; // Set on OpenPopup()
    ImGuiID             OpenParentId;   // Set on OpenPopup(), we need this to differentiate multiple menu sets from each others (e.g. inside menu bar vs loose menu items)
    ImVec2              OpenPopupPos;   // Set on OpenPopup(), preferred popup position (typically == OpenMousePos when using mouse)
    ImVec2              OpenMousePos;   // Set on OpenPopup(), copy of mouse position at the time of opening popup

    //ImGuiPopupData()    { memset(&this, 0, sizeof(this)); ParentNavLayer = OpenFrameCount = -1; }
}

enum ImGuiNextWindowDataFlags : int
{
    None               = 0,
    HasPos             = 1 << 0,
    HasSize            = 1 << 1,
    HasContentSize     = 1 << 2,
    HasCollapsed       = 1 << 3,
    HasSizeConstraint  = 1 << 4,
    HasFocus           = 1 << 5,
    HasBgAlpha         = 1 << 6,
    HasScroll          = 1 << 7,
}

// Storage for SetNexWindow** functions
struct ImGuiNextWindowData
{
    nothrow:
    @nogc:

    ImGuiNextWindowDataFlags    Flags;
    ImGuiCond                   PosCond;
    ImGuiCond                   SizeCond;
    ImGuiCond                   CollapsedCond;
    ImVec2                      PosVal;
    ImVec2                      PosPivotVal;
    ImVec2                      SizeVal;
    ImVec2                      ContentSizeVal;
    ImVec2                      ScrollVal;
    bool                        CollapsedVal;
    ImRect                      SizeConstraintRect;
    ImGuiSizeCallback           SizeCallback;
    void*                       SizeCallbackUserData;
    float                       BgAlphaVal = 0;             // Override background alpha
    ImVec2                      MenuBarOffsetMinVal;    // (Always on) This is not exposed publicly, so we don't clear it and it doesn't have a corresponding flag (could we? for consistency?)

    this(bool dummy)       { memset(&this, 0, sizeof(this)); }
    pragma(inline, true) void ClearFlags()    { Flags = ImGuiNextWindowDataFlags.None; }
}

enum ImGuiNextItemDataFlags : int
{
    None     = 0,
    HasWidth = 1 << 0,
    HasOpen  = 1 << 1,
}

struct ImGuiNextItemData
{
    nothrow:
    @nogc:

    ImGuiNextItemDataFlags      Flags;
    ImGuiItemFlags              ItemFlags;      // Currently only tested/used for ImGuiItemflags_AllowOverlap.
    float                       Width;          // Set by SetNextItemWidth()
    ImGuiID                     FocusScopeId;   // Set by SetNextItemMultiSelectData() (!= 0 signify value has been set, so it's an alternate version of HasSelectionData, we don't use Flags for this because they are cleared too early. This is mostly used for debugging)
    ImGuiCond                   OpenCond;
    bool                        OpenVal;        // Set by SetNextItemOpen()

    @disable this();
    this(bool dummy)         { memset(&this, 0, sizeof(this)); }
    pragma(inline, true) void ClearFlags()    { Flags = ImGuiNextItemDataFlags.None; ItemFlags = ImGuiItemFlags.None; } // Also cleared manually by ItemAdd()!
}

// Status storage for the last submitted item
struct ImGuiLastItemData
{
    ImGuiID                 ID;
    ImGuiItemFlags          InFlags;            // See ImGuiItemFlags_
    ImGuiItemStatusFlags    StatusFlags;        // See ImGuiItemStatusFlags_
    ImRect                  Rect;               // Full rectangle
    ImRect                  NavRect;            // Navigation scoring rectangle (not displayed)
    ImRect                  DisplayRect;        // Display rectangle (only if ImGuiItemStatusFlags_HasDisplayRect is set)

    // ImGuiLastItemData()     { memset(&this, 0, sizeof(this)); }
}

struct ImGuiStackSizes
{
    nothrow:
    @nogc:

    short   SizeOfIDStack;
    short   SizeOfColorStack;
    short   SizeOfStyleVarStack;
    short   SizeOfFontStack;
    short   SizeOfFocusScopeStack;
    short   SizeOfGroupStack;
    short   SizeOfItemFlagsStack;
    short   SizeOfBeginPopupStack;
    short   SizeOfDisabledStack;

    //ImGuiStackSizes() { memset(&this, 0, sizeof(this)); }
    void SetToContextState(ImGuiContext* ctx) { (cast(ImGuiStackSizes_Wrapper*)&this).SetToContextState(ctx); }
    void CompareWithContextState(ImGuiContext* ctx) { (cast(ImGuiStackSizes_Wrapper*)&this).CompareWithContextState(ctx); }
}

// Data saved for each window pushed into the stack
struct ImGuiWindowStackData
{
    ImGuiWindow*            Window;
    ImGuiLastItemData       ParentLastItemDataBackup;
    ImGuiStackSizes         StackSizesOnBegin;      // Store size of various stacks for asserting
}

struct ImGuiShrinkWidthItem
{
    int         Index;
    float       Width;
    float       InitialWidth;
}

struct ImGuiPtrOrIndex
{
    nothrow:
    @nogc:

    void*       Ptr;            // Either field can be set, not both. e.g. Dock node tab bars are loose while BeginTabBar() ones are in a pool.
    int         Index;          // Usually index in a main pool.

    this(void* ptr)  { Ptr = ptr; Index = -1; }
    this(int index)  { Ptr = NULL; Index = index; }
}

//-----------------------------------------------------------------------------
// [SECTION] Inputs support
//-----------------------------------------------------------------------------

// Bit array for named keys
alias ImBitArrayForNamedKeys = ImBitArray!(ImGuiKey.NamedKey_COUNT, -ImGuiKey.NamedKey_BEGIN);

// [Internal] Key ranges
/+
#define ImGuiKey.LegacyNativeKey_BEGIN  0
#define ImGuiKey.LegacyNativeKey_END    512
#define ImGuiKey.Keyboard_BEGIN         (ImGuiKey.NamedKey_BEGIN)
#define ImGuiKey.Keyboard_END           (ImGuiKey.GamepadStart)
#define ImGuiKey.Gamepad_BEGIN          (ImGuiKey.GamepadStart)
#define ImGuiKey.Gamepad_END            (ImGuiKey.GamepadRStickDown + 1)
#define ImGuiKey.Mouse_BEGIN            (ImGuiKey.MouseLeft)
#define ImGuiKey.Mouse_END              (ImGuiKey.MouseWheelY + 1)
#define ImGuiKey.Aliases_BEGIN          (ImGuiKey.Mouse_BEGIN)
#define ImGuiKey.Aliases_END            (ImGuiKey.Mouse_END)

// [Internal] Named shortcuts for Navigation
#define ImGuiKey.NavKeyboardTweakSlow   ImGuiMod.Ctrl
#define ImGuiKey.NavKeyboardTweakFast   ImGuiMod.Shift
#define ImGuiKey.NavGamepadTweakSlow    GamepadL1
#define ImGuiKey.NavGamepadTweakFast    GamepadR1
#define ImGuiKey.NavGamepadActivate     ImGuiKey.GamepadFaceDown
#define ImGuiKey.NavGamepadCancel       ImGuiKey.GamepadFaceRight
#define ImGuiKey.NavGamepadMenu         ImGuiKey.GamepadFaceLeft
#define ImGuiKey.NavGamepadInput        ImGuiKey.GamepadFaceUp
+/

enum ImGuiInputEventType : int
{
    None = 0,
    MousePos,
    MouseWheel,
    MouseButton,
    Key,
    Text,
    Focus,
    COUNT
}

enum ImGuiInputSource : int
{
    None = 0,
    Mouse,         // Note: may be Mouse or TouchScreen or Pen. See io.MouseSource to distinguish them.
    Keyboard,
    Gamepad,
    Clipboard,     // Currently only used by InputText()
    COUNT
}

// FIXME: Structures in the union below need to be declared as anonymous unions appears to be an extension?
// Using ImVec2() would fail on Clang 'union member 'MousePos' has a non-trivial default constructor'
struct ImGuiInputEventMousePos      { float PosX, PosY; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventMouseWheel    { float WheelX, WheelY; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventMouseButton   { ImGuiMouseButton Button; bool Down; ImGuiMouseSource MouseSource; };
struct ImGuiInputEventKey           { ImGuiKey Key; bool Down; float AnalogValue; };
struct ImGuiInputEventText          { uint Char; };
struct ImGuiInputEventAppFocused    { bool Focused; };

struct ImGuiInputEvent
{
    nothrow:
    @nogc:

    ImGuiInputEventType             Type;
    ImGuiInputSource                Source;
    ImU32                           EventId;        // Unique, sequential increasing integer to identify an event (if you need to correlate them to other data).
    union
    {
        ImGuiInputEventMousePos     MousePos;       // if Type == ImGuiInputEventType_MousePos
        ImGuiInputEventMouseWheel   MouseWheel;     // if Type == ImGuiInputEventType_MouseWheel
        ImGuiInputEventMouseButton  MouseButton;    // if Type == ImGuiInputEventType_MouseButton
        ImGuiInputEventKey          Key;            // if Type == ImGuiInputEventType_Key
        ImGuiInputEventText         Text;           // if Type == ImGuiInputEventType_Text
        ImGuiInputEventAppFocused   AppFocused;     // if Type == ImGuiInputEventType_Focus
    };
    bool                            AddedByTestEngine;

    @disable this(); this(bool dummy) { memset(&this, 0, sizeof(this)); }
}

// Input function taking an 'ImGuiID owner_id' argument defaults to (ImGuiKeyOwner_Any == 0) aka don't test ownership, which matches legacy behavior.
enum ImGuiKeyOwner : ImGuiID {
    Any           = (cast(ImGuiID)0),    // Accept key that have an owner, UNLESS a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
    None          = (cast(ImGuiID)-1),   // Require key to have no owner.
}

alias ImGuiKeyRoutingIndex = ImS16;

// Routing table entry (sizeof() == 16 bytes)
struct ImGuiKeyRoutingData
{
    nothrow:
    @nogc:

    ImGuiKeyRoutingIndex            NextEntryIndex;
    ImU16                           Mods;               // Technically we'd only need 4-bits but for simplify we store ImGuiMod_ values which need 16-bits. ImGuiMod_Shortcut is already translated to Ctrl/Super.
    ImU8                            RoutingNextScore;   // Lower is better (0: perfect score)
    ImGuiID                         RoutingCurr;
    ImGuiID                         RoutingNext;

    @disable this();
    this(bool dummy)           { NextEntryIndex = -1; Mods = 0; RoutingNextScore = 255; RoutingCurr = RoutingNext = ImGuiKeyOwner.None; }
}

// Routing table: maintain a desired owner for each possible key-chord (key + mods), and setup owner in NewFrame() when mods are matching.
// Stored in main context (1 instance)
struct ImGuiKeyRoutingTable
{
    nothrow:
    @nogc:

    ImGuiKeyRoutingIndex[ImGuiKey.NamedKey_COUNT]            Index; // Index of first entry in Entries[]
    ImVector!ImGuiKeyRoutingData   Entries;
    ImVector!ImGuiKeyRoutingData   EntriesNext;                    // Double-buffer to avoid reallocation (could use a shared buffer)

    @disable this();
    this(bool dummy)          { Clear(); }
    void Clear()                    { for (int n = 0; n < IM_ARRAYSIZE(Index); n++) Index[n] = -1; Entries.clear(); EntriesNext.clear(); }
}

// This extends ImGuiKeyData but only for named keys (legacy keys don't support the new features)
// Stored in main context (1 per named key). In the future it might be merged into ImGuiKeyData.
struct ImGuiKeyOwnerData
{
    nothrow:
    @nogc:

    ImGuiID     OwnerCurr;
    ImGuiID     OwnerNext;
    bool        LockThisFrame;      // Reading this key requires explicit owner id (until end of frame). Set by ImGuiInputFlags_LockThisFrame.
    bool        LockUntilRelease;   // Reading this key requires explicit owner id (until key is released). Set by ImGuiInputFlags_LockUntilRelease. When this is true LockThisFrame is always true as well.

    @disable this();
    this(bool dummy)             { OwnerCurr = OwnerNext = ImGuiKeyOwner.None; LockThisFrame = LockUntilRelease = false; }
}

// Flags for extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner()
// Don't mistake with ImGuiInputTextFlags! (for ImGui::InputText() function)
enum ImGuiInputFlags : int
{
    // Flags for IsKeyPressed(), IsMouseClicked(), Shortcut()
    None                = 0,
    Repeat              = 1 << 0,   // Return true on successive repeats. Default for legacy IsKeyPressed(). NOT Default for legacy IsMouseClicked(). MUST BE == 1.
    RepeatRateDefault   = 1 << 1,   // Repeat rate: Regular (default)
    RepeatRateNavMove   = 1 << 2,   // Repeat rate: Fast
    RepeatRateNavTweak  = 1 << 3,   // Repeat rate: Faster
    RepeatRateMask_     = ImGuiInputFlags.RepeatRateDefault | ImGuiInputFlags.RepeatRateNavMove | ImGuiInputFlags.RepeatRateNavTweak,

    // Flags for SetItemKeyOwner()
    CondHovered         = 1 << 4,   // Only set if item is hovered (default to both)
    CondActive          = 1 << 5,   // Only set if item is active (default to both)
    CondDefault_        = ImGuiInputFlags.CondHovered | ImGuiInputFlags.CondActive,
    CondMask_           = ImGuiInputFlags.CondHovered | ImGuiInputFlags.CondActive,

    // Flags for SetKeyOwner(), SetItemKeyOwner()
    LockThisFrame       = 1 << 6,   // Access to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared at end of frame. This is useful to make input-owner-aware code steal keys from non-input-owner-aware code.
    LockUntilRelease    = 1 << 7,   // Access to key data will require EXPLICIT owner ID (ImGuiKeyOwner_Any/0 will NOT accepted for polling). Cleared when the key is released or at end of each frame if key is released. This is useful to make input-owner-aware code steal keys from non-input-owner-aware code.

    // Routing policies for Shortcut() + low-level SetShortcutRouting()
    // - The general idea is that several callers register interest in a shortcut, and only one owner gets it.
    // - When a policy (other than _RouteAlways) is set, Shortcut() will register itself with SetShortcutRouting(),
    //   allowing the system to decide where to route the input among other route-aware calls.
    // - Shortcut() uses ImGuiInputFlags_RouteFocused by default: meaning that a simple Shortcut() poll
    //   will register a route and only succeed when parent window is in the focus stack and if no-one
    //   with a higher priority is claiming the shortcut.
    // - Using ImGuiInputFlags_RouteAlways is roughly equivalent to doing e.g. IsKeyPressed(key) + testing mods.
    // - Priorities: GlobalHigh > Focused (when owner is active item) > Global > Focused (when focused window) > GlobalLow.
    // - Can select only 1 policy among all available.
    RouteFocused        = 1 << 8,   // (Default) Register focused route: Accept inputs if window is in focus stack. Deep-most focused window takes inputs. ActiveId takes inputs over deep-most focused window.
    RouteGlobalLow      = 1 << 9,   // Register route globally (lowest priority: unless a focused window or active item registered the route) -> recommended Global priority.
    RouteGlobal         = 1 << 10,  // Register route globally (medium priority: unless an active item registered the route, e.g. CTRL+A registered by InputText).
    RouteGlobalHigh     = 1 << 11,  // Register route globally (highest priority: unlikely you need to use that: will interfere with every active items)
    RouteMask_          = ImGuiInputFlags.RouteFocused | ImGuiInputFlags.RouteGlobal | ImGuiInputFlags.RouteGlobalLow | ImGuiInputFlags.RouteGlobalHigh, // _Always not part of this!
    RouteAlways         = 1 << 12,  // Do not register route, poll keys directly.
    RouteUnlessBgFocused= 1 << 13,  // Global routes will not be applied if underlying background/void is focused (== no Dear ImGui windows are focused). Useful for overlay applications.
    RouteExtraMask_     = ImGuiInputFlags.RouteAlways | ImGuiInputFlags.RouteUnlessBgFocused,

    // [Internal] Mask of which function support which flags
    SupportedByIsKeyPressed     = ImGuiInputFlags.Repeat | ImGuiInputFlags.RepeatRateMask_,
    SupportedByShortcut         = ImGuiInputFlags.Repeat | ImGuiInputFlags.RepeatRateMask_ | ImGuiInputFlags.RouteMask_ | ImGuiInputFlags.RouteExtraMask_,
    SupportedBySetKeyOwner      = ImGuiInputFlags.LockThisFrame | ImGuiInputFlags.LockUntilRelease,
    SupportedBySetItemKeyOwner  = ImGuiInputFlags.SupportedBySetKeyOwner | ImGuiInputFlags.CondMask_,
}

//-----------------------------------------------------------------------------
// [SECTION] Clipper support
//-----------------------------------------------------------------------------

// Note that Max is exclusive, so perhaps should be using a Begin/End convention.
struct ImGuiListClipperRange
{
    nothrow:
    @nogc:

    int     Min;
    int     Max;
    bool    PosToIndexConvert;      // Begin/End are absolute position (will be converted to indices later)
    ImS8    PosToIndexOffsetMin;    // Add to Min after converting to indices
    ImS8    PosToIndexOffsetMax;    // Add to Min after converting to indices

    static ImGuiListClipperRange    FromIndices(int min, int max)                               { ImGuiListClipperRange r = { min, max, false, 0, 0 }; return r; }
    static ImGuiListClipperRange    FromPositions(float y1, float y2, int off_min, int off_max) { ImGuiListClipperRange r = { cast(int)y1, cast(int)y2, true, cast(ImS8)off_min, cast(ImS8)off_max }; return r; }
}

// Temporary clipper data, buffers shared/reused between instances
struct ImGuiListClipperData
{
    nothrow:
    @nogc:

    ImGuiListClipper*               ListClipper;
    float                           LossynessOffset = 0;
    int                             StepNo;
    int                             ItemsFrozen;
    ImVector!ImGuiListClipperRange Ranges;

    //ImGuiListClipperData()          { memset(&this, 0, sizeof(this)); }
    void destroy() { Ranges.destroy(); }
    void                            Reset(ImGuiListClipper* clipper) { ListClipper = clipper; StepNo = ItemsFrozen = 0; Ranges.resize(0); }
}

//-----------------------------------------------------------------------------
// [SECTION] Navigation support
//-----------------------------------------------------------------------------

enum ImGuiActivateFlags : int
{
    None                 = 0,
    PreferInput          = 1 << 0,       // Favor activation that requires keyboard text input (e.g. for Slider/Drag). Default for Enter key.
    PreferTweak          = 1 << 1,       // Favor activation for tweaking with arrows or gamepad (e.g. for Slider/Drag). Default for Space key and if keyboard is not used.
    TryToPreserveState   = 1 << 2,       // Request widget to preserve state if it can (e.g. InputText will try to preserve cursor/selection)
}

// Early work-in-progress API for ScrollToItem()
enum ImGuiScrollFlags : int
{
    None                   = 0,
    KeepVisibleEdgeX       = 1 << 0,       // If item is not visible: scroll as little as possible on X axis to bring item back into view [default for X axis]
    KeepVisibleEdgeY       = 1 << 1,       // If item is not visible: scroll as little as possible on Y axis to bring item back into view [default for Y axis for windows that are already visible]
    KeepVisibleCenterX     = 1 << 2,       // If item is not visible: scroll to make the item centered on X axis [rarely used]
    KeepVisibleCenterY     = 1 << 3,       // If item is not visible: scroll to make the item centered on Y axis
    AlwaysCenterX          = 1 << 4,       // Always center the result item on X axis [rarely used]
    AlwaysCenterY          = 1 << 5,       // Always center the result item on Y axis [default for Y axis for appearing window)
    NoScrollParent         = 1 << 6,       // Disable forwarding scrolling to parent window if required to keep item/rect visible (only scroll window the function was applied to).
    MaskX_                 = ImGuiScrollFlags.KeepVisibleEdgeX | ImGuiScrollFlags.KeepVisibleCenterX | ImGuiScrollFlags.AlwaysCenterX,
    MaskY_                 = ImGuiScrollFlags.KeepVisibleEdgeY | ImGuiScrollFlags.KeepVisibleCenterY | ImGuiScrollFlags.AlwaysCenterY,
}

enum ImGuiNavHighlightFlags : int
{
    None             = 0,
    TypeDefault      = 1 << 0,
    TypeThin         = 1 << 1,
    AlwaysDraw       = 1 << 2,       // Draw rectangular highlight if (g.NavId == id) _even_ when using the mouse.
    NoRounding       = 1 << 3,
}

enum ImGuiNavMoveFlags : int
{
    None                  = 0,
    LoopX                 = 1 << 0,   // On failed request, restart from opposite side
    LoopY                 = 1 << 1,
    WrapX                 = 1 << 2,   // On failed request, request from opposite side one line down (when NavDir==right) or one line up (when NavDir==left)
    WrapY                 = 1 << 3,   // This is not super useful but provided for completeness
    WrapMask_             = ImGuiNavMoveFlags.LoopX | ImGuiNavMoveFlags.LoopY | ImGuiNavMoveFlags.WrapX | ImGuiNavMoveFlags.WrapY,
    AllowCurrentNavId     = 1 << 4,   // Allow scoring and considering the current NavId as a move target candidate. This is used when the move source is offset (e.g. pressing PageDown actually needs to send a Up move request, if we are pressing PageDown from the bottom-most item we need to stay in place)
    AlsoScoreVisibleSet   = 1 << 5,   // Store alternate result in NavMoveResultLocalVisible that only comprise elements that are already fully visible (used by PageUp/PageDown)
    ScrollToEdgeY         = 1 << 6,   // Force scrolling to min/max (used by Home/End) // FIXME-NAV: Aim to remove or reword, probably unnecessary
    Forwarded             = 1 << 7,
    DebugNoResult         = 1 << 8,   // Dummy scoring for debug purpose, don't apply result
    FocusApi              = 1 << 9,   // Requests from focus API can land/focus/activate items even if they are marked with _NoTabStop (see NavProcessItemForTabbingRequest() for details)
    Tabbing               = 1 << 10,  // == Focus + Activate if item is Inputable + DontChangeNavHighlight
    Activate              = 1 << 11,  // Activate/select target item.
    NoSelect              = 1 << 12,  // Don't trigger selection by not setting g.NavJustMovedTo
    NoSetNavHighlight     = 1 << 13,  // Do not alter the visible state of keyboard vs mouse nav highlight
}

enum ImGuiNavLayer : int
{
    Main  = 0,    // Main scrolling layer
    Menu  = 1,    // Menu layer (access with Alt)
    COUNT
}

struct ImGuiNavItemData
{
    nothrow:
    @nogc:

    ImGuiWindow*        Window;         // Init,Move    // Best candidate window (result->ItemWindow->RootWindowForNav == request->Window)
    ImGuiID             ID;             // Init,Move    // Best candidate item ID
    ImGuiID             FocusScopeId;   // Init,Move    // Best candidate focus scope ID
    ImRect              RectRel;        // Init,Move    // Best candidate bounding box in window relative space
    ImGuiItemFlags      InFlags;        // ????,Move    // Best candidate item flags
    float               DistBox;        //      Move    // Best candidate box distance to current NavId
    float               DistCenter;     //      Move    // Best candidate center distance to current NavId
    float               DistAxial;      //      Move    // Best candidate axial distance to current NavId

    @disable this();
    this(bool dummy)  { Clear(); }
    void Clear()        { Window = NULL; ID = FocusScopeId = 0; InFlags = ImGuiItemFlags.None; DistBox = DistCenter = DistAxial = FLT_MAX; }
}

//-----------------------------------------------------------------------------
// [SECTION] Columns support
//-----------------------------------------------------------------------------

// Flags for internal's BeginColumns(). Prefix using BeginTable() nowadays!
enum ImGuiOldColumnFlags : int
{
    None                    = 0,
    NoBorder                = 1 << 0,   // Disable column dividers
    NoResize                = 1 << 1,   // Disable resizing columns when clicking on the dividers
    NoPreserveWidths        = 1 << 2,   // Disable column width preservation when adjusting columns
    NoForceWithinWindow     = 1 << 3,   // Disable forcing columns to fit within window
    GrowParentContentsSize  = 1 << 4,   // (WIP) Restore pre-1.51 behavior of extending the parent window contents size but _without affecting the columns width at all_. Will eventually remove.

    // Obsolete names (will be removed)
/+
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    ImGuiColumnsFlags_None                      = ImGuiOldColumnFlags.None,
    ImGuiColumnsFlags_NoBorder                  = ImGuiOldColumnFlags.NoBorder,
    ImGuiColumnsFlags_NoResize                  = ImGuiOldColumnFlags.NoResize,
    ImGuiColumnsFlags_NoPreserveWidths          = ImGuiOldColumnFlags.NoPreserveWidths,
    ImGuiColumnsFlags_NoForceWithinWindow       = ImGuiOldColumnFlags.NoForceWithinWindow,
    ImGuiColumnsFlags_GrowParentContentsSize    = ImGuiOldColumnFlags.GrowParentContentsSize,
}
+/
}

struct ImGuiOldColumnData
{
    nothrow:
    @nogc:

    float               OffsetNorm;             // Column start offset, normalized 0.0 (far left) -> 1.0 (far right)
    float               OffsetNormBeforeResize;
    ImGuiOldColumnFlags Flags;                  // Not exposed
    ImRect              ClipRect;

    @disable this();
    this(bool dummy) { memset(&this, 0, sizeof(this)); }
}

struct ImGuiOldColumns
{
    nothrow:
    @nogc:

    ImGuiID             ID;
    ImGuiOldColumnFlags Flags;
    bool                IsFirstFrame;
    bool                IsBeingResized;
    int                 Current;
    int                 Count;
    float               OffMinX, OffMaxX;       // Offsets from HostWorkRect.Min.x
    float               LineMinY, LineMaxY;
    float               HostCursorPosY;         // Backup of CursorPos at the time of BeginColumns()
    float               HostCursorMaxPosX;      // Backup of CursorMaxPos at the time of BeginColumns()
    ImRect              HostInitialClipRect;    // Backup of ClipRect at the time of BeginColumns()
    ImRect              HostBackupClipRect;     // Backup of ClipRect during PushColumnsBackground()/PopColumnsBackground()
    ImRect              HostBackupParentWorkRect;//Backup of WorkRect at the time of BeginColumns()
    ImVector!ImGuiOldColumnData Columns;
    ImDrawListSplitter  Splitter;

    @disable this();
    this(bool dummy)   { memset(&this, 0, sizeof(this)); }
}

//-----------------------------------------------------------------------------
// [SECTION] Multi-select support
//-----------------------------------------------------------------------------

// #ifdef IMGUI_HAS_MULTI_SELECT
// <this is filled in 'range_select' branch>
// #endif // #ifdef IMGUI_HAS_MULTI_SELECT

//-----------------------------------------------------------------------------
// [SECTION] Docking support
//-----------------------------------------------------------------------------

version (IMGUI_HAS_DOCK) {
// <this is filled in 'docking' branch>
} // #ifdef IMGUI_HAS_DOCK

//-----------------------------------------------------------------------------
// [SECTION] Viewport support
//-----------------------------------------------------------------------------

// ImGuiViewport Private/Internals fields (cardinal sin: we are using inheritance!)
// Every instance of ImGuiViewport is in fact a ImGuiViewportP.
struct ImGuiViewportP
{
    nothrow:
    @nogc:
    ImGuiViewport base = ImGuiViewport.init;
    alias base this;

    int[2]                 DrawListsLastFrame;  // Last frame number the background (0) and foreground (1) draw lists were used
    ImDrawList*[2]         DrawLists;           // Convenience background (0) and foreground (1) draw lists. We use them to draw software mouser cursor when io.MouseDrawCursor is set and to draw most debug overlays.
    ImDrawData          DrawDataP;
    ImDrawDataBuilder   DrawDataBuilder;

    ImVec2              WorkOffsetMin;          // Work Area: Offset from Pos to top-left corner of Work Area. Generally (0,0) or (0,+main_menu_bar_height). Work Area is Full Area but without menu-bars/status-bars (so WorkArea always fit inside Pos/Size!)
    ImVec2              WorkOffsetMax;          // Work Area: Offset from Pos+Size to bottom-right corner of Work Area. Generally (0,0) or (0,-status_bar_height).
    ImVec2              BuildWorkOffsetMin;     // Work Area: Offset being built during current frame. Generally >= 0.0f.
    ImVec2              BuildWorkOffsetMax;     // Work Area: Offset being built during current frame. Generally <= 0.0f.

    @disable this();
    this(bool dummy)    { DrawDataP = ImDrawData(false); DrawListsLastFrame[0] = DrawListsLastFrame[1] = -1; DrawLists[0] = DrawLists[1] = NULL; }
    void destroy()   { if (DrawLists[0]) IM_DELETE(DrawLists[0]); if (DrawLists[1]) IM_DELETE(DrawLists[1]); DrawDataBuilder.ClearFreeMemory(); }

    // Calculate work rect pos/size given a set of offset (we have 1 pair of offset for rect locked from last frame data, and 1 pair for currently building rect)
    ImVec2  CalcWorkRectPos(const ImVec2/*&*/ off_min) const                            { return ImVec2(Pos.x + off_min.x, Pos.y + off_min.y); }
    ImVec2  CalcWorkRectSize(const ImVec2/*&*/ off_min, const ImVec2/*&*/ off_max) const    { return ImVec2(ImMax(0.0f, Size.x - off_min.x + off_max.x), ImMax(0.0f, Size.y - off_min.y + off_max.y)); }
    void    UpdateWorkRect()            { WorkPos = CalcWorkRectPos(WorkOffsetMin); WorkSize = CalcWorkRectSize(WorkOffsetMin, WorkOffsetMax); } // Update public fields

    // Helpers to retrieve ImRect (we don't need to store BuildWorkRect as every access tend to change it, hence the code asymmetry)
    ImRect  GetMainRect() const         { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }
    ImRect  GetWorkRect() const         { return ImRect(WorkPos.x, WorkPos.y, WorkPos.x + WorkSize.x, WorkPos.y + WorkSize.y); }
    ImRect  GetBuildWorkRect() const    { ImVec2 pos = CalcWorkRectPos(BuildWorkOffsetMin); ImVec2 size = CalcWorkRectSize(BuildWorkOffsetMin, BuildWorkOffsetMax); return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y); }
}

//-----------------------------------------------------------------------------
// [SECTION] Settings support
//-----------------------------------------------------------------------------

// Windows data saved in imgui.ini file
// Because we never destroy or rename ImGuiWindowSettings, we can store the names in a separate buffer easily.
// (this is designed to be stored in a ImChunkStream buffer, with the variable-length Name following our structure)
struct ImGuiWindowSettings
{
    nothrow:
    @nogc:

    ImGuiID     ID;
    ImVec2ih    Pos;
    ImVec2ih    Size;
    bool        Collapsed;
    bool        WantApply;      // Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)
    bool        WantDelete;     // Set to invalidate/delete the settings entry

    // D_IMGUI: Also store the length since we are not using zero termination
    size_t         name_len;

    this(size_t name_length)       { memset(&this, 0, sizeof(this)); name_len = name_length; }
    string GetName()             return { return cast(string)(cast(char*)(&this + 1))[0..name_len]; }
}

struct ImGuiSettingsHandler
{
    nothrow:
    @nogc:

    string TypeName;       // Short description stored in .ini file. Disallowed characters: '[' ']'
    ImGuiID     TypeHash;       // == ImHashStr(TypeName)
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler) ClearAllFn;                                // Clear all settings data
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler) ReadInitFn;                                // Read: Called before reading (in registration order)
    void*       function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, string name) ReadOpenFn;              // Read: Called when entering into a new ini entry e.g. "[Window][Name]"
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, void* entry, string line) ReadLineFn; // Read: Called for every line of text within an ini entry
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler) ApplyAllFn;                                // Read: Called after reading (in registration order)
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, ImGuiTextBuffer* out_buf) WriteAllFn;      // Write: Output every entries into 'out_buf'
    void*       UserData;

    this(bool dummy) { memset(&this, 0, sizeof(this)); }
}

//-----------------------------------------------------------------------------
// [SECTION] Localization support
//-----------------------------------------------------------------------------

// This is experimental and not officially supported, it'll probably fall short of features, if/when it does we may backtrack.
enum ImGuiLocKey : int
{
    VersionStr,
    TableSizeOne,
    TableSizeAllFit,
    TableSizeAllDefault,
    TableResetOrder,
    WindowingMainMenuBar,
    WindowingPopup,
    WindowingUntitled,
    COUNT
}

struct ImGuiLocEntry
{
    ImGuiLocKey     Key;
    string     Text;
}


//-----------------------------------------------------------------------------
// [SECTION] Metrics, Debug Tools
//-----------------------------------------------------------------------------

enum ImGuiDebugLogFlags : int
{
    // Event types
    None             = 0,
    EventActiveId    = 1 << 0,
    EventFocus       = 1 << 1,
    EventPopup       = 1 << 2,
    EventNav         = 1 << 3,
    EventClipper     = 1 << 4,
    EventSelection   = 1 << 5,
    EventIO          = 1 << 6,
    EventMask_       = ImGuiDebugLogFlags.EventActiveId  | ImGuiDebugLogFlags.EventFocus | ImGuiDebugLogFlags.EventPopup | ImGuiDebugLogFlags.EventNav | ImGuiDebugLogFlags.EventClipper | ImGuiDebugLogFlags.EventSelection | ImGuiDebugLogFlags.EventIO,
    OutputToTTY      = 1 << 10,  // Also send output to TTY
}

struct ImGuiMetricsConfig
{
    bool        ShowDebugLog = false;
    bool        ShowStackTool = false;
    bool        ShowWindowsRects = false;
    bool        ShowWindowsBeginOrder = false;
    bool        ShowTablesRects = false;
    bool        ShowDrawCmdMesh = true;
    bool        ShowDrawCmdBoundingBoxes = true;
    bool        ShowAtlasTintedWithTextColor = false;
    int         ShowWindowsRectsType = -1;
    int         ShowTablesRectsType = -1;
}

struct ImGuiStackLevelInfo
{
    nothrow:
    @nogc:

    ImGuiID                 ID;
    ImS8                    QueryFrameCount;            // >= 1: Query in progress
    bool                    QuerySuccess;               // Obtained result from DebugHookIdInfo()
    ubyte           DataType;
    char[57]                    Desc;                   // Arbitrarily sized buffer to hold a result (FIXME: could replace Results[] with a chunk stream?) FIXME: Now that we added CTRL+C this should be fixed.

    @disable this();
    this(bool dummy)   { memset(&this, 0, sizeof(this)); }
}

// State for Stack tool queries
struct ImGuiStackTool
{
    int                     LastActiveFrame;
    int                     StackLevel;                 // -1: query stack and resize Results, >= 0: individual stack level
    ImGuiID                 QueryId;                    // ID to query details for
    ImVector!ImGuiStackLevelInfo Results;
    bool                    CopyToClipboardOnCtrlC;
    float                   CopyToClipboardLastTime = -FLT_MAX;

    //ImGuiStackTool()        { memset(&this, 0, sizeof(this)); CopyToClipboardLastTime = -FLT_MAX; }
}

//-----------------------------------------------------------------------------
// [SECTION] Generic context hooks
//-----------------------------------------------------------------------------

alias ImGuiContextHookCallback = void function(ImGuiContext* ctx, ImGuiContextHook* hook);
enum ImGuiContextHookType { NewFramePre, NewFramePost, EndFramePre, EndFramePost, RenderPre, RenderPost, Shutdown, PendingRemoval_ }

struct ImGuiContextHook
{
    nothrow:
    @nogc:

    ImGuiID                     HookId;     // A unique ID assigned by AddContextHook()
    ImGuiContextHookType        Type;
    ImGuiID                     Owner;
    ImGuiContextHookCallback    Callback;
    void*                       UserData;

    this(bool dummy)          { memset(&this, 0, sizeof(this)); }
}

//-----------------------------------------------------------------------------
// [SECTION] ImGuiContext (main Dear ImGui context)
//-----------------------------------------------------------------------------

struct ImGuiContext
{
    nothrow:
    @nogc:

    bool                    Initialized;
    bool                    FontAtlasOwnedByContext;            // IO.Fonts-> is owned by the ImGuiContext and will be destructed along with it.
    ImGuiIO                 IO;
    ImGuiStyle              Style;
    ImFont*                 Font;                               // (Shortcut) == FontStack.empty() ? IO.Font : FontStack.back()
    float                   FontSize;                           // (Shortcut) == FontBaseSize * g.CurrentWindow->FontWindowScale == window->FontSize(). Text height for current window.
    float                   FontBaseSize;                       // (Shortcut) == IO.FontGlobalScale * Font->Scale * Font->FontSize. Base text height.
    ImDrawListSharedData    DrawListSharedData;
    double                  Time;
    int                     FrameCount;
    int                     FrameCountEnded;
    int                     FrameCountRendered;
    bool                    WithinFrameScope;                   // Set by NewFrame(), cleared by EndFrame()
    bool                    WithinFrameScopeWithImplicitWindow; // Set by NewFrame(), cleared by EndFrame() when the implicit debug window has been pushed
    bool                    WithinEndChild;                     // Set within EndChild()
    bool                    GcCompactAll;                       // Request full GC
    bool                    TestEngineHookItems;                // Will call test engine hooks: ImGuiTestEngineHook_ItemAdd(), ImGuiTestEngineHook_ItemInfo(), ImGuiTestEngineHook_Log()
    void*                   TestEngine;                         // Test engine user data

    // Inputs
    ImVector!ImGuiInputEvent InputEventsQueue;                 // Input events which will be trickled/written into IO structure.
    ImVector!ImGuiInputEvent InputEventsTrail;                 // Past input events processed in NewFrame(). This is to allow domain-specific application to access e.g mouse/pen trail.
    ImGuiMouseSource        InputEventsNextMouseSource;
    ImU32                   InputEventsNextEventId;

    // Windows state
    ImVector!(ImGuiWindow*)  Windows;                            // Windows, sorted in display order, back to front
    ImVector!(ImGuiWindow*)  WindowsFocusOrder;                  // Root windows, sorted in focus order, back to front.
    ImVector!(ImGuiWindow*)  WindowsTempSortBuffer;              // Temporary buffer used in EndFrame() to reorder windows so parents are kept before their child
    ImVector!ImGuiWindowStackData CurrentWindowStack;
    ImGuiStorage            WindowsById;                        // Map window's ImGuiID to ImGuiWindow*
    int                     WindowsActiveCount;                 // Number of unique windows submitted by frame
    ImVec2                  WindowsHoverPadding;                // Padding around resizable windows for which hovering on counts as hovering the window == ImMax(style.TouchExtraPadding, WINDOWS_HOVER_PADDING)
    ImGuiWindow*            CurrentWindow;                      // Window being drawn into
    ImGuiWindow*            HoveredWindow;                      // Window the mouse is hovering. Will typically catch mouse inputs.
    ImGuiWindow*            HoveredWindowUnderMovingWindow;     // Hovered window ignoring MovingWindow. Only set if MovingWindow is set.
    ImGuiWindow*            MovingWindow;                       // Track the window we clicked on (in order to preserve focus). The actual window that is moved is generally MovingWindow->RootWindow.
    ImGuiWindow*            WheelingWindow;                     // Track the window we started mouse-wheeling on. Until a timer elapse or mouse has moved, generally keep scrolling the same window even if during the course of scrolling the mouse ends up hovering a child window.
    ImVec2                  WheelingWindowRefMousePos;
    int                     WheelingWindowStartFrame;           // This may be set one frame before WheelingWindow is != NULL
    float                   WheelingWindowReleaseTimer;
    ImVec2                  WheelingWindowWheelRemainder;
    ImVec2                  WheelingAxisAvg;

    // Item/widgets state and tracking information
    ImGuiID                 DebugHookIdInfo;                    // Will call core hooks: DebugHookIdInfo() from GetID functions, used by Stack Tool [next HoveredId/ActiveId to not pull in an extra cache-line]
    ImGuiID                 HoveredId;                          // Hovered widget, filled during the frame
    ImGuiID                 HoveredIdPreviousFrame;
    bool                    HoveredIdAllowOverlap;
    bool                    HoveredIdDisabled;                  // At least one widget passed the rect test, but has been discarded by disabled flag or popup inhibit. May be true even if HoveredId == 0.
    float                   HoveredIdTimer;                     // Measure contiguous hovering time
    float                   HoveredIdNotActiveTimer;            // Measure contiguous hovering time where the item has not been active
    ImGuiID                 ActiveId;                           // Active widget
    ImGuiID                 ActiveIdIsAlive;                    // Active widget has been seen this frame (we can't use a bool as the ActiveId may change within the frame)
    float                   ActiveIdTimer;
    bool                    ActiveIdIsJustActivated;            // Set at the time of activation for one frame
    bool                    ActiveIdAllowOverlap;               // Active widget allows another widget to steal active id (generally for overlapping widgets, but not always)
    bool                    ActiveIdNoClearOnFocusLoss;         // Disable losing active id if the active id window gets unfocused.
    bool                    ActiveIdHasBeenPressedBefore;       // Track whether the active id led to a press (this is to allow changing between PressOnClick and PressOnRelease without pressing twice). Used by range_select branch.
    bool                    ActiveIdHasBeenEditedBefore;        // Was the value associated to the widget Edited over the course of the Active state.
    bool                    ActiveIdHasBeenEditedThisFrame;
    ImVec2                  ActiveIdClickOffset;                // Clicked offset from upper-left corner, if applicable (currently only set by ButtonBehavior)
    ImGuiWindow*            ActiveIdWindow;
    ImGuiInputSource        ActiveIdSource;                     // Activating source: ImGuiInputSource_Mouse OR ImGuiInputSource_Keyboard OR ImGuiInputSource_Gamepad
    ImGuiMouseButton                     ActiveIdMouseButton;
    ImGuiID                 ActiveIdPreviousFrame;
    bool                    ActiveIdPreviousFrameIsAlive;
    bool                    ActiveIdPreviousFrameHasBeenEditedBefore;
    ImGuiWindow*            ActiveIdPreviousFrameWindow;
    ImGuiID                 LastActiveId;                       // Store the last non-zero ActiveId, useful for animation.
    float                   LastActiveIdTimer;                  // Store the last non-zero ActiveId timer since the beginning of activation, useful for animation.

    // [EXPERIMENTAL] Key/Input Ownership + Shortcut Routing system
    // - The idea is that instead of "eating" a given key, we can link to an owner.
    // - Input query can then read input by specifying ImGuiKeyOwner_Any (== 0), ImGuiKeyOwner_None (== -1) or a custom ID.
    // - Routing is requested ahead of time for a given chord (Key + Mods) and granted in NewFrame().
    ImGuiKeyOwnerData[ImGuiKey.NamedKey_COUNT]       KeysOwnerData;
    ImGuiKeyRoutingTable    KeysRoutingTable;
    ImU32                   ActiveIdUsingNavDirMask;            // Active widget will want to read those nav move requests (e.g. can activate a button and move away from it)
    bool                    ActiveIdUsingAllKeyboardKeys;       // Active widget will want to read all keyboard keys inputs. (FIXME: This is a shortcut for not taking ownership of 100+ keys but perhaps best to not have the inconsistency)
static if (!IMGUI_DISABLE_OBSOLETE_KEYIO) {
    ImU32                   ActiveIdUsingNavInputMask;          // If you used this. Since (IMGUI_VERSION_NUM >= 18804) : 'g.ActiveIdUsingNavInputMask |= (1 << ImGuiNavInput_Cancel);' becomes 'SetKeyOwner(ImGuiKey_Escape, g.ActiveId) and/or SetKeyOwner(ImGuiKey_NavGamepadCancel, g.ActiveId);'
}

    // Next window/item data
    ImGuiID                 CurrentFocusScopeId;                // == g.FocusScopeStack.back()
    ImGuiItemFlags          CurrentItemFlags;                   // == g.ItemFlagsStack.back()
    ImGuiID                 DebugLocateId;                      // Storage for DebugLocateItemOnHover() feature: this is read by ItemAdd() so we keep it in a hot/cached location
    ImGuiNextItemData       NextItemData;                       // Storage for SetNextItem** functions
    ImGuiLastItemData       LastItemData;                       // Storage for last submitted item (setup by ItemAdd)
    ImGuiNextWindowData     NextWindowData;                     // Storage for SetNextWindow** functions

    // Shared stacks
    ImVector!ImGuiColorMod ColorStack;                         // Stack for PushStyleColor()/PopStyleColor() - inherited by Begin()
    ImVector!ImGuiStyleMod StyleVarStack;                      // Stack for PushStyleVar()/PopStyleVar() - inherited by Begin()
    ImVector!(ImFont*)       FontStack;                          // Stack for PushFont()/PopFont() - inherited by Begin()
    ImVector!ImGuiID       FocusScopeStack;                    // Stack for PushFocusScope()/PopFocusScope() - inherited by BeginChild(), pushed into by Begin()
    ImVector!ImGuiItemFlags ItemFlagsStack;                     // Stack for PushItemFlag()/PopItemFlag() - inherited by Begin()
    ImVector!ImGuiGroupData GroupStack;                         // Stack for BeginGroup()/EndGroup() - not inherited by Begin()
    ImVector!ImGuiPopupData OpenPopupStack;                     // Which popups are open (persistent)
    ImVector!ImGuiPopupData BeginPopupStack;                    // Which level of BeginPopup() we are in (reset every frame)
    int                     BeginMenuCount;

    // Viewports
    ImVector!(ImGuiViewportP*) Viewports;                        // Active viewports (Size==1 in 'master' branch). Each viewports hold their copy of ImDrawData.

    // Gamepad/keyboard Navigation
    ImGuiWindow*            NavWindow;                          // Focused window for navigation. Could be called 'FocusedWindow'
    ImGuiID                 NavId;                              // Focused item for navigation
    ImGuiID                 NavFocusScopeId;                    // Identify a selection scope (selection code often wants to "clear other items" when landing on an item of the selection set)
    ImGuiID                 NavActivateId;                      // ~~ (g.ActiveId == 0) && (IsKeyPressed(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate)) ? NavId : 0, also set when calling ActivateItem()
    ImGuiID                 NavActivateDownId;                  // ~~ IsKeyDown(ImGuiKey_Space) || IsKeyDown(ImGuiKey_Enter) || IsKeyDown(ImGuiKey_NavGamepadActivate) ? NavId : 0
    ImGuiID                 NavActivatePressedId;               // ~~ IsKeyPressed(ImGuiKey_Space) || IsKeyPressed(ImGuiKey_Enter) || IsKeyPressed(ImGuiKey_NavGamepadActivate) ? NavId : 0 (no repeat)
    ImGuiActivateFlags      NavActivateFlags;
    ImGuiID                 NavJustMovedToId;                   // Just navigated to this id (result of a successfully MoveRequest).
    ImGuiID                 NavJustMovedToFocusScopeId;         // Just navigated to this focus scope id (result of a successfully MoveRequest).
    ImGuiKeyChord           NavJustMovedToKeyMods;
    ImGuiID                 NavNextActivateId;                  // Set by ActivateItem(), queued until next frame.
    ImGuiActivateFlags      NavNextActivateFlags;
    ImGuiInputSource        NavInputSource;                     // Keyboard or Gamepad mode? THIS CAN ONLY BE ImGuiInputSource_Keyboard or ImGuiInputSource_Mouse
    ImGuiNavLayer           NavLayer;                           // Layer we are navigating on. For now the system is hard-coded for 0=main contents and 1=menu/title bar, may expose layers later.
    bool                    NavIdIsAlive;                       // Nav widget has been seen this frame ~~ NavRectRel is valid
    bool                    NavMousePosDirty;                   // When set we will update mouse position if (io.ConfigFlags & ImGuiConfigFlags_NavEnableSetMousePos) if set (NB: this not enabled by default)
    bool                    NavDisableHighlight;                // When user starts using mouse, we hide gamepad/keyboard highlight (NB: but they are still available, which is why NavDisableHighlight isn't always != NavDisableMouseHover)
    bool                    NavDisableMouseHover;               // When user starts using gamepad/keyboard, we hide mouse hovering highlight until mouse is touched again.

    // Navigation: Init & Move Requests
    bool                    NavAnyRequest;                      // ~~ NavMoveRequest || NavInitRequest this is to perform early out in ItemAdd()
    bool                    NavInitRequest;                     // Init request for appearing window to select first item
    bool                    NavInitRequestFromMove;
    ImGuiNavItemData        NavInitResult;                      // Init request result (first item of the window, or one for which SetItemDefaultFocus() was called)
    bool                    NavMoveSubmitted;                   // Move request submitted, will process result on next NewFrame()
    bool                    NavMoveScoringItems;                // Move request submitted, still scoring incoming items
    bool                    NavMoveForwardToNextFrame;
    ImGuiNavMoveFlags       NavMoveFlags;
    ImGuiScrollFlags        NavMoveScrollFlags;
    ImGuiKeyChord           NavMoveKeyMods;
    ImGuiDir                NavMoveDir;                         // Direction of the move request (left/right/up/down)
    ImGuiDir                NavMoveDirForDebug;
    ImGuiDir                NavMoveClipDir;                     // FIXME-NAV: Describe the purpose of this better. Might want to rename?
    ImRect                  NavScoringRect;                     // Rectangle used for scoring, in screen space. Based of window->NavRectRel[], modified for directional navigation scoring.
    ImRect                  NavScoringNoClipRect;               // Some nav operations (such as PageUp/PageDown) enforce a region which clipper will attempt to always keep submitted
    int                     NavScoringDebugCount;               // Metrics for debugging
    int                     NavTabbingDir;                      // Generally -1 or +1, 0 when tabbing without a nav id
    int                     NavTabbingCounter;                  // >0 when counting items for tabbing
    ImGuiNavItemData        NavMoveResultLocal;                 // Best move request candidate within NavWindow
    ImGuiNavItemData        NavMoveResultLocalVisible;          // Best move request candidate within NavWindow that are mostly visible (when using ImGuiNavMoveFlags_AlsoScoreVisibleSet flag)
    ImGuiNavItemData        NavMoveResultOther;                 // Best move request candidate within NavWindow's flattened hierarchy (when using ImGuiWindowFlags_NavFlattened flag)
    ImGuiNavItemData        NavTabbingResultFirst;              // First tabbing request candidate within NavWindow and flattened hierarchy

    // Navigation: Windowing (CTRL+TAB for list, or Menu button + keys or directional pads to move/resize)
    ImGuiKeyChord           ConfigNavWindowingKeyNext;          // = ImGuiMod_Ctrl | ImGuiKey_Tab, for reconfiguration (see #4828)
    ImGuiKeyChord           ConfigNavWindowingKeyPrev;          // = ImGuiMod_Ctrl | ImGuiMod_Shift | ImGuiKey_Tab
    ImGuiWindow*            NavWindowingTarget;                 // Target window when doing CTRL+Tab (or Pad Menu + FocusPrev/Next), this window is temporarily displayed top-most!
    ImGuiWindow*            NavWindowingTargetAnim;             // Record of last valid NavWindowingTarget until DimBgRatio and NavWindowingHighlightAlpha becomes 0.0f, so the fade-out can stay on it.
    ImGuiWindow*            NavWindowingListWindow;             // Internal window actually listing the CTRL+Tab contents
    float                   NavWindowingTimer;
    float                   NavWindowingHighlightAlpha;
    bool                    NavWindowingToggleLayer;
    ImVec2                  NavWindowingAccumDeltaPos;
    ImVec2                  NavWindowingAccumDeltaSize;

    // Render
    float                   DimBgRatio;                         // 0.0..1.0 animation when fading in a dimming background (for modal window and CTRL+TAB list)

    // Drag and Drop
    bool                    DragDropActive;
    bool                    DragDropWithinSource;               // Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag source.
    bool                    DragDropWithinTarget;               // Set when within a BeginDragDropXXX/EndDragDropXXX block for a drag target.
    ImGuiDragDropFlags      DragDropSourceFlags;
    int                     DragDropSourceFrameCount;
    ImGuiMouseButton                     DragDropMouseButton;
    ImGuiPayload            DragDropPayload;
    ImRect                  DragDropTargetRect;                 // Store rectangle of current target candidate (we favor small targets when overlapping)
    ImGuiID                 DragDropTargetId;
    ImGuiDragDropFlags      DragDropAcceptFlags;
    float                   DragDropAcceptIdCurrRectSurface;    // Target item surface (we resolve overlapping targets by prioritizing the smaller surface)
    ImGuiID                 DragDropAcceptIdCurr;               // Target item id (set at the time of accepting the payload)
    ImGuiID                 DragDropAcceptIdPrev;               // Target item id from previous frame (we need to store this to allow for overlapping drag and drop targets)
    int                     DragDropAcceptFrameCount;           // Last time a target expressed a desire to accept the source
    ImGuiID                 DragDropHoldJustPressedId;          // Set when holding a payload just made ButtonBehavior() return a press.
    ImVector!ubyte DragDropPayloadBufHeap;             // We don't expose the ImVector<> directly, ImGuiPayload only holds pointer+size
    ubyte[16]           DragDropPayloadBufLocal;        // Local buffer for small payloads

    // Clipper
    int                             ClipperTempDataStacked;
    ImVector!ImGuiListClipperData  ClipperTempData;

    // Tables
    ImGuiTable*                     CurrentTable;
    int                             TablesTempDataStacked;      // Temporary table data size (because we leave previous instances undestructed, we generally don't use TablesTempData.Size)
    ImVector!ImGuiTableTempData    TablesTempData;             // Temporary table data (buffers reused/shared across instances, support nesting)
    ImPool!ImGuiTable              Tables;                     // Persistent table data
    ImVector!float                 TablesLastTimeActive;       // Last used timestamp of each tables (SOA, for efficient GC)
    ImVector!ImDrawChannel         DrawChannelsTempMergeBuffer;

    // Tab bars
    ImGuiTabBar*                    CurrentTabBar;
    ImPool!ImGuiTabBar             TabBars;
    ImVector!ImGuiPtrOrIndex       CurrentTabBarStack;
    ImVector!ImGuiShrinkWidthItem  ShrinkWidthBuffer;

    // Hover Delay system
    ImGuiID                 HoverItemDelayId;
    ImGuiID                 HoverItemDelayIdPreviousFrame;
    float                   HoverItemDelayTimer;                // Currently used by IsItemHovered()
    float                   HoverItemDelayClearTimer;           // Currently used by IsItemHovered(): grace time before g.TooltipHoverTimer gets cleared.
    ImGuiID                 HoverItemUnlockedStationaryId;      // Mouse has once been stationary on this item. Only reset after departing the item.
    ImGuiID                 HoverWindowUnlockedStationaryId;    // Mouse has once been stationary on this window. Only reset after departing the window.

    // Mouse state
    ImGuiMouseCursor        MouseCursor;
    float                   MouseStationaryTimer;               // Time the mouse has been stationary (with some loose heuristic)
    ImVec2                  MouseLastValidPos;

    // Widget state
    ImGuiInputTextState     InputTextState;
    ImGuiInputTextDeactivatedState InputTextDeactivatedState;
    ImFont                  InputTextPasswordFont;
    ImGuiID                 TempInputId;                        // Temporary text input when CTRL+clicking on a slider, etc.
    ImGuiColorEditFlags     ColorEditOptions;                   // Store user options for color edit widgets
    ImGuiID                 ColorEditCurrentID;                 // Set temporarily while inside of the parent-most ColorEdit4/ColorPicker4 (because they call each others).
    ImGuiID                 ColorEditSavedID;                   // ID we are saving/restoring HS for
    float                   ColorEditSavedHue;                  // Backup of last Hue associated to LastColor, so we can restore Hue in lossy RGB<>HSV round trips
    float                   ColorEditSavedSat;                  // Backup of last Saturation associated to LastColor, so we can restore Saturation in lossy RGB<>HSV round trips
    ImU32                   ColorEditSavedColor;                // RGB value with alpha set to 0.
    ImVec4                  ColorPickerRef;                     // Initial/reference color at the time of opening the color picker.
    ImGuiComboPreviewData   ComboPreviewData;
    float                   SliderGrabClickOffset;
    float                   SliderCurrentAccum;                 // Accumulated slider delta when using navigation controls.
    bool                    SliderCurrentAccumDirty;            // Has the accumulated slider delta changed since last time we tried to apply it?
    bool                    DragCurrentAccumDirty;
    float                   DragCurrentAccum;                   // Accumulator for dragging modification. Always high-precision, not rounded by end-user precision settings
    float                   DragSpeedDefaultRatio;              // If speed == 0.0f, uses (max-min) * DragSpeedDefaultRatio
    float                   ScrollbarClickDeltaToGrabCenter;    // Distance between mouse and center of grab box, normalized in parent space. Use storage?
    float                   DisabledAlphaBackup;                // Backup for style.Alpha for BeginDisabled()
    short                   DisabledStackSize;
    short                   TooltipOverrideCount;
    ImVector!char          ClipboardHandlerData;               // If no custom clipboard handler is defined
    ImVector!ImGuiID       MenusIdSubmittedThisFrame;          // A list of menu IDs that were rendered at least once

    // Platform support
    ImGuiPlatformImeData    PlatformImeData;                    // Data updated by current frame
    ImGuiPlatformImeData    PlatformImeDataPrev;                // Previous frame data (when changing we will call io.SetPlatformImeDataFn
    char                    PlatformLocaleDecimalPoint;         // '.' or *localeconv()->decimal_point

    // Settings
    bool                    SettingsLoaded;
    float                   SettingsDirtyTimer;                 // Save .ini Settings to memory when time reaches zero
    ImGuiTextBuffer         SettingsIniData;                    // In memory .ini settings
    ImVector!ImGuiSettingsHandler      SettingsHandlers;       // List of .ini settings handlers
    ImChunkStream!ImGuiWindowSettings  SettingsWindows;        // ImGuiWindow .ini settings entries
    ImChunkStream!ImGuiTableSettings   SettingsTables;         // ImGuiTable .ini settings entries
    ImVector!ImGuiContextHook          Hooks;                  // Hooks for extensions (e.g. test engine)
    ImGuiID                             HookIdNext;             // Next available HookId

    // Localization
    string[ImGuiLocKey.COUNT]             LocalizationTable;

    // Capture/Logging
    bool                    LogEnabled;                         // Currently capturing
    ImGuiLogType            LogType;                            // Capture target
    ImFileHandle            LogFile;                            // If != NULL log to stdout/ file
    ImGuiTextBuffer         LogBuffer;                          // Accumulation buffer when log to clipboard. This is pointer so our GImGui static constructor doesn't call heap allocators.
    string             LogNextPrefix;
    string             LogNextSuffix;
    float                   LogLinePosY;
    bool                    LogLineFirstItem;
    int                     LogDepthRef;
    int                     LogDepthToExpand;
    int                     LogDepthToExpandDefault;            // Default/stored value for LogDepthMaxExpand if not specified in the LogXXX function call.

    // Debug Tools
    ImGuiDebugLogFlags      DebugLogFlags;
    ImGuiTextBuffer         DebugLogBuf;
    ImGuiTextIndex          DebugLogIndex;
    ImU8                    DebugLogClipperAutoDisableFrames;
    ImU8                    DebugLocateFrames;                  // For DebugLocateItemOnHover(). This is used together with DebugLocateId which is in a hot/cached spot above.
    ImS8                    DebugBeginReturnValueCullDepth;     // Cycle between 0..9 then wrap around.
    bool                    DebugItemPickerActive;              // Item picker is active (started with DebugStartItemPicker())
    ImU8                    DebugItemPickerMouseButton;
    ImGuiID                 DebugItemPickerBreakId;             // Will call IM_DEBUG_BREAK() when encountering this ID
    ImGuiMetricsConfig      DebugMetricsConfig;
    ImGuiStackTool          DebugStackTool;

    // Misc
    float[60]                   FramerateSecPerFrame;           // Calculate estimate of framerate for user over the last 60 frames..
    int                     FramerateSecPerFrameIdx;
    int                     FramerateSecPerFrameCount;
    float                   FramerateSecPerFrameAccum;
    int                     WantCaptureMouseNextFrame;          // Explicit capture override via SetNextFrameWantCaptureMouse()/SetNextFrameWantCaptureKeyboard(). Default to -1.
    int                     WantCaptureKeyboardNextFrame;       // "
    int                     WantTextInputNextFrame;
    ImVector!char          TempBuffer;                         // Temporary text buffer

    this(ImFontAtlas* shared_font_atlas)
    {
        KeysOwnerData[] = ImGuiKeyOwnerData(false);
        KeysRoutingTable = ImGuiKeyRoutingTable(false);
        InputTextState = ImGuiInputTextState(false);
        IO = ImGuiIO(false);
        Style = ImGuiStyle(false);
        InputTextPasswordFont = ImFont(false);
        DrawListSharedData = ImDrawListSharedData(false);
        NavMoveResultLocal = ImGuiNavItemData(false);
        NavMoveResultOther = ImGuiNavItemData(false);
        DebugMetricsConfig = ImGuiMetricsConfig(false);
        NextItemData = ImGuiNextItemData(false);
        ComboPreviewData = ImGuiComboPreviewData(false);
        NavMoveResultLocalVisible = ImGuiNavItemData(false);
        NavTabbingResultFirst = ImGuiNavItemData(false);
        NavInitResult = ImGuiNavItemData(false);

        IO.Ctx = &this;
        InputTextState.Ctx = &this;

        Initialized = false;
        FontAtlasOwnedByContext = shared_font_atlas ? false : true;
        Font = NULL;
        FontSize = FontBaseSize = 0.0f;
        IO.Fonts = shared_font_atlas ? shared_font_atlas : IM_NEW!ImFontAtlas(false);
        Time = 0.0f;
        FrameCount = 0;
        FrameCountEnded = FrameCountRendered = -1;
        WithinFrameScope = WithinFrameScopeWithImplicitWindow = WithinEndChild = false;
        GcCompactAll = false;
        TestEngineHookItems = false;
        TestEngine = NULL;

        InputEventsNextMouseSource = ImGuiMouseSource.Mouse;
        InputEventsNextEventId = 1;

        WindowsActiveCount = 0;
        CurrentWindow = NULL;
        HoveredWindow = NULL;
        HoveredWindowUnderMovingWindow = NULL;
        MovingWindow = NULL;
        WheelingWindow = NULL;
        WheelingWindowStartFrame = -1;
        WheelingWindowReleaseTimer = 0.0f;

        DebugHookIdInfo = 0;
        HoveredId = HoveredIdPreviousFrame = 0;
        HoveredIdAllowOverlap = false;
        HoveredIdDisabled = false;
        HoveredIdTimer = HoveredIdNotActiveTimer = 0.0f;
        ActiveId = 0;
        ActiveIdIsAlive = 0;
        ActiveIdTimer = 0.0f;
        ActiveIdIsJustActivated = false;
        ActiveIdAllowOverlap = false;
        ActiveIdNoClearOnFocusLoss = false;
        ActiveIdHasBeenPressedBefore = false;
        ActiveIdHasBeenEditedBefore = false;
        ActiveIdHasBeenEditedThisFrame = false;
        ActiveIdClickOffset = ImVec2(-1, -1);
        ActiveIdWindow = NULL;
        ActiveIdSource = ImGuiInputSource.None;
        ActiveIdMouseButton = ImGuiMouseButton.None;
        ActiveIdPreviousFrame = 0;
        ActiveIdPreviousFrameIsAlive = false;
        ActiveIdPreviousFrameHasBeenEditedBefore = false;
        ActiveIdPreviousFrameWindow = NULL;
        LastActiveId = 0;
        LastActiveIdTimer = 0.0f;

        ActiveIdUsingNavDirMask = 0x00;
        ActiveIdUsingAllKeyboardKeys = false;
static if (!IMGUI_DISABLE_OBSOLETE_KEYIO) {
        ActiveIdUsingNavInputMask = 0x00;
}

        CurrentFocusScopeId = 0;
        CurrentItemFlags = ImGuiItemFlags.None;
        BeginMenuCount = 0;

        NavWindow = NULL;
        NavId = NavFocusScopeId = NavActivateId = NavActivateDownId = NavActivatePressedId = 0;
        NavJustMovedToId = NavJustMovedToFocusScopeId = NavNextActivateId = 0;
        NavActivateFlags = NavNextActivateFlags = ImGuiActivateFlags.None;
        NavJustMovedToKeyMods = ImGuiMod.None;
        NavInputSource = ImGuiInputSource.Keyboard;
        NavLayer = ImGuiNavLayer.Main;
        NavIdIsAlive = false;
        NavMousePosDirty = false;
        NavDisableHighlight = true;
        NavDisableMouseHover = false;
        NavAnyRequest = false;
        NavInitRequest = false;
        NavInitRequestFromMove = false;
        NavMoveSubmitted = false;
        NavMoveScoringItems = false;
        NavMoveForwardToNextFrame = false;
        NavMoveFlags = ImGuiNavMoveFlags.None;
        NavMoveScrollFlags = ImGuiScrollFlags.None;
        NavMoveKeyMods = ImGuiMod.None;
        NavMoveDir = NavMoveDirForDebug = NavMoveClipDir = ImGuiDir.None;
        NavScoringDebugCount = 0;
        NavTabbingDir = 0;
        NavTabbingCounter = 0;

        ConfigNavWindowingKeyNext = ImGuiMod.Ctrl | ImGuiKey.Tab;
        ConfigNavWindowingKeyPrev = ImGuiMod.Ctrl | ImGuiMod.Shift | ImGuiKey.Tab;
        NavWindowingTarget = NavWindowingTargetAnim = NavWindowingListWindow = NULL;
        NavWindowingTimer = NavWindowingHighlightAlpha = 0.0f;
        NavWindowingToggleLayer = false;

        DimBgRatio = 0.0f;

        DragDropActive = DragDropWithinSource = DragDropWithinTarget = false;
        DragDropSourceFlags = ImGuiDragDropFlags.None;
        DragDropSourceFrameCount = -1;
        DragDropMouseButton = ImGuiMouseButton.None;
        DragDropTargetId = 0;
        DragDropAcceptFlags = ImGuiDragDropFlags.None;
        DragDropAcceptIdCurrRectSurface = 0.0f;
        DragDropAcceptIdPrev = DragDropAcceptIdCurr = 0;
        DragDropAcceptFrameCount = -1;
        DragDropHoldJustPressedId = 0;
        memset(&DragDropPayloadBufLocal, 0, sizeof(DragDropPayloadBufLocal));

        ClipperTempDataStacked = 0;

        CurrentTable = NULL;
        TablesTempDataStacked = 0;
        CurrentTabBar = NULL;

        HoverItemDelayId = HoverItemDelayIdPreviousFrame = HoverItemUnlockedStationaryId = HoverWindowUnlockedStationaryId = 0;
        HoverItemDelayTimer = HoverItemDelayClearTimer = 0.0f;

        MouseCursor = ImGuiMouseCursor.Arrow;
        MouseStationaryTimer = 0.0f;

        TempInputId = 0;
        ColorEditOptions = ImGuiColorEditFlags.DefaultOptions_;
        ColorEditCurrentID = ColorEditSavedID = 0;
        ColorEditSavedHue = ColorEditSavedSat = 0.0f;
        ColorEditSavedColor = 0;
        SliderGrabClickOffset = 0.0f;
        SliderCurrentAccum = 0.0f;
        SliderCurrentAccumDirty = false;
        DragCurrentAccumDirty = false;
        DragCurrentAccum = 0.0f;
        DragSpeedDefaultRatio = 1.0f / 100.0f;
        ScrollbarClickDeltaToGrabCenter = 0.0f;
        DisabledAlphaBackup = 0.0f;
        DisabledStackSize = 0;
        TooltipOverrideCount = 0;

        PlatformImeData.InputPos = ImVec2(0.0f, 0.0f);
        PlatformImeDataPrev.InputPos = ImVec2(-1.0f, -1.0f); // Different to ensure initial submission
        PlatformLocaleDecimalPoint = '.';

        SettingsLoaded = false;
        SettingsDirtyTimer = 0.0f;
        HookIdNext = 0;

        memset(LocalizationTable, 0, sizeof(LocalizationTable));

        LogEnabled = false;
        LogType = ImGuiLogType.None;
        LogNextPrefix = LogNextSuffix = NULL;
        LogFile = NULL;
        LogLinePosY = FLT_MAX;
        LogLineFirstItem = false;
        LogDepthRef = 0;
        LogDepthToExpand = LogDepthToExpandDefault = 2;

        DebugLogFlags = ImGuiDebugLogFlags.OutputToTTY;
        DebugLocateId = 0;
        DebugLogClipperAutoDisableFrames = 0;
        DebugLocateFrames = 0;
        DebugBeginReturnValueCullDepth = -1;
        DebugItemPickerActive = false;
        DebugItemPickerMouseButton = ImGuiMouseButton.Left;
        DebugItemPickerBreakId = 0;

        memset(FramerateSecPerFrame, 0, sizeof(FramerateSecPerFrame));
        FramerateSecPerFrameIdx = FramerateSecPerFrameCount = 0;
        FramerateSecPerFrameAccum = 0.0f;
        WantCaptureMouseNextFrame = WantCaptureKeyboardNextFrame = WantTextInputNextFrame = -1;
    }

    void destroy() {
        Windows.destroy();
        WindowsFocusOrder.destroy();
        WindowsTempSortBuffer.destroy();
        CurrentWindowStack.destroy();
        FontStack.destroy();
        OpenPopupStack.destroy();
        BeginPopupStack.destroy(); 
        DragDropPayloadBufHeap.destroy();
        CurrentTabBarStack.destroy();
        ShrinkWidthBuffer.destroy();
        ClipboardHandlerData.destroy();
        MenusIdSubmittedThisFrame.destroy();
        SettingsHandlers.destroy();
        InputEventsQueue.destroy();
        InputEventsTrail.destroy();
		GroupStack.destroy();
		TempBuffer.destroy();
		ItemFlagsStack.destroy();
        DebugLogBuf.destroy();
        ClipperTempData.destroy();
        TablesTempData.destroy();
        TablesLastTimeActive.destroy();
        DrawChannelsTempMergeBuffer.destroy();
        Tables.destroy();

        IO.destroy();
        SettingsIniData.destroy();
        LogBuffer.destroy();
        WindowsById.destroy();
        InputTextPasswordFont.destroy();
        TabBars.destroy();
        SettingsWindows.destroy();
        InputTextState.destroy();
        FocusScopeStack.destroy();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] ImGuiWindowTempData, ImGuiWindow
//-----------------------------------------------------------------------------

// Transient per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the DC variable name in ImGuiWindow.
// (That's theory, in practice the delimitation between ImGuiWindow and ImGuiWindowTempData is quite tenuous and could be reconsidered..)
// (This doesn't need a constructor because we zero-clear it as part of ImGuiWindow and all frame-temporary data are setup on Begin)
struct ImGuiWindowTempData
{
    nothrow:
    @nogc:

    // Layout
    ImVec2                  CursorPos;              // Current emitting position, in absolute coordinates.
    ImVec2                  CursorPosPrevLine;
    ImVec2                  CursorStartPos;         // Initial position after Begin(), generally ~ window position + WindowPadding.
    ImVec2                  CursorMaxPos;           // Used to implicitly calculate ContentSize at the beginning of next frame, for scrolling range and auto-resize. Always growing during the frame.
    ImVec2                  IdealMaxPos;            // Used to implicitly calculate ContentSizeIdeal at the beginning of next frame, for auto-resize only. Always growing during the frame.
    ImVec2                  CurrLineSize;
    ImVec2                  PrevLineSize;
    float                   CurrLineTextBaseOffset; // Baseline offset (0.0f by default on a new line, generally == style.FramePadding.y when a framed item has been added).
    float                   PrevLineTextBaseOffset;
    bool                    IsSameLine;
    bool                    IsSetPos;
    ImVec1                  Indent;                 // Indentation / start position from left of window (increased by TreePush/TreePop, etc.)
    ImVec1                  ColumnsOffset;          // Offset to the current column (if ColumnsCurrent > 0). FIXME: This and the above should be a stack to allow use cases like Tree->Column->Tree. Need revamp columns API.
    ImVec1                  GroupOffset;
    ImVec2                  CursorStartPosLossyness;// Record the loss of precision of CursorStartPos due to really large scrolling amount. This is used by clipper to compensate and fix the most common use case of large scroll area.

    // Keyboard/Gamepad navigation
    ImGuiNavLayer           NavLayerCurrent;        // Current layer, 0..31 (we currently only use 0..1)
    short                   NavLayersActiveMask;    // Which layers have been written to (result from previous frame)
    short                   NavLayersActiveMaskNext;// Which layers have been written to (accumulator for current frame)
    bool                    NavIsScrollPushableX;   // Set when current work location may be scrolled horizontally when moving left / right. This is generally always true UNLESS within a column.
    bool                    NavHideHighlightOneFrame;
    bool                    NavWindowHasScrollY;    // Set per window when scrolling can be used (== ScrollMax.y > 0.0f)

    // Miscellaneous
    bool                    MenuBarAppending;       // FIXME: Remove this
    ImVec2                  MenuBarOffset;          // MenuBarOffset.x is sort of equivalent of a per-layer CursorPos.x, saved/restored as we switch to the menu bar. The only situation when MenuBarOffset.y is > 0 if when (SafeAreaPadding.y > FramePadding.y), often used on TVs.
    ImGuiMenuColumns        MenuColumns;            // Simplified columns storage for menu items measurement
    int                     TreeDepth;              // Current tree depth.
    ImU32                   TreeJumpToParentOnPopMask; // Store a copy of !g.NavIdIsAlive for TreeDepth 0..31.. Could be turned into a ImU64 if necessary.
    ImVector!(ImGuiWindow*)  ChildWindows;
    ImGuiStorage*           StateStorage;           // Current persistent per-window storage (store e.g. tree node open/close state)
    ImGuiOldColumns*        CurrentColumns;         // Current columns set
    int                     CurrentTableIdx;        // Current table index (into g.Tables)
    ImGuiLayoutType         LayoutType;
    ImGuiLayoutType         ParentLayoutType;       // Layout type of parent window at the time of Begin()

    // Local parameters stacks
    // We store the current settings outside of the vectors to increase memory locality (reduce cache misses). The vectors are rarely modified. Also it allows us to not heap allocate for short-lived windows which are not using those settings.
    float                   ItemWidth;              // Current item width (>0.0: width in pixels, <0.0: align xx pixels to the right of window).
    float                   TextWrapPos;            // Current text wrap pos.
    ImVector!float         ItemWidthStack;         // Store item widths to restore (attention: .back() is not == ItemWidth)
    ImVector!float         TextWrapPosStack;       // Store text wrap pos to restore (attention: .back() is not == TextWrapPos)

    @disable this();
    this(bool dummy) {
        MenuColumns = ImGuiMenuColumns(false);
    }

    void destroy() {
        ChildWindows.destroy();
        ItemWidthStack.destroy();
        TextWrapPosStack.destroy();
    }
}

// Storage for one window
struct ImGuiWindow
{
    nothrow:
    @nogc:

    ImGuiContext*           Ctx;                                // Parent UI context (needs to be set explicitly by parent).
    string                  Name;                               // Window name, owned by the window.
    char[]                  NameBuf;
    ImGuiID                 ID;                                 // == ImHashStr(Name)
    ImGuiWindowFlags        Flags;                              // See enum ImGuiWindowFlags_
    ImGuiViewportP*         Viewport;                           // Always set in Begin(). Inactive windows may have a NULL value here if their viewport was discarded.
    ImVec2                  Pos;                                // Position (always rounded-up to nearest pixel)
    ImVec2                  Size;                               // Current size (==SizeFull or collapsed title bar size)
    ImVec2                  SizeFull;                           // Size when non collapsed
    ImVec2                  ContentSize;                        // Size of contents/scrollable client area (calculated from the extents reach of the cursor) from previous frame. Does not include window decoration or window padding.
    ImVec2                  ContentSizeIdeal;
    ImVec2                  ContentSizeExplicit;                // Size of contents/scrollable client area explicitly request by the user via SetNextWindowContentSize().
    ImVec2                  WindowPadding;                      // Window padding at the time of Begin().
    float                   WindowRounding;                     // Window rounding at the time of Begin(). May be clamped lower to avoid rendering artifacts with title bar, menu bar etc.
    float                   WindowBorderSize;                   // Window border size at the time of Begin().
    float                   DecoOuterSizeX1, DecoOuterSizeY1;   // Left/Up offsets. Sum of non-scrolling outer decorations (X1 generally == 0.0f. Y1 generally = TitleBarHeight + MenuBarHeight). Locked during Begin().
    float                   DecoOuterSizeX2, DecoOuterSizeY2;   // Right/Down offsets (X2 generally == ScrollbarSize.x, Y2 == ScrollbarSizes.y).
    float                   DecoInnerSizeX1, DecoInnerSizeY1;   // Applied AFTER/OVER InnerRect. Specialized for Tables as they use specialized form of clipping and frozen rows/columns are inside InnerRect (and not part of regular decoration sizes).
    //int                     NameBufLen;                         // Size of buffer storing Name. May be larger than strlen(Name)!
    ImGuiID                 MoveId;                             // == window->GetID("#MOVE")
    ImGuiID                 ChildId;                            // ID of corresponding item in parent window (for navigation to return from child window to parent window)
    ImVec2                  Scroll;
    ImVec2                  ScrollMax;
    ImVec2                  ScrollTarget;                       // target scroll position. stored as cursor position with scrolling canceled out, so the highest point is always 0.0f. (FLT_MAX for no change)
    ImVec2                  ScrollTargetCenterRatio;            // 0.0f = scroll so that target position is at top, 0.5f = scroll so that target position is centered
    ImVec2                  ScrollTargetEdgeSnapDist;           // 0.0f = no snapping, >0.0f snapping threshold
    ImVec2                  ScrollbarSizes;                     // Size taken by each scrollbars on their smaller axis. Pay attention! ScrollbarSizes.x == width of the vertical scrollbar, ScrollbarSizes.y = height of the horizontal scrollbar.
    bool                    ScrollbarX, ScrollbarY;             // Are scrollbars visible?
    bool                    Active;                             // Set to true on Begin(), unless Collapsed
    bool                    WasActive;
    bool                    WriteAccessed;                      // Set to true when any widget access the current window
    bool                    Collapsed;                          // Set when collapsing window to become only title-bar
    bool                    WantCollapseToggle;
    bool                    SkipItems;                          // Set when items can safely be all clipped (e.g. window not visible or collapsed)
    bool                    Appearing;                          // Set during the frame where the window is appearing (or re-appearing)
    bool                    Hidden;                             // Do not display (== HiddenFrames*** > 0)
    bool                    IsFallbackWindow;                   // Set on the "Debug##Default" window.
    bool                    IsExplicitChild;                    // Set when passed _ChildWindow, left to false by BeginDocked()
    bool                    HasCloseButton;                     // Set when the window has a close button (p_open != NULL)
    byte             ResizeBorderHeld;                   // Current border being held for resize (-1: none, otherwise 0-3)
    short                   BeginCount;                         // Number of Begin() during the current frame (generally 0 or 1, 1+ if appending via multiple Begin/End pairs)
    short                   BeginCountPreviousFrame;            // Number of Begin() during the previous frame
    short                   BeginOrderWithinParent;             // Begin() order within immediate parent window, if we are a child window. Otherwise 0.
    short                   BeginOrderWithinContext;            // Begin() order within entire imgui context. This is mostly used for debugging submission order related issues.
    short                   FocusOrder;                         // Order within WindowsFocusOrder[], altered when windows are focused.
    ImGuiID                 PopupId;                            // ID in the popup stack when this window is used as a popup/menu (because we use generic Name/ID for recycling)
    ImS8                    AutoFitFramesX, AutoFitFramesY;
    ImS8                    AutoFitChildAxises;
    bool                    AutoFitOnlyGrows;
    ImGuiDir                AutoPosLastDirection;
    ImS8                    HiddenFramesCanSkipItems;           // Hide the window for N frames
    ImS8                    HiddenFramesCannotSkipItems;        // Hide the window for N frames while allowing items to be submitted so we can measure their size
    ImS8                    HiddenFramesForRenderOnly;          // Hide the window until frame N at Render() time only
    ImS8                    DisableInputsFrames;                // Disable window interactions for N frames
    ImGuiCond               SetWindowPosAllowFlags/* : 8*/;         // store acceptable condition flags for SetNextWindowPos() use.
    ImGuiCond               SetWindowSizeAllowFlags/* : 8*/;        // store acceptable condition flags for SetNextWindowSize() use.
    ImGuiCond               SetWindowCollapsedAllowFlags/* : 8*/;   // store acceptable condition flags for SetNextWindowCollapsed() use.
    ImVec2                  SetWindowPosVal;                    // store window position when using a non-zero Pivot (position set needs to be processed when we know the window size)
    ImVec2                  SetWindowPosPivot;                  // store window pivot for positioning. ImVec2(0, 0) when positioning from top-left corner; ImVec2(0.5f, 0.5f) for centering; ImVec2(1, 1) for bottom right.

    ImVector!ImGuiID       IDStack;                            // ID stack. ID are hashes seeded with the value at the top of the stack. (In theory this should be in the TempData structure)
    ImGuiWindowTempData     DC;                                 // Temporary per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the "DC" variable name.

    // The best way to understand what those rectangles are is to use the 'Metrics->Tools->Show Windows Rectangles' viewer.
    // The main 'OuterRect', omitted as a field, is window->Rect().
    ImRect                  OuterRectClipped;                   // == Window->Rect() just after setup in Begin(). == window->Rect() for root window.
    ImRect                  InnerRect;                          // Inner rectangle (omit title bar, menu bar, scroll bar)
    ImRect                  InnerClipRect;                      // == InnerRect shrunk by WindowPadding*0.5f on each side, clipped within viewport or parent clip rect.
    ImRect                  WorkRect;                           // Initially covers the whole scrolling region. Reduced by containers e.g columns/tables when active. Shrunk by WindowPadding*1.0f on each side. This is meant to replace ContentRegionRect over time (from 1.71+ onward).
    ImRect                  ParentWorkRect;                     // Backup of WorkRect before entering a container such as columns/tables. Used by e.g. SpanAllColumns functions to easily access. Stacked containers are responsible for maintaining this. // FIXME-WORKRECT: Could be a stack?
    ImRect                  ClipRect;                           // Current clipping/scissoring rectangle, evolve as we are using PushClipRect(), etc. == DrawList->clip_rect_stack.back().
    ImRect                  ContentRegionRect;                  // FIXME: This is currently confusing/misleading. It is essentially WorkRect but not handling of scrolling. We currently rely on it as right/bottom aligned sizing operation need some size to rely on.
    ImVec2ih                HitTestHoleSize;                    // Define an optional rectangular hole where mouse will pass-through the window.
    ImVec2ih                HitTestHoleOffset;

    int                     LastFrameActive;                    // Last frame number the window was Active.
    float                   LastTimeActive;                     // Last timestamp the window was Active (using float as we don't need high precision there)
    float                   ItemWidthDefault;
    ImGuiStorage            StateStorage;
    ImVector!ImGuiOldColumns ColumnsStorage;
    float                   FontWindowScale;                    // User scale multiplier per-window, via SetWindowFontScale()
    int                     SettingsOffset;                     // Offset into SettingsWindows[] (offsets are always valid as we only grow the array from the back)

    ImDrawList*             DrawList;                           // == &DrawListInst (for backward compatibility reason with code using imgui_internal.h we keep this a pointer)
    ImDrawList              DrawListInst;
    ImGuiWindow*            ParentWindow;                       // If we are a child _or_ popup _or_ docked window, this is pointing to our parent. Otherwise NULL.
    ImGuiWindow*            ParentWindowInBeginStack;
    ImGuiWindow*            RootWindow;                         // Point to ourself or first ancestor that is not a child window. Doesn't cross through popups/dock nodes.
    ImGuiWindow*            RootWindowPopupTree;                // Point to ourself or first ancestor that is not a child window. Cross through popups parent<>child.
    ImGuiWindow*            RootWindowForTitleBarHighlight;     // Point to ourself or first ancestor which will display TitleBgActive color when this window is active.
    ImGuiWindow*            RootWindowForNav;                   // Point to ourself or first ancestor which doesn't have the NavFlattened flag.

    ImGuiWindow*            NavLastChildNavWindow;              // When going to the menu bar, we remember the child window we came from. (This could probably be made implicit if we kept g.Windows sorted by last focused including child window.)
    ImGuiID[ImGuiNavLayer.COUNT]                 NavLastIds;    // Last known NavId for this window, per layer (0/1)
    ImRect[ImGuiNavLayer.COUNT]                  NavRectRel;    // Reference rectangle, in window relative space
    ImVec2[ImGuiNavLayer.COUNT]                  NavPreferredScoringPosRel; // Preferred X/Y position updated when moving on a given axis, reset to FLT_MAX.
    ImGuiID                 NavRootFocusScopeId;                // Focus Scope ID at the time of Begin()

    int                     MemoryDrawListIdxCapacity;          // Backup of last idx/vtx count, so when waking up the window we can preallocate and avoid iterative alloc/copy
    int                     MemoryDrawListVtxCapacity;
    bool                    MemoryCompacted;                    // Set when window extraneous data have been garbage collected

    this(ImGuiContext* context, string name)
    {
        DC = ImGuiWindowTempData(false);
        (cast(ImGuiWindow_Wrapper*)&this).__ctor(context, name);
    }
    void destroy() { (cast(ImGuiWindow_Wrapper*)&this).destroy(); }

    ImGuiID     GetID(string str) { return (cast(ImGuiWindow_Wrapper*)&this).GetID(str); }
    ImGuiID     GetID(const void* ptr) { return (cast(ImGuiWindow_Wrapper*)&this).GetID(ptr); }
    ImGuiID     GetID(int n) { return (cast(ImGuiWindow_Wrapper*)&this).GetID(n); }
    ImGuiID     GetIDFromRectangle(const ImRect/*&*/ r_abs) { return (cast(ImGuiWindow_Wrapper*)&this).GetIDFromRectangle(r_abs); }

    // We don't use g.FontSize because the window may be != g.CurrentWindow.
    ImRect      Rect() const            { return ImRect(Pos.x, Pos.y, Pos.x + Size.x, Pos.y + Size.y); }
    float       CalcFontSize() const    { const ImGuiContext* g = Ctx; float scale = g.FontBaseSize * FontWindowScale; if (ParentWindow) scale *= ParentWindow.FontWindowScale; return scale; }
    float       TitleBarHeight() const  { const ImGuiContext* g = Ctx; return (Flags & ImGuiWindowFlags.NoTitleBar) ? 0.0f : CalcFontSize() + g.Style.FramePadding.y * 2.0f; }
    ImRect      TitleBarRect() const    { return ImRect(Pos, ImVec2(Pos.x + SizeFull.x, Pos.y + TitleBarHeight())); }
    float       MenuBarHeight() const   { const ImGuiContext* g = Ctx; return (Flags & ImGuiWindowFlags.MenuBar) ? DC.MenuBarOffset.y + CalcFontSize() + g.Style.FramePadding.y * 2.0f : 0.0f; }
    ImRect      MenuBarRect() const     { float y1 = Pos.y + TitleBarHeight(); return ImRect(Pos.x, y1, Pos.x + SizeFull.x, y1 + MenuBarHeight()); }
}

//-----------------------------------------------------------------------------
// [SECTION] Tab bar, Tab item support
//-----------------------------------------------------------------------------

// D_IMGUI: Moved into ImGuiTabBarFlags
/+
// Extend ImGuiTabBarFlags_
enum ImGuiTabBarFlagsPrivate_
{
    DockNode                   = 1 << 20,  // Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
    IsFocused                  = 1 << 21,
    SaveSettings               = 1 << 22,  // FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
}
+/

// D_IMGUI: Moved into ImGuiTabItemFlags
/+
// Extend ImGuiTabItemFlags_
enum ImGuiTabItemFlagsPrivate_
{
    SectionMask_              = ImGuiTabItemFlags.Leading | ImGuiTabItemFlags.Trailing,
    NoCloseButton             = 1 << 20,  // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
    Button                    = 1 << 21,  // Used by TabItemButton, change the tab item behavior to mimic a button
}
+/

// Storage for one active tab item (sizeof() 40 bytes)
struct ImGuiTabItem
{
    nothrow:
    @nogc:

    ImGuiID             ID;
    ImGuiTabItemFlags   Flags;
    int                 LastFrameVisible;
    int                 LastFrameSelected;      // This allows us to infer an ordered list of the last activated tabs with little maintenance
    float               Offset;                 // Position relative to beginning of tab
    float               Width;                  // Width currently displayed
    float               ContentWidth;           // Width of label, stored during BeginTabItem() call
    float               RequestedWidth;         // Width optionally requested by caller, -1.0f is unused
    ImS32               NameOffset;             // When Window==NULL, offset to name within parent ImGuiTabBar::TabsNames
    ImS16               BeginOrder;             // BeginTabItem() order, used to re-order tabs after toggling ImGuiTabBarFlags_Reorderable
    ImS16               IndexDuringLayout;      // Index only used during TabBarLayout(). Tabs gets reordered so 'Tabs[n].IndexDuringLayout == n' but may mismatch during additions.
    bool                WantClose;              // Marked as closed by SetTabItemClosed()

    @disable this();
    this(bool dummy)      { memset(&this, 0, sizeof(this)); LastFrameVisible = LastFrameSelected = -1; RequestedWidth = -1.0f; NameOffset = -1; BeginOrder = IndexDuringLayout = -1; }
}

// Storage for a tab bar (sizeof() 152 bytes)
struct ImGuiTabBar
{
    nothrow:
    @nogc:

    ImVector!ImGuiTabItem Tabs;
    ImGuiTabBarFlags    Flags;
    ImGuiID             ID;                     // Zero for tab-bars used by docking
    ImGuiID             SelectedTabId;          // Selected tab/window
    ImGuiID             NextSelectedTabId;      // Next selected tab/window. Will also trigger a scrolling animation
    ImGuiID             VisibleTabId;           // Can occasionally be != SelectedTabId (e.g. when previewing contents for CTRL+TAB preview)
    int                 CurrFrameVisible;
    int                 PrevFrameVisible;
    ImRect              BarRect;
    float               CurrTabsContentsHeight;
    float               PrevTabsContentsHeight; // Record the height of contents submitted below the tab bar
    float               WidthAllTabs;           // Actual width of all tabs (locked during layout)
    float               WidthAllTabsIdeal;      // Ideal width if all tabs were visible and not clipped
    float               ScrollingAnim;
    float               ScrollingTarget;
    float               ScrollingTargetDistToVisibility;
    float               ScrollingSpeed;
    float               ScrollingRectMinX;
    float               ScrollingRectMaxX;
    ImGuiID             ReorderRequestTabId;
    ImS16               ReorderRequestOffset;
    ImS8                BeginCount;
    bool                WantLayout;
    bool                VisibleTabWasSubmitted;
    bool                TabsAddedNew;           // Set to true when a new tab item or button has been added to the tab bar during last frame
    ImS16               TabsActiveCount;        // Number of tabs submitted this frame.
    ImS16               LastTabItemIdx;         // Index of last BeginTabItem() tab for use by EndTabItem()
    float               ItemSpacingY;
    ImVec2              FramePadding;           // style.FramePadding locked at the time of BeginTabBar()
    ImVec2              BackupCursorPos;
    ImGuiTextBuffer     TabsNames;              // For non-docking tab bar we re-append names in a contiguous buffer.

    @disable this();
    this(bool dummy) { (cast(ImGuiTabBar_Wrapper*)&this).__ctor(dummy); }
    
    void destroy() {
        TabsNames.destroy();
        Tabs.destroy();
    }
}

//-----------------------------------------------------------------------------
// [SECTION] Table support
//-----------------------------------------------------------------------------

enum IM_COL32_DISABLE                = IM_COL32(0,0,0,1);   // Special sentinel code which cannot be used as a regular color.
enum IMGUI_TABLE_MAX_COLUMNS         = 512;                 // May be further lifted

// Our current column maximum is 64 but we may raise that in the future.
alias ImGuiTableColumnIdx = ImS16;
alias ImGuiTableDrawChannelIdx = ImU16;

// [Internal] sizeof() ~ 112
// We use the terminology "Enabled" to refer to a column that is not Hidden by user/api.
// We use the terminology "Clipped" to refer to a column that is out of sight because of scrolling/clipping.
// This is in contrast with some user-facing api such as IsItemVisible() / IsRectVisible() which use "Visible" to mean "not clipped".
struct ImGuiTableColumn
{
    nothrow:
    @nogc:

    ImGuiTableColumnFlags   Flags;                          // Flags after some patching (not directly same as provided by user). See ImGuiTableColumnFlags_
    float                   WidthGiven;                     // Final/actual width visible == (MaxX - MinX), locked in TableUpdateLayout(). May be > WidthRequest to honor minimum width, may be < WidthRequest to honor shrinking columns down in tight space.
    float                   MinX;                           // Absolute positions
    float                   MaxX;
    float                   WidthRequest;                   // Master width absolute value when !(Flags & _WidthStretch). When Stretch this is derived every frame from StretchWeight in TableUpdateLayout()
    float                   WidthAuto;                      // Automatic width
    float                   StretchWeight;                  // Master width weight when (Flags & _WidthStretch). Often around ~1.0f initially.
    float                   InitStretchWeightOrWidth;       // Value passed to TableSetupColumn(). For Width it is a content width (_without padding_).
    ImRect                  ClipRect;                       // Clipping rectangle for the column
    ImGuiID                 UserID;                         // Optional, value passed to TableSetupColumn()
    float                   WorkMinX;                       // Contents region min ~(MinX + CellPaddingX + CellSpacingX1) == cursor start position when entering column
    float                   WorkMaxX;                       // Contents region max ~(MaxX - CellPaddingX - CellSpacingX2)
    float                   ItemWidth;                      // Current item width for the column, preserved across rows
    float                   ContentMaxXFrozen;              // Contents maximum position for frozen rows (apart from headers), from which we can infer content width.
    float                   ContentMaxXUnfrozen;
    float                   ContentMaxXHeadersUsed;         // Contents maximum position for headers rows (regardless of freezing). TableHeader() automatically softclip itself + report ideal desired size, to avoid creating extraneous draw calls
    float                   ContentMaxXHeadersIdeal;
    ImS16                   NameOffset;                     // Offset into parent ColumnsNames[]
    ImGuiTableColumnIdx     DisplayOrder;                   // Index within Table's IndexToDisplayOrder[] (column may be reordered by users)
    ImGuiTableColumnIdx     IndexWithinEnabledSet;          // Index within enabled/visible set (<= IndexToDisplayOrder)
    ImGuiTableColumnIdx     PrevEnabledColumn;              // Index of prev enabled/visible column within Columns[], -1 if first enabled/visible column
    ImGuiTableColumnIdx     NextEnabledColumn;              // Index of next enabled/visible column within Columns[], -1 if last enabled/visible column
    ImGuiTableColumnIdx     SortOrder;                      // Index of this column within sort specs, -1 if not sorting on this column, 0 for single-sort, may be >0 on multi-sort
    ImGuiTableDrawChannelIdx DrawChannelCurrent;            // Index within DrawSplitter.Channels[]
    ImGuiTableDrawChannelIdx DrawChannelFrozen;             // Draw channels for frozen rows (often headers)
    ImGuiTableDrawChannelIdx DrawChannelUnfrozen;           // Draw channels for unfrozen rows
    bool                    IsEnabled;                      // IsUserEnabled && (Flags & ImGuiTableColumnFlags_Disabled) == 0
    bool                    IsUserEnabled;                  // Is the column not marked Hidden by the user? (unrelated to being off view, e.g. clipped by scrolling).
    bool                    IsUserEnabledNextFrame;
    bool                    IsVisibleX;                     // Is actually in view (e.g. overlapping the host window clipping rectangle, not scrolled).
    bool                    IsVisibleY;
    bool                    IsRequestOutput;                // Return value for TableSetColumnIndex() / TableNextColumn(): whether we request user to output contents or not.
    bool                    IsSkipItems;                    // Do we want item submissions to this column to be completely ignored (no layout will happen).
    bool                    IsPreserveWidthAuto;
    ImS8                    NavLayerCurrent;                // ImGuiNavLayer in 1 byte
    ImU8                    AutoFitQueue;                   // Queue of 8 values for the next 8 frames to request auto-fit
    ImU8                    CannotSkipItemsQueue;           // Queue of 8 values for the next 8 frames to disable Clipped/SkipItem
    ImU8                    SortDirection/* : 2*/;              // ImGuiSortDirection_Ascending or ImGuiSortDirection_Descending
    ImU8                    SortDirectionsAvailCount/* : 2*/;   // Number of available sort directions (0 to 3)
    ImU8                    SortDirectionsAvailMask/* : 4*/;    // Mask of available sort directions (1-bit each)
    ImU8                    SortDirectionsAvailList;        // Ordered list of available sort directions (2-bits each, total 8-bits)

    @disable this();
    this(bool dummy)
    {
        memset(&this, 0, sizeof(this));
        StretchWeight = WidthRequest = -1.0f;
        NameOffset = -1;
        DisplayOrder = IndexWithinEnabledSet = -1;
        PrevEnabledColumn = NextEnabledColumn = -1;
        SortOrder = -1;
        SortDirection = ImGuiSortDirection.None;
        DrawChannelCurrent = DrawChannelFrozen = DrawChannelUnfrozen = cast(ImU8)-1;
    }
}

// Transient cell data stored per row.
// sizeof() ~ 6
struct ImGuiTableCellData
{
    ImU32                       BgColor;    // Actual color
    ImGuiTableColumnIdx         Column;     // Column number
}

// Per-instance data that needs preserving across frames (seemingly most others do not need to be preserved aside from debug needs. Does that means they could be moved to ImGuiTableTempData?)
struct ImGuiTableInstanceData
{
    ImGuiID                     TableInstanceID;
    float                       LastOuterHeight = 0.0f;            // Outer height from last frame
    float                       LastFirstRowHeight = 0.0f;         // Height of first row from last frame (FIXME: this is used as "header height" and may be reworked)
    float                       LastFrozenHeight = 0.0f;           // Height of frozen section from last frame

    //ImGuiTableInstanceData()    { TableInstanceID = 0; LastOuterHeight = LastFirstRowHeight = LastFrozenHeight = 0.0f; }
}

// FIXME-TABLE: more transient data could be stored in a stacked ImGuiTableTempData: e.g. SortSpecs, incoming RowData
// sizeof() ~ 580 bytes + heap allocs described in TableBeginInitMemory()
struct ImGuiTable
{
    nothrow:
    @nogc:

    ImGuiID                     ID;
    ImGuiTableFlags             Flags;
    void*                       RawData;                    // Single allocation to hold Columns[], DisplayOrderToIndex[] and RowCellData[]
    ImGuiTableTempData*         TempData;                   // Transient data while table is active. Point within g.CurrentTableStack[]
    ImSpan!ImGuiTableColumn    Columns;                    // Point within RawData[]
    ImSpan!ImGuiTableColumnIdx DisplayOrderToIndex;        // Point within RawData[]. Store display order of columns (when not reordered, the values are 0...Count-1)
    ImSpan!ImGuiTableCellData  RowCellData;                // Point within RawData[]. Store cells background requests for current row.
    ImBitArrayPtr               EnabledMaskByDisplayOrder;  // Column DisplayOrder -> IsEnabled map
    ImBitArrayPtr               EnabledMaskByIndex;         // Column Index -> IsEnabled map (== not hidden by user/api) in a format adequate for iterating column without touching cold data
    ImBitArrayPtr               VisibleMaskByIndex;         // Column Index -> IsVisibleX|IsVisibleY map (== not hidden by user/api && not hidden by scrolling/cliprect)
    ImGuiTableFlags             SettingsLoadedFlags;        // Which data were loaded from the .ini file (e.g. when order is not altered we won't save order)
    int                         SettingsOffset;             // Offset in g.SettingsTables
    int                         LastFrameActive;
    int                         ColumnsCount;               // Number of columns declared in BeginTable()
    int                         CurrentRow;
    int                         CurrentColumn;
    ImS16                       InstanceCurrent;            // Count of BeginTable() calls with same ID in the same frame (generally 0). This is a little bit similar to BeginCount for a window, but multiple table with same ID look are multiple tables, they are just synched.
    ImS16                       InstanceInteracted;         // Mark which instance (generally 0) of the same ID is being interacted with
    float                       RowPosY1;
    float                       RowPosY2;
    float                       RowMinHeight;               // Height submitted to TableNextRow()
    float                       RowTextBaseline;
    float                       RowIndentOffsetX;
    ImGuiTableRowFlags          RowFlags/* : 16*/;              // Current row flags, see ImGuiTableRowFlags_
    ImGuiTableRowFlags          LastRowFlags/* : 16*/;
    int                         RowBgColorCounter;          // Counter for alternating background colors (can be fast-forwarded by e.g clipper), not same as CurrentRow because header rows typically don't increase this.
    ImU32[2]                       RowBgColor;              // Background color override for current row.
    ImU32                       BorderColorStrong;
    ImU32                       BorderColorLight;
    float                       BorderX1;
    float                       BorderX2;
    float                       HostIndentX;
    float                       MinColumnWidth;
    float                       OuterPaddingX;
    float                       CellPaddingX;               // Padding from each borders
    float                       CellPaddingY;
    float                       CellSpacingX1;              // Spacing between non-bordered cells
    float                       CellSpacingX2;
    float                       InnerWidth;                 // User value passed to BeginTable(), see comments at the top of BeginTable() for details.
    float                       ColumnsGivenWidth;          // Sum of current column width
    float                       ColumnsAutoFitWidth;        // Sum of ideal column width in order nothing to be clipped, used for auto-fitting and content width submission in outer window
    float                       ColumnsStretchSumWeights;   // Sum of weight of all enabled stretching columns
    float                       ResizedColumnNextWidth;
    float                       ResizeLockMinContentsX2;    // Lock minimum contents width while resizing down in order to not create feedback loops. But we allow growing the table.
    float                       RefScale;                   // Reference scale to be able to rescale columns on font/dpi changes.
    ImRect                      OuterRect;                  // Note: for non-scrolling table, OuterRect.Max.y is often FLT_MAX until EndTable(), unless a height has been specified in BeginTable().
    ImRect                      InnerRect;                  // InnerRect but without decoration. As with OuterRect, for non-scrolling tables, InnerRect.Max.y is
    ImRect                      WorkRect;
    ImRect                      InnerClipRect;
    ImRect                      BgClipRect;                 // We use this to cpu-clip cell background color fill, evolve during the frame as we cross frozen rows boundaries
    ImRect                      Bg0ClipRectForDrawCmd;      // Actual ImDrawCmd clip rect for BG0/1 channel. This tends to be == OuterWindow->ClipRect at BeginTable() because output in BG0/BG1 is cpu-clipped
    ImRect                      Bg2ClipRectForDrawCmd;      // Actual ImDrawCmd clip rect for BG2 channel. This tends to be a correct, tight-fit, because output to BG2 are done by widgets relying on regular ClipRect.
    ImRect                      HostClipRect;               // This is used to check if we can eventually merge our columns draw calls into the current draw call of the current window.
    ImRect                      HostBackupInnerClipRect;    // Backup of InnerWindow->ClipRect during PushTableBackground()/PopTableBackground()
    ImGuiWindow*                OuterWindow;                // Parent window for the table
    ImGuiWindow*                InnerWindow;                // Window holding the table data (== OuterWindow or a child window)
    ImGuiTextBuffer             ColumnsNames;               // Contiguous buffer holding columns names
    ImDrawListSplitter*         DrawSplitter;               // Shortcut to TempData->DrawSplitter while in table. Isolate draw commands per columns to avoid switching clip rect constantly
    ImGuiTableInstanceData      InstanceDataFirst;
    ImVector!ImGuiTableInstanceData    InstanceDataExtra;  // FIXME-OPT: Using a small-vector pattern would be good.
    ImGuiTableColumnSortSpecs   SortSpecsSingle;
    ImVector!ImGuiTableColumnSortSpecs SortSpecsMulti;     // FIXME-OPT: Using a small-vector pattern would be good.
    ImGuiTableSortSpecs         SortSpecs;                  // Public facing sorts specs, this is what we return in TableGetSortSpecs()
    ImGuiTableColumnIdx         SortSpecsCount;
    ImGuiTableColumnIdx         ColumnsEnabledCount;        // Number of enabled columns (<= ColumnsCount)
    ImGuiTableColumnIdx         ColumnsEnabledFixedCount;   // Number of enabled columns (<= ColumnsCount)
    ImGuiTableColumnIdx         DeclColumnsCount;           // Count calls to TableSetupColumn()
    ImGuiTableColumnIdx         HoveredColumnBody;          // Index of column whose visible region is being hovered. Important: == ColumnsCount when hovering empty region after the right-most column!
    ImGuiTableColumnIdx         HoveredColumnBorder;        // Index of column whose right-border is being hovered (for resizing).
    ImGuiTableColumnIdx         AutoFitSingleColumn;        // Index of single column requesting auto-fit.
    ImGuiTableColumnIdx         ResizedColumn;              // Index of column being resized. Reset when InstanceCurrent==0.
    ImGuiTableColumnIdx         LastResizedColumn;          // Index of column being resized from previous frame.
    ImGuiTableColumnIdx         HeldHeaderColumn;           // Index of column header being held.
    ImGuiTableColumnIdx         ReorderColumn;              // Index of column being reordered. (not cleared)
    ImGuiTableColumnIdx         ReorderColumnDir;           // -1 or +1
    ImGuiTableColumnIdx         LeftMostEnabledColumn;      // Index of left-most non-hidden column.
    ImGuiTableColumnIdx         RightMostEnabledColumn;     // Index of right-most non-hidden column.
    ImGuiTableColumnIdx         LeftMostStretchedColumn;    // Index of left-most stretched column.
    ImGuiTableColumnIdx         RightMostStretchedColumn;   // Index of right-most stretched column.
    ImGuiTableColumnIdx         ContextPopupColumn;         // Column right-clicked on, of -1 if opening context menu from a neutral/empty spot
    ImGuiTableColumnIdx         FreezeRowsRequest;          // Requested frozen rows count
    ImGuiTableColumnIdx         FreezeRowsCount;            // Actual frozen row count (== FreezeRowsRequest, or == 0 when no scrolling offset)
    ImGuiTableColumnIdx         FreezeColumnsRequest;       // Requested frozen columns count
    ImGuiTableColumnIdx         FreezeColumnsCount;         // Actual frozen columns count (== FreezeColumnsRequest, or == 0 when no scrolling offset)
    ImGuiTableColumnIdx         RowCellDataCurrent;         // Index of current RowCellData[] entry in current row
    ImGuiTableDrawChannelIdx    DummyDrawChannel;           // Redirect non-visible columns here.
    ImGuiTableDrawChannelIdx    Bg2DrawChannelCurrent;      // For Selectable() and other widgets drawing across columns after the freezing line. Index within DrawSplitter.Channels[]
    ImGuiTableDrawChannelIdx    Bg2DrawChannelUnfrozen;
    bool                        IsLayoutLocked;             // Set by TableUpdateLayout() which is called when beginning the first row.
    bool                        IsInsideRow;                // Set when inside TableBeginRow()/TableEndRow().
    bool                        IsInitializing;
    bool                        IsSortSpecsDirty;
    bool                        IsUsingHeaders;             // Set when the first row had the ImGuiTableRowFlags_Headers flag.
    bool                        IsContextPopupOpen;         // Set when default context menu is open (also see: ContextPopupColumn, InstanceInteracted).
    bool                        IsSettingsRequestLoad;
    bool                        IsSettingsDirty;            // Set when table settings have changed and needs to be reported into ImGuiTableSetttings data.
    bool                        IsDefaultDisplayOrder;      // Set when display order is unchanged from default (DisplayOrder contains 0...Count-1)
    bool                        IsResetAllRequest;
    bool                        IsResetDisplayOrderRequest;
    bool                        IsUnfrozenRows;             // Set when we got past the frozen row.
    bool                        IsDefaultSizingPolicy;      // Set if user didn't explicitly set a sizing policy in BeginTable()
    bool                        HasScrollbarYCurr;          // Whether ANY instance of this table had a vertical scrollbar during the current frame.
    bool                        HasScrollbarYPrev;          // Whether ANY instance of this table had a vertical scrollbar during the previous.
    bool                        MemoryCompacted;
    bool                        HostSkipItems;              // Backup of InnerWindow->SkipItem at the end of BeginTable(), because we will overwrite InnerWindow->SkipItem on a per-column basis

    @disable this();
    this(bool dummy)                { memset(&this, 0, sizeof(this)); LastFrameActive = -1; }
    void destroy()               { IM_FREE(RawData); SortSpecsMulti.destroy(); InstanceDataExtra.destroy(); ColumnsNames.destroy(); }
}

// Transient data that are only needed between BeginTable() and EndTable(), those buffers are shared (1 per level of stacked table).
// - Accessing those requires chasing an extra pointer so for very frequently used data we leave them in the main table structure.
// - We also leave out of this structure data that tend to be particularly useful for debugging/metrics.
// sizeof() ~ 112 bytes.
struct ImGuiTableTempData
{
    nothrow:
    @nogc:

    int                         TableIndex;                 // Index in g.Tables.Buf[] pool
    float                       LastTimeActive;             // Last timestamp this structure was used

    ImVec2                      UserOuterSize;              // outer_size.x passed to BeginTable()
    ImDrawListSplitter          DrawSplitter;

    ImRect                      HostBackupWorkRect;         // Backup of InnerWindow->WorkRect at the end of BeginTable()
    ImRect                      HostBackupParentWorkRect;   // Backup of InnerWindow->ParentWorkRect at the end of BeginTable()
    ImVec2                      HostBackupPrevLineSize;     // Backup of InnerWindow->DC.PrevLineSize at the end of BeginTable()
    ImVec2                      HostBackupCurrLineSize;     // Backup of InnerWindow->DC.CurrLineSize at the end of BeginTable()
    ImVec2                      HostBackupCursorMaxPos;     // Backup of InnerWindow->DC.CursorMaxPos at the end of BeginTable()
    ImVec1                      HostBackupColumnsOffset;    // Backup of OuterWindow->DC.ColumnsOffset at the end of BeginTable()
    float                       HostBackupItemWidth;        // Backup of OuterWindow->DC.ItemWidth at the end of BeginTable()
    int                         HostBackupItemWidthStackSize;//Backup of OuterWindow->DC.ItemWidthStack.Size at the end of BeginTable()

    @disable this();
    this(bool dummy)        { memset(&this, 0, sizeof(this)); LastTimeActive = -1.0f; }
    void destroy() {DrawSplitter.destroy();}
}

// sizeof() ~ 12
struct ImGuiTableColumnSettings
{
    nothrow:
    @nogc:

    float                   WidthOrWeight;
    ImGuiID                 UserID;
    ImGuiTableColumnIdx     Index;
    ImGuiTableColumnIdx     DisplayOrder;
    ImGuiTableColumnIdx     SortOrder;
    ImU8                    SortDirection/* : 2*/;
    ImU8                    IsEnabled/* : 1*/; // "Visible" in ini file
    ImU8                    IsStretch/* : 1*/;

    @disable this();
    this(bool dummy)
    {
        WidthOrWeight = 0.0f;
        UserID = 0;
        Index = -1;
        DisplayOrder = SortOrder = -1;
        SortDirection = ImGuiSortDirection.None;
        IsEnabled = 1;
        IsStretch = 0;
    }
}

// This is designed to be stored in a single ImChunkStream (1 header followed by N ImGuiTableColumnSettings, etc.)
struct ImGuiTableSettings
{
    nothrow:
    @nogc:

    ImGuiID                     ID;                     // Set to 0 to invalidate/delete the setting
    ImGuiTableFlags             SaveFlags;              // Indicate data we want to save using the Resizable/Reorderable/Sortable/Hideable flags (could be using its own flags..)
    float                       RefScale;               // Reference scale to be able to rescale columns on font/dpi changes.
    ImGuiTableColumnIdx         ColumnsCount;
    ImGuiTableColumnIdx         ColumnsCountMax;        // Maximum number of columns this settings instance can store, we can recycle a settings instance with lower number of columns but not higher
    bool                        WantApply;              // Set when loaded from .ini data (to enable merging/loading .ini data into an already running context)

    @disable this();
    this(bool dummy)        { memset(&this, 0, sizeof(this)); }
    ImGuiTableColumnSettings*   GetColumnSettings() return     { return cast(ImGuiTableColumnSettings*)(&this + 1); }
}

//-----------------------------------------------------------------------------
// [SECTION] ImGui internal API
// No guarantee of forward compatibility here!
//-----------------------------------------------------------------------------

// namespace ImGui
// {
    // Windows
    // We should always have a CurrentWindow in the stack (there is an implicit "Debug" window)
    // If this ever crash because g.CurrentWindow is NULL it means that either
    // - ImGui::NewFrame() has never been called, which is illegal.
    // - You are calling ImGui functions after ImGui::EndFrame()/ImGui::Render() and before the next ImGui::NewFrame(), which is also illegal.
    pragma(inline, true)    ImGuiWindow*  GetCurrentWindowRead()      { ImGuiContext* g = GImGui; return g.CurrentWindow; }
    pragma(inline, true)    ImGuiWindow*  GetCurrentWindow()          { ImGuiContext* g = GImGui; g.CurrentWindow.WriteAccessed = true; return g.CurrentWindow; }

    /+
    ImGuiWindow*  FindWindowByID(ImGuiID id);
    ImGuiWindow*  FindWindowByName(string name);
    void          UpdateWindowParentAndRootLinks(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
    ImVec2        CalcWindowNextAutoFitSize(ImGuiWindow* window);
    bool          IsWindowChildOf(ImGuiWindow* window, ImGuiWindow* potential_parent, bool popup_hierarchy);
    bool          IsWindowWithinBeginStackOf(ImGuiWindow* window, ImGuiWindow* potential_parent);
    bool          IsWindowAbove(ImGuiWindow* potential_above, ImGuiWindow* potential_below);
    bool          IsWindowNavFocusable(ImGuiWindow* window);
    void          SetWindowPos(ImGuiWindow* window, const ImVec2/*&*/ pos, ImGuiCond cond = 0);
    void          SetWindowSize(ImGuiWindow* window, const ImVec2/*&*/ size, ImGuiCond cond = 0);
    void          SetWindowCollapsed(ImGuiWindow* window, bool collapsed, ImGuiCond cond = 0);
    void          SetWindowHitTestHole(ImGuiWindow* window, const ImVec2/*&*/ pos, const ImVec2/*&*/ size);
    void          SetWindowHiddendAndSkipItemsForCurrentFrame(ImGuiWindow* window);
    +/
    pragma(inline, true) ImRect           WindowRectAbsToRel(ImGuiWindow* window, const ImRect/*&*/ r) { ImVec2 off = window.DC.CursorStartPos; return ImRect(r.Min.x - off.x, r.Min.y - off.y, r.Max.x - off.x, r.Max.y - off.y); }
    pragma(inline, true) ImRect           WindowRectRelToAbs(ImGuiWindow* window, const ImRect/*&*/ r) { ImVec2 off = window.DC.CursorStartPos; return ImRect(r.Min.x + off.x, r.Min.y + off.y, r.Max.x + off.x, r.Max.y + off.y); }
    pragma(inline, true) ImVec2           WindowPosRelToAbs(ImGuiWindow* window, const ImVec2/*&*/ p)  { ImVec2 off = window.DC.CursorStartPos; return ImVec2(p.x + off.x, p.y + off.y); }

    /+
    // Windows: Display Order and Focus Order
    void          FocusWindow(ImGuiWindow* window, ImGuiFocusRequestFlags flags = 0);
    void          FocusTopMostWindowUnderOne(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window, ImGuiViewport* filter_viewport, ImGuiFocusRequestFlags flags);
    void          BringWindowToFocusFront(ImGuiWindow* window);
    void          BringWindowToDisplayFront(ImGuiWindow* window);
    void          BringWindowToDisplayBack(ImGuiWindow* window);
    void          BringWindowToDisplayBehind(ImGuiWindow* window, ImGuiWindow* above_window);
    int           FindWindowDisplayIndex(ImGuiWindow* window);
    ImGuiWindow*  FindBottomMostVisibleWindowWithinBeginStack(ImGuiWindow* window);

    // Fonts, drawing
    void          SetCurrentFont(ImFont* font);
    +/
    
    pragma(inline, true) ImFont*          GetDefaultFont() { ImGuiContext* g = GImGui; return g.IO.FontDefault ? g.IO.FontDefault : g.IO.Fonts.Fonts[0]; }
    // D_IMGUI: D can't handle overloading between modules, so this is now GetForegroundDrawList2 instead of GetForegroundDrawList
    pragma(inline, true) ImDrawList*      GetForegroundDrawList2(ImGuiWindow* window) { IM_UNUSED(window); return GetForegroundDrawList(); } // This seemingly unnecessary wrapper simplifies compatibility between the 'master' and 'docking' branches.

    /+
    ImDrawList*   GetBackgroundDrawList(ImGuiViewport* viewport);                     // get background draw list for the given viewport. this draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
    ImDrawList*   GetForegroundDrawList(ImGuiViewport* viewport);                     // get foreground draw list for the given viewport. this draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.

    // Init
    void          Initialize();
    void          Shutdown();    // Since 1.60 this is a _private_ function. You can call DestroyContext() to destroy the context created by CreateContext().

    // NewFrame
    void          UpdateInputEvents(bool trickle_fast_inputs);
    void          UpdateHoveredWindowAndCaptureFlags();
    void          StartMouseMovingWindow(ImGuiWindow* window);
    void          UpdateMouseMovingWindowNewFrame();
    void          UpdateMouseMovingWindowEndFrame();

    // Generic context hooks
    ImGuiID       AddContextHook(ImGuiContext* context, const ImGuiContextHook* hook);
    void          RemoveContextHook(ImGuiContext* context, ImGuiID hook_to_remove);
    void          CallContextHooks(ImGuiContext* context, ImGuiContextHookType type);

    // Viewports
    void          SetWindowViewport(ImGuiWindow* window, ImGuiViewportP* viewport);

    // Settings
    void                  MarkIniSettingsDirty();
    void                  MarkIniSettingsDirty(ImGuiWindow* window);
    void                  ClearIniSettings();
    void                  AddSettingsHandler(const ImGuiSettingsHandler* handler);
    void                  RemoveSettingsHandler(string type_name);
    ImGuiSettingsHandler* FindSettingsHandler(string type_name);

    // Settings - Windows
    ImGuiWindowSettings*  CreateNewWindowSettings(string name);
    ImGuiWindowSettings*  FindWindowSettingsByID(ImGuiID id);
    ImGuiWindowSettings*  FindWindowSettingsByWindow(ImGuiWindow* window);
    void                  ClearWindowSettings(string name);

    // Localization
    void          LocalizeRegisterEntries(const ImGuiLocEntry* entries, int count);
    +/
    pragma(inline, true) string      LocalizeGetMsg(ImGuiLocKey key) { ImGuiContext* g = GImGui; string msg = g.LocalizationTable[key]; return msg ? msg : "*Missing Text*"; }
    /+

    // Scrolling
    void          SetScrollX(ImGuiWindow* window, float scroll_x);
    void          SetScrollY(ImGuiWindow* window, float scroll_y);
    void          SetScrollFromPosX(ImGuiWindow* window, float local_x, float center_x_ratio);
    void          SetScrollFromPosY(ImGuiWindow* window, float local_y, float center_y_ratio);

    // Early work-in-progress API (ScrollToItem() will become public)
    void          ScrollToItem(ImGuiScrollFlags flags = 0);
    void          ScrollToRect(ImGuiWindow* window, const ImRect/*&*/ rect, ImGuiScrollFlags flags = 0);
    ImVec2        ScrollToRectEx(ImGuiWindow* window, const ImRect/*&*/ rect, ImGuiScrollFlags flags = 0);
    +/
//#ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
    pragma(inline, true) void             ScrollToBringRectIntoView(ImGuiWindow* window, const ImRect/*&*/ rect) { ScrollToRect(window, rect, ImGuiScrollFlags.KeepVisibleEdgeY); }
//#endif

    // Basic Accessors
    pragma(inline, true) ImGuiItemStatusFlags GetItemStatusFlags(){ ImGuiContext* g = GImGui; return g.LastItemData.StatusFlags; }
    pragma(inline, true) ImGuiItemFlags   GetItemFlags()  { ImGuiContext* g = GImGui; return g.LastItemData.InFlags; }
    pragma(inline, true) ImGuiID          GetActiveID()   { ImGuiContext* g = GImGui; return g.ActiveId; }
    pragma(inline, true) ImGuiID          GetFocusID()    { ImGuiContext* g = GImGui; return g.NavId; }

    /+
    void          SetActiveID(ImGuiID id, ImGuiWindow* window);
    void          SetFocusID(ImGuiID id, ImGuiWindow* window);
    void          ClearActiveID();
    ImGuiID       GetHoveredID();
    void          SetHoveredID(ImGuiID id);
    void          KeepAliveID(ImGuiID id);
    void          MarkItemEdited(ImGuiID id);     // Mark data associated to given item as "edited", used by IsItemDeactivatedAfterEdit() function.
    void          PushOverrideID(ImGuiID id);     // Push given value as-is at the top of the ID stack (whereas PushID combines old and new hashes)
    ImGuiID       GetIDWithSeed(string str_id_begin, string str_id_end, ImGuiID seed);
    ImGuiID       GetIDWithSeed(int n, ImGuiID seed);

    // Basic Helpers for widget code
    void          ItemSize(const ImVec2/*&*/ size, float text_baseline_y = -1.0f);
    +/
    pragma(inline, true) void             ItemSize(const ImRect/*&*/ bb, float text_baseline_y = -1.0f) { d_imgui.imgui.ItemSize(bb.GetSize(), text_baseline_y); } // FIXME: This is a misleading API since we expect CursorPos to be bb.Min.
    /+
    bool          ItemAdd(const ImRect/*&*/ bb, ImGuiID id, const ImRect* nav_bb = NULL, ImGuiItemFlags extra_flags = 0);
    bool          ItemHoverable(const ImRect/*&*/ bb, ImGuiID id, ImGuiItemFlags item_flags);
    bool          IsWindowContentHoverable(ImGuiWindow* window, ImGuiHoveredFlags flags = 0);
    bool          IsClippedEx(const ImRect/*&*/ bb, ImGuiID id);
    void          SetLastItemData(ImGuiID item_id, ImGuiItemFlags in_flags, ImGuiItemStatusFlags status_flags, const ImRect/*&*/ item_rect);
    ImVec2        CalcItemSize(ImVec2 size, float default_w, float default_h);
    float         CalcWrapWidthForPos(const ImVec2/*&*/ pos, float wrap_pos_x);
    void          PushMultiItemsWidths(int components, float width_full);
    bool          IsItemToggledSelection();                                   // Was the last item selection toggled? (after Selectable(), TreeNode() etc. We only returns toggle _event_ in order to handle clipping correctly)
    ImVec2        GetContentRegionMaxAbs();
    void          ShrinkWidths(ImGuiShrinkWidthItem* items, int count, float width_excess);

    // Parameter stacks (shared)
    void          PushItemFlag(ImGuiItemFlags option, bool enabled);
    void          PopItemFlag();
    const ImGuiDataVarInfo* GetStyleVarInfo(ImGuiStyleVar idx);

    // Logging/Capture
    void          LogBegin(ImGuiLogType type, int auto_open_depth);           // -> BeginCapture() when we design v2 api, for now stay under the radar by using the old name.
    void          LogToBuffer(int auto_open_depth = -1);                      // Start logging/capturing to internal buffer
    void          LogRenderedText(const ImVec2* ref_pos, string text, string text_end = NULL);
    void          LogSetNextTextDecoration(string prefix, string suffix);

    // Popups, Modals, Tooltips
    bool          BeginChildEx(string name, ImGuiID id, const ImVec2/*&*/ size_arg, bool border, ImGuiWindowFlags flags);
    void          OpenPopupEx(ImGuiID id, ImGuiPopupFlags popup_flags = ImGuiPopupFlags.None);
    void          ClosePopupToLevel(int remaining, bool restore_focus_to_window_under_popup);
    void          ClosePopupsOverWindow(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
    void          ClosePopupsExceptModals();
    bool          IsPopupOpen(ImGuiID id, ImGuiPopupFlags popup_flags);
    bool          BeginPopupEx(ImGuiID id, ImGuiWindowFlags extra_flags);
    bool          BeginTooltipEx(ImGuiTooltipFlags tooltip_flags, ImGuiWindowFlags extra_window_flags);
    ImRect        GetPopupAllowedExtentRect(ImGuiWindow* window);
    ImGuiWindow*  GetTopMostPopupModal();
    ImGuiWindow*  GetTopMostAndVisiblePopupModal();
    ImGuiWindow*  FindBlockingModal(ImGuiWindow* window);
    ImVec2        FindBestWindowPosForPopup(ImGuiWindow* window);
    ImVec2        FindBestWindowPosForPopupEx(const ImVec2/*&*/ ref_pos, const ImVec2/*&*/ size, ImGuiDir* last_dir, const ImRect/*&*/ r_outer, const ImRect/*&*/ r_avoid, ImGuiPopupPositionPolicy policy);

    // Menus
    bool          BeginViewportSideBar(string name, ImGuiViewport* viewport, ImGuiDir dir, float size, ImGuiWindowFlags window_flags);
    bool          BeginMenuEx(string label, string icon, bool enabled = true);
    bool          MenuItemEx(string label, string icon, string shortcut = NULL, bool selected = false, bool enabled = true);

    // Combos
    bool          BeginComboPopup(ImGuiID popup_id, const ImRect/*&*/ bb, ImGuiComboFlags flags);
    bool          BeginComboPreview();
    void          EndComboPreview();

    // Gamepad/Keyboard Navigation
    void          NavInitWindow(ImGuiWindow* window, bool force_reinit);
    void          NavInitRequestApplyResult();
    bool          NavMoveRequestButNoResultYet();
    void          NavMoveRequestSubmit(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void          NavMoveRequestForward(ImGuiDir move_dir, ImGuiDir clip_dir, ImGuiNavMoveFlags move_flags, ImGuiScrollFlags scroll_flags);
    void          NavMoveRequestResolveWithLastItem(ImGuiNavItemData* result);
    void          NavMoveRequestCancel();
    void          NavMoveRequestApplyResult();
    void          NavMoveRequestTryWrapping(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
    void          NavClearPreferredPosForAxis(ImGuiAxis axis);
    void          NavUpdateCurrentWindowIsScrollPushableX();
    void          SetNavWindow(ImGuiWindow* window);
    void          SetNavID(ImGuiID id, ImGuiNavLayer nav_layer, ImGuiID focus_scope_id, const ImRect/*&*/ rect_rel);
    +/

    // Focus/Activation
    // This should be part of a larger set of API: FocusItem(offset = -1), FocusItemByID(id), ActivateItem(offset = -1), ActivateItemByID(id) etc. which are
    // much harder to design and implement than expected. I have a couple of private branches on this matter but it's not simple. For now implementing the easy ones.
    void          FocusItem();                    // Focus last item (no selection/activation).
    void          ActivateItemByID(ImGuiID id);   // Activate an item by ID (button, checkbox, tree node etc.). Activation is queued and processed on the next frame when the item is encountered again.

    // Inputs
    // FIXME: Eventually we should aim to move e.g. IsActiveIdUsingKey() into IsKeyXXX functions.
    pragma(inline, true) bool             IsNamedKey(ImGuiKey key)                                    { return key >= ImGuiKey.NamedKey_BEGIN && key < ImGuiKey.NamedKey_END; }
    pragma(inline, true) bool             IsNamedKeyOrModKey(ImGuiKey key)                            { return (key >= ImGuiKey.NamedKey_BEGIN && key < ImGuiKey.NamedKey_END) || key == ImGuiMod.Ctrl || key == ImGuiMod.Shift || key == ImGuiMod.Alt || key == ImGuiMod.Super || key == ImGuiMod.Shortcut; }
    pragma(inline, true) bool             IsLegacyKey(ImGuiKey key)                                   { return key >= ImGuiKey.LegacyNativeKey_BEGIN && key < ImGuiKey.LegacyNativeKey_END; }
    pragma(inline, true) bool             IsKeyboardKey(ImGuiKey key)                                 { return key >= ImGuiKey.Keyboard_BEGIN && key < ImGuiKey.Keyboard_END; }
    pragma(inline, true) bool             IsGamepadKey(ImGuiKey key)                                  { return key >= ImGuiKey.Gamepad_BEGIN && key < ImGuiKey.Gamepad_END; }
    pragma(inline, true) bool             IsMouseKey(ImGuiKey key)                                    { return key >= ImGuiKey.Mouse_BEGIN && key < ImGuiKey.Mouse_END; }
    pragma(inline, true) bool             IsAliasKey(ImGuiKey key)                                    { return key >= ImGuiKey.Aliases_BEGIN && key < ImGuiKey.Aliases_END; }
    pragma(inline, true) ImGuiKeyChord    ConvertShortcutMod(ImGuiKeyChord key_chord)                 { ImGuiContext* g = GImGui; IM_ASSERT_PARANOID(key_chord & ImGuiMod.Shortcut); return (key_chord & ~ImGuiMod.Shortcut) | (g.IO.ConfigMacOSXBehaviors ? ImGuiMod.Super : ImGuiMod.Ctrl); }
    pragma(inline, true) ImGuiKey         ConvertSingleModFlagToKey(ImGuiContext* ctx, ImGuiKey key)
    {
        ImGuiContext* g = ctx;
        if (key == ImGuiMod.Ctrl) return ImGuiKey.ReservedForModCtrl;
        if (key == ImGuiMod.Shift) return ImGuiKey.ReservedForModShift;
        if (key == ImGuiMod.Alt) return ImGuiKey.ReservedForModAlt;
        if (key == ImGuiMod.Super) return ImGuiKey.ReservedForModSuper;
        if (key == ImGuiMod.Shortcut) return (g.IO.ConfigMacOSXBehaviors ? ImGuiKey.ReservedForModSuper : ImGuiKey.ReservedForModCtrl);
        return key;
    }

    /+
    ImGuiKeyData* GetKeyData(ImGuiContext* ctx, ImGuiKey key);
    pragma(inline, true) ImGuiKeyData*    GetKeyData(ImGuiKey key)                                    { ImGuiContext* g = GImGui; return GetKeyData(g, key); }
    void          GetKeyChordName(ImGuiKeyChord key_chord, char* out_buf, int out_buf_size);
    +/
    pragma(inline, true) ImGuiKey         MouseButtonToKey(ImGuiMouseButton button)                   { IM_ASSERT(button >= 0 && button < ImGuiMouseButton.COUNT); return cast(ImGuiKey)(ImGuiKey.MouseLeft + button); }
    /+
    bool          IsMouseDragPastThreshold(ImGuiMouseButton button, float lock_threshold = -1.0f);
    ImVec2        GetKeyMagnitude2d(ImGuiKey key_left, ImGuiKey key_right, ImGuiKey key_up, ImGuiKey key_down);
    float         GetNavTweakPressedAmount(ImGuiAxis axis);
    int           CalcTypematicRepeatAmount(float t0, float t1, float repeat_delay, float repeat_rate);
    void          GetTypematicRepeatRate(ImGuiInputFlags flags, float* repeat_delay, float* repeat_rate);
    void          SetActiveIdUsingAllKeyboardKeys();
    +/
    pragma(inline, true) bool             IsActiveIdUsingNavDir(ImGuiDir dir)                         { ImGuiContext* g = GImGui; return (g.ActiveIdUsingNavDirMask & (1 << dir)) != 0; }

    /+
    // [EXPERIMENTAL] Low-Level: Key/Input Ownership
    // - The idea is that instead of "eating" a given input, we can link to an owner id.
    // - Ownership is most often claimed as a result of reacting to a press/down event (but occasionally may be claimed ahead).
    // - Input queries can then read input by specifying ImGuiKeyOwner_Any (== 0), ImGuiKeyOwner_None (== -1) or a custom ID.
    // - Legacy input queries (without specifying an owner or _Any or _None) are equivalent to using ImGuiKeyOwner_Any (== 0).
    // - Input ownership is automatically released on the frame after a key is released. Therefore:
    //   - for ownership registration happening as a result of a down/press event, the SetKeyOwner() call may be done once (common case).
    //   - for ownership registration happening ahead of a down/press event, the SetKeyOwner() call needs to be made every frame (happens if e.g. claiming ownership on hover).
    // - SetItemKeyOwner() is a shortcut for common simple case. A custom widget will probably want to call SetKeyOwner() multiple times directly based on its interaction state.
    // - This is marked experimental because not all widgets are fully honoring the Set/Test idioms. We will need to move forward step by step.
    //   Please open a GitHub Issue to submit your usage scenario or if there's a use case you need solved.
    ImGuiID           GetKeyOwner(ImGuiKey key);
    void              SetKeyOwner(ImGuiKey key, ImGuiID owner_id, ImGuiInputFlags flags = 0);
    void              SetKeyOwnersForKeyChord(ImGuiKeyChord key, ImGuiID owner_id, ImGuiInputFlags flags = 0);
    void              SetItemKeyOwner(ImGuiKey key, ImGuiInputFlags flags = 0);           // Set key owner to last item if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive()) { SetKeyOwner(key, GetItemID());'.
    bool              TestKeyOwner(ImGuiKey key, ImGuiID owner_id);                       // Test that key is either not owned, either owned by 'owner_id'
    +/
    pragma(inline, true) ImGuiKeyOwnerData*   GetKeyOwnerData(ImGuiContext* ctx, ImGuiKey key)                    { if (key & ImGuiMod.Mask_) key = ConvertSingleModFlagToKey(ctx, key); IM_ASSERT(IsNamedKey(key)); return &ctx.KeysOwnerData[key - ImGuiKey.NamedKey_BEGIN]; }
    /+

    // [EXPERIMENTAL] High-Level: Input Access functions w/ support for Key/Input Ownership
    // - Important: legacy IsKeyPressed(ImGuiKey, bool repeat=true) _DEFAULTS_ to repeat, new IsKeyPressed() requires _EXPLICIT_ ImGuiInputFlags_Repeat flag.
    // - Expected to be later promoted to public API, the prototypes are designed to replace existing ones (since owner_id can default to Any == 0)
    // - Specifying a value for 'ImGuiID owner' will test that EITHER the key is NOT owned (UNLESS locked), EITHER the key is owned by 'owner'.
    //   Legacy functions use ImGuiKeyOwner_Any meaning that they typically ignore ownership, unless a call to SetKeyOwner() explicitly used ImGuiInputFlags_LockThisFrame or ImGuiInputFlags_LockUntilRelease.
    // - Binding generators may want to ignore those for now, or suffix them with Ex() until we decide if this gets moved into public API.
    bool              IsKeyDown(ImGuiKey key, ImGuiID owner_id);
    bool              IsKeyPressed(ImGuiKey key, ImGuiID owner_id, ImGuiInputFlags flags = 0);    // Important: when transitioning from old to new IsKeyPressed(): old API has "bool repeat = true", so would default to repeat. New API requiress explicit ImGuiInputFlags_Repeat.
    bool              IsKeyReleased(ImGuiKey key, ImGuiID owner_id);
    bool              IsMouseDown(ImGuiMouseButton button, ImGuiID owner_id);
    bool              IsMouseClicked(ImGuiMouseButton button, ImGuiID owner_id, ImGuiInputFlags flags = 0);
    bool              IsMouseReleased(ImGuiMouseButton button, ImGuiID owner_id);

    // [EXPERIMENTAL] Shortcut Routing
    // - ImGuiKeyChord = a ImGuiKey optionally OR-red with ImGuiMod_Alt/ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Super.
    //     ImGuiKey_C                 (accepted by functions taking ImGuiKey or ImGuiKeyChord)
    //     ImGuiKey_C | ImGuiMod_Ctrl (accepted by functions taking ImGuiKeyChord)
    //   ONLY ImGuiMod_XXX values are legal to 'OR' with an ImGuiKey. You CANNOT 'OR' two ImGuiKey values.
    // - When using one of the routing flags (e.g. ImGuiInputFlags_RouteFocused): routes requested ahead of time given a chord (key + modifiers) and a routing policy.
    // - Routes are resolved during NewFrame(): if keyboard modifiers are matching current ones: SetKeyOwner() is called + route is granted for the frame.
    // - Route is granted to a single owner. When multiple requests are made we have policies to select the winning route.
    // - Multiple read sites may use the same owner id and will all get the granted route.
    // - For routing: when owner_id is 0 we use the current Focus Scope ID as a default owner in order to identify our location.
    bool              Shortcut(ImGuiKeyChord key_chord, ImGuiID owner_id = 0, ImGuiInputFlags flags = 0);
    bool              SetShortcutRouting(ImGuiKeyChord key_chord, ImGuiID owner_id = 0, ImGuiInputFlags flags = 0);
    bool              TestShortcutRouting(ImGuiKeyChord key_chord, ImGuiID owner_id);
    ImGuiKeyRoutingData* GetShortcutRoutingData(ImGuiKeyChord key_chord);

    // [EXPERIMENTAL] Focus Scope
    // This is generally used to identify a unique input location (for e.g. a selection set)
    // There is one per window (automatically set in Begin), but:
    // - Selection patterns generally need to react (e.g. clear a selection) when landing on one item of the set.
    //   So in order to identify a set multiple lists in same window may each need a focus scope.
    //   If you imagine an hypothetical BeginSelectionGroup()/EndSelectionGroup() api, it would likely call PushFocusScope()/EndFocusScope()
    // - Shortcut routing also use focus scope as a default location identifier if an owner is not provided.
    // We don't use the ID Stack for this as it is common to want them separate.
    void          PushFocusScope(ImGuiID id);
    void          PopFocusScope();
    +/
    pragma(inline, true) ImGuiID          GetCurrentFocusScope() { ImGuiContext* g = GImGui; return g.CurrentFocusScopeId; }   // Focus scope we are outputting into, set by PushFocusScope()
    /+

    // Drag and Drop
    bool          IsDragDropActive();
    bool          BeginDragDropTargetCustom(const ImRect/*&*/ bb, ImGuiID id);
    void          ClearDragDrop();
    bool          IsDragDropPayloadBeingAccepted();
    void          RenderDragDropTargetRect(const ImRect/*&*/ bb);

    // Internal Columns API (this is not exposed because we will encourage transitioning to the Tables API)
    void          SetWindowClipRectBeforeSetChannel(ImGuiWindow* window, const ImRect/*&*/ clip_rect);
    void          BeginColumns(string str_id, int count, ImGuiOldColumnFlags flags = 0); // setup number of columns. use an identifier to distinguish multiple column sets. close with EndColumns().
    void          EndColumns();                                                               // close columns
    void          PushColumnClipRect(int column_index);
    void          PushColumnsBackground();
    void          PopColumnsBackground();
    ImGuiID       GetColumnsID(string str_id, int count);
    ImGuiOldColumns* FindOrCreateColumns(ImGuiWindow* window, ImGuiID id);
    float         GetColumnOffsetFromNorm(const ImGuiOldColumns* columns, float offset_norm);
    float         GetColumnNormFromOffset(const ImGuiOldColumns* columns, float offset);

    // Tables: Candidates for public API
    void          TableOpenContextMenu(int column_n = -1);
    void          TableSetColumnWidth(int column_n, float width);
    void          TableSetColumnSortDirection(int column_n, ImGuiSortDirection sort_direction, bool append_to_sort_specs);
    int           TableGetHoveredColumn(); // May use (TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered) instead. Return hovered column. return -1 when table is not hovered. return columns_count if the unused space at the right of visible columns is hovered.
    float         TableGetHeaderRowHeight();
    void          TablePushBackgroundChannel();
    void          TablePopBackgroundChannel();

    // Tables: Internals
    +/
    pragma(inline, true)    ImGuiTable*   GetCurrentTable() { ImGuiContext* g = GImGui; return g.CurrentTable; }
    /+
    ImGuiTable*   TableFindByID(ImGuiID id);
    bool          BeginTableEx(string name, ImGuiID id, int columns_count, ImGuiTableFlags flags = 0, const ImVec2/*&*/ outer_size = ImVec2(0, 0), float inner_width = 0.0f);
    void          TableBeginInitMemory(ImGuiTable* table, int columns_count);
    void          TableBeginApplyRequests(ImGuiTable* table);
    void          TableSetupDrawChannels(ImGuiTable* table);
    void          TableUpdateLayout(ImGuiTable* table);
    void          TableUpdateBorders(ImGuiTable* table);
    void          TableUpdateColumnsWeightFromWidth(ImGuiTable* table);
    void          TableDrawBorders(ImGuiTable* table);
    void          TableDrawContextMenu(ImGuiTable* table);
    bool          TableBeginContextMenuPopup(ImGuiTable* table);
    void          TableMergeDrawChannels(ImGuiTable* table);
    +/
    pragma(inline, true) ImGuiTableInstanceData*  TableGetInstanceData(ImGuiTable* table, int instance_no) { if (instance_no == 0) return &table.InstanceDataFirst; return &table.InstanceDataExtra[instance_no - 1]; }
    pragma(inline, true) ImGuiID                  TableGetInstanceID(ImGuiTable* table, int instance_no)   { return TableGetInstanceData(table, instance_no).TableInstanceID; }
    /+
    void          TableSortSpecsSanitize(ImGuiTable* table);
    void          TableSortSpecsBuild(ImGuiTable* table);
    ImGuiSortDirection TableGetColumnNextSortDirection(ImGuiTableColumn* column);
    void          TableFixColumnSortDirection(ImGuiTable* table, ImGuiTableColumn* column);
    float         TableGetColumnWidthAuto(ImGuiTable* table, ImGuiTableColumn* column);
    void          TableBeginRow(ImGuiTable* table);
    void          TableEndRow(ImGuiTable* table);
    void          TableBeginCell(ImGuiTable* table, int column_n);
    void          TableEndCell(ImGuiTable* table);
    ImRect        TableGetCellBgRect(const ImGuiTable* table, int column_n);
    string   TableGetColumnName(const ImGuiTable* table, int column_n);
    ImGuiID       TableGetColumnResizeID(ImGuiTable* table, int column_n, int instance_no = 0);
    float         TableGetMaxColumnWidth(const ImGuiTable* table, int column_n);
    void          TableSetColumnWidthAutoSingle(ImGuiTable* table, int column_n);
    void          TableSetColumnWidthAutoAll(ImGuiTable* table);
    void          TableRemove(ImGuiTable* table);
    void          TableGcCompactTransientBuffers(ImGuiTable* table);
    void          TableGcCompactTransientBuffers(ImGuiTableTempData* table);
    void          TableGcCompactSettings();

    // Tables: Settings
    void                  TableLoadSettings(ImGuiTable* table);
    void                  TableSaveSettings(ImGuiTable* table);
    void                  TableResetSettings(ImGuiTable* table);
    ImGuiTableSettings*   TableGetBoundSettings(ImGuiTable* table);
    void                  TableSettingsAddSettingsHandler();
    ImGuiTableSettings*   TableSettingsCreate(ImGuiID id, int columns_count);
    ImGuiTableSettings*   TableSettingsFindByID(ImGuiID id);

    // Tab Bars
    +/
    pragma(inline, true)    ImGuiTabBar*  GetCurrentTabBar() { ImGuiContext* g = GImGui; return g.CurrentTabBar; }
    /+
    bool          BeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect/*&*/ bb, ImGuiTabBarFlags flags);
    ImGuiTabItem* TabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    ImGuiTabItem* TabBarFindTabByOrder(ImGuiTabBar* tab_bar, int order);
    ImGuiTabItem* TabBarGetCurrentTab(ImGuiTabBar* tab_bar);
    +/
    pragma(inline, true) int              TabBarGetTabOrder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab) { return tab_bar.Tabs.index_from_ptr(tab); }
    /+
    string   TabBarGetTabName(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    void          TabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarQueueFocus(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    void          TabBarQueueReorder(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, int offset);
    void          TabBarQueueReorderFromMousePos(ImGuiTabBar* tab_bar, ImGuiTabItem* tab, ImVec2 mouse_pos);
    bool          TabBarProcessReorder(ImGuiTabBar* tab_bar);
    bool          TabItemEx(ImGuiTabBar* tab_bar, string label, bool* p_open, ImGuiTabItemFlags flags, ImGuiWindow* docked_window);
    ImVec2        TabItemCalcSize(string label, bool has_close_button_or_unsaved_marker);
    ImVec2        TabItemCalcSize(ImGuiWindow* window);
    void          TabItemBackground(ImDrawList* draw_list, const ImRect/*&*/ bb, ImGuiTabItemFlags flags, ImU32 col);
    void          TabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect/*&*/ bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, string label, ImGuiID tab_id, ImGuiID close_button_id, bool is_contents_visible, bool* out_just_closed, bool* out_text_clipped);

    // Render helpers
    // AVOID USING OUTSIDE OF IMGUI.CPP! NOT FOR PUBLIC CONSUMPTION. THOSE FUNCTIONS ARE A MESS. THEIR SIGNATURE AND BEHAVIOR WILL CHANGE, THEY NEED TO BE REFACTORED INTO SOMETHING DECENT.
    // NB: All position are in absolute pixels coordinates (we are never using window coordinates internally)
    void          RenderText(ImVec2 pos, string text, string text_end = NULL, bool hide_text_after_hash = true);
    void          RenderTextWrapped(ImVec2 pos, string text, string text_end, float wrap_width);
    void          RenderTextClipped(const ImVec2/*&*/ pos_min, const ImVec2/*&*/ pos_max, string text, string text_end, const ImVec2* text_size_if_known, const ImVec2/*&*/ align = ImVec2(0, 0), const ImRect* clip_rect = NULL);
    void          RenderTextClippedEx(ImDrawList* draw_list, const ImVec2/*&*/ pos_min, const ImVec2/*&*/ pos_max, string text, string text_end, const ImVec2* text_size_if_known, const ImVec2/*&*/ align = ImVec2(0, 0), const ImRect* clip_rect = NULL);
    void          RenderTextEllipsis(ImDrawList* draw_list, const ImVec2/*&*/ pos_min, const ImVec2/*&*/ pos_max, float clip_max_x, float ellipsis_max_x, string text, string text_end, const ImVec2* text_size_if_known);
    void          RenderFrame(ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, bool border = true, float rounding = 0.0f);
    void          RenderFrameBorder(ImVec2 p_min, ImVec2 p_max, float rounding = 0.0f);
    void          RenderColorRectWithAlphaCheckerboard(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, float grid_step, ImVec2 grid_off, float rounding = 0.0f, ImDrawFlags flags = 0);
    void          RenderNavHighlight(const ImRect/*&*/ bb, ImGuiID id, ImGuiNavHighlightFlags flags = ImGuiNavHighlightFlags.TypeDefault); // Navigation highlight
    string   FindRenderedTextEnd(string text, string text_end = NULL); // Find the optional ## from which we stop displaying text.
    void          RenderMouseCursor(ImVec2 pos, float scale, ImGuiMouseCursor mouse_cursor, ImU32 col_fill, ImU32 col_border, ImU32 col_shadow);

    // Render helpers (those functions don't access any ImGui state!)
    void          RenderArrow(ImDrawList* draw_list, ImVec2 pos, ImU32 col, ImGuiDir dir, float scale = 1.0f);
    void          RenderBullet(ImDrawList* draw_list, ImVec2 pos, ImU32 col);
    void          RenderCheckMark(ImDrawList* draw_list, ImVec2 pos, ImU32 col, float sz);
    void          RenderArrowPointingAt(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, ImU32 col);
    void          RenderRectFilledRangeH(ImDrawList* draw_list, const ImRect/*&*/ rect, ImU32 col, float x_start_norm, float x_end_norm, float rounding);
    void          RenderRectFilledWithHole(ImDrawList* draw_list, const ImRect/*&*/ outer, const ImRect/*&*/ inner, ImU32 col, float rounding);
    +/

    /+
    // Widgets
    void          TextEx(string text, string text_end = NULL, ImGuiTextFlags flags = 0);
    bool          ButtonEx(string label, const ImVec2/*&*/ size_arg = ImVec2(0, 0), ImGuiButtonFlags flags = 0);
    bool          ArrowButtonEx(string str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags = 0);
    bool          ImageButtonEx(ImGuiID id, ImTextureID texture_id, const ImVec2/*&*/ size, const ImVec2/*&*/ uv0, const ImVec2/*&*/ uv1, const ImVec4/*&*/ bg_col, const ImVec4/*&*/ tint_col, ImGuiButtonFlags flags = 0);
    void          SeparatorEx(ImGuiSeparatorFlags flags, float thickness = 1.0f);
    void          SeparatorTextEx(ImGuiID id, string label, string label_end, float extra_width);
    bool          CheckboxFlags(string label, ImS64* flags, ImS64 flags_value);
    bool          CheckboxFlags(string label, ImU64* flags, ImU64 flags_value);

    // Widgets: Window Decorations
    bool          CloseButton(ImGuiID id, const ImVec2/*&*/ pos);
    bool          CollapseButton(ImGuiID id, const ImVec2/*&*/ pos);
    void          Scrollbar(ImGuiAxis axis);
    bool          ScrollbarEx(const ImRect/*&*/ bb, ImGuiID id, ImGuiAxis axis, ImS64* p_scroll_v, ImS64 avail_v, ImS64 contents_v, ImDrawFlags flags);
    ImRect        GetWindowScrollbarRect(ImGuiWindow* window, ImGuiAxis axis);
    ImGuiID       GetWindowScrollbarID(ImGuiWindow* window, ImGuiAxis axis);
    ImGuiID       GetWindowResizeCornerID(ImGuiWindow* window, int n); // 0..3: corners
    ImGuiID       GetWindowResizeBorderID(ImGuiWindow* window, ImGuiDir dir);

    // Widgets low-level behaviors
    bool          ButtonBehavior(const ImRect/*&*/ bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags = 0);
    bool          DragBehavior(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, string format, ImGuiSliderFlags flags);
    bool          SliderBehavior(const ImRect/*&*/ bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, string format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    bool          SplitterBehavior(const ImRect/*&*/ bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend = 0.0f, float hover_visibility_delay = 0.0f, ImU32 bg_col = 0);
    bool          TreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, string label, string label_end = NULL);
    void          TreePushOverrideID(ImGuiID id);
    void          TreeNodeSetOpen(ImGuiID id, bool open);
    bool          TreeNodeUpdateNextOpen(ImGuiID id, ImGuiTreeNodeFlags flags);   // Return open state. Consume previous SetNextItemOpen() data, if any. May return true when logging.

    // Template functions are instantiated in imgui_widgets.cpp for a finite number of types.
    // To use them externally (for custom widget) you may need an "extern template" statement in your code in order to link to existing instances and silence Clang warnings (see #2036).
    // e.g. " extern template IMGUI_API float RoundScalarWithFormatT<float, float>(const char* format, ImGuiDataType data_type, float v); "
    template<typename T, typename SIGNED_T, typename FLOAT_T>   float ScaleRatioFromValueT(ImGuiDataType data_type, T v, T v_min, T v_max, bool is_logarithmic, float logarithmic_zero_epsilon, float zero_deadzone_size);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   T     ScaleValueFromRatioT(ImGuiDataType data_type, float t, T v_min, T v_max, bool is_logarithmic, float logarithmic_zero_epsilon, float zero_deadzone_size);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   bool  DragBehaviorT(ImGuiDataType data_type, T* v, float v_speed, T v_min, T v_max, string format, ImGuiSliderFlags flags);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   bool  SliderBehaviorT(const ImRect/*&*/ bb, ImGuiID id, ImGuiDataType data_type, T* v, T v_min, T v_max, string format, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    template<typename T>                                        T     RoundScalarWithFormatT(string format, ImGuiDataType data_type, T v);
    template<typename T>                                        bool  CheckboxFlagsT(string label, T* flags, T flags_value);

    // Data type helpers
    const ImGuiDataTypeInfo*  DataTypeGetInfo(ImGuiDataType data_type);
    int           DataTypeFormatString(char* buf, int buf_size, ImGuiDataType data_type, const void* p_data, string format);
    void          DataTypeApplyOp(ImGuiDataType data_type, int op, void* output, const void* arg_1, const void* arg_2);
    bool          DataTypeApplyFromText(string buf, ImGuiDataType data_type, void* p_data, string format);
    int           DataTypeCompare(ImGuiDataType data_type, const void* arg_1, const void* arg_2);
    bool          DataTypeClamp(ImGuiDataType data_type, void* p_data, const void* p_min, const void* p_max);

    // InputText
    bool          InputTextEx(string label, string hint, char* buf, int buf_size, const ImVec2/*&*/ size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    void          InputTextDeactivateHook(ImGuiID id);
    bool          TempInputText(const ImRect/*&*/ bb, ImGuiID id, string label, char* buf, int buf_size, ImGuiInputTextFlags flags);
    bool          TempInputScalar(const ImRect/*&*/ bb, ImGuiID id, string label, ImGuiDataType data_type, void* p_data, string format, const void* p_clamp_min = NULL, const void* p_clamp_max = NULL);
    +/
    pragma(inline, true) bool             TempInputIsActive(ImGuiID id)       { ImGuiContext* g = GImGui; return (g.ActiveId == id && g.TempInputId == id); }
    pragma(inline, true) ImGuiInputTextState* GetInputTextState(ImGuiID id)   { ImGuiContext* g = GImGui; return (id != 0 && g.InputTextState.ID == id) ? &g.InputTextState : NULL; } // Get input text state if active

    /+
    // Color
    void          ColorTooltip(string text, const float* col, ImGuiColorEditFlags flags);
    void          ColorEditOptionsPopup(const float* col, ImGuiColorEditFlags flags);
    void          ColorPickerOptionsPopup(const float* ref_col, ImGuiColorEditFlags flags);

    // Plot
    int           PlotEx(ImGuiPlotType plot_type, string label, float (*values_getter)(void* data, int idx), void* data, int values_count, int values_offset, string overlay_text, float scale_min, float scale_max, const ImVec2/*&*/ size_arg);

    // Shade functions (write over already created vertices)
    void          ShadeVertsLinearColorGradientKeepAlpha(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, ImU32 col0, ImU32 col1);
    void          ShadeVertsLinearUV(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ uv_a, const ImVec2/*&*/ uv_b, bool clamp);

    // Garbage collection
    void          GcCompactTransientMiscBuffers();
    void          GcCompactTransientWindowBuffers(ImGuiWindow* window);
    void          GcAwakeTransientWindowBuffers(ImGuiWindow* window);

    // Debug Log
    void          DebugLog(string fmt, ...) IM_FMTARGS(1);
    void          DebugLogV(string fmt, va_list args) IM_FMTLIST(1);

    // Debug Tools
    void          ErrorCheckEndFrameRecover(ImGuiErrorLogCallback log_callback, void* user_data = NULL);
    void          ErrorCheckEndWindowRecover(ImGuiErrorLogCallback log_callback, void* user_data = NULL);
    void          ErrorCheckUsingSetCursorPosToExtendParentBoundaries();
    void          DebugLocateItem(ImGuiID target_id);                     // Call sparingly: only 1 at the same time!
    void          DebugLocateItemOnHover(ImGuiID target_id);              // Only call on reaction to a mouse Hover: because only 1 at the same time!
    void          DebugLocateItemResolveWithLastItem();
    +/
    pragma(inline, true) void             DebugDrawItemRect(ImU32 col = IM_COL32(255,0,0,255))    { ImGuiContext* g = GImGui; ImGuiWindow* window = g.CurrentWindow; GetForegroundDrawList2(window).AddRect(g.LastItemData.Rect.Min, g.LastItemData.Rect.Max, col); }
    pragma(inline, true) void             DebugStartItemPicker()                                  { ImGuiContext* g = GImGui; g.DebugItemPickerActive = true; }
    /+
    void          ShowFontAtlas(ImFontAtlas* atlas);
    void          DebugHookIdInfo(ImGuiID id, ImGuiDataType data_type, const void* data_id, const void* data_id_end);
    void          DebugNodeColumns(ImGuiOldColumns* columns);
    void          DebugNodeDrawList(ImGuiWindow* window, const ImDrawList* draw_list, string label);
    void          DebugNodeDrawCmdShowMeshAndBoundingBox(ImDrawList* out_draw_list, const ImDrawList* draw_list, const ImDrawCmd* draw_cmd, bool show_mesh, bool show_aabb);
    void          DebugNodeFont(ImFont* font);
    void          DebugNodeFontGlyph(ImFont* font, const ImFontGlyph* glyph);
    void          DebugNodeStorage(ImGuiStorage* storage, string label);
    void          DebugNodeTabBar(ImGuiTabBar* tab_bar, string label);
    void          DebugNodeTable(ImGuiTable* table);
    void          DebugNodeTableSettings(ImGuiTableSettings* settings);
    void          DebugNodeInputTextState(ImGuiInputTextState* state);
    void          DebugNodeWindow(ImGuiWindow* window, string label);
    void          DebugNodeWindowSettings(ImGuiWindowSettings* settings);
    void          DebugNodeWindowsList(ImVector!(ImGuiWindow*)* windows, string label);
    void          DebugNodeWindowsListByBeginStackParent(ImGuiWindow** windows, int windows_size, ImGuiWindow* parent_in_begin_stack);
    void          DebugNodeViewport(ImGuiViewportP* viewport);
    void          DebugRenderKeyboardPreview(ImDrawList* draw_list);
    void          DebugRenderViewportThumbnail(ImDrawList* draw_list, ImGuiViewportP* viewport, const ImRect/*&*/ bb);
    +/

    // Obsolete functions
static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
    pragma(inline, true) void     SetItemUsingMouseWheel()                                            { SetItemKeyOwner(ImGuiKey.MouseWheelY); }      // Changed in 1.89
    pragma(inline, true) bool     TreeNodeBehaviorIsOpen(ImGuiID id, ImGuiTreeNodeFlags flags = ImGuiTreeNodeFlags.None)    { return TreeNodeUpdateNextOpen(id, flags); }   // Renamed in 1.89

    // Refactored focus/nav/tabbing system in 1.82 and 1.84. If you have old/custom copy-and-pasted widgets that used FocusableItemRegister():
    //  (Old) IMGUI_VERSION_NUM  < 18209: using 'ItemAdd(....)'                              and 'bool tab_focused = FocusableItemRegister(...)'
    //  (Old) IMGUI_VERSION_NUM >= 18209: using 'ItemAdd(..., ImGuiItemAddFlags_Focusable)'  and 'bool tab_focused = (GetItemStatusFlags() & ImGuiItemStatusFlags_Focused) != 0'
    //  (New) IMGUI_VERSION_NUM >= 18413: using 'ItemAdd(..., ImGuiItemFlags_Inputable)'     and 'bool tab_focused = (GetItemStatusFlags() & ImGuiItemStatusFlags_FocusedTabbing) != 0 || (g.NavActivateId == id && (g.NavActivateFlags & ImGuiActivateFlags_PreferInput))' (WIP)
    // Widget code are simplified as there's no need to call FocusableItemUnregister() while managing the transition from regular widget to TempInputText()
    pragma(inline, true) bool     FocusableItemRegister(ImGuiWindow* window, ImGuiID id)              { IM_ASSERT(0); IM_UNUSED(window); IM_UNUSED(id); return false; } // -> pass ImGuiItemAddFlags_Inputable flag to ItemAdd()
    pragma(inline, true) void     FocusableItemUnregister(ImGuiWindow* window)                        { IM_ASSERT(0); IM_UNUSED(window); }                              // -> unnecessary: TempInputText() uses ImGuiInputTextFlags_MergedItem
}
static if (!IMGUI_DISABLE_OBSOLETE_KEYIO) {
    pragma(inline, true) bool     IsKeyPressedMap(ImGuiKey key, bool repeat = true)                   { IM_ASSERT(IsNamedKey(key)); return IsKeyPressed(key, repeat); } // Removed in 1.87: Mapping from named key is always identity!
}

//} // namespace ImGui


//-----------------------------------------------------------------------------
// [SECTION] ImFontAtlas internal API
//-----------------------------------------------------------------------------

// This structure is likely to evolve as we add support for incremental atlas updates
struct ImFontBuilderIO
{
    bool    function(ImFontAtlas* atlas) nothrow @nogc FontBuilder_Build;
}

// Helper for font builder
/+
#ifdef IMGUI_ENABLE_STB_TRUETYPE
const ImFontBuilderIO* ImFontAtlasGetBuilderForStbTruetype();
#endif
void      ImFontAtlasBuildInit(ImFontAtlas* atlas);
void      ImFontAtlasBuildSetupFont(ImFontAtlas* atlas, ImFont* font, ImFontConfig* font_config, float ascent, float descent);
void      ImFontAtlasBuildPackCustomRects(ImFontAtlas* atlas, void* stbrp_context_opaque);
void      ImFontAtlasBuildFinish(ImFontAtlas* atlas);
void      ImFontAtlasBuildRender8bppRectFromString(ImFontAtlas* atlas, int x, int y, int w, int h, string in_str, char in_marker_char, ubyte in_marker_pixel_value);
void      ImFontAtlasBuildRender32bppRectFromString(ImFontAtlas* atlas, int x, int y, int w, int h, string in_str, char in_marker_char, uint in_marker_pixel_value);
void      ImFontAtlasBuildMultiplyCalcLookupTable(ubyte out_table[256], float in_multiply_factor);
void      ImFontAtlasBuildMultiplyRectAlpha8(const ubyte table[256], ubyte* pixels, int x, int y, int w, int h, int stride);
+/

//-----------------------------------------------------------------------------
// [SECTION] Test Engine specific hooks (imgui_test_engine)
//-----------------------------------------------------------------------------

version (IMGUI_ENABLE_TEST_ENGINE) {
/+
extern void         ImGuiTestEngineHook_ItemAdd(ImGuiContext* ctx, ImGuiID id, const ImRect/*&*/ bb, const ImGuiLastItemData* item_data);           // item_data may be NULL
extern void         ImGuiTestEngineHook_ItemInfo(ImGuiContext* ctx, ImGuiID id, string label, ImGuiItemStatusFlags flags);
extern void         ImGuiTestEngineHook_Log(ImGuiContext* ctx, string fmt, ...);
extern string  ImGuiTestEngine_FindItemDebugLabel(ImGuiContext* ctx, ImGuiID id);

// In IMGUI_VERSION_NUM >= 18934: changed IMGUI_TEST_ENGINE_ITEM_ADD(bb,id) to IMGUI_TEST_ENGINE_ITEM_ADD(id,bb,item_data);
#define IMGUI_TEST_ENGINE_ITEM_ADD(_ID,_BB,_ITEM_DATA)      if (g.TestEngineHookItems) ImGuiTestEngineHook_ItemAdd(&g, _ID, _BB, _ITEM_DATA)    // Register item bounding box
#define IMGUI_TEST_ENGINE_ITEM_INFO(_ID,_LABEL,_FLAGS)      if (g.TestEngineHookItems) ImGuiTestEngineHook_ItemInfo(&g, _ID, _LABEL, _FLAGS)    // Register item label and status flags (optional)
#define IMGUI_TEST_ENGINE_LOG(_FMT,...)                     if (g.TestEngineHookItems) ImGuiTestEngineHook_Log(&g, _FMT, __VA_ARGS__)           // Custom log entry from user land into test log
#else
#define IMGUI_TEST_ENGINE_ITEM_ADD(_BB,_ID)                 ((void)0)
#define IMGUI_TEST_ENGINE_ITEM_INFO(_ID,_LABEL,_FLAGS)      ((void)g)
#endif
+/
} else {
pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_ADD(ImRect _BB, uint _IS)                 {}
pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_INFO(ImGuiID _ID, string _LABEL, ImGuiItemStatusFlags _FLAGS)      {}
}
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
+/

// #endif // #ifndef IMGUI_DISABLE
