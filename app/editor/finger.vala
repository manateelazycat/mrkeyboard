using Gtk;
using Draw;
using Utils;
using Render;

namespace Finger {
    public static const string font_family = "Monospace";
    public static const int line_height = 19;
    public static const int char_width = 10;

    public class LineNumberView : DrawingArea {
        public Gdk.Color background_color = Utils.color_from_string("#040404");
        public Gdk.Color text_color = Utils.color_from_string("#202020");
        public int padding_x = 4;
        public int width = 30;
        public EditView edit_view;
        
        public int render_start_row = 0;
        
        public LineNumberView(EditView view) {
            edit_view = view;
            
            set_can_focus(true);  // make widget can receive key event 
            add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                       | Gdk.EventMask.BUTTON_RELEASE_MASK
                       | Gdk.EventMask.KEY_PRESS_MASK
                       | Gdk.EventMask.KEY_RELEASE_MASK
                       | Gdk.EventMask.POINTER_MOTION_MASK
                       | Gdk.EventMask.LEAVE_NOTIFY_MASK);
            
            draw.connect(on_draw);
            set_size_request(width, -1);
            
            view.update_render_start_row.connect((row) => {
                    render_start_row = row;
                    
                    queue_draw();
                });
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            // Draw background.
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            // Draw line number.
            int render_y = 0;
            int line_index = render_start_row + 1;
            while (render_y < alloc.height) {
                // Draw current line.
                Utils.set_context_color(cr, text_color);
                Render.render_line(cr, "%i\n".printf(line_index), padding_x, render_y, line_height, edit_view.font_description);
                
                line_index += 1;
                render_y += line_height;
            }
            
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
        
        public int render_start_row = 0;
        
        public signal void update_render_start_row(int render_row);
        
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
                
                if (cursor_line_in_screen() == 1) {
                    int line_end_index = buffer.content.index_of("\n", render_start_index);
                    render_start_index = line_end_index + 1;
                    
                    render_start_row++;
                    update_render_start_row(render_start_row);
                }
                
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
            
            if (cursor_line_in_screen() == -1) {
                int line_above_index = 0;
                int[] line_above_lines = {};
                while (line_above_index < render_start_index) {
                    line_above_index = buffer.content.index_of("\n", line_above_index);
                    line_above_index++;
                
                    line_above_lines += line_above_index;
                }

                if (line_above_lines.length > 0) {
                    render_start_index = line_above_lines[line_above_lines.length - 2];
                    
                    render_start_row--;
                    update_render_start_row(render_start_row);
                    
                    queue_draw();
                }
            }
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);

            // Draw background.
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            int render_y = 0;
            int render_index = render_start_index;
            int counter = 0;
            while(render_index < buffer.content.length && render_y < alloc.height) {
                int line_end_index = buffer.content.index_of("\n", render_index);
                string render_line_string = buffer.content.slice(render_index, line_end_index);
                
                if (cursor_index >= render_index && cursor_index <= line_end_index) {
                    current_row = render_start_row + counter;
                    
                    // Draw highlight line.
                    Utils.set_context_color(cr, line_background_color);
                    Draw.draw_rectangle(cr, 0, render_y, alloc.width, line_height);

                    // Draw current cursor.
                    Utils.set_context_color(cr, line_cursor_color);
                    Draw.draw_rectangle(cr, 0, render_y, 2, line_height);
                }

                // Draw current line.
                Utils.set_context_color(cr, text_color);
                Render.render_line(cr, "%s\n".printf(render_line_string), 0, render_y, line_height, font_description);
                
                render_index = line_end_index + 1;
                render_y += line_height;
                counter++;
            }
            
            return true;
        }
        
        public int cursor_line_in_screen() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);

            int render_y = (current_row - render_start_row) * line_height;
            if (render_y > alloc.height - 2 * line_height) {
                return 1;
            } else if (render_y <= 2 * line_height) {
                return -1;
            } else {
                return 0;
            }
        }
    }

    public class FingerView : HBox {
        public FingerBuffer buffer;
        public LineNumberView line_number_view;
        public EditView edit_view;
        
        public FingerView(FingerBuffer buf) {
            buffer = buf;
            
            edit_view = new EditView(buf);
            line_number_view = new LineNumberView(edit_view);
            
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