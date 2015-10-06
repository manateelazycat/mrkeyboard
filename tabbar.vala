using Cairo;
using Gee;
using Draw;
using Gtk;
using Utils;
using Widgets;

namespace Widgets {
    public class Tabbar : Gtk.DrawingArea {
        public ArrayList<int> tab_list;
        public HashMap<int, string> tab_name_set;
        public HashMap<int, int> tab_xid_set;
        public int height = 32;
        
        public Gdk.Color background_color = Utils.color_from_hex("#171814");
        public Gdk.Color active_tab_color = Utils.color_from_hex("#272822");
        public Gdk.Color inactive_tab_color = Utils.color_from_hex("#393937");
        public Gdk.Color hover_tab_color = Utils.color_from_hex("#494943");
        public Gdk.Color inactive_arrow_color = Utils.color_from_hex("#393937");
        public Gdk.Color hover_arrow_color = Utils.color_from_hex("#494943");
        public Gdk.Color text_color = Utils.color_from_hex("#aaaaaa");
        public Gdk.Color hover_text_color = Utils.color_from_hex("#ffffff");
        
        private int tab_index = 0;
        private int draw_padding_y = 2;
        private int text_padding_x = 8;
        private int close_button_padding_x = 8;
        private int close_button_padding_y = 8;
        private int close_button_width = 16;
        private int arrow_width = 16;
        private int arrow_padding_x = 4;
        private int arrow_padding_y = 4;
        private bool is_button_press = false;
        private bool draw_hover = false;
        private int hover_x = 0;
        private bool draw_arrow = false;
        private int draw_offset = 0;
        private Cairo.ImageSurface normal_surface;
        private Cairo.ImageSurface hover_surface;
        private Cairo.ImageSurface press_surface;
        
        public signal void switch_page(int old_xid, int new_xid);
        public signal void close_page(int xid);
        public signal void focus_page(int xid);
        
        public Tabbar(string image_path) {
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            tab_list = new ArrayList<int>();
            tab_name_set = new HashMap<int, string>();
            tab_xid_set = new HashMap<int, int>();
            set_size_request(-1, height);
            
            normal_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_normal.png");
            hover_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_hover.png");
            press_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_press.png");
            
            draw.connect(on_draw);
            configure_event.connect(on_config);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);
            motion_notify_event.connect(on_motion_notify);
            leave_notify_event.connect(on_leave_notify);
        }
        
        public void add_tab(string tab_name, int tab_id) {
            tab_list.add(tab_id);
            tab_name_set.set(tab_id, tab_name);
            
            out_of_area();
            
            queue_draw();
        }
        
        public void set_tab_xid(int tab_id, int xid) {
            tab_xid_set.set(tab_id, xid);
        }
        
        public void select_next_tab() {
            var index = tab_index + 1;
            if (index >= tab_list.size) {
                index = 0;
            }
            switch_tab(index);
        }
        
        public void select_prev_tab() {
            var index = tab_index - 1;
            if (index < 0) {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }
        
        public void select_first_tab() {
            switch_tab(0);
        }
        
        public void select_end_tab() {
            var index = 0;
            if (tab_list.size == 0) {
                index = 0;
            } else {
                index = tab_list.size - 1;
            }
            switch_tab(index);
        }
        
        public void select_nth_tab(int index) {
            switch_tab(index);
        }
        
        public void select_tab_with_id(int tab_id) {
            switch_tab(tab_list.index_of(tab_id));
        }
        
        public void close_current_tab() {
            close_nth_tab(tab_index);
        }
        
        public void close_nth_tab(int index) {
            if (tab_list.size > 0) {
                var tab_id = tab_list.get(index);
                var tab_xid = tab_xid_set.get(tab_id);
                
                close_page(tab_xid);
                
                tab_list.remove_at(index);
                tab_name_set.unset(tab_id);
                tab_xid_set.unset(tab_id);

                if (tab_list.size == 0) {
                    tab_index = 0;
                } else if (tab_index >= tab_list.size) {
                    tab_index = tab_list.size - 1;
                }
                
                focus_tab(tab_index);
                
                out_of_area();
                make_current_visible(false);
                
                queue_draw();
            }
        }
        
        public void scroll_left() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            draw_offset += alloc.width / 2;
            if (draw_offset > 0) {
                draw_offset = 0;
            }
            
            queue_draw();
        }
        
        public void scroll_right() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            int draw_x = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_set.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += get_tab_width(name_width);
            }
            
            draw_offset -= alloc.width / 2;
            if (draw_offset < alloc.width - arrow_width * 2 - draw_x) {
                draw_offset = alloc.width - arrow_width * 2 - draw_x;
            }
            
            queue_draw();
        }
        
        public bool on_config(Gtk.Widget widget, Gdk.EventConfigure event) {
            out_of_area();
            make_current_visible(true);
            
            return false;
        }
        
        public bool on_button_press(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = true;
            
            var press_x = (int)event.x;
            
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            if (draw_arrow) {
                if (press_x < arrow_width) {
                    scroll_left();
                    return false;
                } else if (press_x > alloc.width - arrow_width) {
                    scroll_right();
                    return false;
                }
            }
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_set.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (press_x > draw_x && press_x < draw_x + get_tab_width(name_width)) {
                    if (press_x < draw_x + name_width + text_padding_x) {
                        select_nth_tab(counter);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter += 1;
            }
            
            queue_draw();
            
            return false;
        }

        public bool on_button_release(Gtk.Widget widget, Gdk.EventButton event) {
            is_button_press = false;
            
            var release_x = (int)event.x;
            
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_set.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (release_x > draw_x && release_x < draw_x + get_tab_width(name_width)) {
                    if (release_x > draw_x + name_width + text_padding_x) {
                        close_nth_tab(counter);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter += 1;
            }
            
            queue_draw();
            
            return false;
        }
        
        public bool on_motion_notify(Gtk.Widget widget, Gdk.EventMotion event) {
            draw_hover = true;
            hover_x = (int)event.x;
            
            queue_draw();
            
            return false;
        }
        
        public bool on_leave_notify(Gtk.Widget widget, Gdk.EventCrossing event) {
            draw_hover = false;
            hover_x = 0;
            
            queue_draw();
            
            return false;
        }
        
        public int make_current_visible(bool left) {
            if (draw_arrow) {
                Gtk.Allocation alloc;
                this.get_allocation(out alloc);
                
                int draw_x = 0;
                int counter = 0;
                foreach (int tab_id in tab_list) {
                    var layout = create_pango_layout(tab_name_set.get(tab_id));
                    int name_width, name_height;
                    layout.get_pixel_size(out name_width, out name_height);
                    
                    if (tab_index == 0) {
                        draw_offset = 0;
                        return draw_offset;
                    } else {
                        if (left) {
                            draw_x += get_tab_width(name_width);
                            
                            if (counter == tab_index) {
                                if (draw_x > -draw_offset + alloc.width - arrow_width * 2) {
                                    draw_offset = alloc.width - draw_x - arrow_width - close_button_width;
                                    return draw_offset;
                                }
                            }
                        } else {
                            if (tab_index == tab_list.size - 1) {
                                draw_offset = -draw_x + alloc.width - arrow_width - get_tab_width(name_width) - close_button_width;
                            } else if (counter == tab_index) {
                                if (draw_x < -draw_offset - arrow_width) {
                                    draw_offset = -draw_x + arrow_width - close_button_width;
                                    return draw_offset;
                                }
                            }
                            
                            draw_x += get_tab_width(name_width);
                        }
                    }
                    
                    counter += 1;
                }
                
                return draw_offset;
            }
            
            return 0;
        }
        
        public bool out_of_area() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);
            
            int draw_x = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_set.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                
                draw_x += get_tab_width(name_width);
                
                if (draw_x > alloc.width) {
                    draw_arrow = true;
                    return true;
                }
            }
            
            draw_arrow = false;
            draw_offset = 0;
            return false;
        }
        
        public bool on_draw(Gtk.Widget widget, Cairo.Context cr) {
            Gtk.Allocation alloc;
            widget.get_allocation(out alloc);
            
            Utils.set_context_color(cr, background_color);
            Draw.draw_rectangle(cr, 0, 0, alloc.width, alloc.height);
            
            if (draw_arrow) {
                Utils.set_context_color(cr, inactive_arrow_color);
                Draw.draw_rectangle(cr, alloc.x, alloc.y, arrow_width, alloc.height);
                
                if (draw_hover) {
                    if (hover_x < arrow_width) {
                        Utils.set_context_color(cr, hover_text_color);
                    } else {
                        Utils.set_context_color(cr, text_color);
                    }
                } else {
                    Utils.set_context_color(cr, text_color);
                }
                Draw.draw_text(this, cr, "<", arrow_padding_x, arrow_padding_y);
                
                Utils.set_context_color(cr, inactive_arrow_color);
                Draw.draw_rectangle(cr, alloc.width - arrow_width, alloc.y, arrow_width, alloc.height);
                
                if (draw_hover) {
                    if (hover_x > alloc.width - arrow_width) {
                        Utils.set_context_color(cr, hover_text_color);
                    } else {
                        Utils.set_context_color(cr, text_color);
                    }
                } else {
                    Utils.set_context_color(cr, text_color);
                }
                Draw.draw_text(this, cr, ">", alloc.width - 12, arrow_padding_y);
                
                Draw.clip_rectangle(cr, alloc.x + arrow_width, alloc.y, alloc.width - arrow_width * 2, alloc.height);
            }
            
            int draw_x = 0;
            if (draw_arrow) {
                draw_x += arrow_width + draw_offset;
            }
            
            int counter = 0;
            foreach (int tab_id in tab_list) {
                var layout = create_pango_layout(tab_name_set.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);
                
                if (counter == tab_index) {
                    Utils.set_context_color(cr, active_tab_color);
                    Draw.draw_rectangle(cr, draw_x, 0, get_tab_width(name_width), height);
                } else {
                    if (draw_hover) {
                        if (hover_x > draw_x && hover_x < draw_x + get_tab_width(name_width)) {
                            Utils.set_context_color(cr, hover_tab_color);
                        } else {
                            Utils.set_context_color(cr, inactive_tab_color);
                        }
                    } else {
                        Utils.set_context_color(cr, inactive_tab_color);
                    }
                    Draw.draw_rectangle(cr, draw_x, 0, get_tab_width(name_width), height);
                }
                
                draw_x += text_padding_x;
                
                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + get_tab_width(name_width)) {
                        if (hover_x > draw_x + name_width + text_padding_x) {
                            if (is_button_press) {
                                Draw.draw_surface(cr, press_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                            } else {
                                Draw.draw_surface(cr, hover_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                            }
                        } else {
                            Draw.draw_surface(cr, normal_surface, draw_x + name_width + close_button_padding_x, draw_padding_y + close_button_padding_y);
                        }
                    }
                }
                
                Utils.set_context_color(cr, text_color);
                Draw.draw_layout(cr, layout, draw_x, draw_padding_y);
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter += 1;
            }
            
            return true;
        }

        public int get_tab_width(int name_width) {
            return name_width + close_button_width + text_padding_x * 2;
        }
        
        public int? get_current_tab_xid() {
            if (tab_list.size > 0) {
                return tab_xid_set.get(tab_list.get(tab_index));
            } else {
                return null;
            }
        }
        
        public void switch_tab(int new_index) {
            if (tab_index != new_index) {
                var old_xid = tab_xid_set.get(tab_list.get(tab_index));
                var new_xid = tab_xid_set.get(tab_list.get(new_index));
                
                switch_page(old_xid, new_xid);
                
                tab_index = new_index;
                
                make_current_visible(true);
                queue_draw();
            }
        }
        
        public void focus_tab(int index) {
            if (tab_list.size > 0) {
                int tab_id = tab_list.get(index);
                int tab_xid = tab_xid_set.get(tab_id);
                
                focus_page(tab_xid);
            }
        }
    }
}