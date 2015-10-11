using Gtk;
using Vte;

namespace Application {
    public class Window : Gtk.Window {
        public Vte.Terminal term;
        public int tab_id;
        public int window_id;
        public string buffer_id;
        public string buffer_name = "";
        public string mode_name = "terminal";
        public GLib.Pid process_id;
        
        public signal void create_app(int app_win_id, string mode_name, int tab_id);
        public signal void close_app_tab(string mode_name, string buffer_id);
        public signal void rename_app_tab(string mode_name, string buffer_id, string buffer_name);
        
        public Window(int width, int height, int tid, string bid) {
            tab_id = tid;
            buffer_id = bid;
            
            set_decorated(false);
            set_default_size(width, height);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
            
            term = new Terminal();
            term.child_exited.connect((t) => {
                    close_app_tab(mode_name, buffer_id);
                });
            term.window_title_changed.connect((t) => {
                    string working_directory;
                    string[] spawn_args = {"readlink", "/proc/%i/cwd".printf(process_id)};
                    try {
                        Process.spawn_sync(null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, out working_directory);
                    } catch (SpawnError e) {
                        print("Got error when spawn__line_async: %s\n", e.message);
                    }
                    
                    if (working_directory.length > 0) {
                        working_directory = working_directory[0:working_directory.length - 1];
                        if (buffer_name != working_directory) {
                            var paths = working_directory.split("/");
                            rename_app_tab(mode_name, buffer_id, paths[paths.length - 1]);
                            buffer_name = working_directory;
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
                term.fork_command_full(PtyFlags.DEFAULT, null, arguments, null, SpawnFlags.SEARCH_PATH, null, out process_id);
            } catch (GLib.Error e) {
                print("Got error when fork_command_full: %s\n", e.message);
            }
            box.pack_start(term, true, true, 0);
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    window_id = xid;
                    create_app(window_id, mode_name, tab_id);
                });
        }
        
        private static string get_shell() {
            string? shell = Vte.get_user_shell();
        
            if (shell == null) {
                shell = "/bin/sh";
            }
        
            return (!)(shell);
        }

        public void handle_key_event(uint key_val, int key_state, uint32 key_time, bool press) {
            Gdk.EventKey* event;
            if (press) {
                event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_PRESS);
            } else {
                event = (Gdk.EventKey*) new Gdk.Event(Gdk.EventType.KEY_RELEASE);
            }
            event->window = term.get_window();
            event->keyval = key_val;
            event->state = (Gdk.ModifierType) key_state;
            event->time = key_time;
            ((Gdk.Event*) event)->put();
        }
    }
}