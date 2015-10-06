using Widgets;
using Utils;
using Xcb;
using Gdk;
using Keymap;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Widgets.Application app;
    private Widgets.WindowManager window_manager;

    public void send_app_tab_info(int app_win_id, string mode_name, int tab_id) {
        window_manager.show_tab(app_win_id, mode_name, tab_id);
    }

    public signal void send_key_event(int window_id, uint key_val, int key_state, uint32 key_time, bool press);
    public signal void hide_window(int window_id);
    public signal void show_window(int window_id);
    public signal void quit_app();
    
    public void init(string[] args) {
        if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
            print("Clutter init failed.");
        }
        
        app = new Widgets.Application();
        app.destroy.connect(quit);
        Utils.load_css_theme("style.css");
        
        var titlebar = new Widgets.Titlebar();
        titlebar.entry.key_press_event.connect((w, e) => {
                if (Keymap.get_keyevent_name(e) == "Alt + x") {
                    window_manager.grab_focus();
                }
                return false;
            });
        titlebar.close_button.button_press_event.connect((event) => {
                quit();
                return true;
            });
        app.box.pack_start(titlebar, false, false, 0);
        
        window_manager = new Widgets.WindowManager();
        window_manager.key_press_event.connect((w, e) => {
                string keyevent_name = Keymap.get_keyevent_name(e);
                if (keyevent_name == "Alt + x") {
                    titlebar.entry.grab_focus();
                } else if (keyevent_name == "Super + n") {
                    window_manager.new_tab("./app/terminal/main");
                } else if (keyevent_name == "Alt + ,") {
                    var window = window_manager.get_focus_window();
                    window.tabbar.select_prev_tab();
                } else if (keyevent_name == "Alt + .") {
                    var window = window_manager.get_focus_window();
                    window.tabbar.select_next_tab();
                } else {
                    var xid = window_manager.get_focus_tab_xid();
                    if (xid != null) {
                        send_key_event(xid, e.keyval, e.state, e.time, true);
                    }
                }
                
                return true;
            });
        window_manager.key_release_event.connect((w, e) => {
                var xid = window_manager.get_focus_tab_xid();
                if (xid != null) {
                    send_key_event(xid, e.keyval, e.state, e.time, false);
                }
                
                return true;
            });
        window_manager.switch_page.connect((old_xid, new_xid) => {
                print("Switch page: %i %i\n", old_xid, new_xid);
                hide_window(old_xid);
                show_window(new_xid);
            });
        app.box.pack_start(window_manager, true, true, 0);

        app.show_all();
        Gtk.main();
    }
    
    private void quit() {
        quit_app();
        Gtk.main_quit();
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

    Bus.own_name(BusType.SESSION,
                 "org.mrkeyboard.Daemon",
                 BusNameOwnerFlags.NONE,
                 ((con) => {on_bus_aquired(con, daemon_server);}),
                 () => {},
                 () => stderr.printf ("Could not aquire name\n"));
    
    daemon_server.init(args);
}