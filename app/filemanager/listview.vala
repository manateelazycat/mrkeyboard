using Gtk;
using Draw;
using Gee;

namespace Widget {
    public class ListView : DrawingArea {
        public Gdk.Color background_color = Utils.color_from_string("#000000");
        public ArrayList<ListItem> list_items;
        
        public ListView() {
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            list_items = new ArrayList<ListItem>();
            
            draw.connect(on_draw);
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            return true;
        }
        
        public void add_items(ArrayList<ListItem> items) {
            list_items.add_all(items);
            
            queue_draw();
        }
    }

    public abstract class ListItem : Object {
        public abstract int get_height();
        public abstract int[] get_column_widths();
    }
}