using Application;
using GLib;
using Gdk;
using Gee;
using Gtk;
using Interface;

namespace Interface {
    public class ClientServer : Interface.BaseClientServer {
        private ArrayList<Interface.Window> window_list;
        private Daemon daemon;
        
        private HashMap<string, Application.Buffer> buffer_map;
        
        public override int init(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
                return -1;
            }
            
            try {
                daemon = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.Daemon",
                                                            "/org/mrkeyboard/daemon");
            
                daemon.send_key_event.connect((focus_window, key_val, key_state, hardware_keycode, key_time, press) => {
                        handle_send_key_event(focus_window, key_val, key_state, hardware_keycode, key_time, press);
                    });
                daemon.destroy_windows.connect((window_id) => {
                        handle_destroy_windows(window_id);
                    });
                daemon.destroy_buffer.connect((buffer_id) => {
                        handle_destroy_buffer(buffer_id) ;
                    });
                daemon.resize_window.connect((window_id, width, height) => {
                        handle_resize(window_id, width, height);
                    });
                daemon.scroll_vertical_up.connect((window_id) => {
                        handle_scroll_vertical_up(window_id);
                    });
                daemon.scroll_vertical_down.connect((window_id) => {
                        handle_scroll_vertical_down(window_id);
                    });
                daemon.quit_app.connect(() => {
                        print("Receive quit signal from daemon, quit app process...\n");
                        Gtk.main_quit();
                    });
            } catch (IOError e) {
                stderr.printf("%s\n", e.message);
            }    
            
            window_list = new ArrayList<Interface.Window>();
            buffer_map = new HashMap<string, Application.Buffer>();
            
            create_window(args);
            
            return 0;
        }
        
        public override void create_window(string[] args, bool from_dbus=false) {
            if (args.length == 5) {
                var path = args[1];
                var width = int.parse(args[2]);
                var height = int.parse(args[3]);
                var tab_id = int.parse(args[4]);
                
                var buffer_id = get_buffer_id();
                var buffer = new Application.Buffer();
                
                buffer_map.set(buffer_id, buffer);

                new_window(width, height, tab_id, buffer_id, path, buffer);
            } else if (args.length == 6) {
                var path = args[1];
                var width = int.parse(args[2]);
                var height = int.parse(args[3]);
                var tab_id = int.parse(args[4]);
                var buffer_id = args[5];
                
                var buffer = buffer_map.get(buffer_id);
                if (buffer != null) {
                    new_window(width, height, tab_id, buffer_id, path, buffer);
                }
            }
        }

        private void new_window(int width, int height, int tab_id, string buffer_id, string path, Application.Buffer buffer) {
            var window = new Application.Window(width, height, buffer_id, path, buffer);
                
            window.create_app_tab.connect((tab_win_id, mode_name) => {
                    try {
                        daemon.show_app_tab(tab_win_id, mode_name, tab_id, window.buffer_id, "multiview");
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.close_app_tab.connect((mode_name, buffer_id) => {
                    try {
                        daemon.close_app_tab(mode_name, buffer_id);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.rename_app_tab.connect((mode_name, buffer_id, tab_name, tab_path) => {
                    try {
                        daemon.rename_app_tab(mode_name, buffer_id, tab_name, tab_path);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.new_app_tab.connect((app, tab_path) => {
                    try {
                        daemon.new_app_tab(app, tab_path);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.percent_app_tab.connect((buffer_id, percent) => {
                    try {
                        daemon.percent_app_tab(buffer_id, percent);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.emit_button_press_event.connect((e) => {
                    try {
                        daemon.focus_app_tab(window.window_id);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.show_all();
            
            window_list.add(window);
        }
        
        private void handle_send_key_event(int window_id, uint key_val, uint key_state, int hardware_keycode, uint32 key_time, bool press) {
            var window = get_match_window_with_id(window_id);
            if (window != null) {
                window.handle_key_event(key_val, key_state, hardware_keycode, key_time, press);
            }
        }
        
        public void handle_scroll_vertical_up(int window_id) {
            var window = get_match_window_with_id(window_id);
            if (window != null) {
                window.scroll_vertical(true);
            }
        }
        
        public void handle_scroll_vertical_down(int window_id) {
            var window = get_match_window_with_id(window_id);
            if (window != null) {
                window.scroll_vertical(false);
            }
        }
        
        private void handle_destroy_windows(int[] window_ids) {
            foreach (int destroy_window_id in window_ids) {
                ArrayList<Interface.Window> destroy_windows = new ArrayList<Interface.Window>();
                foreach (Interface.Window window in window_list) {
                    if (window.window_id == destroy_window_id) {
                        destroy_windows.add(window);
                    }
                }
    
                foreach (Interface.Window window in destroy_windows) {
                    destroy_window(window);
                }
            }
            
            try_quit();
        }
        
        private void destroy_window(Interface.Window window) {
            window_list.remove(window);
            window.destroy();
        }
        
        private void handle_destroy_buffer(string buffer_id) {
            var match_windows = new ArrayList<Interface.Window>();
            foreach (Interface.Window window in window_list) {
                if (window.buffer_id == buffer_id) {
                    match_windows.add(window);
                }
            }
            
            foreach (Interface.Window window in match_windows) {
                window_list.remove(window);
                window.destroy();
            }
    
            try_quit();
        }
        
        private void try_quit() {
            if (window_list.size == 0) {
                print("All app window destroy, exit %s app process.\n", Application.app_name);
                Gtk.main_quit();
            }
        }
        
        private void handle_resize(int window_id, int width, int height) {
            var window = get_match_window_with_id(window_id);
            if (window != null) {
                window.resize(width, height);
            }
        }
        
        private Interface.Window? get_match_window_with_id(int window_id) {
            foreach (Interface.Window window in window_list) {
                if (window_id == window.window_id) {
                    return window;
                }
            }
            
            return null;
        }
    }
}
