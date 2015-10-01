using Gtk;
using Gdk;
using Keymap;

namespace Widgets {
    public class WindowManager : Gtk.DrawingArea {
        public WindowManager() {
            set_can_focus(true);
            key_press_event.connect(on_key_press);
        }
        
        public bool on_key_press(Gtk.Widget widget, Gdk.EventKey event) {
            print("%s\n", Keymap.get_keyevent_name(event));
            
            return true;
        }
    }
}