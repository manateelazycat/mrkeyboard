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
        public int focus_page = 0;
        
        public int padding = 1;
        
        public HashMap<int, Widgets.Tab> tab_set;
        
        public signal void switch_page(int old_xid, int new_xid);
        
        public Window() {
            var align = new Gtk.Alignment(0, 0, 1, 1);
            align.top_padding = padding;
            align.bottom_padding = padding;
            align.left_padding = padding;
            align.right_padding = padding;
            add(align);
            
            notebook = new Gtk.Notebook();
            
            // NOTE: we need make notebook don't grab focus by tab widget.
            // Otherwise, daemon can't receive 'space' key!!!
            notebook.set_can_focus(false);
            
            align.add(notebook);
            
            draw.connect(on_draw);
            
            tab_set = new HashMap<int, Widgets.Tab>();
            
            notebook.page_added.connect((page, page_num) => {
                    on_page_added(page, (int)page_num);
                });
            
            notebook.switch_page.connect((page, page_num) => {
                    on_switch_page(page, (int)page_num);
                });
        }
        
        public void on_page_added(Gtk.Widget widget, int page_index) {
            if (page_index != focus_page) {
                var tab = get_nth_tab(focus_page);
                print("******* Page add hide: %i\n", tab.tab_xid);
            }

            var tab = get_nth_tab(page_index);
            print("******* Page add show: %i\n", tab.tab_xid);
            
            switch_page(get_nth_tab(focus_page).tab_xid,
                        get_nth_tab(page_index).tab_xid);
            
            focus_page = page_index;
            
            // NOTE: We need show page child first, unless notebook refuse to switch page!
            notebook.get_nth_page(page_index).show_all();
            notebook.set_current_page(page_index);
            
            print("******* Page add: %u\n", page_index);
        }
        
        public void on_switch_page(Gtk.Widget widget, int page_index) {
            if (page_index != focus_page) {
                var tab = get_nth_tab(focus_page);
                print("Hide: %i\n", tab.tab_xid);
            }

            var tab = get_nth_tab(page_index);
            print("Show: %i\n", tab.tab_xid);
            
            switch_page(get_nth_tab(focus_page).tab_xid,
                        get_nth_tab(page_index).tab_xid);
            
            focus_page = page_index;
            
            print("Select page: %u\n", page_index);
        }
        
        public void add_tab(string tab_name, int tab_id) {
            var tab_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            tab = new Widgets.Tab(tab_name);
            tab_set.set(tab_id, tab);
            notebook.append_page(tab_box, tab);
            show_all();
        }
        
        public Widgets.Tab get_nth_tab(int tab_index) {
            return (Widgets.Tab) notebook.get_tab_label(notebook.get_nth_page(tab_index));
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