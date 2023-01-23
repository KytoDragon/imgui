module backends_d.imgui_impl_opengl3_loader;
//-----------------------------------------------------------------------------
// About imgui_impl_opengl3_loader.h:
//
// We embed our own OpenGL loader to not require user to provide their own or to have to use ours,
// which proved to be endless problems for users.
// Our loader is custom-generated, based on gl3w but automatically filtered to only include
// enums/functions that we use in our imgui_impl_opengl3.cpp source file in order to be small.
//
// YOU SHOULD NOT NEED TO INCLUDE/USE THIS DIRECTLY. THIS IS USED BY imgui_impl_opengl3.cpp ONLY.
// THE REST OF YOUR APP SHOULD USE A DIFFERENT GL LOADER: ANY GL LOADER OF YOUR CHOICE.
//
// IF YOU GET BUILD ERRORS IN THIS FILE (commonly macro redefinitions or function redefinitions):
// IT LIKELY MEANS THAT YOU ARE BUILDING 'imgui_impl_opengl3.cpp' OR INCUDING 'imgui_impl_opengl3_loader.h'
// IN THE SAME COMPILATION UNIT AS ONE OF YOUR FILE WHICH IS USING A THIRD-PARTY OPENGL LOADER.
// (e.g. COULD HAPPEN IF YOU ARE DOING A UNITY/JUMBO BUILD, OR INCLUDING .CPP FILES FROM OTHERS)
// YOU SHOULD NOT BUILD BOTH IN THE SAME COMPILATION UNIT.
// BUT IF YOU REALLY WANT TO, you can '#define IMGUI_IMPL_OPENGL_LOADER_CUSTOM' and imgui_impl_opengl3.cpp
// WILL NOT BE USING OUR LOADER, AND INSTEAD EXPECT ANOTHER/YOUR LOADER TO BE AVAILABLE IN THE COMPILATION UNIT.
//
// Regenerate with:
//   python gl3w_gen.py --output ../imgui/backends/imgui_impl_opengl3_loader.h --ref ../imgui/backends/imgui_impl_opengl3.cpp ./extra_symbols.txt
//
// More info:
//   https://github.com/dearimgui/gl3w_stripped
//   https://github.com/ocornut/imgui/issues/4445
//-----------------------------------------------------------------------------

/*
 * This file was generated with gl3w_gen.py, part of imgl3w
 * (hosted at https://github.com/dearimgui/gl3w_stripped)
 *
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

version (IMGUI_OPENGL3):
nothrow @nogc:

import bindbc.opengl;
import core.stdc.stdio : fprintf, stderr;

int imgl3wInit() {
    bool err = false;
    GLSupport retVal = loadOpenGL();
	if (retVal == GLSupport.noLibrary) {
        fprintf(stderr, "Failed to load OpenGL library!\n");
		err = true;
	} else if (retVal == GLSupport.badLibrary) {
        fprintf(stderr, "The OpenGL library is missing core components!\n");
		err = true;
	} else if (retVal == GLSupport.noContext) {
        fprintf(stderr, "OpenGL loader could not find OpenGL context!\n");
		err = true;
	} else if (retVal < glSupport) {
        fprintf(stderr, "Actual OpenGL version is lower than requested.\n");
	}
    return err;
}
