using Cairo;
using Draw;
using Gdk;
using Gtk;
using Utils;

namespace Application {
    const string app_name = "pdfviewer";
    const string dbus_name = "org.mrkeyboard.app.pdfviewer";
    const string dbus_path = "/org/mrkeyboard/app/pdfviewer";

    [DBus (name = "org.mrkeyboard.app.pdfviewer")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.pdfviewer")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public PdfView pdf_view;
        
        public Window(int width, int height, string bid, Buffer buf) {
            base(width, height, bid, buf);
        }
        
        public override void init() {
            pdf_view = new PdfView(buffer);
            
            pdf_view.realize.connect((w) => {
                    update_tab_name(pdf_view.buffer.buffer_path);
                });
            
            box.pack_start(pdf_view, true, true, 0);
        }        
        
        public void update_tab_name(string path) {
            var paths = path.split("/");
            rename_app_tab(mode_name, buffer_id, paths[paths.length - 1], path);
        }
        
        public override void scroll_vertical(bool scroll_up) {
            print("Scroll vertical: %s\n", scroll_up.to_string());
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return pdf_view.get_window();
        }
    }

    public class PdfView : DrawingArea {
        public int page_index;
        public Buffer buffer;
        public Gdk.Color background_color = Utils.color_from_string("#ffffff");

        public PdfView(Buffer buf) {
            page_index = 0;
            buffer = buf;
            
            set_can_focus(true);  // make widget can receive key event 
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.KEY_PRESS_MASK
                        | Gdk.EventMask.KEY_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            draw.connect(on_draw);
            
            key_press_event.connect((w, e) => {
                    handle_key_press(w, e);

                    return false;
                });
        }
        
        public void handle_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            print(keyname);
            if (keyname == "j") {
                
            } else if (keyname == "k") {
            } else if (keyname == "J") {
            } else if (keyname == "K") {
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);

            var page = buffer.document.get_page(page_index);
            double page_width, page_height;
            page.get_size(out page_width, out page_height);
            
            cr.scale(alloc.width / page_width, alloc.width / page_width);
            page.render(cr);
            
            return true;
        }
    }

    public class Buffer : Interface.Buffer {
        public Poppler.Document document;
        
        public Buffer(string path) {
            base(path);

            try {
                document = new Poppler.Document.from_file(Filename.to_uri(path), "");
            } catch (Error err) {
                stderr.printf ("Error: new document failed: %s\n", err.message);
            }
        }
    }
}