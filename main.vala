using Widgets;
using Utils;
using Xcb;
using Gdk;
using Keymap;

[DBus (name = "org.mrkeyboard.Daemon")]
public class DaemonServer : Object {
    private Widgets.Application app;
    private Widgets.WindowManager window_manager;

    public void show_app_tab(int tab_win_id, string mode_name, int tab_id, string buffer_id, string window_type) {
        window_manager.show_tab(tab_win_id, mode_name, tab_id, buffer_id, window_type);
    }
    
    public void close_app_tab(string mode_name, string buffer_id) {
        window_manager.close_tab_with_buffer(mode_name, buffer_id);
    }
    
    public void rename_app_tab(string mode_name, string buffer_id, string tab_name, string tab_path) {
        window_manager.rename_tab_with_buffer(mode_name, buffer_id, tab_name, tab_path);
    }
    
    public void new_app_tab(string app, string tab_path) {
        window_manager.new_tab(app, tab_path);
    }
    
    public void focus_app_tab(int tab_win_id) {
        window_manager.focus_window_with_tab(tab_win_id);
    }
    
    public void percent_app_tab(string buffer_id, int percent) {
        window_manager.update_tab_percent(buffer_id, percent);
    }
    
    public void open_path(string path) {
        try {
            var file = File.new_for_path(path);
            var file_info = file.query_info(FileAttribute.STANDARD_CONTENT_TYPE, FileQueryInfoFlags.NONE, null);
            var content_type = file_info.get_content_type();
            var file_type = content_type.split("/")[0];
            if (file_type == "text" || content_type == "application/x-shellscript") {
                window_manager.new_tab("editor", path, true);
            } else if (content_type == "application/pdf") {
                window_manager.new_tab("pdfviewer", path, true);
            } else if (file_type == "video" || content_type == "application/vnd.rn-realmedia") {
                window_manager.new_tab("videoplayer", path, true);
            } else if (file_type == "image") {
                window_manager.new_tab("imageviewer", path, true);
            } else {
                print("Open %s: %s %s\n", file_type, file_info.get_content_type(), path);
            }
        } catch (Error err) {
            stderr.printf ("Error: FileItem failed: %s\n", err.message);
        }
    }
    
    public signal void send_key_event(int window_id, uint key_val, uint key_state, int hardware_keycode, uint32 key_time, bool press);
    public signal void destroy_buffer(string buffer_id);
    public signal void destroy_windows(int[] window_ids);
    public signal void reparent_window(int window_id);
    public signal void resize_window(int window_id, int width, int height);
    public signal void scroll_vertical_up(int window_id);
    public signal void scroll_vertical_down(int window_id);
    public signal void quit_app();
    
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
                    window_manager.new_tab("terminal", "", true);
                } else if (keyevent_name == "Super + m") {
                    window_manager.new_tab("browser", "", true);
                } else if (keyevent_name == "Super + j") {
                    window_manager.new_tab("musicplayer", "/home/andy/Daniel Powter", true);
                } else if (keyevent_name == "Super + k") {
                    window_manager.new_tab("filemanager", "/space/data/Picture", true);
                } else if (keyevent_name == "Alt + ,") {
                    var window = window_manager.get_focus_window();
                    window.tabbar.select_prev_tab();
                } else if (keyevent_name == "Alt + .") {
                    var window = window_manager.get_focus_window();
                    window.tabbar.select_next_tab();
                } else if (keyevent_name == "Alt + <") {
                    window_manager.switch_to_prev_mode();
                } else if (keyevent_name == "Alt + >") {
                    window_manager.switch_to_next_mode();
                } else if (keyevent_name == "Ctrl + w") {
                    var window = window_manager.get_focus_window();
                    window.tabbar.close_current_tab();
                } else if (keyevent_name == "Alt + ;") {
                    window_manager.split_window_horizontal();
                } else if (keyevent_name == "Alt + :") {
                    window_manager.split_window_vertical();
                } else if (keyevent_name == "Alt + '") {
                    window_manager.close_other_windows();
                } else if (keyevent_name == "Alt + \"") {
                    window_manager.close_current_window();
                } else if (keyevent_name == "Alt + h") {
                    window_manager.focus_left_window();
                } else if (keyevent_name == "Alt + l") {
                    window_manager.focus_right_window();
                } else if (keyevent_name == "Alt + j") {
                    window_manager.focus_down_window();
                } else if (keyevent_name == "Alt + k") {
                    window_manager.focus_up_window();
                } else if (keyevent_name == "Alt + J" || keyevent_name == "Page_Down") {
                    var xid = window_manager.get_focus_tab_xid();
                    if (xid != null) {
                        scroll_vertical_up(xid);
                    }
                } else if (keyevent_name == "Alt + K" || keyevent_name == "Page_Up") {
                    var xid = window_manager.get_focus_tab_xid();
                    if (xid != null) {
                        scroll_vertical_down(xid);
                    }
                } else {
                    var xid = window_manager.get_focus_tab_xid();
                    if (xid != null) {
                        send_key_event(xid, e.keyval, e.state, e.hardware_keycode, e.time, true);
                    }
                }
                
                return true;
            });
        window_manager.key_release_event.connect((w, e) => {
                var xid = window_manager.get_focus_tab_xid();
                if (xid != null) {
                    send_key_event(xid, e.keyval, e.state, e.hardware_keycode, e.time, false);
                }
                
                return true;
            });
        window_manager.destroy_windows.connect((xids) => {
                destroy_windows(xids);
            });
        window_manager.reparent_window.connect((xid) => {
                reparent_window(xid);
            });
        window_manager.destroy_buffer.connect((buffer_id) => {
                destroy_buffer(buffer_id);
            });
        window_manager.resize_window.connect((xid, width, height) => {
                resize_window(xid, width, height);
            });
        
        app.box.pack_start(window_manager, true, true, 0);
        
        app.destroy.connect(quit);
        app.size_allocate.connect_after((w, e) => {
                window_manager.update_windows_allocate();
            });

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