using Gtk;
using GtkClutter;
using ClutterX11;
using Clutter;

namespace Application {
    public class CloneWindow : Gtk.Window {
        public string mode_name = "terminal";
        public int window_id;
        public string buffer_id;
        
        public ClutterX11.TexturePixmap texture;
        public Clutter.Actor stage;
        public int parent_window_id;
        
        public signal void create_app(int app_win_id, string mode_name, int tab_id);
        
        public CloneWindow(int width, int height, int tab_id, int pwid, string bid) {
            parent_window_id = pwid;
            buffer_id = bid;
            
            set_decorated(false);
            set_default_size(width, height);

            var embed = new GtkClutter.Embed();
            add(embed);
    
            texture = new ClutterX11.TexturePixmap.with_window(parent_window_id);
            texture.set_automatic(true);
            
            stage = embed.get_stage();
            stage.set_background_color(Color.from_string("black"));
            stage.add_child(texture);
            
            var tag_actor = new Clutter.Actor();
            tag_actor.width = tag_actor.height = 20;
            tag_actor.background_color = Color.from_string("red");
            stage.add_child(tag_actor);
            
            realize.connect((w) => {
                    var xid = (int)((Gdk.X11.Window) get_window()).get_xid();
                    window_id = xid;
                    create_app(window_id, mode_name, tab_id);
                });
        }
        
        public void update_texture() {
            Gtk.Allocation alloc;
            get_allocation(out alloc);
            
            texture.update_area(0, 0, alloc.width, alloc.height);
        }
        
        public void replace_texture() {
            stage.remove(texture);
            texture = new ClutterX11.TexturePixmap.with_window(parent_window_id);
            texture.set_automatic(true);            
            
            stage.add_child(texture);
            
            stage.show();
        }
    }
}