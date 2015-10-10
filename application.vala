using Gtk;

namespace Widgets {
    public class Application : Gtk.Window {
        public Gtk.Box box;
        
        public Application() {
            set_decorated(false);
            set_position(Gtk.WindowPosition.CENTER);
            set_default_size(800, 600);
            
            box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            add(box);
            
            size_allocate.connect((w, r) => {
                    on_size_allocate(w, r);
                });
        }
        
        public bool on_size_allocate(Gtk.Widget widget, Gdk.Rectangle rect) {
            print("Application size allocate: %i %i %i %i\n", rect.x, rect.y, rect.width, rect.height);
            
            return false;
        }
    }   
}