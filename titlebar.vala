using Widgets;

namespace Widgets {
    public class Titlebar : Gtk.EventBox {
        public Widgets.ImageButton min_button;
        public Widgets.ImageButton close_button;
        
        public Titlebar() {
            var topbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            add(topbar);
            
            var name_label = new Gtk.Label("Mr. keyboard");
            topbar.pack_start(name_label, false, false, 0);
            
            var entry = new Gtk.Entry();
            topbar.pack_start(entry, true, true, 0);
            
            var status_label = new Gtk.Label("");
            status_label.set_size_request(100, -1);
            topbar.pack_start(status_label, false, false, 0);
            
            var window_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            topbar.pack_start(window_button_box, false, false, 0);
            
            min_button = new Widgets.ImageButton("window_min");
            window_button_box.pack_start(min_button, false, false, 0);
            
            close_button = new Widgets.ImageButton("window_close");
            window_button_box.pack_start(close_button, false, false, 0);
        }
    }
}