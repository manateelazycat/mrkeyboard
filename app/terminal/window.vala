using Gtk;
using Vte;

namespace Application {
    public class Window : Gtk.Window {
        public Vte.Terminal term;
        public string mode_name = "terminal";
        public int window_id;
        
        public signal void create_app(int app_win_id, string mode_name, int tab_id);
        
        public Window(int width, int height, int tab_id) {
            set_decorated(false);
            set_default_size(width, height);
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
            
            term = new Terminal();
            var arguments = new string[0];
            var shell = get_shell();
            try {
                GLib.Shell.parse_argv(shell, out arguments);
            } catch (GLib.ShellError e) {
                print("Got error when get_shell: %s\n", e.message);
            }
            try {
                term.fork_command_full(PtyFlags.DEFAULT, null, arguments, null, SpawnFlags.SEARCH_PATH, null, null);
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