public import core.sys.windows.windows;
public import core.sys.windows.winuser;
public import core.sys.windows.dbt;

// D_IMGUI: define all functions, types or enums missing in druntime
version(Windows) extern(Windows):
nothrow @nogc:

enum WM_MOUSEHWHEEL = 0x020E;

alias DPI_AWARENESS_CONTEXT = HANDLE;
enum DPI_AWARENESS_CONTEXT_UNAWARE              = cast(DPI_AWARENESS_CONTEXT)-1;
enum DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         = cast(DPI_AWARENESS_CONTEXT)-2;
enum DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    = cast(DPI_AWARENESS_CONTEXT)-3;
enum DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = cast(DPI_AWARENESS_CONTEXT)-4;
enum DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED    = cast(DPI_AWARENESS_CONTEXT)-5;

enum PROCESS_DPI_AWARENESS { PROCESS_DPI_UNAWARE = 0, PROCESS_SYSTEM_DPI_AWARE = 1, PROCESS_PER_MONITOR_DPI_AWARE = 2 }
enum MONITOR_DPI_TYPE { MDT_EFFECTIVE_DPI = 0, MDT_ANGULAR_DPI = 1, MDT_RAW_DPI = 2, MDT_DEFAULT = MDT_EFFECTIVE_DPI }

BOOL SetProcessDPIAware();

extern(D): // Prevent naming comflict in case the user has already defined these macros

/*
import core.stdc.string : memset, memcpy, memmove;
alias RtlMoveMemory = memmove;
alias RtlCopyMemory = memcpy;
pragma(inline, true) void RtlFillMemory(PVOID Destination, SIZE_T Length, BYTE Fill) { memset(Destination, Fill, Length);}
pragma(inline, true) void RtlZeroMemory(PVOID Destination, SIZE_T Length) { memset(Destination, 0, Length);}

alias MoveMemory = RtlMoveMemory;
alias CopyMemory = RtlCopyMemory;
alias FillMemory = RtlFillMemory;
alias ZeroMemory = RtlZeroMemory;
*/

pragma(inline, true) int GET_X_LPARAM(LPARAM lp) { return (cast(int)cast(short)LOWORD(lp)); }
pragma(inline, true) int GET_Y_LPARAM(LPARAM lp) { return (cast(int)cast(short)HIWORD(lp)); }
pragma(inline, true) int GET_XBUTTON_WPARAM(WPARAM w) { return (HIWORD(w)); }
