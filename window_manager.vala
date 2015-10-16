using Draw;
using Gdk;
using Gee;
using Gtk;
using Keymap;
using Utils;
using Widgets;
using Xcb;

namespace Widgets {
    public class WindowManager : Gtk.Fixed {
        public ArrayList<Widgets.Window> window_list;
        public HashMap<string, ArrayList<string>> mode_buffer_set;
        public HashMap<string, int> mode_window_set;
        public HashMap<string, int> mode_hide_window_set;
        public HashMap<string, string> mode_hide_path_set;
        public HashMap<string, string> mode_hide_name_set;
        public Widgets.Window focus_window;
        public Xcb.Connection conn;
        public int tab_counter;
        
        public signal void destroy_buffer(string buffer_id);
        public signal void destroy_window(int xid);
        public signal void destroy_windows(int[] xids);
        public signal void reparent_window(int xid);
        public signal void resize_window(int xid, int width, int height);
        
        private int cache_height = 0;
        private int cache_width = 0;
        
        public WindowManager() {
            set_can_focus(true);
            draw.connect(on_draw);
            conn = new Xcb.Connection();

            tab_counter = 0;
            window_list = new ArrayList<Widgets.Window>();
            mode_buffer_set = new HashMap<string, ArrayList<string>>();
            mode_window_set = new HashMap<string, int>();
            mode_hide_window_set = new HashMap<string, int>();
            mode_hide_path_set = new HashMap<string, string>();
            mode_hide_name_set = new HashMap<string, string>();
            
            realize.connect((w) => {
                    create_first_window();
                    
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
        
        private void create_first_window() {
            var window = new Widgets.Window(this);
            window.set_allocate(this, 0, 0, this.get_allocated_width(), this.get_allocated_height());
            
            window_list.add(window);
            set_focus_window(window);
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
            var windows_ids = window.tabbar.get_all_xids();
            var paths = window.tabbar.get_all_paths();
            var names = window.tabbar.get_all_names();
            var counter = 0;
            foreach (int xid in windows_ids) {
                var app_path = paths.get(counter);
                var tab_name = names.get(counter);
                
                var info = get_app_execute_info(app_path);
                var app_execute_path = info[0];
                
                tab_counter += 1;
                clone_window.tabbar.add_tab(tab_name, tab_counter, app_path);
                
                string app_command = "%s %i %i %i %i".printf(
                    app_execute_path,
                    clone_window.get_child_width(clone_window_width),
                    clone_window.get_child_height(clone_window_height),
                    tab_counter,
                    xid);
                spawn_app_process(app_command);
                
                counter++;
            }
            
            return clone_window;
        }
        
        private void spawn_app_process(string app_command) {
            try {
                Process.spawn_command_line_async(app_command);
            } catch (SpawnError e) {
                print("Got error when spawn_command_line_async: %s\n", e.message);
            }
        }
        
        public Window get_focus_window() {
            return focus_window;
        }
        
        public void split_window_horizontal() {
            if (window_list.size > 0) {
                var window = get_focus_window();
                create_clone_window(window, true);
            }
        }
        
        public void split_window_vertical() {
            if (window_list.size > 0) {
                var window = get_focus_window();
                create_clone_window(window, false);
            }
        }
        
        public void set_focus_window(Window new_window) {
            focus_window = new_window;
            foreach (Widgets.Window window in window_list) {
                window.queue_draw();
            }
        }
        
        public void focus_left_window() {
            focus_horizontal_window(true);
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
            if (window_list.size > 1) {
                ArrayList<Window> destroy_window_list = new ArrayList<Window>();
                foreach (Window window in window_list) {
                    if (window != focus_window) {
                        destroy_window_list.add(window);
                    }
                }
                
                int[] destroy_window_ids = {};
                HashMap<int, int> replace_tab_set = new HashMap<int, int>();
                foreach (Window window in destroy_window_list) {
                    if (window.mode_name == focus_window.mode_name) {
                        var counter = 0;
                        foreach (int tab_id in window.tabbar.tab_list) {
                            var window_type = window.tabbar.tab_window_type_set.get(tab_id);
                            if (window_type == "clone") {
                                destroy_window_ids += window.tabbar.tab_xid_set.get(tab_id);
                            } else if (window_type == "origin") {
                                var focus_window_tab_id = focus_window.tabbar.tab_list.get(counter);
                                var focus_xid = focus_window.tabbar.tab_xid_set.get(focus_window_tab_id);
                                destroy_window_ids += focus_xid;
                                
                                var tab_xid = window.tabbar.tab_xid_set.get(tab_id);
                                replace_tab_set.set(focus_window_tab_id, tab_xid);
                            }
                            
                            counter++;
                        }
                    } else {
                        var windows_ids = window.tabbar.get_all_xids();
                        foreach (int window_id in windows_ids) {
                            destroy_window_ids += window_id;
                        }
                    }
                    
                    window_list.remove(window);
                    window.destroy();
                }
                
                destroy_windows(destroy_window_ids);

                foreach (var entry in replace_tab_set.entries) {
                    var tab_id = entry.key;
                    var new_win_id = entry.value;
                    
                    focus_window.tabbar.set_tab_xid(tab_id, new_win_id);
                    focus_window.tabbar.set_tab_window_type(tab_id, "origin");
                }
                
                focus_window.set_allocate(this, 0, 0, this.get_allocated_width(), this.get_allocated_height(), true);
            }
        }
        
        public void close_current_window() {
            if (window_list.size > 1) {
                close_window(focus_window);
            }
        }
        
        private void close_window(Window window) {
            int[] destroy_window_ids = {};
            HashMap<int, int> replace_tab_set = new HashMap<int, int>();
            
            var counter = 0;
            foreach (int tab_id in focus_window.tabbar.tab_list) {
                var tab_xid = focus_window.tabbar.tab_xid_set.get(tab_id);
                var tab_window_type = focus_window.tabbar.tab_window_type_set.get(tab_id);
                
                if (tab_window_type == "clone") {
                    destroy_window_ids += tab_xid;
                } else if (tab_window_type == "origin") {
                    ArrayList<Window> same_mode_windows = new ArrayList<Window>();
                    foreach (Window win in window_list) {
                        if (win != focus_window && win.mode_name == focus_window.mode_name) {
                            same_mode_windows.add(win);
                        }
                    }
                    
                    if (same_mode_windows.size == 0) {
                        destroy_window_ids += tab_xid;
                    } else {
                        var replace_window = same_mode_windows.get(0);
                        var replace_window_tab_id = replace_window.tabbar.tab_list.get(counter)        ;
                        var replace_window_tab_xid = replace_window.tabbar.tab_xid_set.get(replace_window_tab_id);
                        
                        destroy_window_ids += replace_window_tab_xid;
                        
                        replace_tab_set.set(replace_window_tab_id, tab_xid);
                    }
                }
                
                counter++;
            }
            
            var brother_window = find_brother_window(window);
            if (brother_window != null) {
                set_focus_window(brother_window);
            }
            
            var window_rect_manager = new Utils.WindowRectangleManager(window_list);
            
            window_rect_manager.remove_window(window.window_xid);
            window_list.remove(window);
            window.destroy();
            
            destroy_windows(destroy_window_ids);
            
            foreach (var entry in replace_tab_set.entries) {
                var replace_tab_id = entry.key;
                var replace_win_id = entry.value;
                
                foreach (Window win in window_list) {
                    foreach (int tab_id in win.tabbar.tab_list) {
                        if (tab_id == replace_tab_id) {
                            win.tabbar.set_tab_xid(replace_tab_id, replace_win_id);
                            win.tabbar.set_tab_window_type(replace_tab_id, "origin");
                        }
                    }
                }
            }
            
            foreach (Utils.WindowRectangle rect in window_rect_manager.window_rectangle_list) {
                foreach (Window win in window_list) {
                    if (win.window_xid == rect.id) {
                        Gtk.Allocation alloc = win.get_allocate();
                        
                        if (rect.x == alloc.x && rect.y == alloc.y && rect.width == alloc.width && rect.height == alloc.height) {
                            var current_tab_xid = win.tabbar.get_current_tab_xid();
                            if (current_tab_xid != null) {
                                win.visible_tab(current_tab_xid);
                            }
                        } else {
                            win.set_allocate(this, rect.x, rect.y, rect.width, rect.height, true);
                        }
                    }
                }
            }
        }
        
        private Window? find_brother_window(Window window) {
            var window_rect_manager = new Utils.WindowRectangleManager(window_list);
            WindowRectangle? window_rect = null;
            foreach (WindowRectangle rect in window_rect_manager.window_rectangle_list) {
                if (rect.id == window.window_xid) {
                    window_rect = rect;
                    break;
                }
            }
            
            if (window_rect != null) {
                var brother_rect = window_rect_manager.find_brother_window(window_rect);
                if (brother_rect != null) {
                    foreach (Window w in window_list) {
                        if (w.window_xid == brother_rect.id) {
                            return w;
                        }
                    }
                } else {
                    var neighblor_windows = window_rect_manager.find_neighblor_windows(window_rect);
                    if (neighblor_windows.length > 0) {
                        var neighblor_window = neighblor_windows[0];
                        foreach (Window w in window_list) {
                            if (w.window_xid == neighblor_window.id) {
                                return w;
                            }
                        }
                    }
                }
            }
            
            return null;
        }
        
        public void update_windows_allocate() {
            var alloc_width = get_allocated_width();
            var alloc_height = get_allocated_height();
            if (alloc_width != cache_width || alloc_height != cache_height) {
                if (cache_width != 0 && cache_height != 0) {
                    var window_rect_manager = new Utils.WindowRectangleManager(window_list);
                    window_rect_manager.scale_windows(alloc_width / (float)cache_width, alloc_height / (float)cache_height, alloc_width, alloc_height);
                    
                    foreach (Utils.WindowRectangle rect in window_rect_manager.window_rectangle_list) {
                        foreach (Window window in window_list) {
                            if (window.window_xid == rect.id) {
                                window.set_allocate(this, rect.x, rect.y, rect.width, rect.height, true);
                                break;
                            }
                        }
                    }
                }
                
                cache_width = alloc_width;
                cache_height = alloc_height;
            }
        }
        
        public void new_tab(string app_path) {
            var info = get_app_execute_info(app_path);
            var app_execute_path = info[0];
            var mode_name = info[1];
            
            var window = get_focus_window();
            if (window != null) {
                switch_mode(window, mode_name);
                
                var window_child_size = window.get_child_allocate();
                
                tab_counter += 1;
                window.tabbar.add_tab("", tab_counter, app_path);
                
                string app_command = "%s %i %i %i".printf(
                    app_execute_path,
                    window_child_size[0],
                    window_child_size[1],
                    tab_counter);
                
                spawn_app_process(app_command);
                print("*******************\n");
            }
        }
        
        public void switch_to_next_mode() {
            if (mode_buffer_set.size > 1) {
                print("switch_to_next_mode: %s %i\n", focus_window.mode_name, mode_buffer_set.size);
                
                bool found_current_mode = false;
                string? first_mode_name = null;
                string? next_mode_name = null;
                var counter = 0;
                foreach (var entry in mode_buffer_set.entries) {
                    string mode_name = entry.key;
                    
                    if (counter == 0) {
                        first_mode_name = mode_name;
                    }
                    
                    if (found_current_mode) {
                        next_mode_name = mode_name;
                        break;
                    } else if (focus_window.mode_name == mode_name && counter != mode_buffer_set.size - 1) {
                        found_current_mode = true;
                    }
                    
                    counter++;
                }
                
                if (!found_current_mode) {
                    next_mode_name = first_mode_name;
                }
                
                if (next_mode_name != null) {
                    switch_mode(focus_window, next_mode_name);
                    print("switch_to_next_mode\n");
                } else {
                    print("switch_to_next_mode: possible here!\n");
                }
            }
        }
        
        public void switch_to_prev_mode() {
            if (mode_buffer_set.size > 1) {
                print("switch_to_prev_mode: %s %i\n", focus_window.mode_name, mode_buffer_set.size);
                
                bool found_current_mode = false;
                string? prev_mode_name = null;
                foreach (var entry in mode_buffer_set.entries) {
                    string mode_name = entry.key;
                    
                    if (focus_window.mode_name == mode_name) {
                        found_current_mode = true;
                        break;
                    }
                    
                    prev_mode_name = mode_name;
                }
                
                if (found_current_mode) {
                    if (prev_mode_name == null) {
                        var counter = 0;
                        foreach (var entry in mode_buffer_set.entries) {
                            string mode_name = entry.key;
                            
                            if (counter == mode_buffer_set.size - 1) {
                                switch_mode(focus_window, mode_name);
                                print("switch_to_prev_mode 1\n");
                                break;
                            }
                            
                            counter++;
                        }
                    } else {
                        switch_mode(focus_window, prev_mode_name);
                        print("switch_to_prev_mode 2\n");
                    }
                }

            }
        }
        
        private void switch_mode(Window window, string mode_name) {
            if (window.mode_name != mode_name) {
                print("** switch_mode window %i mode_name %s\n", window.window_xid, window.mode_name);
                
                // Record buffers of current mode.
                int[] remove_clone_windows = {};
                var hide_windows = new ArrayList<int>();
                var replace_tab_set = new HashMap<int, int>();
                int counter = 0;
                foreach (int tab_id in window.tabbar.tab_list) {
                    var window_type = window.tabbar.tab_window_type_set.get(tab_id);
                    var window_xid = window.tabbar.tab_xid_set.get(tab_id);
                    var buffer_id = window.tabbar.tab_buffer_set.get(tab_id);
                    var app_path = window.tabbar.tab_path_set.get(tab_id);
                    var tab_name = window.tabbar.tab_name_set.get(tab_id);
                    
                    print("switch_mode tab %i with window type %s\n", tab_id, window_type);
                    
                    if (window_type == "clone") {
                        remove_clone_windows += window_xid;
                    } else if (window_type == "origin") {
                        var same_mode = false;
                        foreach (Window win in window_list) {
                            if (win != window && win.mode_name == window.mode_name) {
                                same_mode = true;
                                
                                int replace_tab_id = win.tabbar.tab_list.get(counter);
                                int replace_window_xid = win.tabbar.tab_xid_set.get(replace_tab_id);
                                
                                replace_tab_set.set(replace_tab_id, window_xid);
                                
                                remove_clone_windows += replace_window_xid;
                                break;
                            }
                        }
                        
                        print("switch_mode same_mode %s\n", same_mode.to_string());
                        
                        if (!same_mode) {
                            hide_windows.add(window_xid);
                            mode_hide_window_set.set(buffer_id, window_xid);
                            mode_hide_path_set.set(buffer_id, app_path);
                            mode_hide_name_set.set(buffer_id, tab_name);
                        }
                    }

                    counter++;
                }
                
                destroy_windows(remove_clone_windows);
                print("switch_mode destroy_windows %i\n", remove_clone_windows.length);
                
                foreach (int hide_window in hide_windows) {
                    conn.unmap_window(hide_window);
                    conn.flush();
                    
                    print("switch_mode hide_window %i\n", hide_window);
                }
                
                foreach (var entry in replace_tab_set.entries) {
                    var replace_tab_id = entry.key;
                    var replace_win_id = entry.value;
                    
                    foreach (Window win in window_list) {
                        foreach (int tab_id in win.tabbar.tab_list) {
                            if (tab_id == replace_tab_id) {
                                win.tabbar.set_tab_xid(replace_tab_id, replace_win_id);
                                win.tabbar.set_tab_window_type(replace_tab_id, "origin");
                                
                                print("switch_mode replace %i with %i\n", replace_tab_id, replace_win_id);
                            }
                        }
                    }
                }
                
                window.tabbar.reset();
                print("switch_mode %i reset tab\n", window.window_xid);
                
                // Rebuild window's tabs.
                var buffer_list = mode_buffer_set.get(mode_name);
                if (buffer_list != null && buffer_list.size > 0) {
                    foreach (string buffer_id in buffer_list) {
                        tab_counter++;
                        
                        var buffer_origin_window = mode_window_set.get(buffer_id);
                        int? hide_window = mode_hide_window_set.get(buffer_id);
                        if (hide_window != null && buffer_origin_window == hide_window) {
                            conn.map_window(buffer_origin_window);
                            conn.flush();
                            
                            var app_path = mode_hide_path_set.get(buffer_id);
                            var tab_name = mode_hide_name_set.get(buffer_id);
                            window.tabbar.add_tab(tab_name, tab_counter, app_path);
                            
                            window.tabbar.set_tab_xid(tab_counter, hide_window);
                            window.tabbar.set_tab_buffer(tab_counter, buffer_id);
                            window.tabbar.set_tab_window_type(tab_counter, "origin");
                            
                            mode_hide_window_set.unset(buffer_id);
                            mode_hide_path_set.unset(buffer_id);
                            mode_hide_name_set.unset(buffer_id);
                            
                            window.visible_tab(hide_window);
                            
                            print("switch_mode visible tab %i %i\n", tab_counter, hide_window);
                        } else {
                            foreach (Window win in window_list) {
                                if (win != window) {
                                    foreach (int tab_id in win.tabbar.tab_list) {
                                        var window_xid = win.tabbar.tab_xid_set.get(tab_id);
                                        if (window_xid == buffer_origin_window) {
                                            var tab_name = win.tabbar.tab_name_set.get(tab_id);
                                            var app_path = win.tabbar.tab_path_set.get(tab_id);
                                            window.tabbar.add_tab(tab_name, tab_counter, app_path);
                                            
                                            var info = get_app_execute_info(app_path);
                                            var app_execute_path = info[0];
                                            var window_child_size = window.get_child_allocate();
                                            
                                            string app_command = "%s %i %i %i %i".printf(
                                                app_execute_path,
                                                window_child_size[0],
                                                window_child_size[1],
                                                tab_counter,
                                                window_xid);
                    
                                            spawn_app_process(app_command);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                window.resize_tab_windows();
                
                window.mode_name = mode_name;
                print("** switch_mode switch window % to mode %s\n", window.window_xid, window.mode_name);
            }
        }
        
        private void add_in_mode_set(string mode_name, string buffer_id, int window_id) {
            var buffer_list = mode_buffer_set.get(mode_name);
            if (buffer_list != null) {
                buffer_list.add(buffer_id);
            } else {
                var list = new ArrayList<string>();
                list.add(buffer_id);
                mode_buffer_set.set(mode_name, list);
            }
            
            mode_window_set.set(buffer_id, window_id);
            
            print("Add %s %s in mode_buffer_set\n", mode_name, buffer_id);
        }
        
        private void remove_from_mode_set(string mode_name, string buffer_id) {
            var buffer_list = mode_buffer_set.get(mode_name);
            if (buffer_list != null) {
                foreach (string buffer in buffer_list) {
                    if (buffer == buffer_id) {
                        print("Remove %s %s from mode_buffer_set\n", mode_name, buffer_id);
                        buffer_list.remove(buffer);
                        
                        mode_window_set.unset(buffer_id);
                        break;
                    }
                }
                
                if (buffer_list.size == 0) {
                    mode_buffer_set.unset(mode_name);
                }
            }
        }
        
        private string[] get_app_execute_info(string app_path) {
            string[] info = {};
            
            var parser = new Json.Parser();
            try {
                parser.load_from_file("%s/app.json".printf(app_path));
            } catch (GLib.Error e) {
                print("Got error when load %s/app.json: %s\n", app_path, e.message);
            }
            var root_object = parser.get_root ().get_object();
            info += "%s/%s".printf(app_path, root_object.get_string_member("execute"));
            info += root_object.get_string_member("mode-name");

            return info;
        }
        
        public void close_tab_with_buffer(string mode_name, string buffer_id) {
            foreach (Window window in window_list) {
                if (window.mode_name == mode_name) {
                    window.tabbar.close_tab_with_buffer(buffer_id);
                }
            }
            
            destroy_buffer(buffer_id);

            switch_to_next_mode();
            
            remove_from_mode_set(mode_name, buffer_id);
        }
        
        public void close_tab(Window current_window, string mode_name, int tab_index, string buffer_id) {
            foreach (Window window in window_list) {
                if (window != current_window && window.mode_name == current_window.mode_name) {
                    window.tabbar.close_nth_tab(tab_index, false);
                }
            }
            
            destroy_buffer(buffer_id);

            switch_to_next_mode();
            
            remove_from_mode_set(mode_name, buffer_id);
        }
        
        public void rename_tab_with_buffer(string mode_name, string buffer_id, string buffer_name) {
            foreach (Window window in window_list) {
                if (window.mode_name == mode_name) {
                    window.tabbar.rename_tab(buffer_id, buffer_name);
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
        
        public void show_tab(int app_win_id, string mode_name, int tab_id, string buffer_id, string window_type) {
            print("!!!!!!!!!!!!!!!!!!!\n");
            var window = get_window_with_tab_id(tab_id);
            if (window != null) {
                if (window.mode_name == "") {
                    window.mode_name = mode_name;
                }
                
                if (window_type == "origin") {
                    add_in_mode_set(mode_name, buffer_id, app_win_id);
                }
                
                window.tabbar.set_tab_xid(tab_id, app_win_id);
                window.tabbar.set_tab_buffer(tab_id, buffer_id);
                window.tabbar.set_tab_window_type(tab_id, window_type);
                window.tabbar.select_tab_with_id(tab_id);
                
                window.visible_tab(app_win_id);
                
                sync_windows(window);
                
                print("#################\n");
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
                    var names = window.tabbar.get_all_names();
                    var clone_buffers = current_buffers[buffers.size:current_buffers.size];
                    var clone_paths = current_paths[buffers.size:current_buffers.size];

                    int counter = 0; 
                    foreach (string clone_buffer in clone_buffers) {
                        var app_path = clone_paths.get(counter);
                        var window_child_size = window.get_child_allocate();
                        var tab_name = names.get(counter);
                        tab_counter += 1;
                        
                        var info = get_app_execute_info(app_path);
                        var app_execute_path = info[0];
                        
                        window.tabbar.add_tab(tab_name, tab_counter, app_path);

                        string app_command = "%s %i %i %i %s".printf(
                            app_execute_path,
                            window_child_size[0],
                            window_child_size[1],
                            tab_counter,
                            clone_buffer);
                        
                        spawn_app_process(app_command);
                        
                        counter++;
                    }
                }
            }
        }
    }
}