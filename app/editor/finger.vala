using Gtk;
using Draw;
using Utils;

namespace Finger {
    public static const string font_family = "Monospace";
    public static const int line_height = 19;
    public static const int char_width = 10;

    public class LineNumberView : DrawingArea {
        public Gdk.Color background_color = Utils.color_from_string("#050505");
        public int width = 20;
        
        public LineNumberView() {
            set_can_focus(true);  // make widget can receive key event 
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.KEY_PRESS_MASK
                       | Gdk.EventMask.KEY_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            draw.connect(on_draw);
            set_size_request(width, -1);
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            return true;
        }        
    }

    public class EditView : DrawingArea {
        public Gdk.Color background_color = Utils.color_from_string("#000000");
        public Gdk.Color line_background_color = Utils.color_from_string("#121212");
        public Gdk.Color line_cursor_color = Utils.color_from_string("red");
        public Gdk.Color cursor_color = Utils.color_from_string("#ff1e00");
        public Gdk.Color text_color = Utils.color_from_string("#009900");
        public FingerBuffer buffer;
        public Pango.FontDescription font_description;
        public int font_size = 12;
        public int current_row = 0;
        public int current_column = 0;
        public int render_start_index = 0;
        public int cursor_index = 0;
        public int line_index = 0;
        
        public EditView(FingerBuffer buf) {
            buffer = buf;
            font_description = new Pango.FontDescription();
            font_description.set_family(font_family);
            font_description.set_size((int)(font_size * Pango.SCALE));
            
            set_can_focus(true);  // make widget can receive key event 
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
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
            
            realize.connect((w) => {
                    grab_focus();
                });
        }
        
        public void handle_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            if (keyname == "Ctrl + n") {
                next_line();
            } else if (keyname == "Ctrl + p") {
                prev_line();
            }
        }
        
        public void next_line() {
            int current_line_end_index = buffer.content.index_of("\n", cursor_index);
            if (current_line_end_index < buffer.content.length - 1) {
                cursor_index = current_line_end_index + 1;
                
                queue_draw();
            }
        }
        
        public void prev_line() {
            int prev_line_end_index = render_start_index;
            int[] line_end_lines = {};
            while (prev_line_end_index < cursor_index) {
                prev_line_end_index = buffer.content.index_of("\n", prev_line_end_index);
                prev_line_end_index++;
                
                line_end_lines += prev_line_end_index;
            }
            
            if (line_end_lines.length > 0) {
                cursor_index = line_end_lines[line_end_lines.length - 2];
                
                queue_draw();
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            
            int render_y = 0;
            int render_index = render_start_index;
            while(render_index < buffer.content.length && render_y < alloc.height) {
                int line_end_index = buffer.content.index_of("\n", render_index);
                string render_line_string = buffer.content.slice(render_index, line_end_index);
                
                if (cursor_index >= render_index && cursor_index <= line_end_index) {
                    Utils.set_context_color(cr, line_background_color);
                    Draw.draw_rectangle(cr, 0, render_y, alloc.width, line_height);
                    
                    Utils.set_context_color(cr, line_cursor_color);
                    Draw.draw_rectangle(cr, 0, render_y, 2, line_height);
                }
                
                Utils.set_context_color(cr, text_color);
                render_line(cr, "%s\n".printf(render_line_string), 0, render_y, line_height, font_description);
                
                render_index = line_end_index + 1;
                render_y += line_height;
            }
            
            return true;
        }
        
        public void render_line(Cairo.Context cr, string text, int x, int y, int height,
                                Pango.FontDescription font_description) {
            var layout = Pango.cairo_create_layout(cr);
            layout.set_text(text, (int)text.length);
            layout.set_height((int)(height * Pango.SCALE));
            layout.set_width(-1);
            layout.set_font_description(font_description);
            layout.set_alignment(Pango.Alignment.LEFT);
		
            cr.move_to(x, y);
            Pango.cairo_update_layout(cr, layout);
            Pango.cairo_show_layout(cr, layout);
        }
    }

    public class FingerView : HBox {
        public FingerBuffer buffer;
        public LineNumberView line_number_view;
        public EditView edit_view;
        
        public FingerView(FingerBuffer buf) {
            buffer = buf;
            
            line_number_view = new LineNumberView();
            edit_view = new EditView(buf);
            
            pack_start(line_number_view, false, false, 0);
            pack_start(edit_view, true, true, 0);
        }
    }

    public class FingerBuffer : Object {
        public string content;
        
        public FingerBuffer(string path) {
            try {
                FileUtils.get_contents(path, out content);
            } catch (GLib.FileError e) {
                stderr.printf("FingerBuffer ERROR: %s\n", e.message);
            }
        }
    }
}