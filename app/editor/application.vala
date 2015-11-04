using Gtk;
using Gdk;
using Utils;

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
        public ScrolledWindow scrolled_window;
        
        public Window(int width, int height, string bid, Buffer buf) {
            base(width, height, bid, buf);
        }
        
        public override void init() {
            sourceview = new Gtk.SourceView.with_buffer(buffer.source_buffer);
            sourceview.cursor_visible = true;
            sourceview.highlight_current_line = true;
            sourceview.show_line_numbers = true;
            
            sourceview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            sourceview.realize.connect((w) => {
                    var paths = buffer.buffer_path.split("/");
                    rename_app_tab(mode_name, buffer_id, paths[paths.length - 1], buffer.buffer_path);
                });
            
            scrolled_window = new ScrolledWindow(null, null);
            scrolled_window.add(sourceview);
            
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
            return sourceview.get_window(Gtk.TextWindowType.WIDGET);
        }
    }

    public class Buffer : Interface.Buffer {
        public Gtk.SourceBuffer source_buffer;
        
        public Buffer(string path) {
            base(path);
            
            source_buffer = new Gtk.SourceBuffer(null);
            string content;
            FileUtils.get_contents(path, out content);
            source_buffer.set_text(content);
            
            TextIter start_iter;
            source_buffer.get_start_iter(out start_iter);
            source_buffer.place_cursor(start_iter);
            source_buffer.set_highlight_syntax(true);
            
            var manager = new Gtk.SourceLanguageManager();
            var language = manager.guess_language(path, content);
            if (language != null) {
                source_buffer.set_highlight_syntax(true);
                source_buffer.set_language(language);
            } else {
                print("No language found for file %s\n", path);
            }
        }
    }
}