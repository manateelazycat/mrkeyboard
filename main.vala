using Widgets;
using Utils;
using Xcb;
using Gdk;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Gtk.Window window;
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

    public signal void send_key_event(int window_id, int key_state, uint key_val, uint32 key_time, bool press);
    
    public void init(string[] args) {
        if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
            stdout.printf("Clutter init failed.");
        }
        
        conn = new Xcb.Connection();
        
        window = new Gtk.Window();
        window.set_decorated(false);
        window.set_position(Gtk.WindowPosition.CENTER);
        window.set_default_size(800, 600);
        window.destroy.connect(Gtk.main_quit);
        
        var screen = Gdk.Screen.get_default();
        var css_provider = new Gtk.CssProvider();
        try {
            css_provider.load_from_path("style.css");
        } catch (GLib.Error e) {
            stdout.printf("Got error when load css: %s\n", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        window.add(box);
        
        var titlebar = new Widgets.Titlebar();
        titlebar.min_button.button_press_event.connect((event) => {
                window.iconify() ;
                return true;
            });
        titlebar.close_button.button_press_event.connect((event) => {
                Gtk.main_quit();
                return true;
            });
        titlebar.button_press_event.connect((event) => {
                if (Utils.is_double_click(event)) {
                    Utils.toggle_max_window(window);
                } else {
                    Utils.move_window(titlebar, event, window);
                }
                
                return false;
            });
        box.pack_start(titlebar, false, false, 0);
        
        window_manager = new Widgets.WindowManager();
        window_manager.key_press_event.connect((w, e) => {
                send_key_event(focus_window, e.state, e.keyval, e.time, true);
                
                return true;
            });
        window_manager.key_release_event.connect((w, e) => {
                send_key_event(focus_window, e.state, e.keyval, e.time, false);
                
                return true;
            });
        box.pack_start(window_manager, true, true, 0);
        
        try {
            Process.spawn_command_line_async("./app/terminal/main 800 560");
        } catch (SpawnError e) {
            stdout.printf("Got error when spawn_command_line_async: %s\n", e.message);
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