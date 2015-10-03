using Gtk;
using Gdk;
using Keymap;
using Xcb;

namespace Widgets {
    public class WindowManager : Gtk.DrawingArea {
        public WindowManager() {
            set_can_focus(true);
            
            draw.connect(on_draw);
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            cr.set_source_rgb(1, 0, 0);
            cr.rectangle(0, 0, width, height);
            cr.fill();
            
            return true;
        }
    }
}