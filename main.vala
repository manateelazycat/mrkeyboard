using Widgets;
using Utils;

int main(string[] args) {
    if (GtkClutter.init(ref args) != Clutter.InitError.SUCCESS) {
        return -1;
    }
    
    var window = new Gtk.Window();
    window.set_decorated(false);
    window.set_position(Gtk.WindowPosition.CENTER);
    window.set_default_size(800, 600);
    window.destroy.connect(Gtk.main_quit);
    
    var screen = Gdk.Screen.get_default();
    var css_provider = new Gtk.CssProvider();
    try {
        css_provider.load_from_path("style.css");
    } catch (GLib.Error e) {
        stdout.printf("Got error when load css: %s\n", e.message);
    }
    Gtk.StyleContext.add_provider_for_screen(screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    window.add(box);
    
    var titlebar = new Widgets.Titlebar();
    titlebar.min_button.button_press_event.connect((event) => {
            window.iconify() ;
            return true;
        });
    titlebar.close_button.button_press_event.connect((event) => {
            Gtk.main_quit();
            return true;
        });
    titlebar.button_press_event.connect((event) => {
            if (Utils.is_double_click(event)) {
                Utils.toggle_max_window(window);
            } else {
                Utils.move_window(titlebar, event, window);
            }
            
            return false;
        });
    box.pack_start(titlebar, false, false, 0);
    
    var embed = new GtkClutter.Embed();
    box.pack_start(embed, true, true, 0);
    
    var stage = embed.get_stage();
    stage.background_color = Clutter.Color() {red = 23, green = 24, blue = 20, alpha = 255};
    
    var window_texture = new ClutterX11.TexturePixmap.with_window(0x800002b);
    window_texture.set_automatic(true);
    stage.add_child(window_texture);
    
    window.show_all();
    Gtk.main();
    
    return 0;
}