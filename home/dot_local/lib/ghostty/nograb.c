// Preloaded into the ghostty daemon only. GTK 4.14's X11 backend grabs the
// server on every tooltip-text set (~173 per window build, 2 per title
// change), and on this NVIDIA setup each grab waits one 60Hz frame while the
// whole X server stalls. The grab only makes a pointer query atomic, so
// dropping it costs nothing visible.
#include <stdlib.h>

int XGrabServer(void *dpy)   { (void)dpy; return 1; }
int XUngrabServer(void *dpy) { (void)dpy; return 1; }

// Keep the preload out of every shell and program launched from a terminal.
__attribute__((constructor)) static void drop_preload(void) { unsetenv("LD_PRELOAD"); }
