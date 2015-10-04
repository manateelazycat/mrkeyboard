using Gee;
using Widgets;

namespace Widgets {
    public class Window : Gtk.EventBox {
        public Widgets.Tabbar tabbar;
        public Gtk.Box window_content_area;
        public int window_x;
        public int window_y;
        public int window_width;
        public int window_height;
        public string mode_name = "";
        
        public int padding = 1;
        
        public Window() {
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
            show_all();
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            cr.set_source_rgb(1, 0, 0);
            cr.rectangle(0, 0, width, height);
            cr.stroke();
            
            return false;
        }
        
        public void set_allocate(Gtk.Fixed parent, int x, int y, int w, int h) {
            window_x = x;
            window_y = y;
            window_width = w;
            window_height = h;
            
            set_size_request(window_width, window_height);
            parent.put(this, x, y);
        }
    }
}