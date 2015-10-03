using Widgets;
using Utils;
using Xcb;
using Gdk;
using Keymap;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Widgets.Window window;
    private Xcb.Connection conn;
    private Widgets.WindowManager window_manager;
    private int focus_window;

    public bool create_app_window(string msg) {
        var xid = (ulong)((Gdk.X11.Window) window_manager.get_window()).get_xid();
        focus_window = int.parse(msg);
        
        conn.reparent_window(focus_window, (Xcb.Window)xid, 0, 0);
        conn.flush();
        
        window_manager.grab_focus();
        
        return true;
    }

    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    
    public void init(string[] args) {
        if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
            print("Clutter init failed.");
        }
        
        conn = new Xcb.Connection();
        
        window = new Widgets.Window();

        Utils.load_css_theme("style.css");
        
        var titlebar = new Widgets.Titlebar();
        titlebar.entry.key_press_event.connect((w, e) => {
                if (Keymap.get_keyevent_name(e) == "Alt + x") {
                    window_manager.grab_focus();
                }
                return false;
            });
        window.box.pack_start(titlebar, false, false, 0);
        
        window_manager = new Widgets.WindowManager();
        window_manager.key_press_event.connect((w, e) => {
                if (Keymap.get_keyevent_name(e) == "Alt + x") {
                    titlebar.entry.grab_focus();
                } else {
                    send_key_event(focus_window, e.keyval, e.state, e.time, true);
                }
                
                return true;
            });
        window_manager.key_release_event.connect((w, e) => {
                send_key_event(focus_window, e.keyval, e.state, e.time, false);
                
                return true;
            });
        window.box.pack_start(window_manager, true, true, 0);
        
        try {
            // Process.spawn_command_line_async("./app/terminal/main 800 560");
        } catch (SpawnError e) {
            print("Got error when spawn_command_line_async: %s\n", e.message);
        }
    }
    
    public void run() {
        window.show_all();
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