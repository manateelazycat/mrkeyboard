/*
 * xcb_connection_t *XGetXCBConnection(Display *dpy);
 * enum XEventQueueOwner { XlibOwnsEventQueue = 0, XCBOwnsEventQueue };
 * void XSetEventQueueOwner(Display *dpy, enum XEventQueueOwner owner);
 */

using Xcb;

[CCode (cheader_filename = "X11/Xlib-xcb.h")]
namespace X {
    [CCode (cname="XGetXCBConnection")]
    public unowned Xcb.Connection GetConnection(X.Display xdisplay);

	[CCode (cname = "XEventQueueOwner", has_type_id = false)]
    public enum EventQueueOwner {
        XlibOwnsEventQueue,
        XCBOwnsEventQueue
    }

    [CCode (cname="XSetEventQueueOwner")]
    void SetEventQueueOwner(X.Display dpy, EventQueueOwner owner);
}
