module backends_d.imgui_impl_opengl3_loader;

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
