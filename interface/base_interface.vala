using Application;
using GLib;
using Gdk;
using Gee;
using Gtk;
using Interface;

namespace Interface {
    [DBus (name = "org.mrkeyboard.Daemon")]
    interface Daemon : Object {
        public abstract void show_app_tab(int tab_win_id, string mode_name, int tab_id, string buffer_id, string window_type) throws IOError;
        public abstract void close_app_tab(string mode_name, string buffer_id) throws IOError;
        public abstract void rename_app_tab(string mode_name, string buffer_id, string tab_name, string tab_path) throws IOError;
        public abstract void new_app_tab(string app, string tab_path) throws IOError;
        public abstract void focus_app_tab(int tab_win_id) throws IOError;
        public abstract void percent_app_tab(string buffer_id, int percent) throws IOError;
        public abstract void open_path(string path) throws IOError;
        public signal void send_key_event(int window_id, uint key_val, uint key_state, int hardware_keycode, uint32 key_time, bool press);
        public signal void destroy_buffer(string buffer_id);
        public signal void destroy_windows(int[] window_ids);
        public signal void reparent_window(int window_id);
        public signal void resize_window(int window_id, int width, int height);
        public signal void scroll_vertical_up(int window_id);
        public signal void scroll_vertical_down(int window_id);
        public signal void quit_app();
    }
    
    void on_bus_acquired(DBusConnection conn, Application.ClientServer client_server) {
        try {
            conn.register_object(Application.dbus_path, client_server);
        } catch (IOError e) {
            stderr.printf("Could not register service\n");
        }
    }

    public class BaseClientServer : Application.ClientServer {
        public virtual int init(string[] args) {
            return -1;
        }
        
        public string get_buffer_id() {
            string buffer_id;
            string[] spawn_args = {"uuidgen"};
            try {
                Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out buffer_id);
            } catch (SpawnError e) {
                print("Got error when spawn_sync: %s\n", e.message);
            }
            
            return buffer_id[0:buffer_id.length - 1];  // remove \n char at end
        }
        
        public void start(string[] args) {
            Bus.own_name(BusType.SESSION,
                         Application.dbus_name,
                         BusNameOwnerFlags.NONE,
                         ((con) => {on_bus_acquired(con, this);}),
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
}

int main(string[] args) {
    var client_server = new Interface.ClientServer();
    client_server.start(args);
    
    Gtk.main();
    
    return 0;
}
