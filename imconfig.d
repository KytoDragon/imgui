module d_imgui.imconfig;
//-----------------------------------------------------------------------------
// COMPILE-TIME OPTIONS FOR DEAR IMGUI
// Runtime options (clipboard callbacks, enabling various features, etc.) can generally be set via the ImGuiIO structure.
// You can use ImGui::SetAllocatorFunctions() before calling ImGui::CreateContext() to rewire memory allocation functions.
//-----------------------------------------------------------------------------
// A) You may edit imconfig.h (and not overwrite it when updating Dear ImGui, or maintain a patch/branch with your modifications to imconfig.h)
// B) or add configuration directives in your own file and compile with #define IMGUI_USER_CONFIG "myfilename.h"
// If you do so you need to make sure that configuration settings are defined consistently _everywhere_ Dear ImGui is used, which include
// the imgui*.cpp files but also _any_ of your code that uses Dear ImGui. This is because some compile-time options have an affect on data structures.
// Defining those options in imconfig.h will ensure every compilation unit gets to see the same data structure layouts.
// Call IMGUI_CHECKVERSION() from your .cpp files to verify that the data structures your files are using are matching the ones imgui.cpp is using.
//-----------------------------------------------------------------------------

// #pragma once

//---- Define assertion handler. Defaults to calling assert().
// If your macro uses multiple statements, make sure is enclosed in a 'do { .. } while (0)' block so it can be used as a single statement.
enum D_IMGUI_USER_DEFINED_ASSERT = false;
//alias MyAssert = IM_ASSERT
//pragma(inline, true) void IM_ASSERT(bool _EXPR) {(cast(void)(_EXPR));}     // Disable asserts

//---- Define attributes of all API symbols declarations, e.g. for DLL under Windows
// Using dear imgui via a shared library is not recommended, because of function call overhead and because we don't guarantee backward nor forward ABI compatibility.
// D_IMGUI: Not supported
//#define IMGUI_API __declspec( dllexport )
//#define IMGUI_API __declspec( dllimport )

//---- Don't define obsolete functions/enums/behaviors. Consider enabling from time to time after updating to avoid using soon-to-be obsolete function/names.
// D_IMGUI: Not all obsolet functions are implemented. Please use their replacment instead.
enum IMGUI_DISABLE_OBSOLETE_FUNCTIONS = false;

//---- Disable all of Dear ImGui or don't implement standard windows.
// It is very strongly recommended to NOT disable the demo windows during development. Please read comments in imgui_demo.cpp.
// D_IMGUI: Not supported
//#define IMGUI_DISABLE                                     // Disable everything: all headers and source files will be empty.
enum IMGUI_DISABLE_DEMO_WINDOWS = false;                        // Disable demo windows: ShowDemoWindow()/ShowStyleEditor() will be empty. Not recommended.
//#define IMGUI_DISABLE_METRICS_WINDOW                      // Disable debug/metrics window: ShowMetricsWindow() will be empty.

//---- Don't implement some functions to reduce linkage requirements.
enum IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCTIONS = false;   // [Win32] Don't implement default clipboard handler. Won't use and link with OpenClipboard/GetClipboardData/CloseClipboard etc.
enum IMGUI_DISABLE_WIN32_DEFAULT_IME_FUNCTIONS = false;         // [Win32] Don't implement default IME handler. Won't use and link with ImmGetContext/ImmSetCompositionWindow.
enum IMGUI_DISABLE_WIN32_FUNCTIONS = false;                     // [Win32] Won't use and link with any Win32 function (clipboard, ime).
enum IMGUI_ENABLE_OSX_DEFAULT_CLIPBOARD_FUNCTIONS = false;      // [OSX] Implement default OSX clipboard handler (need to link with '-framework ApplicationServices', this is why this is not the default).
enum IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS = false;            // Don't implement ImFormatString/ImFormatStringV so you can implement them yourself (e.g. if you don't want to link with vsnprintf)
enum IMGUI_DISABLE_DEFAULT_MATH_FUNCTIONS = false;              // Don't implement ImFabs/ImSqrt/ImPow/ImFmod/ImCos/ImSin/ImAcos/ImAtan2 so you can implement them yourself.
enum IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS = false;              // Don't implement ImFileOpen/ImFileClose/ImFileRead/ImFileWrite so you can implement them yourself if you don't want to link with fopen/fclose/fread/fwrite. This will also disable the LogToTTY() function.
enum IMGUI_DISABLE_DEFAULT_ALLOCATORS = false;                  // Don't implement default allocators calling malloc()/free() to avoid linking with them. You will need to call ImGui::SetAllocatorFunctions().
enum IMGUI_DISABLE_TTY_FUNCTIONS = false;                       // Don't implement logging to stdout

//---- Include imgui_user.h at the end of imgui.h as a convenience
// D_IMGUI: Not supported/necessary. Add your own module in package.d.
//#define IMGUI_INCLUDE_IMGUI_USER_H

//---- Pack colors to BGRA8 instead of RGBA8 (to avoid converting from one to another)
//version = IMGUI_USE_BGRA_PACKED_COLOR;

//---- Use 32-bit for ImWchar (default is 16-bit) to support full unicode code points.
//version = IMGUI_USE_WCHAR32;

//---- Avoid multiple STB libraries implementations, or redefine path/filenames to prioritize another version
// By default the embedded implementations are declared static and not available outside of imgui cpp files.
// D_IMGUI: Not supported/necessary. D-Imgui will always use its own truetype/reckpack implementation.
//#define IMGUI_STB_TRUETYPE_FILENAME   "my_folder/stb_truetype.h"
//#define IMGUI_STB_RECT_PACK_FILENAME  "my_folder/stb_rect_pack.h"
//#define IMGUI_DISABLE_STB_TRUETYPE_IMPLEMENTATION
//#define IMGUI_DISABLE_STB_RECT_PACK_IMPLEMENTATION

//---- Unless IMGUI_DISABLE_DEFAULT_FORMAT_FUNCTIONS is defined, use the much faster STB sprintf library implementation of vsnprintf instead of the one from the default C library.
// Note that stb_sprintf.h is meant to be provided by the user and available in the include path at compile time. Also, the compatibility checks of the arguments and formats done by clang and GCC will be disabled in order to support the extra formats provided by STB sprintf.
// D_IMGUI: Not supported. We use the d_snprintf package.
//version = IMGUI_USE_STB_SPRINTF;

//---- Define constructor and implicit cast operators to convert back<>forth between your math types and ImVec2/ImVec4.
// This will be inlined as part of ImVec2 and ImVec4 class declarations.
// D_IMGUI: Not supported.
/*
#define IM_VEC2_CLASS_EXTRA                                                 \
        ImVec2(const MyVec2& f) { x = f.x; y = f.y; }                       \
        operator MyVec2() const { return MyVec2(x,y); }

#define IM_VEC4_CLASS_EXTRA                                                 \
        ImVec4(const MyVec4& f) { x = f.x; y = f.y; z = f.z; w = f.w; }     \
        operator MyVec4() const { return MyVec4(x,y,z,w); }
*/

//---- Use 32-bit vertex indices (default is 16-bit) is one way to allow large meshes with more than 64K vertices.
// Your renderer back-end will need to support it (most example renderer back-ends support both 16/32-bit indices).
// Another way to allow large meshes while keeping 16-bit indices is to handle ImDrawCmd::VtxOffset in your renderer.
// Read about ImGuiBackendFlags_RendererHasVtxOffset for details.
enum D_IMGUI_USER_DEFINED_DRAW_IDX = false;
//alias ImDrawIdx = uint;

//---- Override ImDrawCallback signature (will need to modify renderer back-ends accordingly)
enum D_IMGUI_USER_DEFINED_DRAW_CALLBACK = false;
//import d_imgui.imgui_h.d : ImDrawList, ImDrawCmd;
// alias MyImDrawCallback = void function(const ImDrawList* draw_list, const ImDrawCmd* cmd, void* my_renderer_user_data);
// alias ImDrawCallback = MyImDrawCallback;

//---- Debug Tools: Macro to break in Debugger
// (use 'Metrics->Tools->Item Picker' to pick widgets with the mouse and break into them for easy debugging.)
enum D_IMGUI_USER_DEFINED_DEBUG_BREAK = false;
//pragma(inline, true) void IM_DEBUG_BREAK() {IM_ASSERT(false);}
//alias IM_DEBUG_BREAK = __debugbreak;

//---- Debug Tools: Have the Item Picker break in the ItemAdd() function instead of ItemHoverable(),
// (which comes earlier in the code, will catch a few extra items, allow picking items other than Hovered one.)
// This adds a small runtime cost which is why it is not enabled by default.
// version = IMGUI_DEBUG_TOOL_ITEM_PICKER_EX;

//---- Debug Tools: Enable slower asserts
// version = IMGUI_DEBUG_PARANOID;

//---- Tip: You can add extra functions within the ImGui:: namespace, here or in your own headers files.
// D_IMGUI: Not supported/necessary.
/*
namespace ImGui
{
    void MyFunction(const char* name, const MyMatrix44& v);
}
*/

//-----------------------------------------------------------------------------
// D_IMGUI: Additional compile time options
//-----------------------------------------------------------------------------

//---- Import for your own ImGui widgets
// public import your_app.imgui_extensions;

//---- Don't use \r\n on windows
enum D_IMGUI_NORMAL_NEWLINE_ON_WINDOWS = false;

//---- Define your own backend texture id
alias ImTextureID = int;

//---- Don't assert on recoverable errors
enum D_IMGUI_USER_DEFINED_RECOVERABLE_ERROR = false;
// void IM_ASSERT_USER_ERROR(bool _EXP, string _MSG);