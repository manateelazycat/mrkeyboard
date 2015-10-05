using Gtk;
using Vte;
using GLib;
using Gdk;
using Application;

[DBus (name = "org.mrkeyboard.Daemon")]
interface Daemon : Object {
    public abstract bool send_app_tab_info(int app_win_id, string mode_name, int tab_id) throws IOError;
    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    public signal void hide_window(int window_id);
    public signal void show_window(int window_id);
}

int main(string[] args) {
    int width = int.parse(args[1]);
    int height = int.parse(args[2]);
    int tab_id = int.parse(args[3]);
    
    if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
        return -1;
    }
    
    /* Important: keep daemon variable out of try/catch scope not lose signals! */
    Daemon daemon = null;
    Application.Window window = new Application.Window(width, height, tab_id);

    try {
        daemon = Bus.get_proxy_sync(BusType.SESSION, "org.mrkeyboard.Daemon",
                                                    "/org/mrkeyboard/daemon");

        window.create_app.connect((app_win_id, mode_name, tab_id) => {
                try {
                    daemon.send_app_tab_info(app_win_id, mode_name, tab_id);
                } catch (IOError e) {
                    stderr.printf("%s\n", e.message);
                }
            });
        
        daemon.send_key_event.connect((focus_window, key_val, key_state, key_time, press) => {
               if (focus_window == window.window_id) {
                   window.handle_key_event(key_val, key_state, key_time, press);
               }
            });
        daemon.hide_window.connect((hide_window_id) => {
                if (hide_window_id == window.window_id) {
                    window.hide();
                }
            });
        daemon.show_window.connect((show_window_id) => {
                if (show_window_id == window.window_id) {
                    window.show();
                }
            });
    } catch (IOError e) {
        stderr.printf("%s\n", e.message);
    }    
    
    window.show_all();
    Gtk.main();
    
    return 0;
}

