module d_imgui.imgui_internal;
// dear imgui, v1.76
// (internal structures/api)

// You may use this file to debug, understand or extend ImGui features but we don't provide any guarantee of forward compatibility!
// Set:
//   #define IMGUI_DEFINE_MATH_OPERATORS
// To implement maths operators for ImVec2 (disabled by default to not collide with using IM_VEC2_CLASS_EXTRA along with your own math types+operators)

/*

Index of this file:
// Header mess
// Forward declarations
// STB libraries includes
// Context pointer
// Generic helpers
// Misc data structures
// Main imgui context
// Tab bar, tab item
// Internal API

*/

// #pragma once
// #ifndef IMGUI_DISABLE

//-----------------------------------------------------------------------------
// Header mess
//-----------------------------------------------------------------------------

// #ifndef IMGUI_VERSION
// #error Must include imgui.h before imgui_internal.h
// #endif
import d_imgui.imconfig;
import d_imgui.imgui_h;
import d_imgui.imgui;

import d_imgui.imgui_draw;

import d_imgui.imstb_textedit;

import core.stdc.string : memset, memcpy;
import d_snprintf.vararg;
// #include <stdio.h>      // FILE*, sscanf
// #include <stdlib.h>     // NULL, malloc, free, qsort, atoi, atof
// #include <math.h>       // sqrtf, fabsf, fmodf, powf, floorf, ceilf, cosf, sinf
// #include <limits.h>     // INT_MIN, INT_MAX

nothrow:
@nogc:

// Visual Studio warnings
// #ifdef _MSC_VER
// #pragma warning (push)
// #pragma warning (disable: 4251) // class 'xxx' needs to have dll-interface to be used by clients of struct 'xxx' // when IMGUI_API is set to__declspec(dllexport)
// #endif

// Clang/GCC warnings with -Weverything
// #if defined(__clang__)
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wunused-function"        // for stb_textedit.h
// #pragma clang diagnostic ignored "-Wmissing-prototypes"     // for stb_textedit.h
// #pragma clang diagnostic ignored "-Wold-style-cast"
// #if __has_warning("-Wzero-as-null-pointer-constant")
// #pragma clang diagnostic ignored "-Wzero-as-null-pointer-constant"
// #endif
// #if __has_warning("-Wdouble-promotion")
// #pragma clang diagnostic ignored "-Wdouble-promotion"
// #endif
// #elif defined(__GNUC__)
// #pragma GCC diagnostic push
// #pragma GCC diagnostic ignored "-Wpragmas"                  // warning: unknown option after '#pragma GCC diagnostic' kind
// #pragma GCC diagnostic ignored "-Wclass-memaccess"          // [__GNUC__ >= 8] warning: 'memset/memcpy' clearing/writing an object of type 'xxxx' with no trivial copy-assignment; use assignment or value-initialization instead
// #endif

// Legacy defines
// #ifdef IMGUI_DISABLE_FORMAT_STRING_FUNCTIONS                // Renamed in 1.74
// #error Use IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS
// #endif
// #ifdef IMGUI_DISABLE_MATH_FUNCTIONS                         // Renamed in 1.74
// #error Use IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS
// #endif

//-----------------------------------------------------------------------------
// Forward declarations
//-----------------------------------------------------------------------------

// struct ImBitVector;                 // Store 1-bit per value
// struct ImRect;                      // An axis-aligned rectangle (2 points)
// struct ImDrawDataBuilder;           // Helper to build a ImDrawData instance
// struct ImDrawListSharedData;        // Data shared between all ImDrawList instances
// struct ImGuiColorMod;               // Stacked color modifier, backup of modified data so we can restore it
// struct ImGuiColumnData;             // Storage data for a single column
// struct ImGuiColumns;                // Storage data for a columns set
// struct ImGuiContext;                // Main Dear ImGui context
// struct ImGuiDataTypeInfo;           // Type information associated to a ImGuiDataType enum
// struct ImGuiGroupData;              // Stacked storage data for BeginGroup()/EndGroup()
// struct ImGuiInputTextState;         // Internal state of the currently focused/edited text input box
// struct ImGuiItemHoveredDataBackup;  // Backup and restore IsItemHovered() internal data
// struct ImGuiMenuColumns;            // Simple column measurement, currently used for MenuItem() only
// struct ImGuiNavMoveResult;          // Result of a gamepad/keyboard directional navigation move query result
// struct ImGuiNextWindowData;         // Storage for SetNextWindow** functions
// struct ImGuiNextItemData;           // Storage for SetNextItem** functions
// struct ImGuiPopupData;              // Storage for current popup stack
// struct ImGuiSettingsHandler;        // Storage for one type registered in the .ini file
// struct ImGuiStyleMod;               // Stacked style modifier, backup of modified data so we can restore it
// struct ImGuiTabBar;                 // Storage for a tab bar
// struct ImGuiTabItem;                // Storage for a tab item (within a tab bar)
// struct ImGuiWindow;                 // Storage for one window
// struct ImGuiWindowTempData;         // Temporary storage for one window (that's the data which in theory we could ditch at the end of the frame)
// struct ImGuiWindowSettings;         // Storage for a window .ini settings (we keep one of those even if the actual window wasn't instanced during this session)

// Use your programming IDE "Go to definition" facility on the names of the center columns to find the actual flags/enum lists.
// typedef int ImGuiLayoutType;            // -> enum ImGuiLayoutType_         // Enum: Horizontal or vertical
// typedef int ImGuiButtonFlags;           // -> enum ImGuiButtonFlags_        // Flags: for ButtonEx(), ButtonBehavior()
// typedef int ImGuiColumnsFlags;          // -> enum ImGuiColumnsFlags_       // Flags: BeginColumns()
// typedef int ImGuiDragFlags;             // -> enum ImGuiDragFlags_          // Flags: for DragBehavior()
// typedef int ImGuiItemFlags;             // -> enum ImGuiItemFlags_          // Flags: for PushItemFlag()
// typedef int ImGuiItemStatusFlags;       // -> enum ImGuiItemStatusFlags_    // Flags: for DC.LastItemStatusFlags
// typedef int ImGuiNavHighlightFlags;     // -> enum ImGuiNavHighlightFlags_  // Flags: for RenderNavHighlight()
// typedef int ImGuiNavDirSourceFlags;     // -> enum ImGuiNavDirSourceFlags_  // Flags: for GetNavInputAmount2d()
// typedef int ImGuiNavMoveFlags;          // -> enum ImGuiNavMoveFlags_       // Flags: for navigation requests
// typedef int ImGuiNextItemDataFlags;     // -> enum ImGuiNextItemDataFlags_  // Flags: for SetNextItemXXX() functions
// typedef int ImGuiNextWindowDataFlags;   // -> enum ImGuiNextWindowDataFlags_// Flags: for SetNextWindowXXX() functions
// typedef int ImGuiSeparatorFlags;        // -> enum ImGuiSeparatorFlags_     // Flags: for SeparatorEx()
// typedef int ImGuiSliderFlags;           // -> enum ImGuiSliderFlags_        // Flags: for SliderBehavior()
// typedef int ImGuiTextFlags;             // -> enum ImGuiTextFlags_          // Flags: for TextEx()
// typedef int ImGuiTooltipFlags;          // -> enum ImGuiTooltipFlags_       // Flags: for BeginTooltipEx()

//-------------------------------------------------------------------------
// STB libraries includes
//-------------------------------------------------------------------------

// namespace ImStb
// {

// #undef STB_TEXTEDIT_STRING
// #undef STB_TEXTEDIT_CHARTYPE
alias STB_TEXTEDIT_STRING             = ImGuiInputTextState;
alias STB_TEXTEDIT_CHARTYPE           = ImWchar;
enum STB_TEXTEDIT_GETWIDTH_NEWLINE   = -1.0f;
enum STB_TEXTEDIT_UNDOSTATECOUNT     = 99;
enum STB_TEXTEDIT_UNDOCHARCOUNT      = 999;
import ImStb = d_imgui.imstb_textedit;

// } // namespace ImStb

//-----------------------------------------------------------------------------
// Context pointer
//-----------------------------------------------------------------------------

// #ifndef GImGui
// __gshared ImGuiContext* GImGui;  // Current implicit context pointer
// #endif

//-----------------------------------------------------------------------------
// Macros
//-----------------------------------------------------------------------------

// Debug Logging
// #ifndef IMGUI_DEBUG_LOG
// #define IMGUI_DEBUG_LOG(_FMT,...)       printf("[%05d] " _FMT, GImGui->FrameCount, __VA_ARGS__)
// #endif

// Static Asserts
// #if (__cplusplus >= 201100)
void IM_STATIC_ASSERT(bool _COND)()         {static assert(_COND);}
// #else
// #define IM_STATIC_ASSERT(_COND)         typedef char static_assertion_##__line__[(_COND)?1:-1]
// #endif

// "Paranoid" Debug Asserts are meant to only be enabled during specific debugging/work, otherwise would slow down the code too much.
// We currently don't have many of those so the effect is currently negligible, but onward intent to add more aggressive ones in the code.
//#define IMGUI_DEBUG_PARANOID
version (IMGUI_DEBUG_PARANOID) {
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
static if (D_IMGUI_Windows && D_IMGUI_NORMAL_NEWLINE_ON_WINDOWS) {
    enum IM_NEWLINE                      = "\r\n";   // Play it nice with Windows users (Update: since 2018-05, Notepad finally appears to support Unix-style carriage returns!)
} else {
    enum IM_NEWLINE                      = "\n";
}
enum IM_TABSIZE                      = (4);

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

// Enforce cdecl calling convention for functions called by the standard library, in case compilation settings changed the default to e.g. __vectorcall
// #ifdef _MSC_VER
// #define IMGUI_CDECL __cdecl
// #else
// #define IMGUI_CDECL
// #endif

//-----------------------------------------------------------------------------
// Generic helpers
// Note that the ImXXX helpers functions are lower-level than ImGui functions.
// ImGui functions or the ImGui context are never called/used from other ImXXX functions.
//-----------------------------------------------------------------------------
// - Helpers: Misc
// - Helpers: Bit manipulation
// - Helpers: String, Formatting
// - Helpers: UTF-8 <> wchar conversions
// - Helpers: ImVec2/ImVec4 operators
// - Helpers: Maths
// - Helpers: Geometry
// - Helpers: Bit arrays
// - Helper: ImBitVector
// - Helper: ImPool<>
// - Helper: ImChunkStream<>
//-----------------------------------------------------------------------------

// Helpers: Misc
// D_IMGUI: Dummy qsort implementation
void ImQsort(T)(T[] data, int function(const T*, const T*) nothrow @nogc comp) {
    ImQsort(data, cast(int function(T*, T*) nothrow @nogc)comp);
}
void ImQsort(T)(T[] data, int function(T*, T*) nothrow @nogc comp) {
    if (data.length == 0) return
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
pragma(inline, true) bool ImIsPowerOfTwo(int v)           { return v != 0 && (v & (v - 1)) == 0; }
pragma(inline, true) int ImUpperPowerOfTwo(int v)        { v--; v |= v >> 1; v |= v >> 2; v |= v >> 4; v |= v >> 8; v |= v >> 16; v++; return v; }

// Helpers: String, Formatting
// IMGUI_API int           ImStricmp(const char* str1, const char* str2);
// IMGUI_API int           ImStrnicmp(const char* str1, const char* str2, size_t count);
// IMGUI_API void          ImStrncpy(char* dst, const char* src, size_t count);
// IMGUI_API char*         ImStrdup(const char* str);
// IMGUI_API char*         ImStrdupcpy(char* dst, size_t* p_dst_size, const char* str);
// IMGUI_API const char*   ImStrchrRange(const char* str_begin, const char* str_end, char c);
// IMGUI_API int           ImStrlenW(const ImWchar* str);
// IMGUI_API const char*   ImStreolRange(const char* str, const char* str_end);                // End end-of-line
// IMGUI_API const ImWchar*ImStrbolW(const ImWchar* buf_mid_line, const ImWchar* buf_begin);   // Find beginning-of-line
// IMGUI_API const char*   ImStristr(const char* haystack, const char* haystack_end, const char* needle, const char* needle_end);
// IMGUI_API void          ImStrTrimBlanks(char* str);
// IMGUI_API const char*   ImStrSkipBlank(const char* str);
// IMGUI_API int           ImFormatString(char* buf, size_t buf_size, const char* fmt, ...) IM_FMTARGS(3);
// IMGUI_API int           ImFormatStringV(char* buf, size_t buf_size, const char* fmt, va_list args) IM_FMTLIST(3);
// IMGUI_API const char*   ImParseFormatFindStart(const char* format);
// IMGUI_API const char*   ImParseFormatFindEnd(const char* format);
// IMGUI_API const char*   ImParseFormatTrimDecorations(const char* format, char* buf, size_t buf_size);
// IMGUI_API int           ImParseFormatPrecision(const char* format, int default_value);
pragma(inline, true) bool      ImCharIsBlankA(char c)          { return c == ' ' || c == '\t'; }
pragma(inline, true) bool      ImCharIsBlankW(uint c)  { return c == ' ' || c == '\t' || c == 0x3000; }

// Helpers: UTF-8 <> wchar conversions
// IMGUI_API int           ImTextStrToUtf8(char* buf, int buf_size, const ImWchar* in_text, const ImWchar* in_text_end);      // return output UTF-8 bytes count
// IMGUI_API int           ImTextCharFromUtf8(unsigned int* out_char, const char* in_text, const char* in_text_end);          // read one character. return input UTF-8 bytes count
// IMGUI_API int           ImTextStrFromUtf8(ImWchar* buf, int buf_size, const char* in_text, const char* in_text_end, const char** in_remaining = NULL);   // return input UTF-8 bytes count
// IMGUI_API int           ImTextCountCharsFromUtf8(const char* in_text, const char* in_text_end);                            // return number of UTF-8 code-points (NOT bytes count)
// IMGUI_API int           ImTextCountUtf8BytesFromChar(const char* in_text, const char* in_text_end);                        // return number of bytes to express one char in UTF-8
// IMGUI_API int           ImTextCountUtf8BytesFromStr(const ImWchar* in_text, const ImWchar* in_text_end);                   // return number of bytes to express string in UTF-8

// Helpers: ImVec2/ImVec4 operators
// We are keeping those disabled by default so they don't leak in user space, to allow user enabling implicit cast operators between ImVec2 and their own types (using IM_VEC2_CLASS_EXTRA etc.)
// We unfortunately don't have a unary- operator for ImVec2 because this would needs to be defined inside the class itself.
// #ifdef IMGUI_DEFINE_MATH_OPERATORS
// static inline ImVec2 operator*(const ImVec2& lhs, const float rhs)              { return ImVec2(lhs.x*rhs, lhs.y*rhs); }
// static inline ImVec2 operator/(const ImVec2& lhs, const float rhs)              { return ImVec2(lhs.x/rhs, lhs.y/rhs); }
// static inline ImVec2 operator+(const ImVec2& lhs, const ImVec2& rhs)            { return ImVec2(lhs.x+rhs.x, lhs.y+rhs.y); }
// static inline ImVec2 operator-(const ImVec2& lhs, const ImVec2& rhs)            { return ImVec2(lhs.x-rhs.x, lhs.y-rhs.y); }
// static inline ImVec2 operator*(const ImVec2& lhs, const ImVec2& rhs)            { return ImVec2(lhs.x*rhs.x, lhs.y*rhs.y); }
// static inline ImVec2 operator/(const ImVec2& lhs, const ImVec2& rhs)            { return ImVec2(lhs.x/rhs.x, lhs.y/rhs.y); }
// static inline ImVec2& operator*=(ImVec2& lhs, const float rhs)                  { lhs.x *= rhs; lhs.y *= rhs; return lhs; }
// static inline ImVec2& operator/=(ImVec2& lhs, const float rhs)                  { lhs.x /= rhs; lhs.y /= rhs; return lhs; }
// static inline ImVec2& operator+=(ImVec2& lhs, const ImVec2& rhs)                { lhs.x += rhs.x; lhs.y += rhs.y; return lhs; }
// static inline ImVec2& operator-=(ImVec2& lhs, const ImVec2& rhs)                { lhs.x -= rhs.x; lhs.y -= rhs.y; return lhs; }
// static inline ImVec2& operator*=(ImVec2& lhs, const ImVec2& rhs)                { lhs.x *= rhs.x; lhs.y *= rhs.y; return lhs; }
// static inline ImVec2& operator/=(ImVec2& lhs, const ImVec2& rhs)                { lhs.x /= rhs.x; lhs.y /= rhs.y; return lhs; }
// static inline ImVec4 operator+(const ImVec4& lhs, const ImVec4& rhs)            { return ImVec4(lhs.x+rhs.x, lhs.y+rhs.y, lhs.z+rhs.z, lhs.w+rhs.w); }
// static inline ImVec4 operator-(const ImVec4& lhs, const ImVec4& rhs)            { return ImVec4(lhs.x-rhs.x, lhs.y-rhs.y, lhs.z-rhs.z, lhs.w-rhs.w); }
// static inline ImVec4 operator*(const ImVec4& lhs, const ImVec4& rhs)            { return ImVec4(lhs.x*rhs.x, lhs.y*rhs.y, lhs.z*rhs.z, lhs.w*rhs.w); }
// #endif

// Helpers: File System
version (IMGUI_DISABLE_FILE_FUNCTIONS) {
    // version = IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS;
    alias ImFileHandle = void*;
    pragma(inline, true) ImFileHandle  ImFileOpen(string, string)                    { return NULL; }
    pragma(inline, true) bool          ImFileClose(ImFileHandle)                               { return false; }
    pragma(inline, true) ImU64         ImFileGetSize(ImFileHandle)                             { return (ImU64)-1; }
    pragma(inline, true) ImU64         ImFileRead(void*, ImU64, ImU64, ImFileHandle)           { return 0; }
    pragma(inline, true) ImU64         ImFileWrite(const void*, ImU64, ImU64, ImFileHandle)    { return 0; }
    // D_IMGUI: Encapsulate console handling.
    pragma(inline, true) ImFileHandle  ImGetStdout()                                           { return NULL; }
    pragma(inline, true) bool          ImFlushConsole(ImFileHandle)                            { return false; }
} else

static if (!IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS) {
    // IMGUI_API ImFileHandle      ImFileOpen(string filename, string mode);
    // IMGUI_API bool              ImFileClose(ImFileHandle file);
    // IMGUI_API ImU64             ImFileGetSize(ImFileHandle file);
    // IMGUI_API ImU64             ImFileRead(void* data, ImU64 size, ImU64 count, ImFileHandle file);
    // IMGUI_API ImU64             ImFileWrite(const void* data, ImU64 size, ImU64 count, ImFileHandle file);
// #else
// #define IMGUI_DISABLE_TTY_FUNCTIONS // Can't use stdout, fflush if we are not using default file functions
}
    import core.stdc.stdio : FILE; // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
    alias ImFileHandle = FILE*;
// IMGUI_API void*             ImFileLoadToMemory(string filename, string mode, size_t* out_file_size = NULL, int padding_bytes = 0);

// Helpers: Maths
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
    alias ImFloorStd = floorf;           // We already uses our own ImFloor() { return (float)(int)v } internally so the standard one wrapper is named differently (it's used by e.g. stb_truetype)
    alias ImCeil = ceilf;
    pragma(inline, true) float  ImPow(float x, float y)    { return powf(x, y); }          // DragBehaviorT/SliderBehaviorT uses ImPow with either float/double and need the precision
    pragma(inline, true) double ImPow(double x, double y)  { return pow(x, y); } // TODO D_IMGUI: See bug https://issues.dlang.org/show_bug.cgi?id=20905
    int sscanf(string str, string fmt, ...) {
        mixin va_start;

        // this function only needs to handle the following formats:
        // %d, %i, %u, %lld, %llu, %f, %lf, %08X, %02X%02X%02X, %02X%02X%02X%02X

        return 0;
    }

// - ImMin/ImMax/ImClamp/ImLerp/ImSwap are used by widgets which support variety of types: signed/unsigned int/long long float/double
// (Exceptionally using templates here but we could also redefine them for those types)
pragma(inline, true) T ImMin(T)(T lhs, T rhs)                        { return lhs < rhs ? lhs : rhs; }
pragma(inline, true) T ImMax(T)(T lhs, T rhs)                        { return lhs >= rhs ? lhs : rhs; }
pragma(inline, true) T ImClamp(T)(T v, T mn, T mx)                   { return (v < mn) ? mn : (v > mx) ? mx : v; }
pragma(inline, true) T ImLerp(T)(T a, T b, float t)                  { return cast(T)(a + (b - a) * t); }
pragma(inline, true) void ImSwap(T)(ref T a, ref T b)                      { T tmp = a; a = b; b = tmp; }
pragma(inline, true) T ImAddClampOverflow(T)(T a, T b, T mn, T mx)   { if (b < 0 && (a < mn - b)) return mn; if (b > 0 && (a > mx - b)) return mx; return cast(T)(a + b); }
pragma(inline, true) T ImSubClampOverflow(T)(T a, T b, T mn, T mx)   { if (b > 0 && (a < mn + b)) return mn; if (b < 0 && (a > mx + b)) return mx; return cast(T)(a - b); }
// - Misc maths helpers
pragma(inline, true) ImVec2 ImMin(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x < rhs.x ? lhs.x : rhs.x, lhs.y < rhs.y ? lhs.y : rhs.y); }
pragma(inline, true) ImVec2 ImMax(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x >= rhs.x ? lhs.x : rhs.x, lhs.y >= rhs.y ? lhs.y : rhs.y); }
pragma(inline, true) ImVec2 ImClamp(const ImVec2/*&*/ v, const ImVec2/*&*/ mn, ImVec2 mx)      { return ImVec2((v.x < mn.x) ? mn.x : (v.x > mx.x) ? mx.x : v.x, (v.y < mn.y) ? mn.y : (v.y > mx.y) ? mx.y : v.y); }
pragma(inline, true) ImVec2 ImLerp(const ImVec2/*&*/ a, const ImVec2/*&*/ b, float t)          { return ImVec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t); }
pragma(inline, true) ImVec2 ImLerp(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ t)  { return ImVec2(a.x + (b.x - a.x) * t.x, a.y + (b.y - a.y) * t.y); }
pragma(inline, true) ImVec4 ImLerp(const ImVec4/*&*/ a, const ImVec4/*&*/ b, float t)          { return ImVec4(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t); }
pragma(inline, true) float  ImSaturate(float f)                                        { return (f < 0.0f) ? 0.0f : (f > 1.0f) ? 1.0f : f; }
pragma(inline, true) float  ImLengthSqr(const ImVec2/*&*/ lhs)                             { return lhs.x*lhs.x + lhs.y*lhs.y; }
pragma(inline, true) float  ImLengthSqr(const ImVec4/*&*/ lhs)                             { return lhs.x*lhs.x + lhs.y*lhs.y + lhs.z*lhs.z + lhs.w*lhs.w; }
pragma(inline, true) float  ImInvLength(const ImVec2/*&*/ lhs, float fail_value)           { float d = lhs.x*lhs.x + lhs.y*lhs.y; if (d > 0.0f) return 1.0f / ImSqrt(d); return fail_value; }
pragma(inline, true) float  ImFloor(float f)                                           { return cast(float)cast(int)(f); }
pragma(inline, true) ImVec2 ImFloor(const ImVec2/*&*/ v)                                   { return ImVec2(cast(float)cast(int)(v.x), cast(float)cast(int)(v.y)); }
pragma(inline, true) int    ImModPositive(int a, int b)                                { return (a + b) % b; }
pragma(inline, true) float  ImDot(const ImVec2/*&*/ a, const ImVec2/*&*/ b)                    { return a.x * b.x + a.y * b.y; }
pragma(inline, true) ImVec2 ImRotate(const ImVec2/*&*/ v, float cos_a, float sin_a)        { return ImVec2(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a); }
pragma(inline, true) float  ImLinearSweep(float current, float target, float speed)    { if (current < target) return ImMin(current + speed, target); if (current > target) return ImMax(current - speed, target); return current; }
pragma(inline, true) ImVec2 ImMul(const ImVec2/*&*/ lhs, const ImVec2/*&*/ rhs)                { return ImVec2(lhs.x * rhs.x, lhs.y * rhs.y); }

// Helpers: Geometry
// IMGUI_API ImVec2     ImBezierCalc(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, float t);                                         // Cubic Bezier
// IMGUI_API ImVec2     ImBezierClosestPoint(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& p, int num_segments);       // For curves with explicit number of segments
// IMGUI_API ImVec2     ImBezierClosestPointCasteljau(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, const ImVec2& p4, const ImVec2& p, float tess_tol);// For auto-tessellated curves you can use tess_tol = style.CurveTessellationTol
// IMGUI_API ImVec2     ImLineClosestPoint(const ImVec2& a, const ImVec2& b, const ImVec2& p);
// IMGUI_API bool       ImTriangleContainsPoint(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p);
// IMGUI_API ImVec2     ImTriangleClosestPoint(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p);
// IMGUI_API void       ImTriangleBarycentricCoords(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& p, float& out_u, float& out_v, float& out_w);
pragma(inline, true) float ImTriangleArea(const ImVec2/*&*/ a, const ImVec2/*&*/ b, const ImVec2/*&*/ c) { return ImFabs((a.x * (b.y - c.y)) + (b.x * (c.y - a.y)) + (c.x * (a.y - b.y))) * 0.5f; }
// IMGUI_API ImGuiDir   ImGetDirQuadrantFromDelta(float dx, float dy);

// Helpers: Bit arrays
pragma(inline, true) bool          ImBitArrayTestBit(const ImU32* arr, int n)         { ImU32 mask = cast(ImU32)1 << (n & 31); return (arr[n >> 5] & mask) != 0; }
pragma(inline, true) void          ImBitArrayClearBit(ImU32* arr, int n)              { ImU32 mask = cast(ImU32)1 << (n & 31); arr[n >> 5] &= ~mask; }
pragma(inline, true) void          ImBitArraySetBit(ImU32* arr, int n)                { ImU32 mask = cast(ImU32)1 << (n & 31); arr[n >> 5] |= mask; }
pragma(inline, true) void          ImBitArraySetBitRange(ImU32* arr, int n, int n2)
{
    while (n <= n2)
    {
        int a_mod = (n & 31);
        int b_mod = ((n2 >= n + 31) ? 31 : (n2 & 31)) + 1;
        ImU32 mask = cast(ImU32)((cast(ImU64)1 << b_mod) - 1) & ~cast(ImU32)((cast(ImU64)1 << a_mod) - 1);
        arr[n >> 5] |= mask;
        n = (n + 32) & ~31;
    }
}

// Helper: ImBitVector
// Store 1-bit per value.
struct ImBitVector
{
    nothrow:
    @nogc:

    ImVector!ImU32 Storage;
    void destroy() { Storage.destroy(); }
    void            Create(int sz)              { Storage.resize((sz + 31) >> 5); memset(Storage.Data, 0, cast(size_t)Storage.Size * (Storage.Data[0]).sizeof); }
    void            Clear()                     { Storage.clear(); }
    bool            TestBit(int n) const        { IM_ASSERT(n < (Storage.Size << 5)); return ImBitArrayTestBit(Storage.Data, n); }
    void            SetBit(int n)               { IM_ASSERT(n < (Storage.Size << 5)); ImBitArraySetBit(Storage.Data, n); }
    void            ClearBit(int n)             { IM_ASSERT(n < (Storage.Size << 5)); ImBitArrayClearBit(Storage.Data, n); }
}

// Helper: ImPool<>
// Basic keyed storage for contiguous instances, slow/amortized insertion, O(1) indexable, O(Log N) queries by ID over a dense/hot buffer,
// Honor constructor/destructor. Add/remove invalidate all pointers. Indexes have the same lifetime as the associated object.
alias ImPoolIdx = int;
struct ImPool(T)
{
    ImVector!T     Buf;        // Contiguous data
    ImGuiStorage    Map;        // ID->Index
    ImPoolIdx       FreeIdx;    // Next free idx to use

    // ImPool()    { FreeIdx = 0; }
    void destroy()   { Clear(); }
    T*          GetByKey(ImGuiID key)               { int idx = Map.GetInt(key, -1); return (idx != -1) ? &Buf[idx] : NULL; }
    T*          GetByIndex(ImPoolIdx n)             { return &Buf[n]; }
    ImPoolIdx   GetIndex(const T* p) const          { IM_ASSERT(p >= Buf.Data && p < Buf.Data + Buf.Size); return cast(ImPoolIdx)(p - Buf.Data); }
    T*          GetOrAddByKey(ImGuiID key)          { int* p_idx = Map.GetIntRef(key, -1); if (*p_idx != -1) return &Buf[*p_idx]; *p_idx = FreeIdx; return Add(); }
    bool        Contains(const T* p) const          { return (p >= Buf.Data && p < Buf.Data + Buf.Size); }
    void        Clear()                             { for (int n = 0; n < Map.Data.Size; n++) { int idx = Map.Data[n].val_i; if (idx != -1) Buf[idx].destroy(); } Map.Clear(); Buf.clear(); FreeIdx = 0; }
    T*          Add()                               { int idx = FreeIdx; if (idx == Buf.Size) { Buf.resize(Buf.Size + 1); FreeIdx++; } else { FreeIdx = *cast(int*)&Buf[idx]; } IM_PLACEMENT_NEW(&Buf[idx], T(false)); return &Buf[idx]; }
    void        Remove(ImGuiID key, const T* p)     { Remove(key, GetIndex(p)); }
    void        Remove(ImGuiID key, ImPoolIdx idx)  { Buf[idx].destroy(); *cast(int*)&Buf[idx] = FreeIdx; FreeIdx = idx; Map.SetInt(key, -1); }
    void        Reserve(int capacity)               { Buf.reserve(capacity); Map.Data.reserve(capacity); }
    int         GetSize() const                     { return Buf.Size; }
}

// Helper: ImChunkStream<>
// Build and iterate a contiguous stream of variable-sized structures.
// This is used by Settings to store persistent data while reducing allocation count.
// We store the chunk size first, and align the final size on 4 bytes boundaries (this what the '(X + 3) & ~3' statement is for)
// The tedious/zealous amount of casting is to avoid -Wcast-align warnings.
struct ImChunkStream(T)
{
    ImVector!char  Buf;

    void destroy() { Buf.destroy(); }
    void    clear()                     { Buf.clear(); }
    bool    empty() const               { return Buf.Size == 0; }
    int     size() const                { return Buf.Size; }
    T*      alloc_chunk(size_t sz)      { size_t HDR_SZ = 4; sz = ((HDR_SZ + sz) + 3u) & ~3u; int off = Buf.Size; Buf.resize(off + cast(int)sz); (cast(int*)cast(void*)(Buf.Data + off))[0] = cast(int)sz; return cast(T*)cast(void*)(Buf.Data + off + cast(int)HDR_SZ); }
    T*      begin()                     { size_t HDR_SZ = 4; if (!Buf.Data) return NULL; return cast(T*)cast(void*)(Buf.Data + HDR_SZ); }
    T*      next_chunk(T* p)            { size_t HDR_SZ = 4; IM_ASSERT(p >= begin() && p < end()); p = cast(T*)cast(void*)(cast(char*)cast(void*)p + chunk_size(p)); if (p == cast(T*)cast(void*)(cast(char*)end() + HDR_SZ)) return cast(T*)0; IM_ASSERT(p < end()); return p; }
    int     chunk_size(const T* p)      { return (cast(const int*)p)[-1]; }
    T*      end()                       { return cast(T*)cast(void*)(Buf.Data + Buf.Size); }
    int     offset_from_ptr(const T* p) { IM_ASSERT(p >= begin() && p < end()); const ptrdiff_t off = cast(const char*)p - Buf.Data; return cast(int)off; }
    T*      ptr_from_offset(int off)    { IM_ASSERT(off >= 4 && off < Buf.Size); return cast(T*)cast(void*)(Buf.Data + off); }
}

//-----------------------------------------------------------------------------
// Misc data structures
//-----------------------------------------------------------------------------

enum ImGuiButtonFlags : int
{
    None                   = 0,
    Repeat                 = 1 << 0,   // hold to repeat
    PressedOnClick         = 1 << 1,   // return true on click (mouse down event)
    PressedOnClickRelease  = 1 << 2,   // [Default] return true on click + release on same item <-- this is what the majority of Button are using
    PressedOnClickReleaseAnywhere = 1 << 3, // return true on click + release even if the release event is not done while hovering the item
    PressedOnRelease       = 1 << 4,   // return true on release (default requires click+release)
    PressedOnDoubleClick   = 1 << 5,   // return true on double-click (default requires click+release)
    PressedOnDragDropHold  = 1 << 6,   // return true when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers)
    FlattenChildren        = 1 << 7,   // allow interactions even if a child window is overlapping
    AllowItemOverlap       = 1 << 8,   // require previous frame HoveredId to either match id or be null before being usable, use along with SetItemAllowOverlap()
    DontClosePopups        = 1 << 9,   // disable automatically closing parent popup on press // [UNUSED]
    Disabled               = 1 << 10,  // disable interactions
    AlignTextBaseLine      = 1 << 11,  // vertically align button to match text baseline - ButtonEx() only // FIXME: Should be removed and handled by SmallButton(), not possible currently because of DC.CursorPosPrevLine
    NoKeyModifiers         = 1 << 12,  // disable mouse interaction if a key modifier is held
    NoHoldingActiveId      = 1 << 13,  // don't set ActiveId while holding the mouse (ImGuiButtonFlags_PressedOnClick only)
    NoNavFocus             = 1 << 14,  // don't override navigation focus when activated
    NoHoveredOnFocus       = 1 << 15,  // don't report as hovered when nav focus is on this item
    MouseButtonLeft        = 1 << 16,  // [Default] react on left mouse button
    MouseButtonRight       = 1 << 17,  // react on right mouse button
    MouseButtonMiddle      = 1 << 18,  // react on center mouse button

    MouseButtonMask_       = MouseButtonLeft | MouseButtonRight | MouseButtonMiddle,
    MouseButtonShift_      = 16,
    MouseButtonDefault_    = MouseButtonLeft,
    PressedOnMask_         = PressedOnClick | PressedOnClickRelease | PressedOnClickReleaseAnywhere | PressedOnRelease | PressedOnDoubleClick | PressedOnDragDropHold,
    PressedOnDefault_      = PressedOnClickRelease
}

enum ImGuiSliderFlags : int
{
    None                   = 0,
    Vertical               = 1 << 0
}

enum ImGuiDragFlags : int
{
    None                     = 0,
    Vertical                 = 1 << 0
}

enum ImGuiColumnsFlags : int
{
    // Default: 0
    None                  = 0,
    NoBorder              = 1 << 0,   // Disable column dividers
    NoResize              = 1 << 1,   // Disable resizing columns when clicking on the dividers
    NoPreserveWidths      = 1 << 2,   // Disable column width preservation when adjusting columns
    NoForceWithinWindow   = 1 << 3,   // Disable forcing columns to fit within window
    GrowParentContentsSize= 1 << 4    // (WIP) Restore pre-1.51 behavior of extending the parent window contents size but _without affecting the columns width at all_. Will eventually remove.
}

// Extend ImGuiSelectableFlags_
// D_IMGUI: Moved into ImGuiSelectableFlags
// enum ImGuiSelectableFlagsPrivate : int
// {
//     // NB: need to be in sync with last value of ImGuiSelectableFlags_
//     NoHoldingActiveID  = 1 << 20,
//     SelectOnClick      = 1 << 21,  // Override button behavior to react on Click (default is Click+Release)
//     SelectOnRelease    = 1 << 22,  // Override button behavior to react on Release (default is Click+Release)
//     SpanAvailWidth     = 1 << 23,  // Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
//     DrawHoveredWhenHeld= 1 << 24,  // Always show active when held, even is not hovered. This concept could probably be renamed/formalized somehow.
//     SetNavIdOnHover    = 1 << 25
// }

// Extend ImGuiTreeNodeFlags
// D_IMGUI: Moved into ImGuiTreeNodeFlags
// enum ImGuiTreeNodeFlagsPrivate : int
// {
//     ClipLabelForTrailingButton = 1 << 20
// }

enum ImGuiSeparatorFlags : int
{
    None                = 0,
    Horizontal          = 1 << 0,   // Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
    Vertical            = 1 << 1,
    SpanAllColumns      = 1 << 2
}

// Transient per-window flags, reset at the beginning of the frame. For child window, inherited from parent on first Begin().
// This is going to be exposed in imgui.h when stabilized enough.
enum ImGuiItemFlags : int
{
    None                     = 0,
    NoTabStop                = 1 << 0,  // false
    ButtonRepeat             = 1 << 1,  // false    // Button() will return true multiple times based on io.KeyRepeatDelay and io.KeyRepeatRate settings.
    Disabled                 = 1 << 2,  // false    // [BETA] Disable interactions but doesn't affect visuals yet. See github.com/ocornut/imgui/issues/211
    NoNav                    = 1 << 3,  // false
    NoNavDefaultFocus        = 1 << 4,  // false
    SelectableDontClosePopup = 1 << 5,  // false    // MenuItem/Selectable() automatically closes current Popup window
    MixedValue               = 1 << 6,  // false    // [BETA] Represent a mixed/indeterminate value, generally multi-selection where values differ. Currently only supported by Checkbox() (later should support all sorts of widgets)
    Default_                 = 0
}

// Storage for LastItem data
enum ImGuiItemStatusFlags : int
{
    None               = 0,
    HoveredRect        = 1 << 0,
    HasDisplayRect     = 1 << 1,
    Edited             = 1 << 2,   // Value exposed by item was edited in the current frame (should match the bool return value of most widgets)
    ToggledSelection   = 1 << 3,   // Set when Selectable(), TreeNode() reports toggling a selection. We can't report "Selected" because reporting the change allows us to handle clipping with less issues.
    ToggledOpen        = 1 << 4,   // Set when TreeNode() reports toggling their open state.
    HasDeactivated     = 1 << 5,   // Set if the widget/group is able to provide data for the ImGuiItemStatusFlags_Deactivated flag.
    Deactivated        = 1 << 6    // Only valid if ImGuiItemStatusFlags_HasDeactivated is set.

// #ifdef IMGUI_ENABLE_TEST_ENGINE
    , // [imgui_tests only]
    Openable           = 1 << 10,  //
    Opened             = 1 << 11,  //
    Checkable          = 1 << 12,  //
    Checked            = 1 << 13   //
// #endif
}


version (IMGUI_ENABLE_TEST_ENGINE) {
    // [imgui_tests only]
    enum ImGuiItemStatusFlags_Openable           = 1 << 10;  //
    enum ImGuiItemStatusFlags_Opened             = 1 << 11;  //
    enum ImGuiItemStatusFlags_Checkable          = 1 << 12;  //
    enum ImGuiItemStatusFlags_Checked            = 1 << 13;  //
}

enum ImGuiTextFlags : int
{
    None = 0,
    NoWidthForLargeClippedText = 1 << 0
}

enum ImGuiTooltipFlags : int
{
    None = 0,
    OverridePreviousTooltip = 1 << 0      // Override will clear/ignore previously submitted tooltip (defaults to append)
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
    Clipboard
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
    Histogram
}

enum ImGuiInputSource : int
{
    None = 0,
    Mouse,
    Nav,
    NavKeyboard,   // Only used occasionally for storage, not tested/handled by most code
    NavGamepad,    // "
    COUNT
}

// FIXME-NAV: Clarify/expose various repeat delay/rate
enum ImGuiInputReadMode : int
{
    Down,
    Pressed,
    Released,
    Repeat,
    RepeatSlow,
    RepeatFast
}

enum ImGuiNavHighlightFlags : int
{
    None         = 0,
    TypeDefault  = 1 << 0,
    TypeThin     = 1 << 1,
    AlwaysDraw   = 1 << 2,       // Draw rectangular highlight if (g.NavId == id) _even_ when using the mouse.
    NoRounding   = 1 << 3
}

enum ImGuiNavDirSourceFlags : int
{
    None         = 0,
    Keyboard     = 1 << 0,
    PadDPad      = 1 << 1,
    PadLStick    = 1 << 2
}

enum ImGuiNavMoveFlags : int
{
    None                  = 0,
    LoopX                 = 1 << 0,   // On failed request, restart from opposite side
    LoopY                 = 1 << 1,
    WrapX                 = 1 << 2,   // On failed request, request from opposite side one line down (when NavDir==right) or one line up (when NavDir==left)
    WrapY                 = 1 << 3,   // This is not super useful for provided for completeness
    AllowCurrentNavId     = 1 << 4,   // Allow scoring and considering the current NavId as a move target candidate. This is used when the move source is offset (e.g. pressing PageDown actually needs to send a Up move request, if we are pressing PageDown from the bottom-most item we need to stay in place)
    AlsoScoreVisibleSet   = 1 << 5,   // Store alternate result in NavMoveResultLocalVisibleSet that only comprise elements that are already fully visible.
    ScrollToEdge          = 1 << 6
}

enum ImGuiNavForward : int
{
    None,
    ForwardQueued,
    ForwardActive
}

enum ImGuiNavLayer : int
{
    Main  = 0,    // Main scrolling layer
    Menu  = 1,    // Menu layer (access with Alt/ImGuiNavInput_Menu)
    COUNT
}

enum ImGuiPopupPositionPolicy : int
{
    Default,
    ComboBox
}

// 1D vector (this odd construct is used to facilitate the transition between 1D and 2D, and the maintenance of some branches/patches)
struct ImVec1
{
    nothrow:
    @nogc:

    float   x = 0.0f;
    // this()         { x = 0.0f; }
    this(float _x) { x = _x; }
}

// 2D vector (half-size integer)
struct ImVec2ih
{
    nothrow:
    @nogc:

    short   x, y;
    // this()                           { x = y = 0; }
    this(short _x, short _y)         { x = _x; y = _y; }
    this(const ImVec2/*&*/ rhs) { x = cast(short)rhs.x; y = cast(short)rhs.y; }
}

// 2D axis aligned bounding-box
// NB: we can't rely on ImVec2 math operators being available here
struct ImRect
{
    nothrow:
    @nogc:

    ImVec2      Min;    // Upper-left
    ImVec2      Max;    // Lower-right

    // this()                                        { Min = ImVec2(0.0f, 0.0f); Max = ImVec2(0.0f, 0.0f); }
    this(const ImVec2/*&*/ min, const ImVec2/*&*/ max)    { Min = min; Max = max; }
    this(const ImVec4/*&*/ v)                         { Min = ImVec2(v.x, v.y); Max = ImVec2(v.z, v.w); }
    this(float x1, float y1, float x2, float y2)  {  Min = ImVec2(x1, y1); Max = ImVec2(x2, y2); }

    ImVec2      GetCenter() const                   { return ImVec2((Min.x + Max.x) * 0.5f, (Min.y + Max.y) * 0.5f); }
    ImVec2      GetSize() const                     { return ImVec2(Max.x - Min.x, Max.y - Min.y); }
    float       GetWidth() const                    { return Max.x - Min.x; }
    float       GetHeight() const                   { return Max.y - Min.y; }
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
}

// Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().
struct ImGuiDataTypeInfo
{
    size_t      Size;           // Size in byte
    string PrintFmt;       // Default printf format for the type
    string ScanFmt;        // Default scanf format for the type
}

// Stacked color modifier, backup of modified data so we can restore it
struct ImGuiColorMod
{
    ImGuiCol    Col;
    ImVec4      BackupValue;
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

// Stacked storage data for BeginGroup()/EndGroup()
struct ImGuiGroupData
{
    ImVec2      BackupCursorPos;
    ImVec2      BackupCursorMaxPos;
    ImVec1      BackupIndent;
    ImVec1      BackupGroupOffset;
    ImVec2      BackupCurrLineSize;
    float       BackupCurrLineTextBaseOffset;
    ImGuiID     BackupActiveIdIsAlive;
    bool        BackupActiveIdPreviousFrameIsAlive;
    bool        EmitItem;
}

// Simple column measurement, currently used for MenuItem() only.. This is very short-sighted/throw-away code and NOT a generic helper.
struct ImGuiMenuColumns
{
    nothrow:
    @nogc:

    float       Spacing = 0;
    float       Width = 0, NextWidth = 0;
    float[3]       Pos = 0, NextWidths = 0;

    // this();

    void        Update(int count, float spacing, bool clear)
    {
        IM_ASSERT(count == IM_ARRAYSIZE(Pos));
        IM_UNUSED(count);
        Width = NextWidth = 0.0f;
        Spacing = spacing;
        if (clear)
            memset(NextWidths.ptr, 0, (NextWidths).sizeof);
        for (int i = 0; i < IM_ARRAYSIZE(Pos); i++)
        {
            if (i > 0 && NextWidths[i] > 0.0f)
                Width += Spacing;
            Pos[i] = IM_FLOOR(Width);
            Width += NextWidths[i];
            NextWidths[i] = 0.0f;
        }
    }

    float       DeclColumns(float w0, float w1, float w2)
    {
        NextWidth = 0.0f;
        NextWidths[0] = ImMax(NextWidths[0], w0);
        NextWidths[1] = ImMax(NextWidths[1], w1);
        NextWidths[2] = ImMax(NextWidths[2], w2);
        for (int i = 0; i < IM_ARRAYSIZE(Pos); i++)
            NextWidth += NextWidths[i] + ((i > 0 && NextWidths[i] > 0.0f) ? Spacing : 0.0f);
        return ImMax(Width, NextWidth);
    }

    float       CalcExtraSpace(float avail_w) const
    {
        return ImMax(0.0f, avail_w - Width);
    }
}

// Internal state of the currently focused/edited text input box
// For a given item ID, access with ImGui::GetInputTextState()
struct ImGuiInputTextState
{
    nothrow:
    @nogc:

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
    ImGuiInputTextFlags     UserFlags;              // Temporarily set while we call user's callback
    ImGuiInputTextCallback  UserCallback;           // "
    void*                   UserCallbackData;       // "

    // this()                   { memset(&this, 0, (this).sizeof); }
    void destroy() { ClearFreeMemory(); }
    void        ClearText()                 { CurLenW = CurLenA = 0; TextW[0] = 0; TextA[0] = 0; CursorClamp(); }
    void        ClearFreeMemory()           { TextW.clear(); TextA.clear(); InitialTextA.clear(); }
    int         GetUndoAvailCount() const   { return Stb.undostate.undo_point; }
    int         GetRedoAvailCount() const   { return STB_TEXTEDIT_UNDOSTATECOUNT - Stb.undostate.redo_point; }
    void        OnKeyPressed(int key)      // Cannot be inline because we call in code in stb_textedit.h implementation
    {
        stb_textedit_key(&this, &Stb, key);
        CursorFollow = true;
        CursorAnimReset();
    }

    // Cursor & Selection
    void        CursorAnimReset()           { CursorAnim = -0.30f; }                                   // After a user-input the cursor stays on for a while without blinking
    void        CursorClamp()               { Stb.cursor = ImMin(Stb.cursor, CurLenW); Stb.select_start = ImMin(Stb.select_start, CurLenW); Stb.select_end = ImMin(Stb.select_end, CurLenW); }
    bool        HasSelection() const        { return Stb.select_start != Stb.select_end; }
    void        ClearSelection()            { Stb.select_start = Stb.select_end = Stb.cursor; }
    void        SelectAll()                 { Stb.select_start = 0; Stb.cursor = Stb.select_end = CurLenW; Stb.has_preferred_x = 0; }
}

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
    // D_IMGUI: Also store the length since we are not using zero termination
    size_t         name_len;

    @disable this();
    this(size_t name_length)       { ID = 0; Pos = Size = ImVec2ih(0,0); Collapsed = false; name_len = name_length;}
    string GetName()             {  return cast(string)(cast(char*)(&this + 1))[0..name_len]; }
}

struct ImGuiSettingsHandler
{
    nothrow:
    @nogc:

    string TypeName;       // Short description stored in .ini file. Disallowed characters: '[' ']'
    ImGuiID     TypeHash;       // == ImHashStr(TypeName)
    void*       function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, string name) ReadOpenFn;              // Read: Called when entering into a new ini entry e.g. "[Window][Name]"
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, void* entry, string line) ReadLineFn; // Read: Called for every line of text within an ini entry
    void        function(ImGuiContext* ctx, ImGuiSettingsHandler* handler, ImGuiTextBuffer* out_buf) WriteAllFn;      // Write: Output every entries into 'out_buf'
    void*       UserData;

    // this() { memset(&this, 0, (this).sizeof); }
}

// Storage for current popup stack
struct ImGuiPopupData
{
    nothrow:
    @nogc:

    ImGuiID             PopupId;        // Set on OpenPopup()
    ImGuiWindow*        Window;         // Resolved on BeginPopup() - may stay unresolved if user never calls OpenPopup()
    ImGuiWindow*        SourceWindow;   // Set on OpenPopup() copy of NavWindow at the time of opening the popup
    int                 OpenFrameCount = -1; // Set on OpenPopup()
    ImGuiID             OpenParentId;   // Set on OpenPopup(), we need this to differentiate multiple menu sets from each others (e.g. inside menu bar vs loose menu items)
    ImVec2              OpenPopupPos;   // Set on OpenPopup(), preferred popup position (typically == OpenMousePos when using mouse)
    ImVec2              OpenMousePos;   // Set on OpenPopup(), copy of mouse position at the time of opening popup

    // @disable this();
    // this(bool dummy) { PopupId = 0; Window = SourceWindow = NULL; OpenFrameCount = -1; OpenParentId = 0; }
}

struct ImGuiColumnData
{
    float               OffsetNorm;         // Column start offset, normalized 0.0 (far left) -> 1.0 (far right)
    float               OffsetNormBeforeResize;
    ImGuiColumnsFlags   Flags;              // Not exposed
    ImRect              ClipRect;

    // this()   { OffsetNorm = OffsetNormBeforeResize = 0.0f; Flags = ImGuiColumnsFlags.None; }
}

struct ImGuiColumns
{
    nothrow:
    @nogc:

    ImGuiID             ID;
    ImGuiColumnsFlags   Flags;
    bool                IsFirstFrame;
    bool                IsBeingResized;
    int                 Current;
    int                 Count = -1;
    float               OffMinX = 0, OffMaxX = 0;       // Offsets from HostWorkRect.Min.x
    float               LineMinY = 0, LineMaxY = 0;
    float               HostCursorPosY = 0;         // Backup of CursorPos at the time of BeginColumns()
    float               HostCursorMaxPosX = 0;      // Backup of CursorMaxPos at the time of BeginColumns()
    ImRect              HostClipRect;           // Backup of ClipRect at the time of BeginColumns()
    ImRect              HostWorkRect;           // Backup of WorkRect at the time of BeginColumns()
    ImVector!ImGuiColumnData Columns;
    ImDrawListSplitter  Splitter;

    // this()      { Clear(); }
    void destroy() { Clear(); Splitter.destroy(); }
    void Clear()
    {
        ID = 0;
        Flags = ImGuiColumnsFlags.None;
        IsFirstFrame = false;
        IsBeingResized = false;
        Current = 0;
        Count = 1;
        OffMinX = OffMaxX = 0.0f;
        LineMinY = LineMaxY = 0.0f;
        HostCursorPosY = 0.0f;
        HostCursorMaxPosX = 0.0f;
        Columns.clear();
    }
}

// ImDrawList: Helper function to calculate a circle's segment count given its radius and a "maximum error" value.
enum IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN                     = 12;
enum IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX                     = 512;
pragma(inline, true) int IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(float _RAD, float _MAXERROR) {
    return ImClamp(cast(int)((IM_PI * 2.0f) / ImAcos(((_RAD) - (_MAXERROR)) / (_RAD))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX);
}

// ImDrawList: You may set this to higher values (e.g. 2 or 3) to increase tessellation of fast rounded corners path.
enum IM_DRAWLIST_ARCFAST_TESSELLATION_MULTIPLIER             = 1;

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

    // [Internal] Lookup tables
    ImVec2[12 * IM_DRAWLIST_ARCFAST_TESSELLATION_MULTIPLIER]          ArcFastVtx;  // FIXME: Bake rounded corners fill/borders in atlas
    ImU8[64]            CircleSegmentCounts;    // Precomputed segment count for given radius (array index + 1) before we calculate it dynamically (to avoid calculation overhead)

    @disable this();
    this(bool dummy)
    {
        Font = NULL;
        FontSize = 0.0f;
        CurveTessellationTol = 0.0f;
        CircleSegmentMaxError = 0.0f;
        ClipRectFullscreen = ImVec4(-8192.0f, -8192.0f, +8192.0f, +8192.0f);
        InitialFlags = ImDrawListFlags.None;

        // Lookup tables
        for (int i = 0; i < IM_ARRAYSIZE(ArcFastVtx); i++)
        {
            const float a = (cast(float)i * 2 * IM_PI) / cast(float)IM_ARRAYSIZE(ArcFastVtx);
            ArcFastVtx[i] = ImVec2(ImCos(a), ImSin(a));
        }
        memset(CircleSegmentCounts.ptr, 0, (CircleSegmentCounts).sizeof); // This will be set by SetCircleSegmentMaxError()
    }

    void SetCircleSegmentMaxError(float max_error)
    {
        if (CircleSegmentMaxError == max_error)
            return;
        CircleSegmentMaxError = max_error;
        for (int i = 0; i < IM_ARRAYSIZE(CircleSegmentCounts); i++)
        {
            const float radius = i + 1.0f;
            const int segment_count = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, CircleSegmentMaxError);
            CircleSegmentCounts[i] = cast(ImU8)ImMin(segment_count, 255);
        }
    }
}

struct ImDrawDataBuilder
{
    nothrow:
    @nogc:

    ImVector!(ImDrawList*)[2]   Layers;           // Global layers for: regular, tooltip

    void destroy() { ClearFreeMemory(); }
    void Clear()            { for (int n = 0; n < IM_ARRAYSIZE(Layers); n++) Layers[n].resize(0); }
    void ClearFreeMemory()  { for (int n = 0; n < IM_ARRAYSIZE(Layers); n++) Layers[n].clear(); }
    void FlattenIntoSingleLayer()
    {
        int n = Layers[0].Size;
        int size = n;
        for (int i = 1; i < IM_ARRAYSIZE(Layers); i++)
            size += Layers[i].Size;
        Layers[0].resize(size);
        for (int layer_n = 1; layer_n < IM_ARRAYSIZE(Layers); layer_n++)
        {
            ImVector!(ImDrawList*)* layer = &Layers[layer_n];
            if (layer.empty())
                continue;
            memcpy(&Layers[0][n], &(*layer)[0], layer.Size * (ImDrawList*).sizeof);
            n += layer.Size;
            layer.resize(0);
        }
    }
}

struct ImGuiNavMoveResult
{
    nothrow:
    @nogc:

    ImGuiWindow*    Window;             // Best candidate window
    ImGuiID         ID;                 // Best candidate ID
    ImGuiID         FocusScopeId;       // Best candidate focus scope ID
    float           DistBox = FLT_MAX;            // Best candidate box distance to current NavId
    float           DistCenter = FLT_MAX;         // Best candidate center distance to current NavId
    float           DistAxial = FLT_MAX;
    ImRect          RectRel;            // Best candidate bounding box in window relative space

    // this() { Clear(); }
    void Clear()         { Window = NULL; ID = FocusScopeId = 0; DistBox = DistCenter = DistAxial = FLT_MAX; RectRel = ImRect(); }
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
    HasBgAlpha         = 1 << 6
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
    bool                        CollapsedVal;
    ImRect                      SizeConstraintRect;
    ImGuiSizeCallback           SizeCallback;
    void*                       SizeCallbackUserData;
    float                       BgAlphaVal = 0;             // Override background alpha
    ImVec2                      MenuBarOffsetMinVal;    // *Always on* This is not exposed publicly, so we don't clear it.

    // this()       { memset(&this, 0, (this).sizeof); }
    pragma(inline, true) void ClearFlags()    { Flags = ImGuiNextWindowDataFlags.None; }
}

enum ImGuiNextItemDataFlags
{
    None     = 0,
    HasWidth = 1 << 0,
    HasOpen  = 1 << 1
}

struct ImGuiNextItemData
{
    nothrow:
    @nogc:

    ImGuiNextItemDataFlags      Flags;
    float                       Width = 0;          // Set by SetNextItemWidth()
    ImGuiID                     FocusScopeId;   // Set by SetNextItemMultiSelectData() (!= 0 signify value has been set, so it's an alternate version of HasSelectionData, we don't use Flags for this because they are cleared too early. This is mostly used for debugging)
    ImGuiCond                   OpenCond;
    bool                        OpenVal;        // Set by SetNextItemOpen()

    // this()         { memset(&this, 0, (this).sizeof); }
    pragma(inline, true) void ClearFlags()    { Flags = ImGuiNextItemDataFlags.None; } // Also cleared manually by ItemAdd()!
}

//-----------------------------------------------------------------------------
// Tabs
//-----------------------------------------------------------------------------

struct ImGuiShrinkWidthItem
{
    int             Index;
    float           Width;
}

struct ImGuiPtrOrIndex
{
    nothrow:
    @nogc:

    void*           Ptr;                // Either field can be set, not both. e.g. Dock node tab bars are loose while BeginTabBar() ones are in a pool.
    int             Index;              // Usually index in a main pool.

    this(void* ptr)          { Ptr = ptr; Index = -1; }
    this(int index)          { Ptr = NULL; Index = index; }
}

//-----------------------------------------------------------------------------
// Main Dear ImGui context
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

    // Windows state
    ImVector!(ImGuiWindow*)  Windows;                            // Windows, sorted in display order, back to front
    ImVector!(ImGuiWindow*)  WindowsFocusOrder;                  // Windows, sorted in focus order, back to front. (FIXME: We could only store root windows here! Need to sort out the Docking equivalent which is RootWindowDockStop and is unfortunately a little more dynamic)
    ImVector!(ImGuiWindow*)  WindowsTempSortBuffer;              // Temporary buffer used in EndFrame() to reorder windows so parents are kept before their child
    ImVector!(ImGuiWindow*)  CurrentWindowStack;
    ImGuiStorage            WindowsById;                        // Map window's ImGuiID to ImGuiWindow*
    int                     WindowsActiveCount;                 // Number of unique windows submitted by frame
    ImGuiWindow*            CurrentWindow;                      // Window being drawn into
    ImGuiWindow*            HoveredWindow;                      // Will catch mouse inputs
    ImGuiWindow*            HoveredRootWindow;                  // Will catch mouse inputs (for focus/move only)
    ImGuiWindow*            MovingWindow;                       // Track the window we clicked on (in order to preserve focus). The actually window that is moved is generally MovingWindow->RootWindow.
    ImGuiWindow*            WheelingWindow;                     // Track the window we started mouse-wheeling on. Until a timer elapse or mouse has moved, generally keep scrolling the same window even if during the course of scrolling the mouse ends up hovering a child window.
    ImVec2                  WheelingWindowRefMousePos;
    float                   WheelingWindowTimer;

    // Item/widgets state and tracking information
    ImGuiID                 HoveredId;                          // Hovered widget
    bool                    HoveredIdAllowOverlap;
    ImGuiID                 HoveredIdPreviousFrame;
    float                   HoveredIdTimer;                     // Measure contiguous hovering time
    float                   HoveredIdNotActiveTimer;            // Measure contiguous hovering time where the item has not been active
    ImGuiID                 ActiveId;                           // Active widget
    ImGuiID                 ActiveIdIsAlive;                    // Active widget has been seen this frame (we can't use a bool as the ActiveId may change within the frame)
    float                   ActiveIdTimer;
    bool                    ActiveIdIsJustActivated;            // Set at the time of activation for one frame
    bool                    ActiveIdAllowOverlap;               // Active widget allows another widget to steal active id (generally for overlapping widgets, but not always)
    bool                    ActiveIdHasBeenPressedBefore;       // Track whether the active id led to a press (this is to allow changing between PressOnClick and PressOnRelease without pressing twice). Used by range_select branch.
    bool                    ActiveIdHasBeenEditedBefore;        // Was the value associated to the widget Edited over the course of the Active state.
    bool                    ActiveIdHasBeenEditedThisFrame;
    ImU32                   ActiveIdUsingNavDirMask;            // Active widget will want to read those nav move requests (e.g. can activate a button and move away from it)
    ImU32                   ActiveIdUsingNavInputMask;          // Active widget will want to read those nav inputs.
    ImU64                   ActiveIdUsingKeyInputMask;          // Active widget will want to read those key inputs. When we grow the ImGuiKey enum we'll need to either to order the enum to make useful keys come first, either redesign this into e.g. a small array.
    ImVec2                  ActiveIdClickOffset;                // Clicked offset from upper-left corner, if applicable (currently only set by ButtonBehavior)
    ImGuiWindow*            ActiveIdWindow;
    ImGuiInputSource        ActiveIdSource;                     // Activating with mouse or nav (gamepad/keyboard)
    ImGuiMouseButton                     ActiveIdMouseButton;
    ImGuiID                 ActiveIdPreviousFrame;
    bool                    ActiveIdPreviousFrameIsAlive;
    bool                    ActiveIdPreviousFrameHasBeenEditedBefore;
    ImGuiWindow*            ActiveIdPreviousFrameWindow;
    ImGuiID                 LastActiveId;                       // Store the last non-zero ActiveId, useful for animation.
    float                   LastActiveIdTimer;                  // Store the last non-zero ActiveId timer since the beginning of activation, useful for animation.

    // Next window/item data
    ImGuiNextWindowData     NextWindowData;                     // Storage for SetNextWindow** functions
    ImGuiNextItemData       NextItemData;                       // Storage for SetNextItem** functions

    // Shared stacks
    ImVector!ImGuiColorMod ColorModifiers;                     // Stack for PushStyleColor()/PopStyleColor()
    ImVector!ImGuiStyleMod StyleModifiers;                     // Stack for PushStyleVar()/PopStyleVar()
    ImVector!(ImFont*)       FontStack;                          // Stack for PushFont()/PopFont()
    ImVector!ImGuiPopupData OpenPopupStack;                     // Which popups are open (persistent)
    ImVector!ImGuiPopupData BeginPopupStack;                    // Which level of BeginPopup() we are in (reset every frame)

    // Gamepad/keyboard Navigation
    ImGuiWindow*            NavWindow;                          // Focused window for navigation. Could be called 'FocusWindow'
    ImGuiID                 NavId;                              // Focused item for navigation
    ImGuiID                 NavFocusScopeId;
    ImGuiID                 NavActivateId;                      // ~~ (g.ActiveId == 0) && IsNavInputPressed(ImGuiNavInput_Activate) ? NavId : 0, also set when calling ActivateItem()
    ImGuiID                 NavActivateDownId;                  // ~~ IsNavInputDown(ImGuiNavInput_Activate) ? NavId : 0
    ImGuiID                 NavActivatePressedId;               // ~~ IsNavInputPressed(ImGuiNavInput_Activate) ? NavId : 0
    ImGuiID                 NavInputId;                         // ~~ IsNavInputPressed(ImGuiNavInput_Input) ? NavId : 0
    ImGuiID                 NavJustTabbedId;                    // Just tabbed to this id.
    ImGuiID                 NavJustMovedToId;                   // Just navigated to this id (result of a successfully MoveRequest).
    ImGuiID                 NavJustMovedToFocusScopeId;         // Just navigated to this focus scope id (result of a successfully MoveRequest).
    ImGuiKeyModFlags        NavJustMovedToKeyMods;
    ImGuiID                 NavNextActivateId;                  // Set by ActivateItem(), queued until next frame.
    ImGuiInputSource        NavInputSource;                     // Keyboard or Gamepad mode? THIS WILL ONLY BE None or NavGamepad or NavKeyboard.
    ImRect                  NavScoringRect;                     // Rectangle used for scoring, in screen space. Based of window->DC.NavRefRectRel[], modified for directional navigation scoring.
    int                     NavScoringCount;                    // Metrics for debugging
    ImGuiNavLayer           NavLayer;                           // Layer we are navigating on. For now the system is hard-coded for 0=main contents and 1=menu/title bar, may expose layers later.
    int                     NavIdTabCounter;                    // == NavWindow->DC.FocusIdxTabCounter at time of NavId processing
    bool                    NavIdIsAlive;                       // Nav widget has been seen this frame ~~ NavRefRectRel is valid
    bool                    NavMousePosDirty;                   // When set we will update mouse position if (io.ConfigFlags & ImGuiConfigFlags_NavEnableSetMousePos) if set (NB: this not enabled by default)
    bool                    NavDisableHighlight;                // When user starts using mouse, we hide gamepad/keyboard highlight (NB: but they are still available, which is why NavDisableHighlight isn't always != NavDisableMouseHover)
    bool                    NavDisableMouseHover;               // When user starts using gamepad/keyboard, we hide mouse hovering highlight until mouse is touched again.
    bool                    NavAnyRequest;                      // ~~ NavMoveRequest || NavInitRequest
    bool                    NavInitRequest;                     // Init request for appearing window to select first item
    bool                    NavInitRequestFromMove;
    ImGuiID                 NavInitResultId;
    ImRect                  NavInitResultRectRel;
    bool                    NavMoveFromClampedRefRect;          // Set by manual scrolling, if we scroll to a point where NavId isn't visible we reset navigation from visible items
    bool                    NavMoveRequest;                     // Move request for this frame
    ImGuiNavMoveFlags       NavMoveRequestFlags;
    ImGuiNavForward         NavMoveRequestForward;              // None / ForwardQueued / ForwardActive (this is used to navigate sibling parent menus from a child menu)
    ImGuiKeyModFlags        NavMoveRequestKeyMods;
    ImGuiDir                NavMoveDir, NavMoveDirLast;         // Direction of the move request (left/right/up/down), direction of the previous move request
    ImGuiDir                NavMoveClipDir;                     // FIXME-NAV: Describe the purpose of this better. Might want to rename?
    ImGuiNavMoveResult      NavMoveResultLocal;                 // Best move request candidate within NavWindow
    ImGuiNavMoveResult      NavMoveResultLocalVisibleSet;       // Best move request candidate within NavWindow that are mostly visible (when using ImGuiNavMoveFlags_AlsoScoreVisibleSet flag)
    ImGuiNavMoveResult      NavMoveResultOther;                 // Best move request candidate within NavWindow's flattened hierarchy (when using ImGuiWindowFlags_NavFlattened flag)

    // Navigation: Windowing (CTRL+TAB, holding Menu button + directional pads to move/resize)
    ImGuiWindow*            NavWindowingTarget;                 // When selecting a window (holding Menu+FocusPrev/Next, or equivalent of CTRL-TAB) this window is temporarily displayed top-most.
    ImGuiWindow*            NavWindowingTargetAnim;             // Record of last valid NavWindowingTarget until DimBgRatio and NavWindowingHighlightAlpha becomes 0.0f
    ImGuiWindow*            NavWindowingList;
    float                   NavWindowingTimer;
    float                   NavWindowingHighlightAlpha;
    bool                    NavWindowingToggleLayer;

    // Legacy Focus/Tabbing system (older than Nav, active even if Nav is disabled, misnamed. FIXME-NAV: This needs a redesign!)
    ImGuiWindow*            FocusRequestCurrWindow;             //
    ImGuiWindow*            FocusRequestNextWindow;             //
    int                     FocusRequestCurrCounterRegular;     // Any item being requested for focus, stored as an index (we on layout to be stable between the frame pressing TAB and the next frame, semi-ouch)
    int                     FocusRequestCurrCounterTabStop;     // Tab item being requested for focus, stored as an index
    int                     FocusRequestNextCounterRegular;     // Stored for next frame
    int                     FocusRequestNextCounterTabStop;     // "
    bool                    FocusTabPressed;                    //

    // Render
    ImDrawData              DrawData;                           // Main ImDrawData instance to pass render information to the user
    ImDrawDataBuilder       DrawDataBuilder;
    float                   DimBgRatio;                         // 0.0..1.0 animation when fading in a dimming background (for modal window and CTRL+TAB list)
    ImDrawList              BackgroundDrawList;                 // First draw list to be rendered.
    ImDrawList              ForegroundDrawList;                 // Last draw list to be rendered. This is where we the render software mouse cursor (if io.MouseDrawCursor is set) and most debug overlays.
    ImGuiMouseCursor        MouseCursor;

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
    ImVector!ubyte DragDropPayloadBufHeap;             // We don't expose the ImVector<> directly, ImGuiPayload only holds pointer+size
    ubyte[16]           DragDropPayloadBufLocal;        // Local buffer for small payloads

    // Tab bars
    ImGuiTabBar*                    CurrentTabBar;
    ImPool!ImGuiTabBar             TabBars;
    ImVector!ImGuiPtrOrIndex       CurrentTabBarStack;
    ImVector!ImGuiShrinkWidthItem  ShrinkWidthBuffer;

    // Widget state
    ImVec2                  LastValidMousePos;
    ImGuiInputTextState     InputTextState;
    ImFont                  InputTextPasswordFont;
    ImGuiID                 TempInputId;                        // Temporary text input when CTRL+clicking on a slider, etc.
    ImGuiColorEditFlags     ColorEditOptions;                   // Store user options for color edit widgets
    float                   ColorEditLastHue;                   // Backup of last Hue associated to LastColor[3], so we can restore Hue in lossy RGB<>HSV round trips
    float                   ColorEditLastSat;                   // Backup of last Saturation associated to LastColor[3], so we can restore Saturation in lossy RGB<>HSV round trips
    float[3]                   ColorEditLastColor;
    ImVec4                  ColorPickerRef;                     // Initial/reference color at the time of opening the color picker.
    bool                    DragCurrentAccumDirty;
    float                   DragCurrentAccum;                   // Accumulator for dragging modification. Always high-precision, not rounded by end-user precision settings
    float                   DragSpeedDefaultRatio;              // If speed == 0.0f, uses (max-min) * DragSpeedDefaultRatio
    float                   ScrollbarClickDeltaToGrabCenter;    // Distance between mouse and center of grab box, normalized in parent space. Use storage?
    int                     TooltipOverrideCount;
    ImVector!char          ClipboardHandlerData;               // If no custom clipboard handler is defined
    ImVector!ImGuiID       MenusIdSubmittedThisFrame;          // A list of menu IDs that were rendered at least once

    // Platform support
    ImVec2                  PlatformImePos;                     // Cursor position request & last passed to the OS Input Method Editor
    ImVec2                  PlatformImeLastPos;

    // Settings
    bool                    SettingsLoaded;
    float                   SettingsDirtyTimer;                 // Save .ini Settings to memory when time reaches zero
    ImGuiTextBuffer         SettingsIniData;                    // In memory .ini settings
    ImVector!ImGuiSettingsHandler      SettingsHandlers;       // List of .ini settings handlers
    ImChunkStream!ImGuiWindowSettings  SettingsWindows;        // ImGuiWindow .ini settings entries

    // Capture/Logging
    bool                    LogEnabled;
    ImGuiLogType            LogType;
    ImFileHandle            LogFile;                            // If != NULL log to stdout/ file
    ImGuiTextBuffer         LogBuffer;                          // Accumulation buffer when log to clipboard. This is pointer so our GImGui static constructor doesn't call heap allocators.
    float                   LogLinePosY;
    bool                    LogLineFirstItem;
    int                     LogDepthRef;
    int                     LogDepthToExpand;
    int                     LogDepthToExpandDefault;            // Default/stored value for LogDepthMaxExpand if not specified in the LogXXX function call.

    // Debug Tools
    bool                    DebugItemPickerActive;
    ImGuiID                 DebugItemPickerBreakId;             // Will call IM_DEBUG_BREAK() when encountering this id

    // Misc
    float[120]                   FramerateSecPerFrame;          // Calculate estimate of framerate for user over the last 2 seconds.
    int                     FramerateSecPerFrameIdx;
    float                   FramerateSecPerFrameAccum;
    int                     WantCaptureMouseNextFrame;          // Explicit capture via CaptureKeyboardFromApp()/CaptureMouseFromApp() sets those flags
    int                     WantCaptureKeyboardNextFrame;
    int                     WantTextInputNextFrame;
    char[1024*3+1]                    TempBuffer;               // Temporary text buffer

    this(ImFontAtlas* shared_font_atlas)
    {
        IO = ImGuiIO(false);
        Style = ImGuiStyle(false);
        InputTextPasswordFont = ImFont(false);
        DrawListSharedData = ImDrawListSharedData(false);

        BackgroundDrawList = ImDrawList(&DrawListSharedData);
        ForegroundDrawList = ImDrawList(&DrawListSharedData);

        Initialized = false;
        Font = NULL;
        FontSize = FontBaseSize = 0.0f;
        FontAtlasOwnedByContext = shared_font_atlas ? false : true;
        IO.Fonts = shared_font_atlas ? shared_font_atlas : IM_NEW!ImFontAtlas(false);
        Time = 0.0f;
        FrameCount = 0;
        FrameCountEnded = FrameCountRendered = -1;
        WithinFrameScope = WithinFrameScopeWithImplicitWindow = WithinEndChild = false;

        WindowsActiveCount = 0;
        CurrentWindow = NULL;
        HoveredWindow = NULL;
        HoveredRootWindow = NULL;
        MovingWindow = NULL;
        WheelingWindow = NULL;
        WheelingWindowTimer = 0.0f;

        HoveredId = 0;
        HoveredIdAllowOverlap = false;
        HoveredIdPreviousFrame = 0;
        HoveredIdTimer = HoveredIdNotActiveTimer = 0.0f;
        ActiveId = 0;
        ActiveIdIsAlive = 0;
        ActiveIdTimer = 0.0f;
        ActiveIdIsJustActivated = false;
        ActiveIdAllowOverlap = false;
        ActiveIdHasBeenPressedBefore = false;
        ActiveIdHasBeenEditedBefore = false;
        ActiveIdHasBeenEditedThisFrame = false;
        ActiveIdUsingNavDirMask = 0x00;
        ActiveIdUsingNavInputMask = 0x00;
        ActiveIdUsingKeyInputMask = 0x00;
        ActiveIdClickOffset = ImVec2(-1,-1);
        ActiveIdWindow = NULL;
        ActiveIdSource = ImGuiInputSource.None;
        ActiveIdMouseButton = ImGuiMouseButton.None;
        ActiveIdPreviousFrame = 0;
        ActiveIdPreviousFrameIsAlive = false;
        ActiveIdPreviousFrameHasBeenEditedBefore = false;
        ActiveIdPreviousFrameWindow = NULL;
        LastActiveId = 0;
        LastActiveIdTimer = 0.0f;

        NavWindow = NULL;
        NavId = NavFocusScopeId = NavActivateId = NavActivateDownId = NavActivatePressedId = NavInputId = 0;
        NavJustTabbedId = NavJustMovedToId = NavJustMovedToFocusScopeId = NavNextActivateId = 0;
        NavJustMovedToKeyMods = ImGuiKeyModFlags.None;
        NavInputSource = ImGuiInputSource.None;
        NavScoringRect = ImRect();
        NavScoringCount = 0;
        NavLayer = ImGuiNavLayer.Main;
        NavIdTabCounter = INT_MAX;
        NavIdIsAlive = false;
        NavMousePosDirty = false;
        NavDisableHighlight = true;
        NavDisableMouseHover = false;
        NavAnyRequest = false;
        NavInitRequest = false;
        NavInitRequestFromMove = false;
        NavInitResultId = 0;
        NavMoveFromClampedRefRect = false;
        NavMoveRequest = false;
        NavMoveRequestFlags = ImGuiNavMoveFlags.None;
        NavMoveRequestForward = ImGuiNavForward.None;
        NavMoveRequestKeyMods = ImGuiKeyModFlags.None;
        NavMoveDir = NavMoveDirLast = NavMoveClipDir = ImGuiDir.None;

        NavWindowingTarget = NavWindowingTargetAnim = NavWindowingList = NULL;
        NavWindowingTimer = NavWindowingHighlightAlpha = 0.0f;
        NavWindowingToggleLayer = false;

        FocusRequestCurrWindow = FocusRequestNextWindow = NULL;
        FocusRequestCurrCounterRegular = FocusRequestCurrCounterTabStop = INT_MAX;
        FocusRequestNextCounterRegular = FocusRequestNextCounterTabStop = INT_MAX;
        FocusTabPressed = false;

        DimBgRatio = 0.0f;
        BackgroundDrawList._OwnerName = "##Background"; // Give it a name for debugging
        ForegroundDrawList._OwnerName = "##Foreground"; // Give it a name for debugging
        MouseCursor = ImGuiMouseCursor.Arrow;

        DragDropActive = DragDropWithinSource = DragDropWithinTarget = false;
        DragDropSourceFlags = ImGuiDragDropFlags.None;
        DragDropSourceFrameCount = -1;
        DragDropMouseButton = ImGuiMouseButton.None;
        DragDropTargetId = 0;
        DragDropAcceptFlags = ImGuiDragDropFlags.None;
        DragDropAcceptIdCurrRectSurface = 0.0f;
        DragDropAcceptIdPrev = DragDropAcceptIdCurr = 0;
        DragDropAcceptFrameCount = -1;
        memset(&DragDropPayloadBufLocal, 0, (DragDropPayloadBufLocal).sizeof);

        CurrentTabBar = NULL;

        LastValidMousePos = ImVec2(0.0f, 0.0f);
        TempInputId = 0;
        ColorEditOptions = ImGuiColorEditFlags._OptionsDefault;
        ColorEditLastHue = ColorEditLastSat = 0.0f;
        ColorEditLastColor[0] = ColorEditLastColor[1] = ColorEditLastColor[2] = FLT_MAX;
        DragCurrentAccumDirty = false;
        DragCurrentAccum = 0.0f;
        DragSpeedDefaultRatio = 1.0f / 100.0f;
        ScrollbarClickDeltaToGrabCenter = 0.0f;
        TooltipOverrideCount = 0;

        PlatformImePos = PlatformImeLastPos = ImVec2(FLT_MAX, FLT_MAX); // TODO D_IMGUI: This was broken in older D compilers. Is this fixed now?

        SettingsLoaded = false;
        SettingsDirtyTimer = 0.0f;

        LogEnabled = false;
        LogType = ImGuiLogType.None;
        LogFile = NULL;
        LogLinePosY = FLT_MAX;
        LogLineFirstItem = false;
        LogDepthRef = 0;
        LogDepthToExpand = LogDepthToExpandDefault = 2;

        DebugItemPickerActive = false;
        DebugItemPickerBreakId = 0;

        memset(FramerateSecPerFrame.ptr, 0, (FramerateSecPerFrame).sizeof);
        FramerateSecPerFrameIdx = 0;
        FramerateSecPerFrameAccum = 0.0f;
        WantCaptureMouseNextFrame = WantCaptureKeyboardNextFrame = WantTextInputNextFrame = -1;
        memset(TempBuffer.ptr, 0, (TempBuffer).sizeof);
    }

    void destroy() {
        Windows.destroy();
        WindowsFocusOrder.destroy();
        WindowsTempSortBuffer.destroy();
        CurrentWindowStack.destroy();
        ColorModifiers.destroy();
        StyleModifiers.destroy();
        FontStack.destroy();
        OpenPopupStack.destroy();
        BeginPopupStack.destroy(); 
        DragDropPayloadBufHeap.destroy();
        CurrentTabBarStack.destroy();
        ShrinkWidthBuffer.destroy();
        ClipboardHandlerData.destroy();
        MenusIdSubmittedThisFrame.destroy();
        SettingsHandlers.destroy();

        IO.destroy();
        SettingsIniData.destroy();
        LogBuffer.destroy();
        WindowsById.destroy();
        BackgroundDrawList.destroy();
        ForegroundDrawList.destroy();
        DrawData.destroy();
        InputTextPasswordFont.destroy();
        TabBars.destroy();
        SettingsWindows.destroy();
        InputTextState.destroy();
        DrawDataBuilder.destroy();
    }
}

//-----------------------------------------------------------------------------
// ImGuiWindow
//-----------------------------------------------------------------------------

// Transient per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the DC variable name in ImGuiWindow.
// FIXME: That's theory, in practice the delimitation between ImGuiWindow and ImGuiWindowTempData is quite tenuous and could be reconsidered.
struct ImGuiWindowTempData
{
    nothrow:
    @nogc:

    // Layout
    ImVec2                  CursorPos;              // Current emitting position, in absolute coordinates.
    ImVec2                  CursorPosPrevLine;
    ImVec2                  CursorStartPos;         // Initial position after Begin(), generally ~ window position + WindowPadding.
    ImVec2                  CursorMaxPos;           // Used to implicitly calculate the size of our contents, always growing during the frame. Used to calculate window->ContentSize at the beginning of next frame
    ImVec2                  CurrLineSize;
    ImVec2                  PrevLineSize;
    float                   CurrLineTextBaseOffset; // Baseline offset (0.0f by default on a new line, generally == style.FramePadding.y when a framed item has been added).
    float                   PrevLineTextBaseOffset;
    ImVec1                  Indent;                 // Indentation / start position from left of window (increased by TreePush/TreePop, etc.)
    ImVec1                  ColumnsOffset;          // Offset to the current column (if ColumnsCurrent > 0). FIXME: This and the above should be a stack to allow use cases like Tree->Column->Tree. Need revamp columns API.
    ImVec1                  GroupOffset;

    // Last item status
    ImGuiID                 LastItemId;             // ID for last item
    ImGuiItemStatusFlags    LastItemStatusFlags;    // Status flags for last item (see ImGuiItemStatusFlags_)
    ImRect                  LastItemRect;           // Interaction rect for last item
    ImRect                  LastItemDisplayRect;    // End-user display rect for last item (only valid if LastItemStatusFlags & ImGuiItemStatusFlags_HasDisplayRect)

    // Keyboard/Gamepad navigation
    ImGuiNavLayer           NavLayerCurrent;        // Current layer, 0..31 (we currently only use 0..1)
    int                     NavLayerCurrentMask;    // = (1 << NavLayerCurrent) used by ItemAdd prior to clipping.
    int                     NavLayerActiveMask;     // Which layer have been written to (result from previous frame)
    int                     NavLayerActiveMaskNext; // Which layer have been written to (buffer for current frame)
    ImGuiID                 NavFocusScopeIdCurrent; // Current focus scope ID while appending
    bool                    NavHideHighlightOneFrame;
    bool                    NavHasScroll;           // Set when scrolling can be used (ScrollMax > 0.0f)

    // Miscellaneous
    bool                    MenuBarAppending;       // FIXME: Remove this
    ImVec2                  MenuBarOffset;          // MenuBarOffset.x is sort of equivalent of a per-layer CursorPos.x, saved/restored as we switch to the menu bar. The only situation when MenuBarOffset.y is > 0 if when (SafeAreaPadding.y > FramePadding.y), often used on TVs.
    ImGuiMenuColumns        MenuColumns;            // Simplified columns storage for menu items measurement
    int                     TreeDepth;              // Current tree depth.
    ImU32                   TreeJumpToParentOnPopMask; // Store a copy of !g.NavIdIsAlive for TreeDepth 0..31.. Could be turned into a ImU64 if necessary.
    ImVector!(ImGuiWindow*)  ChildWindows;
    ImGuiStorage*           StateStorage;           // Current persistent per-window storage (store e.g. tree node open/close state)
    ImGuiColumns*           CurrentColumns;         // Current columns set
    ImGuiLayoutType         LayoutType;
    ImGuiLayoutType         ParentLayoutType;       // Layout type of parent window at the time of Begin()
    int                     FocusCounterRegular;    // (Legacy Focus/Tabbing system) Sequential counter, start at -1 and increase as assigned via FocusableItemRegister() (FIXME-NAV: Needs redesign)
    int                     FocusCounterTabStop;    // (Legacy Focus/Tabbing system) Same, but only count widgets which you can Tab through.

    // Local parameters stacks
    // We store the current settings outside of the vectors to increase memory locality (reduce cache misses). The vectors are rarely modified. Also it allows us to not heap allocate for short-lived windows which are not using those settings.
    ImGuiItemFlags          ItemFlags;              // == ItemFlagsStack.back() [empty == ImGuiItemFlags_Default]
    float                   ItemWidth;              // == ItemWidthStack.back(). 0.0: default, >0.0: width in pixels, <0.0: align xx pixels to the right of window
    float                   TextWrapPos;            // == TextWrapPosStack.back() [empty == -1.0f]
    ImVector!ImGuiItemFlags ItemFlagsStack;
    ImVector!float         ItemWidthStack;
    ImVector!float         TextWrapPosStack;
    ImVector!ImGuiGroupData GroupStack;
    short[6]                   StackSizesBackup;    // Store size of various stacks for asserting

    @disable this();
    this(bool dummy)
    {
        CursorPos = CursorPosPrevLine = CursorStartPos = CursorMaxPos = ImVec2(0.0f, 0.0f);
        CurrLineSize = PrevLineSize = ImVec2(0.0f, 0.0f);
        CurrLineTextBaseOffset = PrevLineTextBaseOffset = 0.0f;
        Indent = ImVec1(0.0f);
        ColumnsOffset = ImVec1(0.0f);
        GroupOffset = ImVec1(0.0f);

        LastItemId = 0;
        LastItemStatusFlags = ImGuiItemStatusFlags.None;
        LastItemRect = LastItemDisplayRect = ImRect();

        NavLayerActiveMask = NavLayerActiveMaskNext = 0x00;
        NavLayerCurrent = ImGuiNavLayer.Main;
        NavLayerCurrentMask = (1 << ImGuiNavLayer.Main);
        NavFocusScopeIdCurrent = 0;
        NavHideHighlightOneFrame = false;
        NavHasScroll = false;

        MenuBarAppending = false;
        MenuBarOffset = ImVec2(0.0f, 0.0f);
        TreeDepth = 0;
        TreeJumpToParentOnPopMask = 0x00;
        StateStorage = NULL;
        CurrentColumns = NULL;
        LayoutType = ParentLayoutType = ImGuiLayoutType.Vertical;
        FocusCounterRegular = FocusCounterTabStop = -1;

        ItemFlags = ImGuiItemFlags.Default_;
        ItemWidth = 0.0f;
        TextWrapPos = -1.0f;
        memset(StackSizesBackup.ptr, 0, (StackSizesBackup).sizeof);
    }

    void destroy() {
        ChildWindows.destroy();
        ItemFlagsStack.destroy();
        ItemWidthStack.destroy();
        TextWrapPosStack.destroy();
        GroupStack.destroy();
    }
}

// Storage for one window
struct ImGuiWindow
{
    nothrow:
    @nogc:

    string                  Name;                               // Window name, owned by the window.
    char[]                  NameBuf;
    ImGuiID                 ID;                                 // == ImHashStr(Name)
    ImGuiWindowFlags        Flags;                              // See enum ImGuiWindowFlags_
    ImVec2                  Pos;                                // Position (always rounded-up to nearest pixel)
    ImVec2                  Size;                               // Current size (==SizeFull or collapsed title bar size)
    ImVec2                  SizeFull;                           // Size when non collapsed
    ImVec2                  ContentSize;                        // Size of contents/scrollable client area (calculated from the extents reach of the cursor) from previous frame. Does not include window decoration or window padding.
    ImVec2                  ContentSizeExplicit;                // Size of contents/scrollable client area explicitly request by the user via SetNextWindowContentSize().
    ImVec2                  WindowPadding;                      // Window padding at the time of Begin().
    float                   WindowRounding;                     // Window rounding at the time of Begin().
    float                   WindowBorderSize;                   // Window border size at the time of Begin().
    // int                     NameBufLen;                         // Size of buffer storing Name. May be larger than strlen(Name)!
    ImGuiID                 MoveId;                             // == window->GetID("#MOVE")
    ImGuiID                 ChildId;                            // ID of corresponding item in parent window (for navigation to return from child window to parent window)
    ImVec2                  Scroll;
    ImVec2                  ScrollMax;
    ImVec2                  ScrollTarget;                       // target scroll position. stored as cursor position with scrolling canceled out, so the highest point is always 0.0f. (FLT_MAX for no change)
    ImVec2                  ScrollTargetCenterRatio;            // 0.0f = scroll so that target position is at top, 0.5f = scroll so that target position is centered
    ImVec2                  ScrollbarSizes;                     // Size taken by each scrollbars on their smaller axis. Pay attention! ScrollbarSizes.x == width of the vertical scrollbar, ScrollbarSizes.y = height of the horizontal scrollbar.
    bool                    ScrollbarX, ScrollbarY;             // Are scrollbars visible?
    bool                    Active;                             // Set to true on Begin(), unless Collapsed
    bool                    WasActive;
    bool                    WriteAccessed;                      // Set to true when any widget access the current window
    bool                    Collapsed;                          // Set when collapsing window to become only title-bar
    bool                    WantCollapseToggle;
    bool                    SkipItems;                          // Set when items can safely be all clipped (e.g. window not visible or collapsed)
    bool                    Appearing;                          // Set during the frame where the window is appearing (or re-appearing)
    bool                    Hidden;                             // Do not display (== (HiddenFrames*** > 0))
    bool                    IsFallbackWindow;                   // Set on the "Debug##Default" window.
    bool                    HasCloseButton;                     // Set when the window has a close button (p_open != NULL)
    byte             ResizeBorderHeld;                   // Current border being held for resize (-1: none, otherwise 0-3)
    short                   BeginCount;                         // Number of Begin() during the current frame (generally 0 or 1, 1+ if appending via multiple Begin/End pairs)
    short                   BeginOrderWithinParent;             // Order within immediate parent window, if we are a child window. Otherwise 0.
    short                   BeginOrderWithinContext;            // Order within entire imgui context. This is mostly used for debugging submission order related issues.
    ImGuiID                 PopupId;                            // ID in the popup stack when this window is used as a popup/menu (because we use generic Name/ID for recycling)
    ImS8                    AutoFitFramesX, AutoFitFramesY;
    ImS8                    AutoFitChildAxises;
    bool                    AutoFitOnlyGrows;
    ImGuiDir                AutoPosLastDirection;
    int                     HiddenFramesCanSkipItems;           // Hide the window for N frames
    int                     HiddenFramesCannotSkipItems;        // Hide the window for N frames while allowing items to be submitted so we can measure their size
    ImGuiCond               SetWindowPosAllowFlags;             // store acceptable condition flags for SetNextWindowPos() use.
    ImGuiCond               SetWindowSizeAllowFlags;            // store acceptable condition flags for SetNextWindowSize() use.
    ImGuiCond               SetWindowCollapsedAllowFlags;       // store acceptable condition flags for SetNextWindowCollapsed() use.
    ImVec2                  SetWindowPosVal;                    // store window position when using a non-zero Pivot (position set needs to be processed when we know the window size)
    ImVec2                  SetWindowPosPivot;                  // store window pivot for positioning. ImVec2(0,0) when positioning from top-left corner; ImVec2(0.5f,0.5f) for centering; ImVec2(1,1) for bottom right.

    ImVector!ImGuiID       IDStack;                            // ID stack. ID are hashes seeded with the value at the top of the stack. (In theory this should be in the TempData structure)
    ImGuiWindowTempData     DC;                                 // Temporary per-window data, reset at the beginning of the frame. This used to be called ImGuiDrawContext, hence the "DC" variable name.

    // The best way to understand what those rectangles are is to use the 'Metrics -> Tools -> Show windows rectangles' viewer.
    // The main 'OuterRect', omitted as a field, is window->Rect().
    ImRect                  OuterRectClipped;                   // == Window->Rect() just after setup in Begin(). == window->Rect() for root window.
    ImRect                  InnerRect;                          // Inner rectangle (omit title bar, menu bar, scroll bar)
    ImRect                  InnerClipRect;                      // == InnerRect shrunk by WindowPadding*0.5f on each side, clipped within viewport or parent clip rect.
    ImRect                  WorkRect;                           // Cover the whole scrolling region, shrunk by WindowPadding*1.0f on each side. This is meant to replace ContentRegionRect over time (from 1.71+ onward).
    ImRect                  ClipRect;                           // Current clipping/scissoring rectangle, evolve as we are using PushClipRect(), etc. == DrawList->clip_rect_stack.back().
    ImRect                  ContentRegionRect;                  // FIXME: This is currently confusing/misleading. It is essentially WorkRect but not handling of scrolling. We currently rely on it as right/bottom aligned sizing operation need some size to rely on.

    int                     LastFrameActive;                    // Last frame number the window was Active.
    float                   LastTimeActive;                     // Last timestamp the window was Active (using float as we don't need high precision there)
    float                   ItemWidthDefault;
    ImGuiStorage            StateStorage;
    ImVector!ImGuiColumns  ColumnsStorage;
    float                   FontWindowScale;                    // User scale multiplier per-window, via SetWindowFontScale()
    int                     SettingsOffset;                     // Offset into SettingsWindows[] (offsets are always valid as we only grow the array from the back)

    ImDrawList*             DrawList;                           // == &DrawListInst (for backward compatibility reason with code using imgui_internal.h we keep this a pointer)
    ImDrawList              DrawListInst;
    ImGuiWindow*            ParentWindow;                       // If we are a child _or_ popup window, this is pointing to our parent. Otherwise NULL.
    ImGuiWindow*            RootWindow;                         // Point to ourself or first ancestor that is not a child window.
    ImGuiWindow*            RootWindowForTitleBarHighlight;     // Point to ourself or first ancestor which will display TitleBgActive color when this window is active.
    ImGuiWindow*            RootWindowForNav;                   // Point to ourself or first ancestor which doesn't have the NavFlattened flag.

    ImGuiWindow*            NavLastChildNavWindow;              // When going to the menu bar, we remember the child window we came from. (This could probably be made implicit if we kept g.Windows sorted by last focused including child window.)
    ImGuiID[ImGuiNavLayer.COUNT]                 NavLastIds;    // Last known NavId for this window, per layer (0/1)
    ImRect[ImGuiNavLayer.COUNT]                  NavRectRel;    // Reference rectangle, in window relative space

    bool                    MemoryCompacted;
    int                     MemoryDrawListIdxCapacity;
    int                     MemoryDrawListVtxCapacity;

    this(ImGuiContext* context, string name)
    {
        DC = ImGuiWindowTempData(false);

        DrawListInst = ImDrawList(&context.DrawListSharedData);

        NameBuf = ImStrdup(name);
        Name = cast(string)NameBuf[0..$-1];
        ID = ImHashStr(name);
        IDStack.push_back(ID);
        Flags = ImGuiWindowFlags.None;
        Pos = ImVec2(0.0f, 0.0f);
        Size = SizeFull = ImVec2(0.0f, 0.0f);
        ContentSize = ContentSizeExplicit = ImVec2(0.0f, 0.0f);
        WindowPadding = ImVec2(0.0f, 0.0f);
        WindowRounding = 0.0f;
        WindowBorderSize = 0.0f;
        //NameBufLen = cast(int)name.length + 1;
        MoveId = GetID("#MOVE");
        ChildId = 0;
        Scroll = ImVec2(0.0f, 0.0f);
        ScrollTarget = ImVec2(FLT_MAX, FLT_MAX);
        ScrollTargetCenterRatio = ImVec2(0.5f, 0.5f);
        ScrollbarSizes = ImVec2(0.0f, 0.0f);
        ScrollbarX = ScrollbarY = false;
        Active = WasActive = false;
        WriteAccessed = false;
        Collapsed = false;
        WantCollapseToggle = false;
        SkipItems = false;
        Appearing = false;
        Hidden = false;
        IsFallbackWindow = false;
        HasCloseButton = false;
        ResizeBorderHeld = -1;
        BeginCount = 0;
        BeginOrderWithinParent = -1;
        BeginOrderWithinContext = -1;
        PopupId = 0;
        AutoFitFramesX = AutoFitFramesY = -1;
        AutoFitChildAxises = 0x00;
        AutoFitOnlyGrows = false;
        AutoPosLastDirection = ImGuiDir.None;
        HiddenFramesCanSkipItems = HiddenFramesCannotSkipItems = 0;
        SetWindowPosAllowFlags = SetWindowSizeAllowFlags = SetWindowCollapsedAllowFlags = ImGuiCond.Always | ImGuiCond.Once | ImGuiCond.FirstUseEver | ImGuiCond.Appearing;
        SetWindowPosVal = SetWindowPosPivot = ImVec2(FLT_MAX, FLT_MAX);

        InnerRect = ImRect(0.0f, 0.0f, 0.0f, 0.0f); // Clear so the InnerRect.GetSize() code in Begin() doesn't lead to overflow even if the result isn't used.

        LastFrameActive = -1;
        ItemWidthDefault = 0.0f;
        FontWindowScale = 1.0f;
        SettingsOffset = -1;

        DrawList = &DrawListInst;
        DrawList._OwnerName = Name;
        ParentWindow = NULL;
        RootWindow = NULL;
        RootWindowForTitleBarHighlight = NULL;
        RootWindowForNav = NULL;

        NavLastIds[0] = NavLastIds[1] = 0;
        NavRectRel[0] = NavRectRel[1] = ImRect();
        NavLastChildNavWindow = NULL;
    
        MemoryCompacted = false;
        MemoryDrawListIdxCapacity = MemoryDrawListVtxCapacity = 0;
    }

    void destroy()
    {
        IM_ASSERT(DrawList == &DrawListInst);
        IM_FREE(NameBuf.ptr);
        for (int i = 0; i != ColumnsStorage.Size; i++)
            ColumnsStorage[i].destroy();

		DrawListInst.destroy();
        IDStack.destroy();
        ColumnsStorage.destroy();
        StateStorage.destroy();
        DC.destroy();
    }

    ImGuiID     GetID(string str)
    {
        ImGuiID seed = IDStack.back();
        ImGuiID id = ImHashStr(str, seed);
        KeepAliveID(id);
        return id;
    }

    ImGuiID     GetID(const void* ptr)
    {
        ImGuiID seed = IDStack.back();
        ImGuiID id = ImHashData(&ptr, (void*).sizeof, seed);
        KeepAliveID(id);
        return id;
    }

    ImGuiID     GetID(int n)
    {
        ImGuiID seed = IDStack.back();
        ImGuiID id = ImHashData(&n, (n).sizeof, seed);
        KeepAliveID(id);
        return id;
    }

    ImGuiID     GetIDNoKeepAlive(string str)
    {
        ImGuiID seed = IDStack.back();
        return ImHashStr(str, seed);
    }

    ImGuiID     GetIDNoKeepAlive(const void* ptr)
    {
        ImGuiID seed = IDStack.back();
        return ImHashData(&ptr, (void*).sizeof, seed);
    }

    ImGuiID     GetIDNoKeepAlive(int n)
    {
        ImGuiID seed = IDStack.back();
        return ImHashData(&n, (n).sizeof, seed);
    }

    ImGuiID     GetIDFromRectangle(const ImRect/*&*/ r_abs)
    {
        ImGuiID seed = IDStack.back();
        const int[4] r_rel = [ cast(int)(r_abs.Min.x - Pos.x), cast(int)(r_abs.Min.y - Pos.y), cast(int)(r_abs.Max.x - Pos.x), cast(int)(r_abs.Max.y - Pos.y) ];
        ImGuiID id = ImHashData(&r_rel, r_rel.sizeof, seed);
        KeepAliveID(id);
        return id;
    }

    // We don't use g.FontSize because the window may be != g.CurrentWidow.
    ImRect      Rect() const                { return ImRect(Pos.x, Pos.y, Pos.x+Size.x, Pos.y+Size.y); }
    float       CalcFontSize() const        { ImGuiContext* g = GImGui; float scale = g.FontBaseSize * FontWindowScale; if (ParentWindow) scale *= ParentWindow.FontWindowScale; return scale; }
    float       TitleBarHeight() const      { ImGuiContext* g = GImGui; return (Flags & ImGuiWindowFlags.NoTitleBar) ? 0.0f : CalcFontSize() + g.Style.FramePadding.y * 2.0f; }
    ImRect      TitleBarRect() const        { return ImRect(Pos, ImVec2(Pos.x + SizeFull.x, Pos.y + TitleBarHeight())); }
    float       MenuBarHeight() const       { ImGuiContext* g = GImGui; return (Flags & ImGuiWindowFlags.MenuBar) ? DC.MenuBarOffset.y + CalcFontSize() + g.Style.FramePadding.y * 2.0f : 0.0f; }
    ImRect      MenuBarRect() const         { float y1 = Pos.y + TitleBarHeight(); return ImRect(Pos.x, y1, Pos.x + SizeFull.x, y1 + MenuBarHeight()); }
}

// Backup and restore just enough data to be able to use IsItemHovered() on item A after another B in the same window has overwritten the data.
struct ImGuiItemHoveredDataBackup
{
    nothrow:
    @nogc:

    ImGuiID                 LastItemId;
    ImGuiItemStatusFlags    LastItemStatusFlags;
    ImRect                  LastItemRect;
    ImRect                  LastItemDisplayRect;

    @disable this();
    this(bool dummy) { Backup(); }
    void Backup()           { ImGuiWindow* window = GImGui.CurrentWindow; LastItemId = window.DC.LastItemId; LastItemStatusFlags = window.DC.LastItemStatusFlags; LastItemRect = window.DC.LastItemRect; LastItemDisplayRect = window.DC.LastItemDisplayRect; }
    void Restore() const    { ImGuiWindow* window = GImGui.CurrentWindow; window.DC.LastItemId = LastItemId; window.DC.LastItemStatusFlags = LastItemStatusFlags; window.DC.LastItemRect = LastItemRect; window.DC.LastItemDisplayRect = LastItemDisplayRect; }
}

//-----------------------------------------------------------------------------
// Tab bar, tab item
//-----------------------------------------------------------------------------

// D_IMGUI: Moved into ImGuiTabBarFlags
/+
// Extend ImGuiTabBarFlags_
enum ImGuiTabBarFlagsPrivate
{
    DockNode                   = 1 << 20,  // Part of a dock node [we don't use this in the master branch but it facilitate branch syncing to keep this around]
    IsFocused                  = 1 << 21,
    SaveSettings               = 1 << 22   // FIXME: Settings are handled by the docking system, this only request the tab bar to mark settings dirty when reordering tabs
}
+/

// D_IMGUI: Moved into ImGuiTabItemFlags
/+
// Extend ImGuiTabItemFlags_
enum ImGuiTabItemFlagsPrivate
{
    NoCloseButton             = 1 << 20   // Track whether p_open was set or not (we'll need this info on the next frame to recompute ContentWidth during layout)
}
+/

// Storage for one active tab item (sizeof() 26~32 bytes)
struct ImGuiTabItem
{
    ImGuiID             ID;
    ImGuiTabItemFlags   Flags;
    int                 LastFrameVisible = -1;
    int                 LastFrameSelected = -1;      // This allows us to infer an ordered list of the last activated tabs with little maintenance
    int                 NameOffset = -1;             // When Window==NULL, offset to name within parent ImGuiTabBar::TabsNames
    float               Offset = 0;                 // Position relative to beginning of tab
    float               Width = 0;                  // Width currently displayed
    float               ContentWidth = 0;           // Width of actual contents, stored during BeginTabItem() call

    // this()      { ID = 0; Flags = ImGuiTabItemFlags.None; LastFrameVisible = LastFrameSelected = -1; NameOffset = -1; Offset = Width = ContentWidth = 0.0f; }
}

// Storage for a tab bar (sizeof() 92~96 bytes)
struct ImGuiTabBar
{
    nothrow:
    @nogc:

    ImVector!ImGuiTabItem Tabs;
    ImGuiID             ID;                     // Zero for tab-bars used by docking
    ImGuiID             SelectedTabId;          // Selected tab/window
    ImGuiID             NextSelectedTabId;
    ImGuiID             VisibleTabId;           // Can occasionally be != SelectedTabId (e.g. when previewing contents for CTRL+TAB preview)
    int                 CurrFrameVisible;
    int                 PrevFrameVisible;
    ImRect              BarRect;
    float               LastTabContentHeight;   // Record the height of contents submitted below the tab bar
    float               OffsetMax;              // Distance from BarRect.Min.x, locked during layout
    float               OffsetMaxIdeal;         // Ideal offset if all tabs were visible and not clipped
    float               OffsetNextTab;          // Distance from BarRect.Min.x, incremented with each BeginTabItem() call, not used if ImGuiTabBarFlags_Reorderable if set.
    float               ScrollingAnim;
    float               ScrollingTarget;
    float               ScrollingTargetDistToVisibility;
    float               ScrollingSpeed;
    ImGuiTabBarFlags    Flags;
    ImGuiID             ReorderRequestTabId;
    ImS8                ReorderRequestDir;
    bool                WantLayout;
    bool                VisibleTabWasSubmitted;
    short               LastTabItemIdx;         // For BeginTabItem()/EndTabItem()
    ImVec2              FramePadding;           // style.FramePadding locked at the time of BeginTabBar()
    ImGuiTextBuffer     TabsNames;              // For non-docking tab bar we re-append names in a contiguous buffer.

    @disable this();
    this(bool dummy)
    {
        ID = 0;
        SelectedTabId = NextSelectedTabId = VisibleTabId = 0;
        CurrFrameVisible = PrevFrameVisible = -1;
        LastTabContentHeight = 0.0f;
        OffsetMax = OffsetMaxIdeal = OffsetNextTab = 0.0f;
        ScrollingAnim = ScrollingTarget = ScrollingTargetDistToVisibility = ScrollingSpeed = 0.0f;
        Flags = ImGuiTabBarFlags.None;
        ReorderRequestTabId = 0;
        ReorderRequestDir = 0;
        WantLayout = VisibleTabWasSubmitted = false;
        LastTabItemIdx = -1;
    }

    void destroy() {
        Tabs.destroy();
    }

    int                 GetTabOrder(const ImGuiTabItem* tab) const  { return Tabs.index_from_ptr(tab); }
    string         GetTabName(const ImGuiTabItem* tab) const
    {
        IM_ASSERT(tab.NameOffset != -1 && tab.NameOffset < TabsNames.Buf.Size);
        return ImCstring(TabsNames.Buf.Data + tab.NameOffset);
    }
}

//-----------------------------------------------------------------------------
// Internal API
// No guarantee of forward compatibility here.
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
    IMGUI_API ImGuiWindow*  FindWindowByID(ImGuiID id);
    IMGUI_API ImGuiWindow*  FindWindowByName(const char* name);
    IMGUI_API void          UpdateWindowParentAndRootLinks(ImGuiWindow* window, ImGuiWindowFlags flags, ImGuiWindow* parent_window);
    IMGUI_API ImVec2        CalcWindowExpectedSize(ImGuiWindow* window);
    IMGUI_API bool          IsWindowChildOf(ImGuiWindow* window, ImGuiWindow* potential_parent);
    IMGUI_API bool          IsWindowNavFocusable(ImGuiWindow* window);
    IMGUI_API ImRect        GetWindowAllowedExtentRect(ImGuiWindow* window);
    IMGUI_API void          SetWindowPos(ImGuiWindow* window, const ImVec2& pos, ImGuiCond cond = 0);
    IMGUI_API void          SetWindowSize(ImGuiWindow* window, const ImVec2& size, ImGuiCond cond = 0);
    IMGUI_API void          SetWindowCollapsed(ImGuiWindow* window, bool collapsed, ImGuiCond cond = 0);

    // Windows: Display Order and Focus Order
    IMGUI_API void          FocusWindow(ImGuiWindow* window);
    IMGUI_API void          FocusTopMostWindowUnderOne(ImGuiWindow* under_this_window, ImGuiWindow* ignore_window);
    IMGUI_API void          BringWindowToFocusFront(ImGuiWindow* window);
    IMGUI_API void          BringWindowToDisplayFront(ImGuiWindow* window);
    IMGUI_API void          BringWindowToDisplayBack(ImGuiWindow* window);

    // Fonts, drawing
    IMGUI_API void          SetCurrentFont(ImFont* font);
    +/

    pragma(inline, true) ImFont*          GetDefaultFont() { ImGuiContext* g = GImGui; return g.IO.FontDefault ? g.IO.FontDefault : g.IO.Fonts.Fonts[0]; }
    // D_IMGUI: D can't handle overloading between modules, so this is now GetForegroundDrawList2 instead of GetForegroundDrawList
    pragma(inline, true) ImDrawList*      GetForegroundDrawList2(ImGuiWindow* window) { IM_UNUSED(window); ImGuiContext* g = GImGui; return &g.ForegroundDrawList; } // This seemingly unnecessary wrapper simplifies compatibility between the 'master' and 'docking' branches.

    /+
    // Init
    IMGUI_API void          Initialize(ImGuiContext* context);
    IMGUI_API void          Shutdown(ImGuiContext* context);    // Since 1.60 this is a _private_ function. You can call DestroyContext() to destroy the context created by CreateContext().

    // NewFrame
    IMGUI_API void          UpdateHoveredWindowAndCaptureFlags();
    IMGUI_API void          StartMouseMovingWindow(ImGuiWindow* window);
    IMGUI_API void          UpdateMouseMovingWindowNewFrame();
    IMGUI_API void          UpdateMouseMovingWindowEndFrame();

    // Settings
    IMGUI_API void                  MarkIniSettingsDirty();
    IMGUI_API void                  MarkIniSettingsDirty(ImGuiWindow* window);
    IMGUI_API ImGuiWindowSettings*  CreateNewWindowSettings(const char* name);
    IMGUI_API ImGuiWindowSettings*  FindWindowSettings(ImGuiID id);
    IMGUI_API ImGuiWindowSettings*  FindOrCreateWindowSettings(const char* name);
    IMGUI_API ImGuiSettingsHandler* FindSettingsHandler(const char* type_name);

    // Scrolling
    IMGUI_API void          SetScrollX(ImGuiWindow* window, float new_scroll_x);
    IMGUI_API void          SetScrollY(ImGuiWindow* window, float new_scroll_y);
    IMGUI_API void          SetScrollFromPosX(ImGuiWindow* window, float local_x, float center_x_ratio = 0.5f);
    IMGUI_API void          SetScrollFromPosY(ImGuiWindow* window, float local_y, float center_y_ratio = 0.5f);
    IMGUI_API ImVec2        ScrollToBringRectIntoView(ImGuiWindow* window, const ImRect& item_rect);
    +/

    // Basic Accessors
    pragma(inline, true) ImGuiID          GetItemID()     { ImGuiContext* g = GImGui; return g.CurrentWindow.DC.LastItemId; }
    pragma(inline, true) ImGuiItemStatusFlags GetItemStatusFlags() { ImGuiContext* g = GImGui; return g.CurrentWindow.DC.LastItemStatusFlags; }
    pragma(inline, true) ImGuiID          GetActiveID()   { ImGuiContext* g = GImGui; return g.ActiveId; }
    pragma(inline, true) ImGuiID          GetFocusID()    { ImGuiContext* g = GImGui; return g.NavId; }

    /+
    IMGUI_API void          SetActiveID(ImGuiID id, ImGuiWindow* window);
    IMGUI_API void          SetFocusID(ImGuiID id, ImGuiWindow* window);
    IMGUI_API void          ClearActiveID();
    IMGUI_API ImGuiID       GetHoveredID();
    IMGUI_API void          SetHoveredID(ImGuiID id);
    IMGUI_API void          KeepAliveID(ImGuiID id);
    IMGUI_API void          MarkItemEdited(ImGuiID id);     // Mark data associated to given item as "edited", used by IsItemDeactivatedAfterEdit() function.
    IMGUI_API void          PushOverrideID(ImGuiID id);     // Push given value at the top of the ID stack (whereas PushID combines old and new hashes)

    // Basic Helpers for widget code
    IMGUI_API void          ItemSize(const ImVec2& size, float text_baseline_y = -1.0f);
    IMGUI_API void          ItemSize(const ImRect& bb, float text_baseline_y = -1.0f);
    IMGUI_API bool          ItemAdd(const ImRect& bb, ImGuiID id, const ImRect* nav_bb = NULL);
    IMGUI_API bool          ItemHoverable(const ImRect& bb, ImGuiID id);
    IMGUI_API bool          IsClippedEx(const ImRect& bb, ImGuiID id, bool clip_even_when_logged);
    IMGUI_API bool          FocusableItemRegister(ImGuiWindow* window, ImGuiID id);   // Return true if focus is requested
    IMGUI_API void          FocusableItemUnregister(ImGuiWindow* window);
    IMGUI_API ImVec2        CalcItemSize(ImVec2 size, float default_w, float default_h);
    IMGUI_API float         CalcWrapWidthForPos(const ImVec2& pos, float wrap_pos_x);
    IMGUI_API void          PushMultiItemsWidths(int components, float width_full);
    IMGUI_API void          PushItemFlag(ImGuiItemFlags option, bool enabled);
    IMGUI_API void          PopItemFlag();
    IMGUI_API bool          IsItemToggledSelection();                           // Was the last item selection toggled? (after Selectable(), TreeNode() etc. We only returns toggle _event_ in order to handle clipping correctly)
    IMGUI_API ImVec2        GetContentRegionMaxAbs();
    IMGUI_API void          ShrinkWidths(ImGuiShrinkWidthItem* items, int count, float width_excess);

    // Logging/Capture
    IMGUI_API void          LogBegin(ImGuiLogType type, int auto_open_depth);   // -> BeginCapture() when we design v2 api, for now stay under the radar by using the old name.
    IMGUI_API void          LogToBuffer(int auto_open_depth = -1);              // Start logging/capturing to internal buffer

    // Popups, Modals, Tooltips
    IMGUI_API bool          BeginChildEx(const char* name, ImGuiID id, const ImVec2& size_arg, bool border, ImGuiWindowFlags flags);
    IMGUI_API void          OpenPopupEx(ImGuiID id);
    IMGUI_API void          ClosePopupToLevel(int remaining, bool restore_focus_to_window_under_popup);
    IMGUI_API void          ClosePopupsOverWindow(ImGuiWindow* ref_window, bool restore_focus_to_window_under_popup);
    IMGUI_API bool          IsPopupOpen(ImGuiID id); // Test for id within current popup stack level (currently begin-ed into); this doesn't scan the whole popup stack!
    IMGUI_API bool          BeginPopupEx(ImGuiID id, ImGuiWindowFlags extra_flags);
    IMGUI_API void          BeginTooltipEx(ImGuiWindowFlags extra_flags, ImGuiTooltipFlags tooltip_flags);
    IMGUI_API ImGuiWindow*  GetTopMostPopupModal();
    IMGUI_API ImVec2        FindBestWindowPosForPopup(ImGuiWindow* window);
    IMGUI_API ImVec2        FindBestWindowPosForPopupEx(const ImVec2& ref_pos, const ImVec2& size, ImGuiDir* last_dir, const ImRect& r_outer, const ImRect& r_avoid, ImGuiPopupPositionPolicy policy = ImGuiPopupPositionPolicy_Default);

    // Navigation
    IMGUI_API void          NavInitWindow(ImGuiWindow* window, bool force_reinit);
    IMGUI_API bool          NavMoveRequestButNoResultYet();
    IMGUI_API void          NavMoveRequestCancel();
    IMGUI_API void          NavMoveRequestForward(ImGuiDir move_dir, ImGuiDir clip_dir, const ImRect& bb_rel, ImGuiNavMoveFlags move_flags);
    IMGUI_API void          NavMoveRequestTryWrapping(ImGuiWindow* window, ImGuiNavMoveFlags move_flags);
    IMGUI_API float         GetNavInputAmount(ImGuiNavInput n, ImGuiInputReadMode mode);
    IMGUI_API ImVec2        GetNavInputAmount2d(ImGuiNavDirSourceFlags dir_sources, ImGuiInputReadMode mode, float slow_factor = 0.0f, float fast_factor = 0.0f);
    IMGUI_API int           CalcTypematicRepeatAmount(float t0, float t1, float repeat_delay, float repeat_rate);
    IMGUI_API void          ActivateItem(ImGuiID id);   // Remotely activate a button, checkbox, tree node etc. given its unique ID. activation is queued and processed on the next frame when the item is encountered again.
    IMGUI_API void          SetNavID(ImGuiID id, int nav_layer, ImGuiID focus_scope_id);
    IMGUI_API void          SetNavIDWithRectRel(ImGuiID id, int nav_layer, ImGuiID focus_scope_id, const ImRect& rect_rel);

    // Focus scope (WIP)
    IMGUI_API void          PushFocusScope(ImGuiID id);     // Note: this is storing in same stack as IDStack, so Push/Pop mismatch will be reported there.
    IMGUI_API void          PopFocusScope();
    +/

    pragma(inline, true) ImGuiID          GetFocusScopeID()               { ImGuiContext* g = GImGui; return g.NavFocusScopeId; }

    // Inputs
    // FIXME: Eventually we should aim to move e.g. IsActiveIdUsingKey() into IsKeyXXX functions.
    pragma(inline, true) bool             IsActiveIdUsingNavDir(ImGuiDir dir)                         { ImGuiContext* g = GImGui; return (g.ActiveIdUsingNavDirMask & (1 << dir)) != 0; }
    pragma(inline, true) bool             IsActiveIdUsingNavInput(ImGuiNavInput input)                { ImGuiContext* g = GImGui; return (g.ActiveIdUsingNavInputMask & (1 << input)) != 0; }
    pragma(inline, true) bool             IsActiveIdUsingKey(ImGuiKey key)                            { ImGuiContext* g = GImGui; IM_ASSERT(key < 64); return (g.ActiveIdUsingKeyInputMask & (cast(ImU64)1 << key)) != 0; }
    // IMGUI_API bool          IsMouseDragPastThreshold(ImGuiMouseButton button, float lock_threshold = -1.0f);
    pragma(inline, true) bool             IsKeyPressedMap(ImGuiKey key, bool repeat = true)           { ImGuiContext* g = GImGui; const int key_index = g.IO.KeyMap[key]; return (key_index >= 0) ? IsKeyPressed(key_index, repeat) : false; }
    pragma(inline, true) bool             IsNavInputDown(ImGuiNavInput n)                             { ImGuiContext* g = GImGui; return g.IO.NavInputs[n] > 0.0f; }
    pragma(inline, true) bool             IsNavInputTest(ImGuiNavInput n, ImGuiInputReadMode rm)      { return (GetNavInputAmount(n, rm) > 0.0f); }
    // IMGUI_API ImGuiKeyModFlags GetMergedKeyModFlags();

    /+
    // Drag and Drop
    IMGUI_API bool          BeginDragDropTargetCustom(const ImRect& bb, ImGuiID id);
    IMGUI_API void          ClearDragDrop();
    IMGUI_API bool          IsDragDropPayloadBeingAccepted();

    // Internal Columns API (this is not exposed because we will encourage transitioning to the Tables api)
    IMGUI_API void          BeginColumns(const char* str_id, int count, ImGuiColumnsFlags flags = 0); // setup number of columns. use an identifier to distinguish multiple column sets. close with EndColumns().
    IMGUI_API void          EndColumns();                                                             // close columns
    IMGUI_API void          PushColumnClipRect(int column_index);
    IMGUI_API void          PushColumnsBackground();
    IMGUI_API void          PopColumnsBackground();
    IMGUI_API ImGuiID       GetColumnsID(const char* str_id, int count);
    IMGUI_API ImGuiColumns* FindOrCreateColumns(ImGuiWindow* window, ImGuiID id);
    IMGUI_API float         GetColumnOffsetFromNorm(const ImGuiColumns* columns, float offset_norm);
    IMGUI_API float         GetColumnNormFromOffset(const ImGuiColumns* columns, float offset);

    // Tab Bars
    IMGUI_API bool          BeginTabBarEx(ImGuiTabBar* tab_bar, const ImRect& bb, ImGuiTabBarFlags flags);
    IMGUI_API ImGuiTabItem* TabBarFindTabByID(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    IMGUI_API void          TabBarRemoveTab(ImGuiTabBar* tab_bar, ImGuiID tab_id);
    IMGUI_API void          TabBarCloseTab(ImGuiTabBar* tab_bar, ImGuiTabItem* tab);
    IMGUI_API void          TabBarQueueChangeTabOrder(ImGuiTabBar* tab_bar, const ImGuiTabItem* tab, int dir);
    IMGUI_API bool          TabItemEx(ImGuiTabBar* tab_bar, const char* label, bool* p_open, ImGuiTabItemFlags flags);
    IMGUI_API ImVec2        TabItemCalcSize(const char* label, bool has_close_button);
    IMGUI_API void          TabItemBackground(ImDrawList* draw_list, const ImRect& bb, ImGuiTabItemFlags flags, ImU32 col);
    IMGUI_API bool          TabItemLabelAndCloseButton(ImDrawList* draw_list, const ImRect& bb, ImGuiTabItemFlags flags, ImVec2 frame_padding, const char* label, ImGuiID tab_id, ImGuiID close_button_id);

    // Render helpers
    // AVOID USING OUTSIDE OF IMGUI.CPP! NOT FOR PUBLIC CONSUMPTION. THOSE FUNCTIONS ARE A MESS. THEIR SIGNATURE AND BEHAVIOR WILL CHANGE, THEY NEED TO BE REFACTORED INTO SOMETHING DECENT.
    // NB: All position are in absolute pixels coordinates (we are never using window coordinates internally)
    IMGUI_API void          RenderText(ImVec2 pos, const char* text, const char* text_end = NULL, bool hide_text_after_hash = true);
    IMGUI_API void          RenderTextWrapped(ImVec2 pos, const char* text, const char* text_end, float wrap_width);
    IMGUI_API void          RenderTextClipped(const ImVec2& pos_min, const ImVec2& pos_max, const char* text, const char* text_end, const ImVec2* text_size_if_known, const ImVec2& align = ImVec2(0,0), const ImRect* clip_rect = NULL);
    IMGUI_API void          RenderTextClippedEx(ImDrawList* draw_list, const ImVec2& pos_min, const ImVec2& pos_max, const char* text, const char* text_end, const ImVec2* text_size_if_known, const ImVec2& align = ImVec2(0, 0), const ImRect* clip_rect = NULL);
    IMGUI_API void          RenderTextEllipsis(ImDrawList* draw_list, const ImVec2& pos_min, const ImVec2& pos_max, float clip_max_x, float ellipsis_max_x, const char* text, const char* text_end, const ImVec2* text_size_if_known);
    IMGUI_API void          RenderFrame(ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, bool border = true, float rounding = 0.0f);
    IMGUI_API void          RenderFrameBorder(ImVec2 p_min, ImVec2 p_max, float rounding = 0.0f);
    IMGUI_API void          RenderColorRectWithAlphaCheckerboard(ImDrawList* draw_list, ImVec2 p_min, ImVec2 p_max, ImU32 fill_col, float grid_step, ImVec2 grid_off, float rounding = 0.0f, int rounding_corners_flags = ~0);
    IMGUI_API void          RenderNavHighlight(const ImRect& bb, ImGuiID id, ImGuiNavHighlightFlags flags = ImGuiNavHighlightFlags_TypeDefault); // Navigation highlight
    IMGUI_API const char*   FindRenderedTextEnd(const char* text, const char* text_end = NULL); // Find the optional ## from which we stop displaying text.
    IMGUI_API void          LogRenderedText(const ImVec2* ref_pos, const char* text, const char* text_end = NULL);

    // Render helpers (those functions don't access any ImGui state!)
    IMGUI_API void          RenderArrow(ImDrawList* draw_list, ImVec2 pos, ImU32 col, ImGuiDir dir, float scale = 1.0f);
    IMGUI_API void          RenderBullet(ImDrawList* draw_list, ImVec2 pos, ImU32 col);
    IMGUI_API void          RenderCheckMark(ImDrawList* draw_list, ImVec2 pos, ImU32 col, float sz);
    IMGUI_API void          RenderMouseCursor(ImDrawList* draw_list, ImVec2 pos, float scale, ImGuiMouseCursor mouse_cursor, ImU32 col_fill, ImU32 col_border, ImU32 col_shadow);
    IMGUI_API void          RenderArrowPointingAt(ImDrawList* draw_list, ImVec2 pos, ImVec2 half_sz, ImGuiDir direction, ImU32 col);
    IMGUI_API void          RenderRectFilledRangeH(ImDrawList* draw_list, const ImRect& rect, ImU32 col, float x_start_norm, float x_end_norm, float rounding);
    +/

    static if (!IMGUI_DISABLE_OBSOLETE_FUNCTIONS) {
        // [1.71: 2019/06/07: Updating prototypes of some of the internal functions. Leaving those for reference for a short while]
        pragma(inline, true) void RenderArrowOld(ImVec2 pos, ImGuiDir dir, float scale=1.0f) { ImGuiWindow* window = GetCurrentWindow(); RenderArrow(window.DrawList, pos, GetColorU32(ImGuiCol.Text), dir, scale); }
        pragma(inline, true) void RenderBulletOld(ImVec2 pos)                                { ImGuiWindow* window = GetCurrentWindow(); RenderBullet(window.DrawList, pos, GetColorU32(ImGuiCol.Text)); }
    }

    /+
    // Widgets
    IMGUI_API void          TextEx(const char* text, const char* text_end = NULL, ImGuiTextFlags flags = 0);
    IMGUI_API bool          ButtonEx(const char* label, const ImVec2& size_arg = ImVec2(0,0), ImGuiButtonFlags flags = 0);
    IMGUI_API bool          CloseButton(ImGuiID id, const ImVec2& pos);
    IMGUI_API bool          CollapseButton(ImGuiID id, const ImVec2& pos);
    IMGUI_API bool          ArrowButtonEx(const char* str_id, ImGuiDir dir, ImVec2 size_arg, ImGuiButtonFlags flags = 0);
    IMGUI_API void          Scrollbar(ImGuiAxis axis);
    IMGUI_API bool          ScrollbarEx(const ImRect& bb, ImGuiID id, ImGuiAxis axis, float* p_scroll_v, float avail_v, float contents_v, ImDrawCornerFlags rounding_corners);
    IMGUI_API ImRect        GetWindowScrollbarRect(ImGuiWindow* window, ImGuiAxis axis);
    IMGUI_API ImGuiID       GetWindowScrollbarID(ImGuiWindow* window, ImGuiAxis axis);
    IMGUI_API ImGuiID       GetWindowResizeID(ImGuiWindow* window, int n); // 0..3: corners, 4..7: borders
    IMGUI_API void          SeparatorEx(ImGuiSeparatorFlags flags);

    // Widgets low-level behaviors
    IMGUI_API bool          ButtonBehavior(const ImRect& bb, ImGuiID id, bool* out_hovered, bool* out_held, ImGuiButtonFlags flags = 0);
    IMGUI_API bool          DragBehavior(ImGuiID id, ImGuiDataType data_type, void* p_v, float v_speed, const void* p_min, const void* p_max, const char* format, float power, ImGuiDragFlags flags);
    IMGUI_API bool          SliderBehavior(const ImRect& bb, ImGuiID id, ImGuiDataType data_type, void* p_v, const void* p_min, const void* p_max, const char* format, float power, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    IMGUI_API bool          SplitterBehavior(const ImRect& bb, ImGuiID id, ImGuiAxis axis, float* size1, float* size2, float min_size1, float min_size2, float hover_extend = 0.0f, float hover_visibility_delay = 0.0f);
    IMGUI_API bool          TreeNodeBehavior(ImGuiID id, ImGuiTreeNodeFlags flags, const char* label, const char* label_end = NULL);
    IMGUI_API bool          TreeNodeBehaviorIsOpen(ImGuiID id, ImGuiTreeNodeFlags flags = 0);                     // Consume previous SetNextItemOpen() data, if any. May return true when logging
    IMGUI_API void          TreePushOverrideID(ImGuiID id);

    // Template functions are instantiated in imgui_widgets.cpp for a finite number of types.
    // To use them externally (for custom widget) you may need an "extern template" statement in your code in order to link to existing instances and silence Clang warnings (see #2036).
    // e.g. " extern template IMGUI_API float RoundScalarWithFormatT<float, float>(const char* format, ImGuiDataType data_type, float v); "
    template<typename T, typename SIGNED_T, typename FLOAT_T>   IMGUI_API bool  DragBehaviorT(ImGuiDataType data_type, T* v, float v_speed, T v_min, T v_max, const char* format, float power, ImGuiDragFlags flags);
    template<typename T, typename SIGNED_T, typename FLOAT_T>   IMGUI_API bool  SliderBehaviorT(const ImRect& bb, ImGuiID id, ImGuiDataType data_type, T* v, T v_min, T v_max, const char* format, float power, ImGuiSliderFlags flags, ImRect* out_grab_bb);
    template<typename T, typename FLOAT_T>                      IMGUI_API float SliderCalcRatioFromValueT(ImGuiDataType data_type, T v, T v_min, T v_max, float power, float linear_zero_pos);
    template<typename T, typename SIGNED_T>                     IMGUI_API T     RoundScalarWithFormatT(const char* format, ImGuiDataType data_type, T v);

    // Data type helpers
    IMGUI_API const ImGuiDataTypeInfo*  DataTypeGetInfo(ImGuiDataType data_type);
    IMGUI_API int           DataTypeFormatString(char* buf, int buf_size, ImGuiDataType data_type, const void* p_data, const char* format);
    IMGUI_API void          DataTypeApplyOp(ImGuiDataType data_type, int op, void* output, void* arg_1, const void* arg_2);
    IMGUI_API bool          DataTypeApplyOpFromText(const char* buf, const char* initial_value_buf, ImGuiDataType data_type, void* p_data, const char* format);

    // InputText
    IMGUI_API bool          InputTextEx(const char* label, const char* hint, char* buf, int buf_size, const ImVec2& size_arg, ImGuiInputTextFlags flags, ImGuiInputTextCallback callback = NULL, void* user_data = NULL);
    IMGUI_API bool          TempInputText(const ImRect& bb, ImGuiID id, const char* label, char* buf, int buf_size, ImGuiInputTextFlags flags);
    IMGUI_API bool          TempInputScalar(const ImRect& bb, ImGuiID id, const char* label, ImGuiDataType data_type, void* p_data, const char* format);
    +/

    pragma(inline, true) bool             TempInputIsActive(ImGuiID id)       { ImGuiContext* g = GImGui; return (g.ActiveId == id && g.TempInputId == id); }
    pragma(inline, true) ImGuiInputTextState* GetInputTextState(ImGuiID id)   { ImGuiContext* g = GImGui; return (g.InputTextState.ID == id) ? &g.InputTextState : NULL; } // Get input text state if active

    /+
    // Color
    IMGUI_API void          ColorTooltip(const char* text, const float* col, ImGuiColorEditFlags flags);
    IMGUI_API void          ColorEditOptionsPopup(const float* col, ImGuiColorEditFlags flags);
    IMGUI_API void          ColorPickerOptionsPopup(const float* ref_col, ImGuiColorEditFlags flags);

    // Plot
    IMGUI_API int           PlotEx(ImGuiPlotType plot_type, const char* label, float (*values_getter)(void* data, int idx), void* data, int values_count, int values_offset, const char* overlay_text, float scale_min, float scale_max, ImVec2 frame_size);

    // Shade functions (write over already created vertices)
    IMGUI_API void          ShadeVertsLinearColorGradientKeepAlpha(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, ImVec2 gradient_p0, ImVec2 gradient_p1, ImU32 col0, ImU32 col1);
    IMGUI_API void          ShadeVertsLinearUV(ImDrawList* draw_list, int vert_start_idx, int vert_end_idx, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, bool clamp);

    // Garbage collection
    IMGUI_API void          GcCompactTransientWindowBuffers(ImGuiWindow* window);
    IMGUI_API void          GcAwakeTransientWindowBuffers(ImGuiWindow* window);
    +/

    // Debug Tools
    pragma(inline, true) void             DebugDrawItemRect(ImU32 col = IM_COL32(255,0,0,255))    { ImGuiContext* g = GImGui; ImGuiWindow* window = g.CurrentWindow; GetForegroundDrawList2(window).AddRect(window.DC.LastItemRect.Min, window.DC.LastItemRect.Max, col); }
    pragma(inline, true) void             DebugStartItemPicker()                                  { ImGuiContext* g = GImGui; g.DebugItemPickerActive = true; }

// } // namespace ImGui

// ImFontAtlas internals
// IMGUI_API bool              ImFontAtlasBuildWithStbTruetype(ImFontAtlas* atlas);
// IMGUI_API void              ImFontAtlasBuildInit(ImFontAtlas* atlas);
// IMGUI_API void              ImFontAtlasBuildSetupFont(ImFontAtlas* atlas, ImFont* font, ImFontConfig* font_config, float ascent, float descent);
// IMGUI_API void              ImFontAtlasBuildPackCustomRects(ImFontAtlas* atlas, void* stbrp_context_opaque);
// IMGUI_API void              ImFontAtlasBuildFinish(ImFontAtlas* atlas);
// IMGUI_API void              ImFontAtlasBuildMultiplyCalcLookupTable(unsigned char out_table[256], float in_multiply_factor);
// IMGUI_API void              ImFontAtlasBuildMultiplyRectAlpha8(const unsigned char table[256], unsigned char* pixels, int x, int y, int w, int h, int stride);

// Debug Tools
// Use 'Metrics->Tools->Item Picker' to break into the call-stack of a specific item.
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

// Test Engine Hooks (imgui_tests)
//#define IMGUI_ENABLE_TEST_ENGINE
version (IMGUI_ENABLE_TEST_ENGINE) {
    extern extern(C) void                 ImGuiTestEngineHook_PreNewFrame(ImGuiContext* ctx);
    extern extern(C) void                 ImGuiTestEngineHook_PostNewFrame(ImGuiContext* ctx);
    extern extern(C) void                 ImGuiTestEngineHook_ItemAdd(ImGuiContext* ctx, const ImRect/*&*/ bb, ImGuiID id);
    extern extern(C) void                 ImGuiTestEngineHook_ItemInfo(ImGuiContext* ctx, ImGuiID id, string label, ImGuiItemStatusFlags flags);
    extern extern(C) void                 ImGuiTestEngineHook_Log(ImGuiContext* ctx, string fmt, ...);
    pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_ADD(const ImRect _BB, ImGuiID _ID) { ImGuiTestEngineHook_ItemAdd(GImGui, _BB, _ID);}                // Register item bounding box
    pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_INFO(ImGuiID _ID, string _LABEL, ImGuiItemStatusFlags _FLAGS) { ImGuiTestEngineHook_ItemInfo(GImGui, _ID, _LABEL, _FLAGS);}   // Register item label and status flags (optional)
    pragma(inline, true) void IMGUI_TEST_ENGINE_LOG(_FMT, ...) { ImGuiTestEngineHook_Log(&g, _FMT, __VA_ARGS__); }          // Custom log entry from user land into test log
} else {
    pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_ADD(const ImRect _BB, ImGuiID _ID) {}
    pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_INFO(ImGuiID _ID, string _LABEL, ImGuiItemStatusFlags _FLAGS) {}
    pragma(inline, true) void IMGUI_TEST_ENGINE_ITEM_INFO(ImGuiID _ID, string _LABEL, ImGuiItemFlags _FLAGS) {}
    pragma(inline, true) void IMGUI_TEST_ENGINE_LOG(string _FMT, ...) {}
}

// #if defined(__clang__)
// #pragma clang diagnostic pop
// #elif defined(__GNUC__)
// #pragma GCC diagnostic pop
// #endif

// #ifdef _MSC_VER
// #pragma warning (pop)
// #endif

// #endif // #ifndef IMGUI_DISABLE
