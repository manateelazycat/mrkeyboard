using WebKit;
using Gtk;

namespace Application {
    const string app_name = "browser";
    const string dbus_name = "org.mrkeyboard.app.browser";
    const string dbus_path = "/org/mrkeyboard/app/browser";

    [DBus (name = "org.mrkeyboard.app.browser")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.browser")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public WebView webview;
        
        public Window(int width, int height, int tid, string bid) {
            base(width, height, tid, bid);
        }
        
        public override void init() {
            webview = new WebView();
            webview.load_uri("http://www.baidu.com");
            box.pack_start(webview, true, true, 0);
            
            webview.title_changed.connect((source, frame, title) => {
                    rename_app_tab(mode_name, buffer_id, title);
                });
            
            webview.create_web_view.connect(on_create_web_view);
        }        
        
        public WebView on_create_web_view(WebView web_view, WebFrame web_frame) {
            return webview;
        }
        
        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return webview.get_window();
        }
    }

    public class CloneWindow : Interface.CloneWindow {
        public CloneWindow(int width, int height, int tid, int pwid, string mode_name, string bid) {
            base(width, height, tid, pwid, mode_name, bid);
        }
        
        public override string get_background_color() {
            return "white";
        }
    }
}