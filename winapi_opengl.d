

import core.runtime;
import core.sys.windows.windows;

import core.stdc.stdlib;

import std.utf;

version(Windows) {
    pragma(lib, "gdi32.lib");
    pragma(lib, "opengl32.lib");
    pragma(lib, "glu32");
} else {
    static assert(0, "Not supported  yet");
}

auto toUTF16z(S)(S s) {
    return toUTFz!(const(wchar)*)(s);
}

alias uint GLenum;
alias int GLint;
alias int GLsizei;
alias uint GLbitfield;
alias float GLfloat;


enum {
    GL_DEPTH_BUFFER_BIT               = 0x00000100,
    GL_COLOR_BUFFER_BIT               = 0x00004000,
    GL_TRIANGLES                      = 0x0004,

}

extern(System) nothrow @nogc {
    void glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
    void glClear(GLbitfield mask) nothrow;
    void glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    void glBegin(GLenum mode);
    void glEnd();
    void glColor3f (GLfloat red, GLfloat green, GLfloat blue);
    void glVertex2f (GLfloat x, GLfloat y);
}

/*
extern(Windows) {
    void glViewport(GLint x, GLint y, GLsizei width, GLsizei height) nothrow;
    void glClear(GLbitfield mask) nothrow;
    void glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha) nothrow;
    void glBegin(GLenum mode) nothrow;
    void glEnd() nothrow;
    void glColor3f (GLfloat red, GLfloat green, GLfloat blue) nothrow;
    void glVertex2f (GLfloat x, GLfloat y) nothrow;
}
*/


extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow) {
    int result;
    void exceptionHandler(Throwable e) { throw e; }

    try {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate(&exceptionHandler);
    }
    catch (Throwable t) {
        MessageBox(null, t.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow) {

    string appName = "WindowsOpenGlApp";
    HWND hwnd;
    MSG  msg;
    WNDCLASSEX wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    // If there's a brush, the system will clear the window right after each redraw step, 
    // then send the WM_PAINT. In case of V-Synced SwapBuffers your picture may have been 
    // overdrawn by the next resizing step before the buffer swap happened, or just right 
    // after it, but before that part of the screen was sent to the display device.
    //wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.hbrBackground = NULL;
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if(!RegisterClassEx(&wndclass)) {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,      // window class name
                         "Windows OpenGL App", // window caption
                         WS_OVERLAPPEDWINDOW,  // window style
                         CW_USEDEFAULT,        // initial x position
                         CW_USEDEFAULT,        // initial y position
                         CW_USEDEFAULT,        // initial x size
                         CW_USEDEFAULT,        // initial y size
                         NULL,                 // parent window handle
                         NULL,                 // window menu handle
                         hInstance,            // program instance handle
                         NULL);                // creation parameters

    PIXELFORMATDESCRIPTOR pfd;
    pfd.dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 32;
    pfd.cDepthBits = 32;
    pfd.iLayerType = PFD_MAIN_PLANE;

    HDC hdc = GetDC(hwnd);

    auto pixelformat = ChoosePixelFormat(hdc, &pfd);

    if(!SetPixelFormat(hdc, pixelformat, &pfd)) {
        MessageBox(NULL, "Failed to set pixel format!",  NULL, MB_ICONERROR);
        return EXIT_FAILURE;
    }
    HGLRC hrc = wglCreateContext(hdc);
    if(!wglMakeCurrent(hdc, hrc)) {
        MessageBox(NULL, "Failed to set HGLRC!",  NULL, MB_ICONERROR);
        return EXIT_FAILURE;
    }

    glClearColor(0.2f, 0.3f, .4f, 1.0f);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

void drawGlScene() nothrow {
    glClear(GL_COLOR_BUFFER_BIT);
    glBegin(GL_TRIANGLES);
    glColor3f(1.0f, 0.0f, 0.0f);
    glVertex2f(0,  1);
    glColor3f(0.0f, 1.0f, 0.0f);
    glVertex2f(-1, -1);
    glColor3f(0.0f, 0.0f, 1.0f);
    glVertex2f(1, -1);
    glEnd();
}


extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow {
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;

    switch (message) {
        case WM_CREATE:
            return 0;
        case WM_SIZE:
            glViewport(0, 0, LOWORD(lParam), HIWORD(lParam));
            PostMessage(hwnd, WM_PAINT, 0, 0);
            return 0;
        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            drawGlScene();

            SwapBuffers(hdc);
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}