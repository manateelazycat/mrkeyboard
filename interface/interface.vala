using Application;
using GLib;
using Gdk;
using Gee;
using Gtk;
using Interface;

namespace Interface {
    [DBus (name = "org.mrkeyboard.Daemon")]
    interface Daemon : Object {
        public abstract void show_app_tab(int app_win_id, string mode_name, int tab_id, string buffer_id, string window_type) throws IOError;
        public abstract void close_app_tab(string mode_name, string buffer_id) throws IOError;
        public abstract void rename_app_tab(string mode_name, string buffer_id, string tab_name, string tab_path) throws IOError;
        public abstract void new_app_tab(string app, string tab_path) throws IOError;
        public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
        public signal void destroy_buffer(string buffer_id);
        public signal void destroy_windows(int[] window_ids);
        public signal void reparent_window(int window_id);
        public signal void resize_window(int window_id, int width, int height);
        public signal void scroll_vertical_up(int window_id);
        public signal void scroll_vertical_down(int window_id);
        public signal void quit_app();
    }
    
    public class ClientServer : Application.ClientServer {
        private ArrayList<Interface.Window> window_list;
        private ArrayList<Interface.CloneWindow> clone_window_list;
        private HashMap<string, Interface.Window> buffer_window_set;
        private HashMap<string, HashSet<Interface.CloneWindow>> buffer_clone_set;
        private Daemon daemon;
        
        public int init(string[] args) {
            if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
                return -1;
            }
            
            try {
                daemon = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.Daemon",
                                                            "/org/mrkeyboard/daemon");
            
                daemon.send_key_event.connect((focus_window, key_val, key_state, key_time, press) => {
                        handle_send_key_event(focus_window, key_val, key_state, key_time, press);
                    });
                daemon.destroy_windows.connect((window_id) => {
                        handle_destroy_windows(window_id);
                    });
                daemon.reparent_window.connect((window_id) => {
                        handle_reparent(window_id);
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
            clone_window_list = new ArrayList<Interface.CloneWindow>();
            buffer_window_set = new HashMap<string, Interface.Window>();
            buffer_clone_set = new HashMap<string, HashSet<Interface.CloneWindow>>();
            
            create_window(args);
            
            return 0;
        }
        
        private string get_buffer_id() {
            string buffer_id;
            string[] spawn_args = {"uuidgen"};
            try {
                Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out buffer_id);
            } catch (SpawnError e) {
                print("Got error when spawn_sync: %s\n", e.message);
            }
            
            return buffer_id[0:buffer_id.length - 1];  // remove \n char at end
        }
        
        public override void create_window(string[] args, bool from_dbus=false) {
            if (args.length == 5) {
                var path = args[1];
                var width = int.parse(args[2]);
                var height = int.parse(args[3]);
                var tab_id = int.parse(args[4]);
                
                var buffer_id = get_buffer_id();
                var window = new Application.Window(width, height, buffer_id, path);
                
                window.create_app_tab.connect((app_win_id, mode_name) => {
                        try {
                            daemon.show_app_tab(app_win_id, mode_name, tab_id, window.buffer_id, "origin");
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
                window.show_all();
                
                window_list.add(window);
                buffer_window_set.set(buffer_id, window);
            } else if (args.length == 6) {
                var path = args[1];
                var width = int.parse(args[2]);
                var height = int.parse(args[3]);
                var tab_id = int.parse(args[4]);
                int? parent_window_id = 0;
                
                // If four argment has '-' char, we consider it is buffer_id (uuid format).
                if ("-" in args[5]) {
                    var buffer_id = args[5];
                    
                    var parent_window = buffer_window_set.get(buffer_id);
                    parent_window_id = parent_window.window_id;
                } else {
                    parent_window_id = get_parent_window_id(int.parse(args[5]));
                }
                
                if (parent_window_id != null) {
                    var window = get_match_window_with_id(parent_window_id);
                    if (window != null) {
                        
                        var clone_window = new Application.CloneWindow(width, height, parent_window_id, window.mode_name, window.buffer_id, path);
                        
                        clone_window.create_app_tab.connect((app_win_id, mode_name) => {
                                try {
                                    daemon.show_app_tab(app_win_id, mode_name, tab_id, clone_window.buffer_id, "clone");
                                } catch (IOError e) {
                                    stderr.printf("%s\n", e.message);
                                }
                            });
                        clone_window.show_all();
                        clone_window_list.add(clone_window);
                    
                        var clone_window_set = buffer_clone_set.get(clone_window.buffer_id);
                        if (clone_window_set == null) {
                            var clone_set = new HashSet<Interface.CloneWindow>();
                            clone_set.add(clone_window);
                            buffer_clone_set.set(clone_window.buffer_id, clone_set);
                        } else {
                            clone_window_set.add(clone_window);
                        }
                    }
                } else {
                    print("ERROR: get_parent_window_id can't found valid window id.\n");
                }
            }
        }
        
        private int? get_parent_window_id(int window_id) {
            foreach (Interface.Window window in window_list) {
                if (window.window_id == window_id) {
                    return window_id;
                }
            }
            
            foreach (Interface.CloneWindow clone_window in clone_window_list) {
                if (clone_window.window_id == window_id) {
                    return buffer_window_set.get(clone_window.buffer_id).window_id;
                }
            }
            
            return null;
        }
        
        private void handle_send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press) {
            var wid = get_parent_window_id(window_id);
            if (wid != null) {
                var window = get_match_window_with_id(wid);
                if (window != null) {
                    window.handle_key_event(key_val, key_state, key_time, press);
                }
            }
        }
        
        public void handle_scroll_vertical_up(int window_id) {
            var wid = get_parent_window_id(window_id);
            if (wid != null) {
                var window = get_match_window_with_id(wid);
                if (window != null) {
                    window.scroll_vertical(true);
                }
            }
        }
        
        public void handle_scroll_vertical_down(int window_id) {
            var wid = get_parent_window_id(window_id);
            if (wid != null) {
                var window = get_match_window_with_id(wid);
                if (window != null) {
                    window.scroll_vertical(false);
                }
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
    
                ArrayList<Interface.CloneWindow> destroy_clone_windows = new ArrayList<Interface.CloneWindow>();
                foreach (Interface.CloneWindow clone_window in clone_window_list) {
                    if (clone_window.window_id == destroy_window_id) {
                        destroy_clone_windows.add(clone_window);
                    }
                }
                
                foreach (Interface.Window window in destroy_windows) {
                    destroy_window(window);
                }
    
                foreach (Interface.CloneWindow clone_window in destroy_clone_windows) {
                    destroy_clone_window(clone_window);
                }
            }
            
            try_quit();
        }
        
        private void destroy_window(Interface.Window window) {
            buffer_window_set.unset(window.buffer_id);
            window_list.remove(window);
            window.destroy();
        }
        
        private bool destroy_clone_window(CloneWindow clone_window) {
            clone_window_list.remove(clone_window);
            clone_window.destroy();
                    
            var clone_window_set = buffer_clone_set.get(clone_window.buffer_id);
            if (clone_window_set != null) {
                clone_window_set.remove(clone_window);
                if (clone_window_set.size == 0) {
                    buffer_clone_set.unset(clone_window.buffer_id);
                }
                        
                return true;
            }
            
            return true;
        }
        
        private void handle_reparent(int window_id) {
            foreach (Interface.Window window in window_list) {
                if (window_id == window.window_id) {
                    var clone_windows = buffer_clone_set.get(window.buffer_id);
                    if (clone_windows != null) {
                        foreach (Interface.CloneWindow clone_window in clone_windows) {
                            /* This is HACKING WAY!!!
                            /* TexturePixmap will freeze once parent window reparent by daemon proces.
                            /* So i use function 'replace_texture' to re-bulid new texture when parent window do x11 reparent operation.
                            /* To avoid clone texture freeze.
                            /* 
                            /* Please fix this with better way if you configure why TexturePixmap will freeze when parent window reparent.
                            */  
                            clone_window.update_texture();
                        }
                    }
                }
            }
            
            foreach (Interface.CloneWindow window in clone_window_list) {
                if (window_id == window.window_id) {
                    window.update_texture_area();
                }
            }
        }
        
        private void handle_destroy_buffer(string buffer_id) {
            var window = buffer_window_set.get(buffer_id);
            if (window != null) {
                buffer_window_set.unset(window.buffer_id);
                window_list.remove(window);
                window.destroy();
            }
            
            var clone_windows = buffer_clone_set.get(buffer_id);
            if (clone_windows != null) {
                foreach (Interface.CloneWindow clone_window in clone_windows) {
                    clone_window_list.remove(clone_window);
                    clone_window.destroy();
                }
                
                buffer_clone_set.unset(buffer_id);
            }
    
            try_quit();
        }
        
        private void try_quit() {
            if (window_list.size == 0) {
                if (clone_window_list.size != 0 || buffer_window_set.size != 0 || buffer_clone_set.size != 0) {
                    print("It's something wrong with clone_window_list or buffer_window_set or buffer_clone_set.\n");
                }
                
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
        
        public void start(string[] args) {
            Bus.own_name(BusType.SESSION,
                         Application.dbus_name,
                         BusNameOwnerFlags.NONE,
                         ((con) => {on_bus_aquired(con, this);}),
                         () => {
                             init(args);
                         },
                         () => {
                             Application.Client client = null;
                             
                             try {
                                 client = Bus.get_proxy_sync(BusType.SESSION, Application.dbus_name, Application.dbus_path);
                                 client.create_window(args, true);
                             } catch (IOError e) {
                                 stderr.printf("%s\n", e.message);
                             }
                             
                             Gtk.main_quit();
                         });
        
        }
    }
    
    void on_bus_aquired(DBusConnection conn, Application.ClientServer client_server) {
        try {
            conn.register_object(Application.dbus_path, client_server);
        } catch (IOError e) {
            stderr.printf("Could not register service\n");
        }
    }
}

int main(string[] args) {
    var client_server = new Interface.ClientServer();
    client_server.start(args);
    
    Gtk.main();
    
    return 0;
}
