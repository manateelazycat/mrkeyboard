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
}