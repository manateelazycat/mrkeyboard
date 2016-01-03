using Gtk;
using Draw;
using Utils;
using Render;
using Gee;

namespace Finger {
    public static const string font_family = "Monospace";
    public static const int line_height = 19;
    public static const int char_width = 10;

    public class LineNumberView : DrawingArea {
        public Gdk.Color background_color = Utils.color_from_string("#040404");
        public Gdk.Color text_color = Utils.color_from_string("#202020");
        public int padding_x = 4;
        public EditView edit_view;
        
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
            
            view.render_line_number.connect((row) => {
					int line_number = edit_view.get_logic_line_count();
					set_size_request(padding_x * 2 + line_number.to_string().length * char_width, -1);
					
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
			int skip_line_count = 0;
			bool reach_bottom = false;
			while (render_y < alloc.height && !reach_bottom) {
				int[]? lines = edit_view.index_to_lines(0, (edit_view.render_offset + render_y) * Pango.SCALE);
				if (lines != null) {
					
					if (lines[0] == lines[1]) {
						if (lines[0] <= edit_view.layout.get_line_count() - 1) {
							Utils.set_context_color(cr, text_color);
							render_text(cr, (lines[1] + 1 - skip_line_count).to_string(),
										padding_x, render_y, alloc.width, line_height, edit_view.font_description);
							if (lines[0] == edit_view.layout.get_line_count() - 1) {
								reach_bottom = true;
							}
						}
					} else {
						skip_line_count += 1;
					}
				}

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
        
        public int cursor_index = 0;
		public int cursor_trailing = 0;
		public int cursor_width = 2;
		public int render_offset = 0;
        
        public ArrayList<int> render_line_heights = new ArrayList<int>();
        
        public signal void render_line_number();
		
		public Pango.Layout layout;		
		
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
            } else if (keyname == "Ctrl + f") {
				forward_char();
			} else if (keyname == "Ctrl + b") {
				backward_char();
			}
        }
        
        public void next_line() {
			int line, x_pos;
			bool trailing = cursor_trailing > 0;
			layout.index_to_line_x(cursor_index, trailing, out line, out x_pos);

			int new_index, new_trailing;
			layout.xy_to_index(x_pos, (line + 1) * line_height * Pango.SCALE, out new_index, out new_trailing);
			cursor_index = new_index;
			cursor_trailing = new_trailing;
			
			try_scroll_up();
			
			queue_draw();
        }
        
        public void prev_line() {
			int line, x_pos;
			bool trailing = cursor_trailing > 0;
			layout.index_to_line_x(cursor_index, trailing, out line, out x_pos);

			int new_index, new_trailing;
			layout.xy_to_index(x_pos, (line - 1) * line_height * Pango.SCALE, out new_index, out new_trailing);
			cursor_index = new_index;
			cursor_trailing = new_trailing;
			
			try_scroll_down();
			
			queue_draw();
        }
		
		public void forward_char() {
			int new_index, new_trailing;
			layout.move_cursor_visually(true, cursor_index, cursor_trailing, 1, out new_index, out new_trailing);
			cursor_index = new_index;
			cursor_trailing = new_trailing;
			
			try_scroll_up();
			
			queue_draw();
		}
		
		public void backward_char() {
			int new_index, new_trailing;
			layout.move_cursor_visually(true, cursor_index, cursor_trailing, -1, out new_index, out new_trailing);
			if (new_index >= 0) {
				cursor_index = new_index;
			}
			cursor_trailing = new_trailing;
			
			try_scroll_down();

			queue_draw();
		}

		public void try_scroll_up() {
			int line, x_pos;
			bool trailing = cursor_trailing > 0;
			layout.index_to_line_x(cursor_index, trailing, out line, out x_pos);
			
            Gtk.Allocation alloc;
            get_allocation(out alloc);
			if ((line + 2) * line_height - render_offset > alloc.height) {
				render_offset += line_height;
			}
		}
		
		public void try_scroll_down() {
			int line, x_pos;
			bool trailing = cursor_trailing > 0;
			layout.index_to_line_x(cursor_index, trailing, out line, out x_pos);
			
			if ((line - 1) * line_height - render_offset < line_height) {
				render_offset = int.max(render_offset - line_height, 0);
			}
		}
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
			
			if (layout == null) {
				layout = Pango.cairo_create_layout(cr);
				layout.set_text(buffer.content, (int)buffer.content.length);
				layout.set_wrap(Pango.WrapMode.WORD_CHAR);
				layout.set_font_description(font_description);
				layout.set_alignment(Pango.Alignment.LEFT);
			}

			layout.set_width((int)(alloc.width * Pango.SCALE));
			
			int line, x_pos;
			bool trailing = cursor_trailing > 0;
			layout.index_to_line_x(cursor_index, trailing, out line, out x_pos);
			
            // Draw background.
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
			
			cr.translate(0, -render_offset);
			
			// Draw line background.
			int[] line_bound = find_line_bound();
			int start_line, start_line_x_pos;
			int end_line, end_line_x_pos;
			
			layout.index_to_line_x(line_bound[0], false, out start_line, out start_line_x_pos);
			layout.index_to_line_x(line_bound[1], false, out end_line, out end_line_x_pos);
			Utils.set_context_color(cr, line_background_color);
			draw_rectangle(cr, 0, start_line * line_height, alloc.width, int.max((end_line - start_line), 1 )* line_height);
			
			// Draw context.
			cr.save();
			
			cr.rectangle(0, render_offset, alloc.width, alloc.height);
			cr.clip();
			
            Utils.set_context_color(cr, text_color);
			Pango.cairo_update_layout(cr, layout);
			Pango.cairo_show_layout(cr, layout);
			
			cr.restore();
			
			// Draw cursor.
			Utils.set_context_color(cr, cursor_color);
			draw_rectangle(cr, x_pos / Pango.SCALE, line * line_height, cursor_width, line_height);
			
			render_line_number();
            
            return true;
        }

		public int[] find_line_bound() {
			int[] line_bound = new int[2];
			
			line_bound[0] = int.max(0, buffer.content.substring(0, cursor_index).last_index_of_char('\n')) + 1;
			line_bound[1] = buffer.content.index_of_char('\n', cursor_index);
			if (line_bound[1] == -1) {
				line_bound[1] = buffer.content.char_count() - 1;
			} else {
				line_bound[1] += 1;
			}
			
			return line_bound;
		}
		
		public int get_logic_line_count() {
			int line_index = int.max(0, buffer.content.last_index_of_char('\n')) + 1;
			int line, line_x_pos;
			layout.index_to_line_x(line_index, false, out line, out line_x_pos);
			
			return line;
		}
		
		public int[]? index_to_lines(int x, int y) {
			if (layout != null) {
				int target_index, target_trailing;
				layout.xy_to_index(x, y, out target_index, out target_trailing);
				
			    int target_line, target_line_x_pos;
			    layout.index_to_line_x(target_index, false, out target_line, out target_line_x_pos);
			    
			    int start_line_index = int.max(0, buffer.content.substring(0, target_index).last_index_of_char('\n')) + 1;
			    int start_line, start_line_x_pos;
			    layout.index_to_line_x(start_line_index, false, out start_line, out start_line_x_pos);
			    
			    int[] lines = {target_line, start_line};
			    return lines;
			} else {
				return null;
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