using Clutter;
using ClutterX11;
using Gtk;
using GtkClutter;

namespace Application {
    public class CloneWindow : Gtk.Window {
        public Clutter.Actor stage;
        public ClutterX11.TexturePixmap texture;
        public int parent_window_id;
        public int tab_id;
        public int window_id;
        public string buffer_id;
        public string mode_name = "terminal";
        
        public signal void create_app(int app_win_id, string mode_name, int tab_id);
        
        public CloneWindow(int width, int height, int tid, int pwid, string bid) {
            tab_id = tid;
            parent_window_id = pwid;
            buffer_id = bid;
            
            set_decorated(false);
            set_default_size(width, height);

            var embed = new GtkClutter.Embed();
            add(embed);
    
            stage = embed.get_stage();
            stage.set_background_color(Color.from_string("black"));
            
            update_texture();
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    window_id = xid;
                    create_app(window_id, mode_name, tab_id);
                });
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