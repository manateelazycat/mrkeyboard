using Gtk;
using Gdk;
using Utils;
using Finger;

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
        public FingerView sourceview;
        
        public Window(int width, int height, string bid, Buffer buf) {
            base(width, height, bid, buf);
        }
        
        public override void init() {
            sourceview = new FingerView(buffer.source_buffer);
            
            sourceview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            sourceview.realize.connect((w) => {
                    rename_app_tab(mode_name, buffer_id, GLib.Path.get_basename(buffer.buffer_path), buffer.buffer_path);
                });
            
            box.pack_start(sourceview, true, true, 0);
        }        
        
        public override void scroll_vertical(bool scroll_up) {
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return sourceview.get_window();
        }
    }

    public class Buffer : Interface.Buffer {
        public FingerBuffer source_buffer;
        
        public Buffer(string path) {
            base(path);
            
            source_buffer = new FingerBuffer(path);
        }
    }
}
