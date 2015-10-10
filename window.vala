using Draw;
using Gee;
using Widgets;

namespace Widgets {
    public class Window : Gtk.EventBox {
        public Gdk.Color window_frame_active_color = Utils.color_from_hex("#536773");
        public Gdk.Color window_frame_color = Utils.color_from_hex("#262721");
        public Gtk.Box window_content_area;
        public Widgets.Tabbar tabbar;
        public int padding = 1;
        public int window_xid;
        public string mode_name = "";
        
        private Widgets.WindowManager window_manager;
        private bool visible_tab_after_size = false;
        
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
            realize.connect((w) => {
                    window_xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                });
            size_allocate.connect((w, r) => {
                    on_size_allocate(w, r);
                });

            tabbar.destroy_buffer.connect((index, buffer_id) => {
                    window_manager.close_tab(this, mode_name, index, buffer_id);
                });
            tabbar.focus_window.connect((xid) => {
                    visible_tab(xid);
                });
            
            show_all();
            window_manager.add(this);
        }
        
        public void visible_tab(int xid) {
            var window_manager_xid = (int)((Gdk.X11.Window) window_manager.get_window()).get_xid();
            int x, y;
            window_content_area.translate_coordinates(window_manager.get_toplevel(), 0, 0, out x, out y);
            
            window_manager.conn.reparent_window(
                xid,
                window_manager_xid,
                (uint16)x,
                (uint16)y);
            window_manager.conn.flush();
            
            window_manager.reparent_window(xid);
        }
        
        public bool on_size_allocate(Gtk.Widget widget, Gdk.Rectangle rect) {
            resize_tab_windows();
            
            if (visible_tab_after_size) {
                var xid = tabbar.get_current_tab_xid();
                if (xid != null) {
                    visible_tab(xid);
                }
                
                visible_tab_after_size = false;
            }
            
            return false;
        }
        
        public void resize_tab_windows() {
            var size = get_child_allocate();
            
            var xids = tabbar.get_all_xids();
            foreach (int xid in xids) {
                window_manager.resize_window(
                    xid,
                    size[0],
                    size[1]
                    );
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            
            Utils.set_context_color(cr, window_frame_color);
            Draw.draw_rectangle(cr, 0, 0, width, height, false);
            
            if (window_manager.focus_window == this) {
                Utils.set_context_color(cr, window_frame_active_color);
                Draw.draw_rectangle(cr, padding * 2, height - 1, width - padding * 4, 1, false);
            }
            
            return false;
        }
        
        public int[] get_child_allocate() {
            Gtk.Allocation window_alloc = get_allocate();
            var size = new int[2];
            size[0] = get_child_width(window_alloc.width);
            size[1] = get_child_height(window_alloc.height);
            
            return size;
        }
        
        public int get_child_width(int window_width) {
            return window_width - padding * 2;;
        }
        
        public int get_child_height(int window_height) {
            return window_height - padding * 2 - tabbar.height;
        }
        
        public Gtk.Allocation get_allocate() {
            Gtk.Allocation window_alloc = Gtk.Allocation();

            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            if (alloc.x != -1) {
                int x, y;
                this.translate_coordinates(window_manager, 0, 0, out x, out y);

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
            
            return window_alloc;
        }
        
        public void set_allocate(Gtk.Fixed parent, int x, int y, int w, int h, bool visible_tab=false) {
            visible_tab_after_size = visible_tab;
            
            parent.move(this, x, y);
            set_size_request(w, h);
        }
    }
}