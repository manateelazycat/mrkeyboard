using Draw;
using Gdk;
using Gee;
using Gtk;
using Keymap;
using Utils;
using Widgets;
using Xcb;
using WindowMode;

namespace Widgets {
    public class WindowManager : Gtk.Fixed {
        public ArrayList<Widgets.Window> window_list;
        public WindowMode.WindowMode window_mode;
        public Widgets.Window focus_window;
        public Xcb.Connection conn;
        public int tab_id_counter;
        public HashSet<int> tab_visible_set;
        
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
			conn = X.GetConnection(Gdk.X11.get_default_xdisplay());

            tab_id_counter = 0;
            window_list = new ArrayList<Widgets.Window>();
            window_mode = new WindowMode.WindowMode(conn);
            tab_visible_set = new HashSet<int>();
            
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
        
        public bool focus_window_with_tab(int tab_win_id) {
            foreach (Window window in window_list) {
                foreach (var entry in window.tabbar.tab_xid_map.entries) {
                    if (entry.value == tab_win_id) {
                        set_focus_window(window);
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        public void update_tab_percent(string buffer_id, int percent) {
            foreach (Window window in window_list) {
                window.tabbar.percent_tab(buffer_id, percent);
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
            var apps = window.tabbar.get_all_apps();
            var names = window.tabbar.get_all_names();
            var paths = window.tabbar.get_all_paths();
            var types = window.tabbar.get_all_types();
            var buffers = window.tabbar.get_all_buffers();
            var counter = 0;
            foreach (int xid in windows_ids) {
                var app = apps.get(counter);
                var tab_name = names.get(counter);
                var tab_path = paths.get(counter);
                var buffer_id = buffers.get(counter);
                var window_type = types.get(counter);
                string last_arg = "";
                if (window_type == "multiview") {
                    last_arg = buffer_id;
                } else {
                    last_arg = xid.to_string();
                }
                
                tab_id_counter++;
                clone_window.tabbar.add_tab(tab_name, tab_path, tab_id_counter, app);
                start_app_process(
                    app,
                    tab_path,
                    clone_window.get_child_width(clone_window_width),
                    clone_window.get_child_height(clone_window_height),
                    last_arg);
                
                counter++;
            }
            
            return clone_window;
        }
        
        private void start_app_process(string app, string path, int window_width, int window_height, string other_arg = "") {
            var info = get_app_execute_info(app);
			if (info != null) {
				string app_command = "%s '%s' %i %i %i %s".printf(
					info[0],
                    path,
                    window_width,
                    window_height,
                    tab_id_counter,
                    other_arg);
                
                try {
                    Process.spawn_command_line_async(app_command);
                } catch (SpawnError e) {
                    print("Got error when spawn_command_line_async: %s\n", e.message);
                }
			} else {
				print("start_app_process: application info of %s is null", app);
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
                var hide_windows = new ArrayList<int>();
                
                foreach (Window window in window_list) {
                    if (window != focus_window) {
                        destroy_window_list.add(window);
                    }
                }
                
                window_mode.rember_destroy_windows_focus_tab(destroy_window_list, focus_window);
                
                int[] destroy_window_ids = {};
                HashMap<int, int> replace_tab_map = new HashMap<int, int>();
                foreach (Window window in destroy_window_list) {
                    if (window.mode_name == focus_window.mode_name) {
                        var counter = 0;
                        foreach (int tab_id in window.tabbar.tab_list) {
                            var window_type = window.tabbar.tab_window_type_map.get(tab_id);
                            var buffer_id = window.tabbar.tab_buffer_map.get(tab_id);
                            var window_id = window.tabbar.tab_xid_map.get(tab_id);
                            
                            if (window_type == "clone") {
                                destroy_window_ids += window.tabbar.tab_xid_map.get(tab_id);
                            } else if (window_type == "origin") {
                                var focus_window_tab_id = focus_window.tabbar.tab_list.get(counter);
                                var focus_xid = focus_window.tabbar.tab_xid_map.get(focus_window_tab_id);
                                destroy_window_ids += focus_xid;
                                
                                var tab_xid = window.tabbar.tab_xid_map.get(tab_id);
                                replace_tab_map.set(focus_window_tab_id, tab_xid);
                            } else if (window_type == "multiview") {
                                destroy_window_ids += window_id;
                                window_mode.remove_mode_window(buffer_id, window_id);
                            }
                            
                            counter++;
                        }
                    } else {
                        foreach (int tab_id in window.tabbar.tab_list) {
                            var tab_xid = window.tabbar.tab_xid_map.get(tab_id);
                            var tab_window_type = window.tabbar.tab_window_type_map.get(tab_id);
                            
                            if (tab_window_type == "clone") {
                                destroy_window_ids += tab_xid;
                            } else if (tab_window_type == "origin" || tab_window_type == "multiview") {
                                hide_windows.add(tab_xid);
                                window_mode.add_hideinfo_tab(window, tab_id);
                            }
                        }
                    }
                    
                    window_list.remove(window);
                    window.destroy();
                }
                
                destroy_windows(destroy_window_ids);
                
                window_mode.hide_windows(hide_windows);
                
                foreach (var entry in replace_tab_map.entries) {
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
                int[] destroy_window_ids = {};
                HashMap<int, int> replace_tab_map = new HashMap<int, int>();
                var hide_windows = new ArrayList<int>();
                
                window_mode.rember_window_focus_tab(window_list, focus_window);
                
                var counter = 0;
                foreach (int tab_id in focus_window.tabbar.tab_list) {
                    var tab_xid = focus_window.tabbar.tab_xid_map.get(tab_id);
                    var tab_window_type = focus_window.tabbar.tab_window_type_map.get(tab_id);
                    var tab_buffer_id = focus_window.tabbar.tab_buffer_map.get(tab_id);
                    
                    if (tab_window_type == "clone") {
                        destroy_window_ids += tab_xid;
                    } else if (tab_window_type == "origin") {
                        ArrayList<Window> same_mode_windows = find_same_windows(focus_window);
                        
                        if (same_mode_windows.size == 0) {
                            hide_windows.add(tab_xid);
                            window_mode.add_hideinfo_tab(focus_window, tab_id);
                        } else {
                            var replace_window = same_mode_windows.get(0);
                            var replace_window_tab_id = replace_window.tabbar.tab_list.get(counter)        ;
                            var replace_window_tab_xid = replace_window.tabbar.tab_xid_map.get(replace_window_tab_id);
                            
                            destroy_window_ids += replace_window_tab_xid;
                            
                            replace_tab_map.set(replace_window_tab_id, tab_xid);
                        }
                    } else if (tab_window_type == "multiview") {
                        ArrayList<Window> same_mode_windows = find_same_windows(focus_window);
                        
                        if (same_mode_windows.size == 0) {
                            hide_windows.add(tab_xid);
                            window_mode.add_hideinfo_tab(focus_window, tab_id);
                        } else {
                            destroy_window_ids += tab_xid;
                            window_mode.remove_mode_window(tab_buffer_id, tab_xid);
                        }
                    }
                    
                    counter++;
                }
                
                var brother_window = find_brother_window(focus_window);
                var window_rect_manager = new Utils.WindowRectangleManager(window_list);
                
                window_rect_manager.remove_window(focus_window.window_xid);
                window_list.remove(focus_window);
                focus_window.destroy();
                
                if (brother_window != null) {
                    set_focus_window(brother_window);
                }
                
                destroy_windows(destroy_window_ids);
                
                window_mode.hide_windows(hide_windows);
                
                foreach (var entry in replace_tab_map.entries) {
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
        }
        
        private ArrayList<Window> find_same_windows(Window window) {
            ArrayList<Window> same_mode_windows = new ArrayList<Window>();
            foreach (Window win in window_list) {
                if (win != window && win.mode_name == window.mode_name) {
                    same_mode_windows.add(win);
                }
            }
            
            return same_mode_windows;
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
        
        public void new_tab(string app, string path, bool visible_tab=false) {
            var info = get_app_execute_info(app);
			if (info != null) {
                var mode_name = info[1];
                
                var window = get_focus_window();
                if (window != null) {
                    switch_mode(window, mode_name);
                    
                    var window_child_size = window.get_child_allocate();
                    
                    tab_id_counter++;
                    if (visible_tab) {
                        tab_visible_set.add(tab_id_counter);
                    }
                    
                    window.tabbar.add_tab("", path, tab_id_counter, app);
                    start_app_process(
                        app,
                        path,
                        window_child_size[0],
                        window_child_size[1]);
                }
			} else {
				print("new_tab: application info of %s is null", app);
			}
        }
        
        public void switch_to_next_mode() {
            switch_to_next_mode_with_window(focus_window);
        }
        
        public void switch_to_next_mode_with_window(Window window) {
            if (window_mode.mode_buffer_map.size > 1) {
                bool found_current_mode = false;
                string? first_mode_name = null;
                string? next_mode_name = null;
                var counter = 0;
                foreach (var entry in window_mode.mode_buffer_map.entries) {
                    string mode_name = entry.key;
                    
                    if (counter == 0) {
                        first_mode_name = mode_name;
                    }
                    
                    if (found_current_mode) {
                        next_mode_name = mode_name;
                        break;
                    } else if (window.mode_name == mode_name && counter != window_mode.mode_buffer_map.size - 1) {
                        found_current_mode = true;
                    }
                    
                    counter++;
                }
                
                if (!found_current_mode) {
                    next_mode_name = first_mode_name;
                }
                
                if (next_mode_name != null) {
                    switch_mode(window, next_mode_name);
                } else {
                    print("switch_to_next_mode: possible here!\n");
                }
            }
        }
        
        public void switch_to_prev_mode() {
            switch_to_prev_mode_with_window(focus_window);
        }
        
        public void switch_to_prev_mode_with_window(Window window) {
            if (window_mode.mode_buffer_map.size > 1) {
                bool found_current_mode = false;
                string? prev_mode_name = null;
                foreach (var entry in window_mode.mode_buffer_map.entries) {
                    string mode_name = entry.key;
                    
                    if (window.mode_name == mode_name) {
                        found_current_mode = true;
                        break;
                    }
                    
                    prev_mode_name = mode_name;
                }
                
                if (found_current_mode) {
                    if (prev_mode_name == null) {
                        var counter = 0;
                        foreach (var entry in window_mode.mode_buffer_map.entries) {
                            string mode_name = entry.key;
                            
                            if (counter == window_mode.mode_buffer_map.size - 1) {
                                switch_mode(window, mode_name);
                                break;
                            }
                            
                            counter++;
                        }
                    } else {
                        switch_mode(window, prev_mode_name);
                    }
                }

            }
        }
        
        private void switch_mode(Window window, string mode_name) {
            if (window.mode_name != mode_name) {
                // Record buffers of current mode.
                int[] remove_clone_windows = {};
                int[] remove_multiview_windows = {};
                var hide_windows = new ArrayList<int>();
                var replace_tab_map = new HashMap<int, int>();
                int counter = 0;
                foreach (int tab_id in window.tabbar.tab_list) {
                    var window_type = window.tabbar.tab_window_type_map.get(tab_id);
                    var window_xid = window.tabbar.tab_xid_map.get(tab_id);
                    var window_buffer_id = window.tabbar.tab_buffer_map.get(tab_id);
                    
                    if (window_type == "clone") {
                        remove_clone_windows += window_xid;
                    } else if (window_type == "origin") {
                        var same_mode = false;
                        foreach (Window win in window_list) {
                            if (win != window && win.mode_name == window.mode_name) {
                                same_mode = true;
                                
                                int replace_tab_id = win.tabbar.tab_list.get(counter);
                                int replace_window_xid = win.tabbar.tab_xid_map.get(replace_tab_id);
                                
                                replace_tab_map.set(replace_tab_id, window_xid);
                                
                                remove_clone_windows += replace_window_xid;
                                break;
                            }
                        }
                        
                        if (!same_mode) {
                            hide_windows.add(window_xid);
                            window_mode.add_hideinfo_tab(window, tab_id);
                        }
                    } else if (window_type == "multiview") {
                        var same_mode = false;
                        foreach (Window win in window_list) {
                            if (win != window && win.mode_name == window.mode_name) {
                                same_mode = true;
                                
                                remove_multiview_windows += window_xid;
                                window_mode.remove_mode_window(window_buffer_id, window_xid);
                                break;
                            }
                        }
                        
                        if (!same_mode) {
                            hide_windows.add(window_xid);
                            window_mode.add_hideinfo_tab(window, tab_id);
                        }
                    }

                    counter++;
                }
                
                window_mode.rember_window_focus_tab(window_list, window);
                
                destroy_windows(remove_clone_windows);
                destroy_windows(remove_multiview_windows);
                
                window_mode.hide_windows(hide_windows);
                
                foreach (var entry in replace_tab_map.entries) {
                    var replace_tab_id = entry.key;
                    var replace_win_id = entry.value;
                    
                    foreach (Window win in window_list) {
                        var do_replace = false;
                        foreach (int tab_id in win.tabbar.tab_list) {
                            if (tab_id == replace_tab_id) {
                                win.tabbar.set_tab_xid(replace_tab_id, replace_win_id);
                                win.tabbar.set_tab_window_type(replace_tab_id, "origin");
                                
                                do_replace = true;
                                
                            }
                        }
                        
                        if (do_replace) {
                            // We need reparent window of current tab if have replace tab operation in window.
                            var focus_tab_id = win.tabbar.tab_list.get(win.tabbar.tab_index);
                            if (replace_tab_id == focus_tab_id) {
                                var focus_xid = win.tabbar.tab_xid_map.get(focus_tab_id);
                                win.visible_tab(focus_xid);
                            }
                        }
                    }
                }
                
                window.tabbar.reset();
                
                // Rebuild window's tabs.
                var buffer_list = window_mode.mode_buffer_map.get(mode_name);
                if (buffer_list != null && buffer_list.size > 0) {
                    foreach (string buffer_id in buffer_list) {
                        tab_id_counter++;
                        
                        var buffer_windows = window_mode.mode_window_map.get(buffer_id);
                        var hide_info = window_mode.hide_info_map.get(buffer_id);
                        if (hide_info != null) {
                            if (buffer_windows.contains(hide_info.tab_xid)) {
                                window.tabbar.add_tab(hide_info.tab_name, hide_info.tab_path, tab_id_counter, hide_info.tab_app);
                                
                                window.tabbar.set_tab_xid(tab_id_counter, hide_info.tab_xid);
                                window.tabbar.set_tab_buffer(tab_id_counter, buffer_id);
                                window.tabbar.set_tab_window_type(tab_id_counter, hide_info.tab_window_type);
                                
                                window_mode.show_window(hide_info.tab_xid);
                                window_mode.remove_hideinfo_tab(buffer_id);
                                
                                window.visible_tab(hide_info.tab_xid);
                            }
                        } else {
                            foreach (Window win in window_list) {
                                if (win != window) {
                                    foreach (int tab_id in win.tabbar.tab_list) {
                                        var window_xid = win.tabbar.tab_xid_map.get(tab_id);
                                        
                                        // If window type is origin, clone from origin window.
                                        // If window type is multiview, just build new window with first window.
                                        if (window_xid == buffer_windows[0]) {
                                            var tab_name = win.tabbar.tab_name_map.get(tab_id);
                                            var tab_path = win.tabbar.tab_path_map.get(tab_id);
                                            var app = win.tabbar.tab_app_map.get(tab_id);
                                            var window_type = win.tabbar.tab_window_type_map.get(tab_id);
                                            var tab_buffer_id = win.tabbar.tab_buffer_map.get(tab_id);
                                            var window_child_size = window.get_child_allocate();
                                            string last_arg = "";
                                            if (window_type == "multiview") {
                                                last_arg = tab_buffer_id;
                                            } else {
                                                last_arg = window_xid.to_string();
                                            }
                                            
                                            window.tabbar.add_tab(tab_name, tab_path, tab_id_counter, app);
                                            start_app_process(
                                                app,
                                                tab_path,
                                                window_child_size[0],
                                                window_child_size[1],
                                                last_arg);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                window.resize_tab_windows();
                window.mode_name = mode_name;
                window_mode.restore_window_focus_tab(window_list, window);
            }
        }
        
        private string[]? get_app_execute_info(string app) {
            string[] info = {};
            
            var parser = new Json.Parser();
            try {
                parser.load_from_file("./app/%s/app.json".printf(app));
            } catch (GLib.Error e) {
                print("get_app_execute_info: got error when load %s/app.json: %s\n", app, e.message);
				return null;
            }
			
            var root_object = parser.get_root ().get_object();
            info += "./app/%s/%s".printf(app, root_object.get_string_member("execute"));
            info += root_object.get_string_member("mode-name");

            return info;
        }
        
        public void close_tab_with_buffer(string mode_name, string buffer_id) {
            foreach (Window window in window_list) {
                if (window.mode_name == mode_name) {
                    window.tabbar.close_tab_with_buffer(buffer_id);
                    
                    if (window.tabbar.tab_list.size == 0) {
                        switch_to_next_mode_with_window(window);
                    }
                }
            }
            
            destroy_buffer(buffer_id);
            
            window_mode.remove_mode_tab(mode_name, buffer_id);
        }
        
        public void close_tab(Window current_window, string mode_name, int tab_index, string buffer_id) {
            foreach (Window window in window_list) {
                if (window != current_window && window.mode_name == current_window.mode_name) {
                    window.tabbar.close_nth_tab(tab_index, false);
                    
                    if (window.tabbar.tab_list.size == 0) {
                        switch_to_next_mode_with_window(window);
                    }
                }
            }
            
            if (current_window.tabbar.tab_list.size == 0) {
                switch_to_next_mode_with_window(current_window);
            }
            
            destroy_buffer(buffer_id);

            window_mode.remove_mode_tab(mode_name, buffer_id);
        }
        
        public void rename_tab_with_buffer(string mode_name, string buffer_id, string tab_name, string tab_path) {
            foreach (Window window in window_list) {
                if (window.mode_name == mode_name) {
                    window.tabbar.rename_tab(buffer_id, tab_name, tab_path);
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
        
        public void show_tab(int tab_win_id, string mode_name, int tab_id, string buffer_id, string window_type) {
            var window = get_window_with_tab_id(tab_id);
            if (window != null) {
                if (window.mode_name == "") {
                    window.mode_name = mode_name;
                }
                
                if (window_type == "origin" || window_type == "multiview") {
                    window_mode.add_mode_tab(mode_name, buffer_id, tab_win_id);
                }
                
                window.tabbar.set_tab_xid(tab_id, tab_win_id);
                window.tabbar.set_tab_buffer(tab_id, buffer_id);
                window.tabbar.set_tab_window_type(tab_id, window_type);
                
                if (tab_visible_set.contains(tab_id)) {
                    window.tabbar.select_tab_with_id(tab_id);
                    tab_visible_set.remove(tab_id);
                } else {
                    window.tabbar.protect_current_tab(() => {
                            window.visible_tab(tab_win_id);
                        });
                }

                // FIXEME: We need add some delay to avoid sync_windows execute before 'set_tab_buffer'.
                // Otherwise, we will pass null buffer_id to app process.
                //
                // Question is why sync_windows will execute before 'set_tab_buffer' at above?
                GLib.Timeout.add(200, () => {
                        sync_windows(window);
                        
                        return false;
                    });
            } else {
                print("Can't found window that contain tab_id: %i\n", tab_id);
            }
        }
        
        private void sync_windows(Widgets.Window current_window) {
            var current_buffers = current_window.tabbar.get_all_buffers();
            
            foreach (Widgets.Window window in window_list) {
                if (window != current_window && window.mode_name == current_window.mode_name) {
                    var buffers = window.tabbar.get_all_buffers();
                    var clone_names = current_window.tabbar.get_all_names()[buffers.size:current_buffers.size];
                    var clone_paths = current_window.tabbar.get_all_paths()[buffers.size:current_buffers.size];
                    var clone_apps = current_window.tabbar.get_all_apps()[buffers.size:current_buffers.size];
                    var clone_buffers = current_buffers[buffers.size:current_buffers.size];

                    int counter = 0; 
                    foreach (string clone_buffer in clone_buffers) {
                        var app = clone_apps.get(counter);
                        var window_child_size = window.get_child_allocate();
                        var tab_name = clone_names.get(counter);
                        var tab_path = clone_paths.get(counter);
                        
                        tab_id_counter++;
                        window.tabbar.add_tab(tab_name, tab_path, tab_id_counter, app);
                        start_app_process(
                            app,
                            tab_path,
                            window_child_size[0],
                            window_child_size[1],
                            clone_buffer);
                        
                        counter++;
                    }
                }
            }
        }
    }
}
