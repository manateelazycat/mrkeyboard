using Gee;
using Widgets;

namespace WindowMode {
    public class WindowMode : Object {
        public struct HideInfo {
            public int tab_xid;
            public string tab_name;
            public string tab_path;
            public string tab_app;
        }

        public HashMap<string, ArrayList<string>> mode_buffer_map;
        public HashMap<string, HideInfo?> hide_info_map;
        public HashMap<string, int> mode_window_map;
        public HashMap<string, int> mode_focus_tab_map;
        public Xcb.Connection conn;
        
        public WindowMode(Xcb.Connection connection) {
            conn = connection;
            hide_info_map = new HashMap<string, HideInfo?>();
            mode_buffer_map = new HashMap<string, ArrayList<string>>();
            mode_window_map = new HashMap<string, int>();
            mode_focus_tab_map = new HashMap<string, int>();
        }
        
        public void add_hideinfo_tab(Window window, int tab_id) {
            hide_info_map.set(
                window.tabbar.tab_buffer_map.get(tab_id),
                HideInfo () {tab_xid = window.tabbar.tab_xid_map.get(tab_id),
                             tab_name = window.tabbar.tab_name_map.get(tab_id),
                             tab_path = window.tabbar.tab_path_map.get(tab_id),
                             tab_app = window.tabbar.tab_app_map.get(tab_id)
                });
        }
        
        public void remove_hideinfo_tab(string buffer_id) {
            hide_info_map.unset(buffer_id);
        }
        
        public void hide_windows(ArrayList<int> hide_windows) {
            foreach (int hide_window in hide_windows) {
                conn.unmap_window(hide_window);
                conn.flush();
            }
        }

        public void show_window(int show_window) {
            conn.map_window(show_window);
            conn.flush();
        }
        
        public void add_mode_tab(string mode_name, string buffer_id, int window_id) {
            var buffer_list = mode_buffer_map.get(mode_name);
            if (buffer_list != null) {
                buffer_list.add(buffer_id);
            } else {
                var list = new ArrayList<string>();
                list.add(buffer_id);
                mode_buffer_map.set(mode_name, list);
            }
            
            mode_window_map.set(buffer_id, window_id);
        }
        
        public void remove_mode_tab(string mode_name, string buffer_id) {
            var buffer_list = mode_buffer_map.get(mode_name);
            if (buffer_list != null) {
                foreach (string buffer in buffer_list) {
                    if (buffer == buffer_id) {
                        buffer_list.remove(buffer);
                        
                        mode_window_map.unset(buffer_id);
                        break;
                    }
                }
                
                if (buffer_list.size == 0) {
                    mode_buffer_map.unset(mode_name);
                }
            }
        }

        public void rember_window_focus_tab(ArrayList<Widgets.Window> window_list, Window window) {
            bool has_same_window = false;
            if (window_list.size > 1) {
                foreach (Window win in window_list) {
                    if (win != window && win.mode_name == window.mode_name) {
                        has_same_window = true;
                        break;
                    }
                }
            }
            
            if (!has_same_window) {
                mode_focus_tab_map.set(window.mode_name, window.tabbar.tab_index);
            }
        }
        
        public void rember_destroy_windows_focus_tab(ArrayList<Window> destroy_window_list, Window focus_window) {
            foreach (Window destroy_window in destroy_window_list) {
                if (destroy_window.mode_name != focus_window.mode_name) {
                    mode_focus_tab_map.set(destroy_window.mode_name, destroy_window.tabbar.tab_index);
                }
            }
        }
        
        public void restore_window_focus_tab(ArrayList<Window> window_list, Window window) {
            if (window.tabbar.tab_list.size > 0) {
                var tab_index = 0;
                int? focus_index = mode_focus_tab_map.get(window.mode_name);
                if (focus_index != null && focus_index > 0 && focus_index < window.tabbar.tab_list.size) {
                    tab_index = focus_index;
                }
                
                window.tabbar.switch_tab(tab_index);
                window.visible_tab(window.tabbar.tab_xid_map.get(window.tabbar.tab_list.get(tab_index)));
            }
        }
    }
}