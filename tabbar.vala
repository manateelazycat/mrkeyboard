using Cairo;
using Draw;
using Gee;
using Gtk;
using Utils;
using Widgets;
using GLib;

namespace Widgets {
    public class Tabbar : Gtk.DrawingArea {
        public ArrayList<int> tab_list;
        public HashMap<int, int> tab_xid_map;
        public HashMap<int, string> tab_buffer_map;
        public HashMap<int, string> tab_name_map;
        public HashMap<int, string> tab_path_map;
        public HashMap<int, string> tab_app_map;
        public HashMap<int, string> tab_window_type_map;
        public HashMap<int, int> tab_percent_map;
        public int height = 28;
        public int tab_index = 0;
        
        public Gdk.Color background_color = Utils.color_from_string("#171814");
        public Gdk.Color active_tab_color = Utils.color_from_string("#272822");
        public Gdk.Color inactive_tab_color = Utils.color_from_string("#393937");
        public Gdk.Color hover_tab_color = Utils.color_from_string("#494943");
        public Gdk.Color inactive_arrow_color = Utils.color_from_string("#393937");
        public Gdk.Color hover_arrow_color = Utils.color_from_string("#494943");
        public Gdk.Color text_color = Utils.color_from_string("#aaaaaa");
        public Gdk.Color hover_text_color = Utils.color_from_string("#ffffff");
        public Gdk.Color percent_color = Utils.color_from_string("#3880AB");
        
        private Cairo.ImageSurface hover_surface;
        private Cairo.ImageSurface normal_surface;
        private Cairo.ImageSurface press_surface;
        private bool draw_arrow = false;
        private bool draw_hover = false;
        private bool is_button_press = false;
        private int arrow_padding_x = 4;
        private int arrow_padding_y = 0;
        private int arrow_width = 16;
        private int close_button_padding_x = 8;
        private int close_button_padding_y = 2;
        private int close_button_width = 12;
        private int draw_offset = 0;
        private int draw_padding_y = 8;
        private int hover_x = 0;
        private int text_padding_x = 12;
        
        public signal void destroy_buffer(int index, string buffer_id);
        public signal void focus_window(int xid);
        public signal void press_tab(int tab_index);
        
        public Tabbar(string image_path) {
            add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                        | Gdk.EventMask.BUTTON_RELEASE_MASK
                        | Gdk.EventMask.POINTER_MOTION_MASK
                        | Gdk.EventMask.LEAVE_NOTIFY_MASK);

            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            tab_path_map = new HashMap<int, string>();
            tab_xid_map = new HashMap<int, int>();
            tab_buffer_map = new HashMap<int, string>();
            tab_window_type_map = new HashMap<int, string>();
            tab_app_map = new HashMap<int, string>();
            tab_percent_map = new HashMap<int, int>();
            
            set_size_request(-1, height);
            
            normal_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_normal.png");
            hover_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_hover.png");
            press_surface = new Cairo.ImageSurface.from_png("image/" + image_path + "_press.png");
            
            draw.connect(on_draw);
            configure_event.connect(on_configure);
            button_press_event.connect(on_button_press);
            button_release_event.connect(on_button_release);
            motion_notify_event.connect(on_motion_notify);
            leave_notify_event.connect(on_leave_notify);
        }
        
        public void reset() {
            tab_list = new ArrayList<int>();
            tab_name_map = new HashMap<int, string>();
            tab_path_map = new HashMap<int, string>();
            tab_xid_map = new HashMap<int, int>();
            tab_buffer_map = new HashMap<int, string>();
            tab_window_type_map = new HashMap<int, string>();
            tab_app_map = new HashMap<int, string>();
            tab_index = 0;
        }
        
        public void add_tab(string tab_name, string tab_path, int tab_id, string app) {
            tab_list.add(tab_id);
            tab_name_map.set(tab_id, tab_name);
            tab_path_map.set(tab_id, tab_path);
            tab_app_map.set(tab_id, app);
            
            out_of_area();
            
            queue_draw();
        }
        
        public void rename_tab(string buffer_id, string tab_name, string tab_path) {
            foreach (var name_entry in tab_buffer_map.entries) {
                if (name_entry.value == buffer_id) {
                    tab_name_map.set(name_entry.key, tab_name);
                    tab_path_map.set(name_entry.key, tab_path);
                    queue_draw();
                    
                    break;
                }
            }
        }
        
        public void percent_tab(string buffer_id, int percent) {
            foreach (var name_entry in tab_buffer_map.entries) {
                if (name_entry.value == buffer_id) {
                    tab_percent_map.set(name_entry.key, percent);
                    queue_draw();
                    
                    // We need remove percent later once reach 100% percent.
                    if (percent == 100) {
                        GLib.Timeout.add(500, () => {
                                tab_percent_map.unset(name_entry.key);
                                queue_draw();
                                
                                return false;
                            });
                    }
                    
                    break;
                }
            }
        }
        
        public void set_tab_xid(int tab_id, int xid) {
            tab_xid_map.set(tab_id, xid);
        }
        
        public bool has_tab(int tab_id) {
            int? tab_xid = tab_xid_map.get(tab_id);
            return (tab_xid != null);
        }
        
        public bool is_focus_tab(int tab_id) {
            int? index = tab_list.index_of(tab_id);
            if (index != null) {
                return tab_index == index;
            } else {
                return false;
            }
        }
        
        public void set_tab_buffer(int tab_id, string buffer_id) {
            tab_buffer_map.set(tab_id, buffer_id);
        }
        
        public void set_tab_window_type(int tab_id, string window_type) {
            tab_window_type_map.set(tab_id, window_type);
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
        
        public bool close_tab_with_buffer(string buffer_id) {
            foreach (var entry in tab_buffer_map.entries) {
                if (entry.value == buffer_id) {
                    int? tab_index = tab_list.index_of(entry.key);
                    if (tab_index != null) {
                        close_nth_tab(tab_index, false);
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        public void close_nth_tab(int index, bool emit_close_signal=true) {
            if (tab_list.size > 0) {
                var tab_id = tab_list.get(index);
                
                tab_list.remove_at(index);
                tab_name_map.unset(tab_id);
                tab_path_map.unset(tab_id);
                tab_app_map.unset(tab_id);
                tab_xid_map.unset(tab_id);

                if (emit_close_signal) {
                    destroy_buffer(index, tab_buffer_map.get(tab_id));
                }
                tab_buffer_map.unset(tab_id);
                tab_window_type_map.unset(tab_id);

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
                var layout = create_pango_layout(tab_name_map.get(tab_id));
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
        
        public bool on_configure(Gtk.Widget widget, Gdk.EventConfigure event) {
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
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (press_x > draw_x && press_x < draw_x + get_tab_width(name_width)) {
                    if (press_x < draw_x + name_width + text_padding_x) {
                        select_nth_tab(counter);
                        
                        press_tab(counter);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter++;
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
                var layout = create_pango_layout(tab_name_map.get(tab_id));
                int name_width, name_height;
                layout.get_pixel_size(out name_width, out name_height);

                draw_x += text_padding_x;
                
                if (release_x > draw_x && release_x < draw_x + get_tab_width(name_width)) {
                    if (release_x > draw_x + name_width) {
                        close_nth_tab(counter);
                        return false;
                    }
                }
                
                draw_x += name_width + close_button_width + text_padding_x;
                
                counter++;
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
                    var layout = create_pango_layout(tab_name_map.get(tab_id));
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
                    
                    counter++;
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
                var layout = create_pango_layout(tab_name_map.get(tab_id));
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
                var layout = create_pango_layout(tab_name_map.get(tab_id));
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
                
                int? percent = tab_percent_map.get(tab_id);
                if (percent != null) {
                    Utils.set_context_color(cr, percent_color);
                    Draw.draw_rectangle(cr, draw_x, height - 2, get_tab_width(name_width) * percent / 100, 2);
                }
                
                draw_x += text_padding_x;
                
                if (draw_hover) {
                    if (hover_x > draw_x && hover_x < draw_x + get_tab_width(name_width)) {
                        if (hover_x > draw_x + name_width) {
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
                
                counter++;
            }
            
            return true;
        }

        public int get_tab_width(int name_width) {
            return name_width + close_button_width + text_padding_x * 2;
        }
        
        public int? get_current_tab_xid() {
            if (tab_list.size > 0) {
                return tab_xid_map.get(tab_list.get(tab_index));
            } else {
                return null;
            }
        }
        
        public delegate void AnyAction();
        
        public void protect_current_tab(AnyAction action) {
            var tab_id_backup = tab_list.get(tab_index);
            action();

            // FIXEDME: This is hacking way.
            // 
            // We need add timeout here to avoid xcb.reparent_window request to fast
            // that current tab can't reparent correctly.
            //
            // Please found a better way that we don't need depend time delay to reparent window.
            GLib.Timeout.add(10, () => {
                    select_tab_with_id(tab_id_backup);
                    return false;
                });
        }
        
        public ArrayList<int> get_all_xids() {
            ArrayList<int> xids = new ArrayList<int>();
            foreach (int index in tab_list) {
                xids.add(tab_xid_map.get(index));
            }
            
            return xids;
        }

        public ArrayList<string> get_all_apps() {
            ArrayList<string> apps = new ArrayList<string>();
            foreach (int index in tab_list) {
                apps.add(tab_app_map.get(index));
            }
            
            return apps;
        }
        
        public ArrayList<string> get_all_buffers() {
            ArrayList<string> buffers = new ArrayList<string>();
            foreach (int index in tab_list) {
                buffers.add(tab_buffer_map.get(index));
            }
            
            return buffers;
        }
        
        public ArrayList<string> get_all_names() {
            ArrayList<string> names = new ArrayList<string>();
            foreach (int index in tab_list) {
                names.add(tab_name_map.get(index));
            }
            
            return names;
        }

        public ArrayList<string> get_all_paths() {
            ArrayList<string> paths = new ArrayList<string>();
            foreach (int index in tab_list) {
                paths.add(tab_path_map.get(index));
            }
            
            return paths;
        }

        public ArrayList<string> get_all_types() {
            ArrayList<string> types = new ArrayList<string>();
            foreach (int index in tab_list) {
                types.add(tab_window_type_map.get(index));
            }
            
            return types;
        }
        
        public void switch_tab(int new_index) {
            var new_xid = tab_xid_map.get(tab_list.get(new_index));
                
            focus_window(new_xid);
                
            tab_index = new_index;
                
            make_current_visible(true);
            queue_draw();
        }
        
        public void focus_tab(int index) {
            if (tab_list.size > 0) {
                int tab_id = tab_list.get(index);
                int tab_xid = tab_xid_map.get(tab_id);
                
                focus_window(tab_xid);
            }
        }
    }
}