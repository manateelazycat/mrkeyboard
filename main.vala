using Widgets;
using Utils;
using Xcb;
using Gdk;
using Keymap;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Widgets.Application app;
    private Widgets.WindowManager window_manager;

    public bool send_app_tab_info(int app_win_id, string mode_name, int tab_id) {
        window_manager.show_tab(app_win_id, mode_name, tab_id);
        
        return true;
    }

    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    
    public void init(string[] args) {
        if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
            print("Clutter init failed.");
        }
        
        app = new Widgets.Application();

        Utils.load_css_theme("style.css");
        
        var titlebar = new Widgets.Titlebar();
        titlebar.entry.key_press_event.connect((w, e) => {
                if (Keymap.get_keyevent_name(e) == "Alt + x") {
                    window_manager.grab_focus();
                }
                return false;
            });
        app.box.pack_start(titlebar, false, false, 0);
        
        window_manager = new Widgets.WindowManager();
        window_manager.key_press_event.connect((w, e) => {
                string keyevent_name = Keymap.get_keyevent_name(e);
                if (keyevent_name == "Alt + x") {
                    titlebar.entry.grab_focus();
                } else if (keyevent_name == "Super + n") {
                    window_manager.new_tab("./app/terminal/main");
                } else {
                    var xid = window_manager.get_focus_tab_xid();
                    if (xid > 0) {
                        send_key_event(xid, e.keyval, e.state, e.time, true);
                    }
                }
                
                return true;
            });
        window_manager.key_release_event.connect((w, e) => {
                var xid = window_manager.get_focus_tab_xid();
                if (xid > 0) {
                    send_key_event(xid, e.keyval, e.state, e.time, false);
                }
                
                return true;
            });
        app.box.pack_start(window_manager, true, true, 0);
    }
    
    public void run() {
        app.show_all();
        Gtk.main();
    }
}

void on_bus_aquired(DBusConnection conn, DaemonServer daemon_server) {
    try {
        conn.register_object("/org/mrkeyboard/daemon", daemon_server);
    } catch (IOError e) {
        stderr.printf("Could not register service\n");
    }
}

void main(string[] args) {
    var daemon_server = new DaemonServer();
    daemon_server.init(args);

    Bus.own_name(BusType.SESSION,
                 "org.mrkeyboard.Daemon",
                 BusNameOwnerFlags.NONE,
                 ((con) => {on_bus_aquired(con, daemon_server);}),
                 () => {},
                 () => stderr.printf ("Could not aquire name\n"));
    
    daemon_server.run();
}