using Gtk;
using Gdk;
using Keymap;
using Xcb;
using Gee;
using Widgets;
using Draw;
using Utils;

namespace Widgets {
    public class WindowManager : Gtk.Fixed {
        public int tab_counter;
        public ArrayList<Widgets.Window> window_list;
        public Widgets.Window focus_window;
        public Xcb.Connection conn;
        
        public signal void reparent_page(int xid);
        public signal void close_page(string buffer_id);
        public signal void resize_page(int xid, int width, int height);
        
        public WindowManager() {
            set_can_focus(true);
            draw.connect(on_draw);
            conn = new Xcb.Connection();

            tab_counter = 0;
            window_list = new ArrayList<Widgets.Window>();
            
            realize.connect((w) => {
                    grab_focus();
                });
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            int width = widget.get_allocated_width();
            int height = widget.get_allocated_height();
            cr.set_source_rgb(23 / 255.0, 24 / 255.0, 20 / 255.0);
            Draw.draw_rectangle(cr, 0, 0, width, height);
            
            return false;
        }
        
        public int? get_focus_tab_xid() {
            if (window_list.size == 0) {
                return null;
            } else {
                var window = get_focus_window();
                
                return window.tabbar.get_current_tab_xid();
            }
        }
        
        private Window create_first_window() {
            var window = new Widgets.Window(this);
            window.set_allocate(this, 0, 0, this.get_allocated_width(), this.get_allocated_height());
            
            window_list.add(window);
            set_focus_window(window);

            return window;
        }
        
        private Window create_clone_window(Widgets.Window window, bool is_horizontal=true) {
            var clone_window = new Widgets.Window(this);
            Gtk.Allocation alloc;
            window.get_allocation(out alloc);

            var window_alloc = window.get_allocate();
            int clone_window_width;
            int clone_window_height;
            
            if (is_horizontal) {
                clone_window_width = alloc.width;
                clone_window_height = alloc.height - alloc.height / 2;
                
                window.set_allocate(this,
                                    window_alloc.x,
                                    window_alloc.y,
                                    alloc.width,
                                    alloc.height / 2
                                    );
                
                clone_window.set_allocate(this,
                                          window_alloc.x,
                                          window_alloc.y + alloc.height / 2,
                                          clone_window_width,
                                          clone_window_height
                                          );
            } else {
                clone_window_width = alloc.width - alloc.width / 2;
                clone_window_height = alloc.height;
                
                window.set_allocate(this,
                                    window_alloc.x,
                                    window_alloc.y,
                                    alloc.width / 2,
                                    alloc.height
                                    );
                
                clone_window.set_allocate(this,
                                          window_alloc.x + alloc.width / 2,
                                          window_alloc.y,
                                          clone_window_width,
                                          clone_window_height
                                          );
            }
            
            window_list.add(clone_window);
            
            // Clone tabs.
            var xids = window.tabbar.get_all_xids();
            var paths = window.tabbar.get_all_paths();
            var counter = 0;
            foreach (int xid in xids) {
                var app_path = paths.get(counter);
                
                tab_counter += 1;
                clone_window.tabbar.add_tab("Tab", tab_counter, app_path);
                
                string app_command = "%s %i %i %i %i".printf(
                    app_path,
                    clone_window_width - clone_window.padding * 2,
                    clone_window_height - clone_window.padding * 2 - clone_window.tabbar.height,
                    tab_counter,
                    xid);
            
                try {
                    Process.spawn_command_line_async(app_command);
                } catch (SpawnError e) {
                    print("Got error when spawn_command_line_async: %s\n", e.message);
                }
                
                counter++;
            }
            
            return clone_window;
        }
        
        public Window get_focus_window() {
            if (window_list.size == 0) {
                return create_first_window();
            } else {
                return focus_window;
            }
        }
        
        public void split_window_horizontal() {
            var window = get_focus_window();
            create_clone_window(window, true);
        }
        
        public void split_window_vertical() {
            var window = get_focus_window();
            create_clone_window(window, false);
        }
        
        public void set_focus_window(Window new_window) {
            focus_window = new_window;
            foreach (Window window in window_list) {
                window.queue_draw();
            }
        }
        
        public bool focus_left_window() {
            focus_horizontal_window(true);
            
            return false;
        }
        
        public void focus_right_window() {
            focus_horizontal_window(false);
        }

        public void focus_up_window() {
            focus_vertical_window(true);
        }
        
        public void focus_down_window() {
            focus_vertical_window(false);
        }
        
        private bool focus_horizontal_window(bool focus_left) {
            if (window_list.size > 1) {
                var overlap_windows = new HashMap<int, Window>();
                int max_overlap = 0;
                
                var w_alloc = focus_window.get_allocate();
                foreach (Window brother_window in window_list) {
                    var b_alloc = brother_window.get_allocate();
                    if ((focus_left && w_alloc.x == b_alloc.x + b_alloc.width) || (!focus_left && w_alloc.x + w_alloc.width == b_alloc.x)) {
                        if (b_alloc.y < w_alloc.y && b_alloc.y + b_alloc.height >= w_alloc.y + w_alloc.height) {
                            set_focus_window(brother_window);
                            return true;
                        }
                        var overlap = (b_alloc.height + w_alloc.height - (b_alloc.y - w_alloc.y).abs() - (b_alloc.y + b_alloc.height - w_alloc.y - w_alloc.height).abs() / 2);
                        
                        if (overlap > max_overlap) {
                            max_overlap = overlap;
                        }
                        
                        overlap_windows.set(overlap, brother_window);
                    }
                }
                
                var max_overlap_window = overlap_windows.get(max_overlap);
                if (max_overlap_window != null) {
                    set_focus_window(max_overlap_window);
                }
            }
            
            return false;
        }

        private bool focus_vertical_window(bool focus_up) {
            if (window_list.size > 1) {
                var overlap_windows = new HashMap<int, Window>();
                int max_overlap = 0;
                
                var w_alloc = focus_window.get_allocate();
                foreach (Window brother_window in window_list) {
                    var b_alloc = brother_window.get_allocate();
                    if ((focus_up && w_alloc.y == b_alloc.y + b_alloc.height) || (!focus_up && w_alloc.y + w_alloc.height == b_alloc.y)) {
                        if (b_alloc.x < w_alloc.x && b_alloc.x + b_alloc.width >= w_alloc.x + w_alloc.width) {
                            set_focus_window(brother_window);
                            return true;
                        }
                        
                        var overlap = (b_alloc.width + w_alloc.width - (b_alloc.x - w_alloc.x).abs() - (b_alloc.x + b_alloc.width - w_alloc.x - w_alloc.width).abs() / 2);
                        
                        if (overlap > max_overlap) {
                            max_overlap = overlap;
                        }
                        
                        overlap_windows.set(overlap, brother_window);
                    }
                }
                
                var max_overlap_window = overlap_windows.get(max_overlap);
                if (max_overlap_window != null) {
                    set_focus_window(max_overlap_window);
                }
            }
            
            return false;
        }
        
        public void close_other_windows() {
            print("close other windows\n");
        }
        
        public void close_current_window() {
            print("close current window\n");
        }
        
        public void new_tab(string app_path) {
            var window = get_focus_window();
            var window_alloc = window.get_allocate();
            
            tab_counter += 1;
            window.tabbar.add_tab("Tab", tab_counter, app_path);
            
            string app_command = "%s %i %i %i".printf(
                app_path,
                window_alloc.width - window.padding * 2,
                window_alloc.height - window.padding * 2 - window.tabbar.height,
                tab_counter);
            
            try {
                Process.spawn_command_line_async(app_command);
            } catch (SpawnError e) {
                print("Got error when spawn_command_line_async: %s\n", e.message);
            }
        }
        
        public void close_tab_with_buffer(string mode_name, string buffer_id) {
            foreach (Window window in window_list) {
                if (window.mode_name == mode_name) {
                    window.tabbar.close_tab_with_buffer(buffer_id);
                }
            }
            
            close_page(buffer_id);

            clean_windows();
        }
        
        public void close_tab(Window current_window, string mode_name, int tab_index, string buffer_id) {
            foreach (Window window in window_list) {
                if (window != current_window && window.mode_name == current_window.mode_name) {
                    window.tabbar.close_nth_tab(tab_index, false);
                }
            }
            
            close_page(buffer_id);

            clean_windows();
        }
        
        public void clean_windows() {
            var window_rect_manager = new Utils.WindowRectangleManager(window_list);
            window_rect_manager.remove_blank_windows();
            
            foreach (Utils.WindowRectangle rect in window_rect_manager.window_rectangle_list) {
                foreach (Window window in window_list) {
                    if (window.window_xid == rect.id) {
                        print("set_allocate: %i %i %i %i\n", rect.x, rect.y, rect.width, rect.height);
                        window.set_allocate(this, rect.x, rect.y, rect.width, rect.height);
                        break;
                    }
                }
            }
            
            foreach (Utils.WindowRectangle rect in window_rect_manager.window_remove_list) {
                foreach (Window window in window_list) {
                    if (window.window_xid == rect.id) {
                        window_list.remove(window);
                        window.destroy();
                        break;
                    }
                }
            }
        }
        
        public Window? get_window_with_tab_id(int tab_id) {
            foreach (Window window in window_list) {
                foreach (int id in window.tabbar.tab_list) {
                    if (id == tab_id) {
                        return window;
                    }
                }
            }
            
            return null;
        }
        
        public void show_tab(int app_win_id, string mode_name, int tab_id, string buffer_id) {
            var window = get_window_with_tab_id(tab_id);
            if (window != null) {
                if (window.mode_name == "") {
                    window.mode_name = mode_name;
                }
                
                window.tabbar.set_tab_xid(tab_id, app_win_id);
                window.tabbar.set_tab_buffer(tab_id, buffer_id);
                window.tabbar.select_tab_with_id(tab_id);
                
                window.visible_tab(app_win_id);
                
                sync_windows(window);
            } else {
                print("Can't found window that contain tab_id: %i\n", tab_id);
            }
        }
        
        private void sync_windows(Widgets.Window current_window) {
            var current_buffers = current_window.tabbar.get_all_buffers();
            var current_paths = current_window.tabbar.get_all_paths();
            foreach (Widgets.Window window in window_list) {
                if (window != current_window && window.mode_name == current_window.mode_name) {
                    var buffers = window.tabbar.get_all_buffers();
                    var clone_buffers = current_buffers[buffers.size:current_buffers.size];
                    var clone_paths = current_paths[buffers.size:current_buffers.size];

                    int counter = 0; 
                    foreach (string clone_buffer in clone_buffers) {
                        var app_path = clone_paths.get(counter);
                        var window_alloc = window.get_allocate();
                        tab_counter += 1;
                        
                        window.tabbar.add_tab("Tab", tab_counter, app_path);

                        string app_command = "%s %i %i %i %s".printf(
                            app_path,
                            window_alloc.width - window.padding * 2,
                            window_alloc.height - window.padding * 2 - window.tabbar.height,
                            tab_counter,
                            clone_buffer);
                        
                        try {
                            Process.spawn_command_line_async(app_command);
                        } catch (SpawnError e) {
                            print("Got error when spawn_command_line_async: %s\n", e.message);
                        }
                        
                        counter++;
                    }
                }
            }
        }
    }
}