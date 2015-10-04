using Gee;

namespace Widgets {
    public class Window : Gtk.EventBox {
        public Gtk.Notebook notebook;
        public Widgets.Tab tab;
        public int window_x;
        public int window_y;
        public int window_width;
        public int window_height;
        public string mode_name = "";
        
        public int padding = 1;
        
        private HashMap<int, Widgets.Tab> tab_set;
        
        public Window() {
            var align = new Gtk.Alignment(0, 0, 1, 1);
            align.top_padding = padding;
            align.bottom_padding = padding;
            align.left_padding = padding;
            align.right_padding = padding;
            add(align);
            
            notebook = new Gtk.Notebook();
            align.add(notebook);
            
            draw.connect(on_draw);
            
            tab_set = new HashMap<int, Widgets.Tab>();
        }
        
        public void add_tab(string tab_name, int tab_id) {
            var tab_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            tab = new Widgets.Tab(tab_name);
            tab_set.set(tab_id, tab);
            notebook.append_page(tab_box, tab);
            show_all();
        }
        
        public Widgets.Tab get_current_tab() {
            return (Widgets.Tab) notebook.get_tab_label(get_current_tab_box());
        }

        public Gtk.Widget get_current_tab_box() {
            int current_index = notebook.get_current_page();
            return notebook.get_nth_page(current_index);
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