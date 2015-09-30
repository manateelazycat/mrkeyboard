using Widgets;
using Utils;
using Xcb;
using Gdk;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Gtk.Window window;
    private Clutter.Actor stage;
    private Xcb.Connection conn;

    public void ping(string msg) {
        var xid = (ulong)((Gdk.X11.Window) window.get_window()).get_xid();
        
        conn.reparent_window(int.parse(msg), (Xcb.Window)xid, 0, 40);
        conn.flush();
    }

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
        
        var embed = new GtkClutter.Embed();
        box.pack_start(embed, true, true, 0);
        
        stage = embed.get_stage();
        stage.background_color = Clutter.Color() {red = 23, green = 24, blue = 20, alpha = 255};
        
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

    Bus.own_name(BusType.SESSION, "org.mrkeyboard.Daemon", BusNameOwnerFlags.NONE,
                 ((c) => {
                     on_bus_aquired(c, daemon_server);
                 }),
                 () => {},
                 () => stderr.printf ("Could not aquire name\n"));
     
    daemon_server.run();
}