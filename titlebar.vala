using Widgets;

namespace Widgets {
    public class Titlebar : Gtk.EventBox {
        public Gtk.Entry entry;
        public Widgets.ImageButton min_button;
        public Widgets.ImageButton close_button;
        
        public Titlebar() {
            var align = new Gtk.Alignment(0, 0.5f, 1, 0);
            align.top_padding = 2;
            align.bottom_padding = 2;
            add(align);

            var topbar = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            align.add(topbar);
            
            var name_align = new Gtk.Alignment(0, 0.5f, 0, 0);
            name_align.left_padding = 4;
            name_align.right_padding = 4;
            name_align.set_size_request(150, -1);
            topbar.pack_start(name_align, false, false, 0);
            
            var name_label = new Gtk.Label("Mr. keyboard");
            name_align.add(name_label);
            
            var entry_align = new Gtk.Alignment(0, 0.5f, 1, 0);
            entry_align.top_padding = 4;
            entry_align.bottom_padding = 4;
            topbar.pack_start(entry_align, true, true, 0);
            
            entry = new Gtk.Entry();
            entry_align.add(entry);
            
            var status_label = new Gtk.Label("");
            status_label.set_size_request(100, -1);
            topbar.pack_start(status_label, false, false, 0);
            
            var window_button_align = new Gtk.Alignment(0, 0.5f, 0, 0);
            topbar.pack_start(window_button_align, false, false, 0);
            
            var window_button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            window_button_align.add(window_button_box);
            
            min_button = new Widgets.ImageButton("window_min");
            window_button_box.pack_start(min_button, false, false, 0);
            
            close_button = new Widgets.ImageButton("window_close");
            window_button_box.pack_start(close_button, false, false, 0);
            
            min_button.button_press_event.connect((event) => {
                    ((Gtk.Window)this.get_toplevel()).iconify() ;
                    return true;
                });
            button_press_event.connect((event) => {
                    if (Utils.is_double_click(event)) {
                        Utils.toggle_max_window((Gtk.Window)this.get_toplevel());
                    } else {
                        Utils.move_window(this, event, (Gtk.Window)this.get_toplevel());
                    }
                    
                    return false;
                });
            
        }
    }
}