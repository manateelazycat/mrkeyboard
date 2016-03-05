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
        public Gdk.RGBA background_color = Gdk.RGBA();
        public Gdk.RGBA text_color = Gdk.RGBA();
        public int padding_x = 4;
        public EditView edit_view;
        
        public LineNumberView(EditView view) {
			background_color.parse("#040404");
			text_color.parse("#888888");
			
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
						// We need increment line number count once found wrap line.
						skip_line_count += 1;
					}
				}

				render_y += line_height;
			}
            
			return true;
        }        
    }

    public class EditView : DrawingArea {
        public Gdk.RGBA background_color = Gdk.RGBA();
        public Gdk.RGBA line_background_color = Gdk.RGBA();
        public Gdk.RGBA line_cursor_color = Gdk.RGBA();
        public Gdk.RGBA cursor_color = Gdk.RGBA();
        public Gdk.RGBA text_color = Gdk.RGBA();
		
        public FingerBuffer buffer;
        public Pango.FontDescription font_description;
        public int font_size = 12;
        
        public int cursor_index = 0;
		public int cursor_trailing = 0;
		public int cursor_width = 2;
		public int render_offset = 0;
        
		public Pango.Layout layout;		
		
		public int column_offset = 0;
		
		public signal void render_line_number();
		
		public EditView(FingerBuffer buf) {
			background_color.parse("#000000");
			line_background_color.parse("#121212");
			line_cursor_color.parse("red");
			cursor_color.parse("#ff1e00");
			text_color.parse("#009900");
			
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
			} else if (keyname == "Alt + f") {
				forward_word();
			} else if (keyname == "Alt + b") {
				backward_word();
			} else if (keyname == "Ctrl + a") {
				move_beginning_of_line();
			} else if (keyname == "Ctrl + e") {
				move_end_of_line();
			} else if (keyname == "Alt + m") {
				back_to_indentation();
			} else if (keyname == "Ctrl + N") {
				end_of_buffer();
			} else if (keyname == "Ctrl + P") {
				beginning_of_buffer();
			} else if (keyname == "Super + J") {
				scroll_up_one_line();
			} else if (keyname == "Super + K") {
				scroll_down_one_line();
			}
        }
        
        public void next_line() {
			int line = get_cursor_line();

			int new_index, new_trailing;
			layout.xy_to_index(column_offset, (line + 1) * line_height * Pango.SCALE, out new_index, out new_trailing);
			cursor_index = new_index;
			cursor_trailing = new_trailing;
			
			try_scroll_up();
			
			queue_draw();
        }
        
        public void prev_line() {
			int line = get_cursor_line();

			int new_index, new_trailing;
			layout.xy_to_index(column_offset, (line - 1) * line_height * Pango.SCALE, out new_index, out new_trailing);
			cursor_index = new_index;
			cursor_trailing = new_trailing;
			
			try_scroll_down();
			
			queue_draw();
        }
		
		public void forward_char() {
			forward_char_internal();
			
			remeber_column_offset();
			
			try_scroll_up();
			
			queue_draw();
		}
		
		public void backward_char() {
			backward_char_internal();
			
			remeber_column_offset();
			
			try_scroll_down();

			queue_draw();
		}
		
		public bool forward_char_internal() {
			int new_index, new_trailing;
			layout.move_cursor_visually(true, cursor_index, cursor_trailing, 1, out new_index, out new_trailing);
			
			if (new_index != int.MAX) {
				cursor_index = new_index;
				cursor_trailing = new_trailing;
			}
			
			return new_index == int.MAX;
		}
		
		public bool backward_char_internal() {
			int new_index, new_trailing;
			layout.move_cursor_visually(true, cursor_index, cursor_trailing, -1, out new_index, out new_trailing);
			
			if (new_index >= 0) {
				cursor_index = new_index;
				cursor_trailing = new_trailing;
			}
			
			return new_trailing == -1;
		}
		
		public void forward_word() {
			forward_skip_word_chars();
			
			forward_to_word_bound();
			
			remeber_column_offset();
			
			try_scroll_up();
			
			queue_draw();
		}
		
		public void backward_word() {
			backward_skip_word_chars();
			
			backward_to_word_bound();
			
			remeber_column_offset();
			
			try_scroll_down();
			
			queue_draw();
		}
		
		public void move_beginning_of_line() {
			move_beginning_of_line_internal();
			
			remeber_column_offset();
			
			queue_draw();
		}
		
		public void move_end_of_line() {
			move_end_of_line_internal();

			remeber_column_offset();
			
			queue_draw();
		}
		
		public void back_to_indentation() {
			move_beginning_of_line_internal();
			
			forward_skip_indentation_chars();
			
			remeber_column_offset();
			
			queue_draw();
		}
		
		public void beginning_of_buffer() {
			cursor_index = 0;
			cursor_trailing = 0;
			
			remeber_column_offset();
			
			visible_cursor();
			
			queue_draw();
		}
		
		public void end_of_buffer() {
			cursor_index = buffer.content.char_count() - 1;
			cursor_trailing = 1;
			
			remeber_column_offset();
			
			visible_cursor();
			
			queue_draw();
		}
		
		public void scroll_up_one_line() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
			
			render_offset = int.min(render_offset + line_height, (layout.get_line_count() + 1) * line_height - alloc.height);
			
			int line = get_cursor_line();

			if (line * line_height < render_offset + line_height) {
				int new_index, new_trailing;
				layout.xy_to_index(column_offset, (render_offset + line_height) * Pango.SCALE, out new_index, out new_trailing);

				cursor_index = new_index;
				cursor_trailing = new_trailing;
			}
			
			queue_draw();
		}
		
		public void scroll_down_one_line() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
			
			render_offset = int.max(render_offset - line_height, 0);
			
			int line = get_cursor_line();

			if (line * line_height > render_offset + alloc.height - 2 * line_height) {
				int new_index, new_trailing;
				layout.xy_to_index(column_offset, (render_offset + alloc.height - 2 * line_height) * Pango.SCALE, out new_index, out new_trailing);

				cursor_index = new_index;
				cursor_trailing = new_trailing;
			}
			
			queue_draw();
		}
		
		public int get_cursor_line() {
			return index_to_line_x(cursor_index, cursor_trailing)[0];
		}
		
		public void move_beginning_of_line_internal() {
			int[] line_bound = find_line_bound();
			cursor_index = line_bound[0];
			cursor_trailing = 0;
		}
		
		public void move_end_of_line_internal() {
			int[] line_bound = find_line_bound();
			cursor_index = line_bound[1];
			cursor_trailing = 1;
		}
		
		public void forward_skip_indentation_chars() {
			bool reach_end = false;
			unichar c = 0;
			bool found_next_char = true;

			found_next_char = buffer.content.get_next_char(ref cursor_index, out c);
			while (found_next_char && !reach_end) {
				if (is_indentation_chars(c, true)) {
					backward_char_internal();
					reach_end = true;
				} else {
					found_next_char = buffer.content.get_next_char(ref cursor_index, out c);
					reach_end = !found_next_char;
				}
			}
		}

		public void forward_skip_word_chars() {
			forward_to_word_bound(true);
		}
		
		public void forward_to_word_bound(bool is_skip=false) {
			bool reach_end = false;
			unichar c = 0;
			bool found_next_char = true;

			found_next_char = buffer.content.get_next_char(ref cursor_index, out c);
			while (found_next_char && !reach_end) {
				if (is_word_bound_chars(c, is_skip)) {
                    if (c != '\n') {
                        backward_char_internal();
                    }
                    
					reach_end = true;
				} else {
					found_next_char = buffer.content.get_next_char(ref cursor_index, out c);
					reach_end = !found_next_char;
				}
			}
		}

		public void backward_skip_word_chars() {
			backward_to_word_bound(true);
		}
		
		public void backward_to_word_bound(bool is_skip=false) {
			bool reach_end = false;
			unichar c = 0;
			bool found_prev_char = true;

			found_prev_char = buffer.content.get_prev_char(ref cursor_index, out c);
			while (found_prev_char && !reach_end) {
				if (is_word_bound_chars(c, is_skip)) {
					forward_char_internal();
					reach_end = true;
				} else {
					found_prev_char = buffer.content.get_prev_char(ref cursor_index, out c);
					reach_end = !found_prev_char;
				}
			}
		}
		
		public bool is_word_bound_chars(unichar c, bool is_skip) {
			unichar[] word_chars =  {' ', '_', '-', ',', '.',
									 '\n', '\t', ';', ':', '!',
									 '|', '&', '>', '<', '{', '}',
									 '[', ']', '#', '\"', '(', ')',
									 '=', '*', '^', '%', '$', '@',
									 '?', '/', '~', '`'};
			
			if (is_skip) {
				return !(c in word_chars);
			} else {
				return c in word_chars;
			}
		}
		
		public bool is_indentation_chars(unichar c, bool is_skip) {
			unichar[] indentation_chars = {' ', '\t'};
			
			if (is_skip) {
				return !(c in indentation_chars);
			} else {
				return c in indentation_chars;
			}
		}
		
		public void try_scroll_up() {
			int line = get_cursor_line();
			
            Gtk.Allocation alloc;
            get_allocation(out alloc);
			if ((line + 2) * line_height - render_offset > alloc.height) {
				render_offset += line_height;
			}
		}
		
		public void try_scroll_down() {
			int line = get_cursor_line();
			
			if ((line - 1) * line_height - render_offset < line_height) {
				render_offset = int.max(render_offset - line_height, 0);
			}
		}
		
		public void visible_cursor() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
			
			int line = get_cursor_line();

			render_offset = int.min(line * line_height, (layout.get_line_count() + 1) * line_height - alloc.height);
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

			int[] index_coordinate = index_to_line_x(cursor_index, cursor_trailing);
			int line = index_coordinate[0];
			int x_pos = index_coordinate[1];
			
			// Draw background.
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
			
			cr.translate(0, -render_offset);
			
			// Draw line background.
			int[] line_bound = find_line_bound();
			line_bound[1] += 1;
			
			int start_line = index_to_line_x(line_bound[0], 0)[0];
			int end_line = index_to_line_x(line_bound[1], 0)[0];
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
		
		public void remeber_column_offset() {
			column_offset = index_to_line_x(cursor_index, cursor_trailing)[1];
		}

		public int[] find_line_bound() {
			int[] line_bound = new int[2];
			
			line_bound[0] = buffer.content.substring(0, cursor_index).last_index_of_char('\n') + 1;
			line_bound[1] = buffer.content.index_of_char('\n', cursor_index);
			
			if (line_bound[1] == -1) {
				line_bound[1] = buffer.content.char_count() - 1;
			}
			
			return line_bound;
		}
		
		public int get_logic_line_count() {
			int line_index = int.max(0, buffer.content.last_index_of_char('\n')) + 1;
			
			return index_to_line_x(line_index, 0)[0];
		}
		
		public int[]? index_to_lines(int x, int y) {
			if (layout != null) {
				int target_index, target_trailing;
				layout.xy_to_index(x, y, out target_index, out target_trailing);
				
			    int target_line = index_to_line_x(target_index, 0)[0];
			    
			    int start_line_index = int.max(0, buffer.content.substring(0, target_index).last_index_of_char('\n')) + 1;
			    int start_line = index_to_line_x(start_line_index, 0)[0];
			    
			    int[] lines = {target_line, start_line};
			    return lines;
			} else {
				return null;
			}
		}
		
		public int[] index_to_line_x(int index, int trailing) {
			int line, x_pos;
			bool is_trailing = trailing > 0;
			layout.index_to_line_x(index, is_trailing, out line, out x_pos);
			
			return {line, x_pos};
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