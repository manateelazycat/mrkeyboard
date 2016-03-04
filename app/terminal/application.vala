using Vte;
using Gtk;

namespace Application {
    const string app_name = "terminal";
    const string dbus_name = "org.mrkeyboard.app.terminal";
    const string dbus_path = "/org/mrkeyboard/app/terminal";

    [DBus (name = "org.mrkeyboard.app.terminal")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.terminal")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public Vte.Terminal term;
        public GLib.Pid process_id;
        
        public Window(int width, int height, string bid, string path) {
            base(width, height, bid, path);
        }
        
        public override void init() {
            term = new Terminal();
            term.set_scrollback_lines(-1);
            term.child_exited.connect((t) => {
                    close_app_tab(mode_name, buffer_id);
                });
            term.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            term.window_title_changed.connect((t) => {
                    string working_directory;
                    string[] spawn_args = {"readlink", "/proc/%i/cwd".printf(process_id)};
                    try {
                        Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out working_directory);
                    } catch (SpawnError e) {
                        print("Got error when spawn_sync: %s\n", e.message);
                    }
                    
                    if (working_directory.length > 0) {
                        working_directory = working_directory[0:working_directory.length - 1];
                        if (buffer_path != working_directory) {
                            rename_app_tab(mode_name, buffer_id, GLib.Path.get_basename(working_directory), working_directory);
                            buffer_path = working_directory;
                        }
                    }
                });
            var arguments = new string[0];
            var shell = get_shell();
            try {
                GLib.Shell.parse_argv(shell, out arguments);
            } catch (GLib.ShellError e) {
                print("Got error when get_shell: %s\n", e.message);
            }
            try {
                string? working_directory = null;
				string?[] envv = null;
				
                if (buffer_path.length > 0) {
                    working_directory = buffer_path;
                }
				
				term.spawn_sync(Vte.PtyFlags.DEFAULT, working_directory, {shell}, envv, SpawnFlags.SEARCH_PATH, null, out process_id, null);
            } catch (GLib.Error e) {
                print("Got error when fork_command_full: %s\n", e.message);
            }
            
            box.pack_start(term, true, true, 0);
        }        
        
        public override void scroll_vertical(bool scroll_up) {
            var vadj = term.get_vadjustment();
            var value = vadj.get_value();
            var lower = vadj.get_lower();
            var upper = vadj.get_upper();
            var page_size = vadj.get_page_size();
            var scroll_offset = 2;  // avoid we can't read page continue when scroll page
            
            if (scroll_up) {
                vadj.set_value(double.min(value + (page_size - scroll_offset), upper - page_size));
            } else {
                vadj.set_value(double.max(value - (page_size - scroll_offset), lower));
            }
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return term.get_window();
        }
        
        private static string get_shell() {
            string? shell = Vte.get_user_shell();
        
            if (shell == null) {
                shell = "/bin/sh";
            }
        
            return (!)(shell);
        }
    }

    public class CloneWindow : Interface.CloneWindow {
        public CloneWindow(int width, int height, int pwid, string mode_name, string bid, string path) {
            base(width, height, pwid, mode_name, bid, path);
        }
        
        public override string get_background_color() {
            return "black";
        }
    }
}