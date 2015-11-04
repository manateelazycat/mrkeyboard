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
        public FileView fileview;
        
        public Window(int width, int height, string bid, Buffer buf) {
            base(width, height, bid, buf);
        }
        
        public override void init() {
            fileview = new FileView(buffer);
            fileview.realize.connect((w) => {
                    update_tab_name(buffer.buffer_path);
                });
            
            buffer.change_directory.connect((path) => {
                    update_tab_name(path);
                    
                    fileview.list_items.clear();
                    fileview.current_row = 0;
                    fileview.load_buffer_items();
                });
            
            fileview.load_buffer_items();
            
            fileview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            fileview.active_item.connect((item_index) => {
                    fileview.load_path("%s/%s".printf(buffer.buffer_path, fileview.items.get(item_index).file_info.get_name()));
                });
            
            box.pack_start(fileview, true, true, 0);
        }        
        
        public void update_tab_name(string path) {
            var paths = path.split("/");
            rename_app_tab(mode_name, buffer_id, paths[paths.length - 1], path);
        }
        
        public override void scroll_vertical(bool scroll_up) {
            fileview.scroll_vertical(scroll_up);
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
        public bool hide_dot_files = true;
        public Buffer buffer;
        public ArrayList<FileItem> items;
        
        public FileView(Buffer buf) {
            base();
            
            buffer = buf;
            items = new ArrayList<FileItem>();
            
            key_press_event.connect((w, e) => {
                    handle_key_press(w, e);
                    
                    return false;
                });
        }
        
        public void handle_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            if (keyname == "H") {
                hide_dot_files = !hide_dot_files;
                
                list_items.clear();
                load_buffer_items();
            } else if (keyname == "f") {
                load_path("%s/%s".printf(buffer.buffer_path, items.get(current_row).file_info.get_name()));
            } else if (keyname == "'") {
                load_parent_directory();
            }
        }
        
        public void load_path(string path) {
            var file = File.new_for_path(path);
            try {
                var file_info = file.query_info(FileAttribute.STANDARD_TYPE, FileQueryInfoFlags.NONE, null);
                if (file_info.get_file_type() == FileType.DIRECTORY) {
                    buffer.load_directory(path);
                } else {
                    print("open file: %s\n", path);
                }
            } catch (Error err) {
                stderr.printf ("Error: FileItem failed: %s\n", err.message);
            }
        }
        
        public void load_parent_directory() {
            var parent_file = File.new_for_path(buffer.buffer_path).get_parent();
            if (parent_file != null) {
                var parent_path = parent_file.get_path();
                if (parent_path != null) {
                    var paths = buffer.buffer_path.split("/");
                    var directory_name = paths[paths.length - 1];
                    
                    buffer.load_directory(parent_path);
                    
                    var item_paths = new ArrayList<string>();
                    foreach (FileItem item in items) {
                        item_paths.add(item.file_info.get_name());
                    }
                    
                    current_row = item_paths.index_of(directory_name);
                    visible_item(true);
                    
                    queue_draw();
                }
            }
        }
        
        public void load_buffer_items() {
            items.clear();
            
            if (hide_dot_files) {
                foreach (FileItem item in buffer.file_items) {
                    if (!item.file_info.get_is_hidden()) {
                        items.add(item);
                    }
                }
            } else {
                items.add_all(buffer.file_items);
            }
            
            add_items(items);
        }

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
        public string buffer_path;
        public string modification_time;
        
        public int column_padding_x = 10;
        
        public FileItem(FileInfo info, string directory) {
            file_info = info;
            buffer_path = directory;
            
            try {
                var file = File.new_for_path("%s/%s".printf(buffer_path, file_info.get_name()));
                var mod_time = file.query_info(FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE, null).get_modification_time();
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
        
        public static int compare_file_item(FileItem a, FileItem b) {
            if (a.file_info.get_name() > b.file_info.get_name()) {
                return 1;
            } else {
                return -1;
            }
        }        
    }

    public class Buffer : Interface.Buffer {
        public ArrayList<FileItem> file_items;
        
        public signal void change_directory(string path);
        
        public Buffer(string path) {
            base(path);
            
            if (buffer_path == "") {
                buffer_path = Environment.get_home_dir();
            }
            
            file_items = new ArrayList<FileItem>();
            
            load_directory(buffer_path);
        }
        
        public void load_directory(string path) {
            buffer_path = path;
            load_files();
            
            change_directory(buffer_path);
        }
        
        public void load_files() {
            var files = new ArrayList<FileItem>();
            var dirs = new ArrayList<FileItem>();
            
            try {
        	    FileEnumerator enumerator = File.new_for_path(buffer_path).enumerate_children (
        	    	"standard::*",
        	    	FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                
        	    FileInfo info = null;
        	    while (((info = enumerator.next_file()) != null)) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        dirs.add(new FileItem(info, buffer_path));
                    } else {
                        files.add(new FileItem(info, buffer_path));
                    }
        	    }
                
                dirs.sort((CompareFunc) FileItem.compare_file_item);
                files.sort((CompareFunc) FileItem.compare_file_item);
                
                file_items.clear();
                file_items.add_all(dirs);
                file_items.add_all(files);
            } catch (Error err) {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
        }
    }
}