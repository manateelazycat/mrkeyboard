using Gtk;
using Utils;
using Draw;

namespace Application {
    const string app_name = "videoplayer";
    const string dbus_name = "org.mrkeyboard.app.videoplayer";
    const string dbus_path = "/org/mrkeyboard/app/videoplayer";

    [DBus (name = "org.mrkeyboard.app.videoplayer")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.videoplayer")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public PlayerView player_view;
        
        public Window(int width, int height, string bid, string path) {
            base(width, height, bid, path);
        }
        
        public override void init() {
            player_view = new PlayerView(buffer_path);
            
            player_view.realize.connect((w) => {
                    update_tab_name(buffer_path);
                });
            
            box.pack_start(player_view, true, true, 0);
        }        
        
        public void update_tab_name(string path) {
            var paths = path.split("/");
            rename_app_tab(mode_name, buffer_id, paths[paths.length - 1], path);
        }
        
        public override void scroll_vertical(bool scroll_up) {
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return player_view.get_window();
        }
    }

    public class PlayerView : DrawingArea {
        public string video_path;
        public string mplayer_channel_file;
        private IOChannel mplayer_channel;
        public Gdk.Color background_color = Utils.color_from_string("#000000");
        public GLib.Pid process_id;
        
        public PlayerView(string path) {
            video_path = path;
            
            set_can_focus(true);  // make widget can receive key event 
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.KEY_PRESS_MASK
                        | Gdk.EventMask.KEY_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    mplayer_channel_file = "/tmp/mrkeyboard/mplayer_channel-%i".printf(xid);
                    
                    try {
                        Process.spawn_command_line_async("rm -f %s".printf(mplayer_channel_file));
                        Process.spawn_command_line_async("mkfifo %s".printf(mplayer_channel_file));
                        
                        string spawn_command_line = "mplayer -slave -quiet -input file=%s %s -wid %i".printf(mplayer_channel_file, video_path, xid);
                        string[] spawn_args;
                        try {
                            Shell.parse_argv(spawn_command_line, out spawn_args);
                        } catch (ShellError e) {
                            stderr.printf("%s\n", e.message);
                        }
                        
                        Process.spawn_async(
                            null,
                            spawn_args,
                            null,
                            SpawnFlags.SEARCH_PATH,
                            null,
                            out process_id);
                    } catch (SpawnError e) {
                        stderr.printf("%s\n", e.message);
                    }

                    try {
                        mplayer_channel = new IOChannel.file("%s".printf(mplayer_channel_file), "r+");
                    } catch (FileError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            configure_event.connect((w, e) => {
                    print("*********************\n");
                    queue_draw();
                    
                    return false;
                });
            destroy.connect((w) => {
                    try {
                        Process.spawn_command_line_async("kill %i".printf(process_id));
                        Process.spawn_command_line_async("rm -f %s".printf(mplayer_channel_file));
                    } catch (SpawnError e) {
                        stderr.printf("%s\n", e.message);
                    }
                });
            
            draw.connect(on_draw);
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            return true;
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