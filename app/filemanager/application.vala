using Gtk;
using Gdk;
using Utils;
using Widget;
using Gee;

namespace Application {
    const string app_name = "filemanager";
    const string dbus_name = "org.mrkeyboard.app.filemanager";
    const string dbus_path = "/org/mrkeyboard/app/filemanager";

    [DBus (name = "org.mrkeyboard.app.filemanager")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.filemanager")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public ListView fileview;
        
        public Window(int width, int height, string bid, string path, Buffer buf) {
            base(width, height, bid, path, buf);
        }
        
        public override void init() {
            fileview = new ListView();
            
            fileview.add_items(buffer.file_items);
            
            fileview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            
            box.pack_start(fileview, true, true, 0);
        }        
        
        public override void scroll_vertical(bool scroll_up) {
            print("We need implement scroll feature\n");
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return fileview.get_window();
        }
    }

    public class FileItem : ListItem {
        public int height = 24;
        public FileInfo file_info;
        
        public FileItem(FileInfo info) {
            file_info = info;
        }
        
        public override int get_height() {
            return height;
        }
        
        public override int[] get_column_widths() {
            return {-1, 200, 300};
        }
    }

    public class Buffer : Interface.Buffer {
        public string current_directory = "";
        public ArrayList<FileItem> file_items;
        
        public Buffer() {
            base();
            
            // Init.
            file_items = new ArrayList<FileItem>();
            
            load_files_from_path(Environment.get_home_dir());
        }
        
        public void load_files_from_path(string directory) {
            current_directory = directory;
            file_items.clear();
            
            try {
        	    FileEnumerator enumerator = File.new_for_path(current_directory).enumerate_children (
        	    	"standard::*",
        	    	FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                
        	    FileInfo info = null;
        	    while (((info = enumerator.next_file()) != null)) {
                    file_items.add(new FileItem(info));
        	    }
            } catch (Error err) {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
        }
    }
}