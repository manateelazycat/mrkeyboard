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
            if (scroll_up) {
                pdf_view.scroll_page_up();
            } else {
                pdf_view.scroll_page_down();
            }
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
        public int render_y;
        public int scroll_offset;
        public Buffer buffer;
        public Gdk.Color background_color = Utils.color_from_string("#ffffff");

        public PdfView(Buffer buf) {
            page_index = 0;
            render_y = 0;
            scroll_offset = 20;
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
            if (keyname == "j") {
                scroll_up();
            } else if (keyname == "k") {
                scroll_down();
            } else if (keyname == "J") {
                scroll_last();
            } else if (keyname == "K") {
                scroll_first();
            } else if (keyname == "Space") {
                scroll_page_up();
            }
        }
        
        public void scroll_page_up() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);
            
            scroll_up((int)(alloc.height * current_page_width / alloc.width) - scroll_offset);
        }
        
        public void scroll_page_down() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);
            
            scroll_down((int)(alloc.height * current_page_width / alloc.width) - scroll_offset);
        }
        
        public void scroll_up(int offset=scroll_offset) {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);
            
            if (page_index == buffer.page_counter - 1) {
                render_y = int.max(render_y - offset, alloc.height - (int)current_page_height);
            } else {
                render_y -= offset;
            }
            
            adjust_page_index();
            
            queue_draw();
        }
        
        public void scroll_down(int offset=scroll_offset) {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);
            
            if (page_index == 0) {
                render_y = int.min(0, render_y + offset);
            } else {
                render_y += offset;
            }

            adjust_page_index();
            
            queue_draw();
        }
        
        public void scroll_first() {
            page_index = 0;
            render_y = 0;
            
            queue_draw();
        }
        
        public void scroll_last() {
            page_index = buffer.page_counter - 1;
            render_y = 0;
            
            queue_draw();
        }
        
        public void adjust_page_index() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);

            if (render_y <= -current_page_height) {
                page_index = int.min(buffer.page_counter - 1, page_index + 1);
                render_y = render_y + (int)current_page_height;
            } else if (render_y >= current_page_height) {
                page_index = int.max(0, page_index - 1);
                render_y = render_y - (int)current_page_height;
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            // Draw background.
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);

            // Draw preview page.
            if (page_index > 0) {
                cr.save();
                var previous_page = buffer.document.get_page(page_index - 1);
                double previous_page_width, previous_page_height;
                previous_page.get_size(out previous_page_width, out previous_page_height);
                cr.scale(alloc.width / previous_page_width, alloc.width / previous_page_width);
                cr.translate(0, render_y - previous_page_height);
                previous_page.render(cr);
                cr.restore();
            }

            // Draw current page.
            cr.save();
            var current_page = buffer.document.get_page(page_index);
            double current_page_width, current_page_height;
            current_page.get_size(out current_page_width, out current_page_height);
            cr.scale(alloc.width / current_page_width, alloc.width / current_page_width);
            cr.translate(0, render_y);
            current_page.render(cr);
            cr.restore();
            
            // Draw next page.
            if (page_index < buffer.page_counter - 1) {
                cr.save();
                var next_page = buffer.document.get_page(page_index + 1);
                double next_page_width, next_page_height;
                next_page.get_size(out next_page_width, out next_page_height);
                cr.scale(alloc.width / next_page_width, alloc.width / next_page_width);
                cr.translate(0, render_y + next_page_height);
                next_page.render(cr);
                cr.restore();
            }
            
            return true;
        }
    }

    public class Buffer : Interface.Buffer {
        public Poppler.Document document;
        public int page_counter;
        
        public Buffer(string path) {
            base(path);

            try {
                document = new Poppler.Document.from_file(Filename.to_uri(path), "");
                page_counter = document.get_n_pages();
            } catch (Error err) {
                stderr.printf ("Error: new document failed: %s\n", err.message);
            }
        }
    }
}