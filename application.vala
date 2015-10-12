using Gtk;

namespace Widgets {
    public class Application : Gtk.Window {
        public Gtk.Box box;
        
        public Application() {
            set_decorated(false);
            
            set_position(Gtk.WindowPosition.CENTER);
            
            var screen = Gdk.Screen.get_default();
            
            Gdk.Geometry size = Gdk.Geometry();
            size.min_width = screen.get_width() * 2 / 3;
            size.min_height = screen.get_width() * 1 / 2;
            set_geometry_hints(this, size, Gdk.WindowHints.MIN_SIZE);
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
        }
    }   
}