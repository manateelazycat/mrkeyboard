using Gtk;

namespace Widgets {
    public class Window : Gtk.Window {
        public Gtk.Box box;
        
        public Window() {
            set_decorated(false);
            set_position(Gtk.WindowPosition.CENTER);
            set_default_size(800, 600);
            destroy.connect(Gtk.main_quit);
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
        }
    }   
}