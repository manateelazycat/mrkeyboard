using Gtk;
using Gdk;
using Keymap;
using Xcb;
using Gee;
using Widgets;

namespace Widgets {
    public class WindowManager : Gtk.Fixed {
        public int tab_counter;
        public ArrayList<Widgets.Window> window_list;
        public Widgets.Window focus_window;
        public HashMap<int, Gtk.Box> tab_list;
        private Xcb.Connection conn;
        private int xid;
        
        public WindowManager() {
            set_can_focus(true);
            draw.connect(on_draw);
            conn = new Xcb.Connection();

            tab_counter = 0;
            window_list = new ArrayList<Widgets.Window>();
            tab_list = new HashMap<int, Gtk.Box>();
            
            realize.connect((w) => {
                    xid = (int)((Gdk.X11.Window) get_window()).get_xid(); 
                    grab_focus();
                });
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            cr.set_source_rgb(23 / 255.0, 24 / 255.0, 20 / 255.0);
            cr.rectangle(0, 0, width, height);
            cr.fill();
            
            return false;
        }
        
        public Window get_focus_window() {
            if (window_list.size == 0) {
                var window = new Widgets.Window();
                window.set_allocate(this, 0, 0, this.get_allocated_width(), this.get_allocated_height());
                
                window_list.add(window);
                focus_window = window;

                return window;
            } else {
                return focus_window;
            }
        }
        
        public void new_tab(string app_path) {
            var window = get_focus_window();
            
            tab_counter += 1;
            var tab_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            tab_list.set(tab_counter, tab_box);
            window.add_tab("Tab", tab_box);
            
            string app_command = "%s %i %i %i".printf(
                app_path,
                window.window_width - window.padding * 2,
                window.window_height - window.padding * 2 - window.tab.height,
                tab_counter);
            try {
                Process.spawn_command_line_async(app_command);
            } catch (SpawnError e) {
                print("Got error when spawn_command_line_async: %s\n", e.message);
            }
        }
        
        public void show_tab(int app_win_id, string mode_name, int tab_id) {
            var tab_box = tab_list.get(tab_id);
            
            Gtk.Allocation tab_box_alloc;
            tab_box.get_allocation(out tab_box_alloc);

            Gtk.Allocation window_alloc;
            var window = get_focus_window();
            window.get_allocation(out window_alloc);
            
            conn.reparent_window(app_win_id, xid,
                                 (uint16)window_alloc.x + (uint16)tab_box_alloc.x,
                                 (uint16)window_alloc.y + (uint16)tab_box_alloc.y);
            conn.flush();
        }
    }
}