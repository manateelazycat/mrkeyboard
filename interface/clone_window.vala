using Clutter;
using ClutterX11;
using Gtk;
using GtkClutter;

namespace Interface {
    public class CloneWindow : Gtk.Window {
        public Clutter.Actor stage;
        public ClutterX11.TexturePixmap texture;
        public int parent_window_id;
        public int window_id;
        public string buffer_id;
        public string buffer_path;
        public GtkClutter.Embed embed;
        
        public signal void create_app_tab(int app_win_id, string mode_name);
        public signal void emit_scroll_event(Gdk.EventScroll event);
        public signal void emit_button_press_event(Gdk.EventButton event);
        public signal void emit_button_release_event(Gdk.EventButton event);
        public signal void emit_motion_event(Gdk.EventMotion event);
        
        public CloneWindow(int width, int height, int pwid, string mode_name, string bid, string path) {
            parent_window_id = pwid;
            buffer_id = bid;
            buffer_path = path;
            
            set_decorated(false);
            set_default_size(width, height);

            embed = new GtkClutter.Embed();
            add(embed);
            
            embed.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            embed.button_release_event.connect((w, e) => {
                    emit_button_release_event(e);
                    
                    return false;
                });
            embed.scroll_event.connect((w, e) => {
                    emit_scroll_event(e);
                    
                    return false;
                });
            embed.motion_notify_event.connect((w, e) => {
                    emit_motion_event(e);
                    
                    return false;
                });
            
            stage = embed.get_stage();
            stage.set_background_color(Color.from_string(get_background_color()));
            
            update_texture();
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    window_id = xid;
                    create_app_tab(window_id, mode_name);
                });
        }
        
        public virtual string get_background_color() {
            print("You need implement 'get_background_color' in your application code.\n");
            
            return "black";
        }
        
        public void update_texture_area() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            texture.update_area(0, 0, alloc.width, alloc.height);
        }
        
        public void update_texture() {
            if (texture != null) {
                stage.remove_child(texture);
            }
            texture = new ClutterX11.TexturePixmap.with_window(parent_window_id);
            texture.set_automatic(true);            
            stage.add_child(texture);
            
            stage.show();
            
            update_texture_area();
        }
    }
}