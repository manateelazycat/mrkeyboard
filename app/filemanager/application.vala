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
            fileview = new FileView();
            
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

    public class FileView : ListView {
        public int height = 24;

        public override int get_item_height() {
            return height;
        }
        
        public override int[] get_column_widths() {
            return {-1, 100, 150};
        }        
    }

    public class FileItem : ListItem {
        public Gdk.Color directory_type_color = Utils.color_from_string("#1E90FF");
        public Gdk.Color file_type_color = Utils.color_from_string("#00CD00");
        public Gdk.Color attr_type_color = Utils.color_from_string("#333333");
        
        public FileInfo file_info;
        public string current_directory;
        public string modification_time;
        
        public int column_padding_x = 10;
        
        public FileItem(FileInfo info, string directory) {
            file_info = info;
            current_directory = directory;
            
            try {
                var file = File.new_for_path("%s/%s".printf(current_directory, file_info.get_name()));
                var mod_time = file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE, null).get_modification_time();
                modification_time = Time.local(mod_time.tv_sec).format("%Y-%m-%d  %R");
            } catch (Error err) {
                stderr.printf ("Error: FileItem failed: %s\n", err.message);
            }
        }
        
        public override void render_column_cell(Gtk.Widget widget, Cairo.Context cr, int column_index, int x, int y, int w, int h) {
            if (column_index == 0) {
                if (file_info.get_file_type() == FileType.DIRECTORY) {
                    Utils.set_context_color(cr, directory_type_color);
                } else {
                    Utils.set_context_color(cr, file_type_color);
                }
                Draw.draw_text(widget, cr, file_info.get_display_name(), x + column_padding_x, y);
            } else if (column_index == 1) {
                var font_description = widget.get_style_context().get_font(Gtk.StateFlags.NORMAL);
                Utils.set_context_color(cr, attr_type_color);
                Draw.render_text(cr, GLib.format_size(file_info.get_size()), x, y, w, h, font_description, Pango.Alignment.RIGHT);
            } else if (column_index == 2) {
                Utils.set_context_color(cr, attr_type_color);
                Draw.draw_text(widget, cr, modification_time, x + column_padding_x, y);
            }
        }
        
        public string get_date(TimeVal tv) {
            DateTime dt = new DateTime.from_timeval_local(tv);
            int d, m, y;
            d = dt.get_day_of_month();
            m = dt.get_month();
            y = dt.get_year();
            
            return "%i %i %i".printf(d, m, y);
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
                    file_items.add(new FileItem(info, current_directory));
        	    }
            } catch (Error err) {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
        }
    }
}