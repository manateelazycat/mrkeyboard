using Gee;
using Widgets;
using Draw;

namespace Widgets {
    public class Window : Gtk.EventBox {
        public Widgets.Tabbar tabbar;
        public Gtk.Box window_content_area;
        public string mode_name = "";
        public int padding = 1;

        // public Gdk.Color window_frame_color = Utils.color_from_hex("#262721");
        public Gdk.Color window_frame_color = Utils.color_from_hex("#FF0000");
        public Gdk.Color window_frame_active_color = Utils.color_from_hex("#2DB213");
        
        private Widgets.WindowManager window_manager;
        
        public Window(Widgets.WindowManager wm) {
            window_manager = wm;
            
            var align = new Gtk.Alignment(0, 0, 1, 1);
            align.top_padding = padding;
            align.bottom_padding = padding;
            align.left_padding = padding;
            align.right_padding = padding;
            add(align);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            align.add(box);
            
            tabbar = new Widgets.Tabbar("tab_close");
            box.pack_start(tabbar, false, false, 0);
            
            window_content_area = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(window_content_area, true, true, 0);
            
            draw.connect(on_draw);
            size_allocate.connect((w, r) => {
                    on_size_allocate(w, r);
                });

            tabbar.switch_page.connect((old_xid, new_xid) => {
                    var alloc = get_allocate();
                    window_manager.switch_page(old_xid, new_xid, alloc.width, alloc.height);
                });
            tabbar.close_page.connect((xid) => {
                    window_manager.close_page(xid);
                });
            tabbar.focus_page.connect((xid) => {
                    var alloc = get_allocate();
                    window_manager.focus_page(xid, alloc.width, alloc.height);
                });
            
            show_all();
            window_manager.add(this);
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            if (window_manager.focus_window == this) {
                Utils.set_context_color(cr, window_frame_active_color);
            } else {
                Utils.set_context_color(cr, window_frame_color);
            }
            Draw.draw_rectangle(cr, 0, 0, width, height, false);
            
            return false;
        }
        
        public bool on_size_allocate(Gtk.Widget widget, Gdk.Rectangle rect) {
            print("#############################%s %i %i %i %i\n", this.get_name(), rect.x, rect.y, rect.width, rect.height);
            var xid = tabbar.get_current_tab_xid();
            if (xid != null) {
                print("************************:%i\n", xid);
                window_manager.resize_page(xid,
                                           rect.width - padding * 2,
                                           rect.height - padding *2 - tabbar.height);
            }
            
            return false;
        }
        
        public Gtk.Allocation get_allocate() {
            Gtk.Allocation window_alloc = Gtk.Allocation();

            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            print("alloc is: %i %i %i %i\n", alloc.x, alloc.y, alloc.width, alloc.height);
            
            if (alloc.x != -1) {
                int x, y;
                this.translate_coordinates(window_manager, 0, 0, out x, out y);
                
                print("Translate: %i %i\n", x, y);
                
                window_alloc.x = x;
                window_alloc.y = y;
                window_alloc.width = alloc.width;
                window_alloc.height = alloc.height;
            } else {
                window_alloc.x = 0;
                window_alloc.y = 0;
                window_alloc.width = this.get_parent().get_allocated_width();
                window_alloc.height = this.get_parent().get_allocated_height();
            }
            
            print("window_alloc is: %i %i %i %i\n", window_alloc.x, window_alloc.y, window_alloc.width, window_alloc.height);

            return window_alloc;
        }
        
        public void set_allocate(Gtk.Fixed parent, int x, int y, int w, int h) {
            set_size_request(w, h);
            parent.move(this, x, y);
        }
    }
}