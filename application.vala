using Gtk;

namespace Widgets {
    public class Application : Gtk.Window {
        public Gtk.Box box;
        
        public Application() {
            set_decorated(false);
            
            set_position(Gtk.WindowPosition.CENTER);
            
            Gdk.Geometry size = Gdk.Geometry();
            size.min_width = 800;
            size.min_height = 600;
            set_geometry_hints(this, size, Gdk.WindowHints.MIN_SIZE);
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
        }
    }   
}