using Widgets;
using Gdk;

namespace Widgets {
    public class Tab : Gtk.EventBox {
        public Gtk.Label label;
        public Gtk.Alignment close_button_align;
        public Widgets.ImageButton close_button;
        public int width = 100;
        public int height = 32;
        
        public Tab(string tab_name) {
            set_visible_window(false);
            set_size_request(width, -1);
            
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            add(box);
            
            var label_align = new Gtk.Alignment(0, 0.5f, 0, 0);
            box.pack_start(label_align, true, true, 0);
            
            label = new Gtk.Label(tab_name);
            label_align.add(label);
            
            close_button_align = new Gtk.Alignment(0, 0.5f, 0, 0);
            box.pack_start(close_button_align, false, false, 0);
            
            close_button = new Widgets.ImageButton("tab_close");
            
            realize.connect(on_realize);
            enter_notify_event.connect(on_enter_notify_event);
            leave_notify_event.connect(on_leave_notify_event);
            
            show_all();
        }
        
        public void on_realize(Gtk.Widget widget) {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            alloc.height = height;
            set_allocation(alloc);
        }
        
        public bool on_enter_notify_event(Gdk.EventCrossing event) {
            if (close_button_align.get_children().length() == 0) {
                close_button_align.add(close_button);
                show_all();
            }
            
            return false;
        }
        
        public bool on_leave_notify_event(Gdk.EventCrossing event) {
            Timeout.add(500, remove_close_button);
            
            return false;
        }
        
        public bool remove_close_button() {
            if (Utils.is_pointer_out_widget(this) && close_button_align.get_children().length() > 0) {
                close_button_align.remove(close_button);
                show_all();
            }
            
            return false;
        }
    }   
}