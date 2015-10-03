using Gtk;
using Gdk;
using Keymap;
using Xcb;

namespace Widgets {
    public class WindowManager : Gtk.DrawingArea {
        public WindowManager() {
            set_can_focus(true);
        }
    }
}