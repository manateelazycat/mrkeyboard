using Gtk;
using Gdk;
using Utils;
using Widget;

namespace Application {
    const string app_name = "filemanager";
    const string dbus_name = "org.mrkeyboard.app.filemanager";
    const string dbus_path = "/org/mrkeyboard/app/filemanager";

    [DBus (name = "org.mrkeyboard.app.filemanager")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.filemanager")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public ListView fileview;
        public ScrolledWindow scrolled_window;
        
        public Window(int width, int height, string bid, string path, Buffer buf) {
            base(width, height, bid, path, buf);
        }
        
        public override void init() {
            fileview = new ListView();
            
            fileview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            
            scrolled_window = new ScrolledWindow(null, null);
            scrolled_window.add(fileview);
            
            box.pack_start(scrolled_window, true, true, 0);
        }        
        
        public override void scroll_vertical(bool scroll_up) {
            var vadj = scrolled_window.get_vadjustment();
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
            return fileview.get_window();
        }
    }

    public class Buffer : Interface.Buffer {
        public Buffer() {
            base();
        }
    }
}