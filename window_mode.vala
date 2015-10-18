using Gee;
using Widgets;

namespace WindowMode {
    public class WindowMode : Object {
        public struct HideInfo {
            public int tab_xid;
            public string tab_name;
            public string tab_app_path;
        }
        
        public HashMap<string, ArrayList<string>> mode_buffer_set;
        public HashMap<string, HideInfo?> hide_info_set;
        public HashMap<string, int> mode_window_set;
        public Xcb.Connection conn;
        
        public WindowMode(Xcb.Connection connection) {
            conn = connection;
            hide_info_set = new HashMap<string, HideInfo?>();
            mode_buffer_set = new HashMap<string, ArrayList<string>>();
            mode_window_set = new HashMap<string, int>();
        }
        
        public void add_hideinfo_tab(Window window, int tab_id) {
            hide_info_set.set(
                window.tabbar.tab_buffer_set.get(tab_id),
                HideInfo () {tab_xid = window.tabbar.tab_xid_set.get(tab_id),
                             tab_name = window.tabbar.tab_name_set.get(tab_id),
                             tab_app_path = window.tabbar.tab_path_set.get(tab_id)
                });
        }
        
        public void remove_hideinfo_tab(string buffer_id) {
            hide_info_set.unset(buffer_id);
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
            var buffer_list = mode_buffer_set.get(mode_name);
            if (buffer_list != null) {
                buffer_list.add(buffer_id);
            } else {
                var list = new ArrayList<string>();
                list.add(buffer_id);
                mode_buffer_set.set(mode_name, list);
            }
            
            mode_window_set.set(buffer_id, window_id);
        }
        
        public void remove_mode_tab(string mode_name, string buffer_id) {
            var buffer_list = mode_buffer_set.get(mode_name);
            if (buffer_list != null) {
                foreach (string buffer in buffer_list) {
                    if (buffer == buffer_id) {
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
    }
}