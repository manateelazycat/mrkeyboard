using Gtk;
using Gdk;

namespace Utils {
    public bool move_window(Gtk.Widget widget, Gdk.EventButton event, Gtk.Window window) {
        if (is_left_button(event)) {
            window.begin_move_drag(
                (int)event.button, 
                (int)event.x_root, 
                (int)event.y_root, 
                event.time);
        }
        
        return false;
    }

    public void toggle_max_window(Gtk.Window window) {
        var window_state = window.get_window().get_state();
        if (Gdk.WindowState.MAXIMIZED in window_state) {
            window.unmaximize();
        } else {
            window.maximize();
        }
    }

    public bool is_left_button(Gdk.EventButton event) {
        return event.button == 1;
    }

    public bool is_double_click(Gdk.EventButton event) {
        return event.button == 1 && event.type == Gdk.EventType.2BUTTON_PRESS;
    }

    public void load_css_theme(string css_path) {
        var screen = Gdk.Screen.get_default();
        var css_provider = new Gtk.CssProvider();
        try {
            css_provider.load_from_path(css_path);
        } catch (GLib.Error e) {
            print("Got error when load css: %s\n", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }

    public bool is_pointer_out_widget(Gtk.Widget widget) {
        Gtk.Allocation alloc;
        widget.get_allocation(out alloc);
        
        int wx;
        int wy;
        widget.get_toplevel().get_window().get_origin(out wx, out wy);
        
        int px;
        int py;
        Gdk.ModifierType mask;
        Gdk.get_default_root_window().get_pointer(out px, out py, out mask);
        
        int rect_start_x = wx + alloc.x;
        int rect_start_y = wx + alloc.y;
        int rect_end_x = rect_start_x + alloc.width;
        int rect_end_y = rect_start_y + alloc.height;

        return (px < rect_start_x || px > rect_end_x || py < rect_start_y || py > rect_end_y);
    }
}