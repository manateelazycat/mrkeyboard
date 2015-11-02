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
            
            if (get_item_height() > 0 && list_items.size > 0) {
                var render_widths = get_render_widths(alloc.width);
                
                var row_counter = 0;
                var row_y = 0;
                foreach (ListItem item in list_items) {
                    var column_counter = 0;
                    var column_x = 0;
                    foreach (int width in render_widths) {
                        item.render_column_cell(this, cr, column_counter, column_x, row_y, width, get_item_height());
                        column_x += width;
                        column_counter++;
                    }
                    
                    row_y += get_item_height();
                    row_counter++;
                }
            }
            
            return true;
        }
        
        public virtual int[] get_column_widths() {
            print("You should implement 'get_column_widths' in your application code.\n");
            
            return {};
        }

        public virtual int get_item_height() {
            print("You should implement 'get_height' in your application code.\n");

            return 0;
        }
        
        public int[] get_render_widths(int alloc_width) {
            var item_column_widths = get_column_widths();
            int expand_times = 0;
            int fixed_width = 0;
            foreach (int width in item_column_widths) {
                if (width == -1) {
                    expand_times++;
                } else {
                    fixed_width += width;
                }
            }
            
            int[] render_widths = {};
            if (expand_times > 0) {
                int expand_width = (alloc_width - fixed_width) / expand_times;
                foreach (int width in item_column_widths) {
                    if (width == -1) {
                        render_widths += expand_width;
                    } else {
                        render_widths += width;
                    }
                }
            } else {
                render_widths = item_column_widths;
            }

            return render_widths;
        }
        
        public void add_items(ArrayList<ListItem> items) {
            list_items.add_all(items);
            
            queue_draw();
        }
    }

    public abstract class ListItem : Object {
        public abstract void render_column_cell(Gtk.Widget widget, Cairo.Context cr, int column_index, int x, int y, int w, int h);
    }
}