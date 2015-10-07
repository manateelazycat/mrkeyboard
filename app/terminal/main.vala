using Gtk;
using Vte;
using GLib;
using Gdk;
using Application;
using Gee;

[DBus (name = "org.mrkeyboard.Daemon")]
interface Daemon : Object {
    public abstract void send_app_tab_info(int app_win_id, string mode_name, int tab_id, string buffer_id) throws IOError;
    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    public signal void init_window(int window_id);
    public signal void destroy_window(int window_id);
    public signal void resize_window(int window_id, int width, int height);
    public signal void quit_app();
}

[DBus (name = "org.mrkeyboard.app.terminal")]
public class ClientServer : Object {
    private ArrayList<Application.Window> window_list;
    private ArrayList<Application.CloneWindow> clone_window_list;
    private HashMap<string, Application.Window> buffer_window_set;
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
            daemon.init_window.connect((window_id) => {
                    handle_init(window_id);
                });
            daemon.destroy_window.connect((window_id) => {
                    handle_destroy(window_id) ;
                });
            daemon.resize_window.connect((window_id, width, height) => {
                    handle_resize(window_id, width, height);
                });
            daemon.quit_app.connect(() => {
                    print("Receive quit signal from daemon, quit app process...\n");
                    Gtk.main_quit();
                });
        } catch (IOError e) {
            stderr.printf("%s\n", e.message);
        }    
        
        window_list = new ArrayList<Application.Window>();
        clone_window_list = new ArrayList<Application.CloneWindow>();
        buffer_window_set = new HashMap<string, Application.Window>();
        create_window(args);
        
        Gtk.main();
        
        return 0;
    }
    
    public void create_window(string[] args) {
        if (args.length == 4) {
            var width = int.parse(args[1]);
            var height = int.parse(args[2]);
            var tab_id = int.parse(args[3]);

            string buffer_id;
            string[] spawn_args = {"uuidgen"};
            try {
                Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out buffer_id);
            } catch (SpawnError e) {
                print("Got error when spawn__line_async: %s\n", e.message);
            }
            var window = new Application.Window(width, height, tab_id, buffer_id);
            window.create_app.connect((app_win_id, mode_name, tab_id) => {
                    try {
                        daemon.send_app_tab_info(app_win_id, mode_name, tab_id, window.buffer_id);
                    } catch (IOError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            window.show_all();
            window_list.add(window);
            
            buffer_window_set.set(buffer_id, window);
        } else if (args.length == 5) {
            var width = int.parse(args[1]);
            var height = int.parse(args[2]);
            var tab_id = int.parse(args[3]);
            var parent_window_id = 0;
            
            // If four argment length is 37, we consider it is buffer_id (uuid format).
            if (args[4].length == 37) {
                var buffer_id = args[4];
                var parent_window = buffer_window_set.get(buffer_id);
                parent_window_id = parent_window.window_id;
            } else {
                parent_window_id = int.parse(args[4]);
            }
            
            var window = get_match_window(parent_window_id);
            if (window != null) {
                
                var clone_window = new Application.CloneWindow(width, height, tab_id, parent_window_id, window.buffer_id);
                clone_window.create_app.connect((app_win_id, mode_name, tab_id) => {
                        try {
                            daemon.send_app_tab_info(app_win_id, mode_name, tab_id, clone_window.buffer_id);
                        } catch (IOError e) {
                            stderr.printf("%s\n", e.message);
                        }
                    });
                clone_window.show_all();
                clone_window_list.add(clone_window);
            }
        }
    }
    
    private void handle_send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press) {
        var window = get_match_window(window_id);
        if (window != null) {
            window.handle_key_event(key_val, key_state, key_time, press);
        }
    }
    
    private void handle_init(int window_id) {
        foreach (Application.CloneWindow window in clone_window_list) {
            if (window_id == window.window_id) {
                window.update_texture();
            }
        }
    }
    
    private void handle_destroy(int window_id) {
        var window = get_match_window(window_id);
        if (window != null) {
            buffer_window_set.unset(window.buffer_id);
            window_list.remove(window);
            window.destroy();
        }
    }
    
    private void handle_resize(int window_id, int width, int height) {
        var window = get_match_window(window_id);
        if (window != null) {
            window.resize(width, height);
        }
    }
    
    private Application.Window? get_match_window(int window_id) {
        foreach (Application.Window window in window_list) {
            if (window_id == window.window_id) {
                return window;
            }
        }
        
        return null;
    }
}

[DBus (name = "org.mrkeyboard.app.terminal")]
interface Client : Object {
    public abstract void create_window(string[] args) throws IOError;
}

void on_bus_aquired(DBusConnection conn, ClientServer client_server) {
    try {
        conn.register_object("/org/mrkeyboard/app/terminal", client_server);
    } catch (IOError e) {
        stderr.printf("Could not register service\n");
    }
}

int main(string[] args) {
    var client_server = new ClientServer();
    
    Bus.own_name(BusType.SESSION,
                 "org.mrkeyboard.app.terminal",
                 BusNameOwnerFlags.NONE,
                 ((con) => {on_bus_aquired(con, client_server);}),
                 () => {},
                 () => {
                     Client client = null;
                     
                     try {
                         client = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.app.terminal", "/org/mrkeyboard/app/terminal");
                         client.create_window(args);
                     } catch (IOError e) {
                         stderr.printf("%s\n", e.message);
                     }
                     
                     Gtk.main_quit();
                 });

    client_server.init(args);
    
    return 0;
}

