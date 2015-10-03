using Gtk;

namespace Widgets {
    public class Application : Gtk.Window {
        public Gtk.Box box;
        
        public Application() {
            set_decorated(false);
            set_position(Gtk.WindowPosition.CENTER);
            set_default_size(800, 600);
            destroy.connect(Gtk.main_quit);
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
        }
    }   
}