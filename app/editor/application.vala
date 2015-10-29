using Gtk;

namespace Application {
    const string app_name = "editor";
    const string dbus_name = "org.mrkeyboard.app.editor";
    const string dbus_path = "/org/mrkeyboard/app/editor";

    [DBus (name = "org.mrkeyboard.app.editor")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.editor")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public Gtk.SourceView sourceview;
        
        public Window(int width, int height, string bid, string path) {
            base(width, height, bid, path);
        }
        
        public override void init() {
            sourceview = new Gtk.SourceView();
            
            box.pack_start(sourceview, true, true, 0);
        }        
        
        public override void scroll_vertical(bool scroll_up) {
            var vadj = sourceview.get_vadjustment();
            var value = vadj.get_value();
            var lower = vadj.get_lower();
            var upper = vadj.get_upper();
            var page_size = vadj.get_page_size();
            var scroll_offset = 10;  // avoid we can't read page continue when scroll page
            
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
            return sourceview.get_window(Gtk.TextWindowType.WIDGET);
        }
    }

    public class CloneWindow : Interface.CloneWindow {
        public CloneWindow(int width, int height, int pwid, string mode_name, string bid, string path) {
            base(width, height, pwid, mode_name, bid, path);
        }
        
        public override string get_background_color() {
            return "white";
        }
    }
}