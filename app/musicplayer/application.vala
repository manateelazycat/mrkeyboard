using Gtk;
using Gdk;
using Utils;
using Widget;
using Gee;
using Tagle;

extern char* current_dir();

namespace Application {
    const string app_name = "musicplayer";
    const string dbus_name = "org.mrkeyboard.app.musicplayer";
    const string dbus_path = "/org/mrkeyboard/app/musicplayer";

    [DBus (name = "org.mrkeyboard.app.musicplayer")]
    interface Client : Object {
        public abstract void create_window(string[] args, bool from_dbus) throws IOError;
    }

    [DBus (name = "org.mrkeyboard.app.musicplayer")]
    public class ClientServer : Object {
        public virtual void create_window(string[] args, bool from_dbus=false) {
        }
    }

    public class Window : Interface.Window {
        public Musicview musicview;
        
        public Window(int width, int height, string bid, Buffer buf) {
            base(width, height, bid, buf);
        }
        
        public override void init() {
            musicview = new Musicview(buffer);
            
            musicview.load_buffer_items();
            
            musicview.button_press_event.connect((w, e) => {
                    emit_button_press_event(e);
                    
                    return false;
                });
            musicview.active_item.connect((item_index) => {
                    musicview.buffer.play_music(musicview.items.get(item_index));
                    print("#### %s\n", musicview.items.get(item_index).get_path());
                    
                    musicview.queue_draw();
                });
            musicview.realize.connect((w) => {
                    update_tab_name(buffer.buffer_path);
                });
            
            box.pack_start(musicview, true, true, 0);
        }        
        
        public void update_tab_name(string path) {
            rename_app_tab(mode_name, buffer_id, GLib.Path.get_basename(path), path);
        }
        
        public override void scroll_vertical(bool scroll_up) {
            musicview.scroll_vertical(scroll_up);
        }

        public override string get_mode_name() {
            return app_name;
        }
        
        public override Gdk.Window get_event_window() {
            return musicview.get_window();
        }
    }

    public class Musicview : ListView {
        public int height = 24;
        public Buffer buffer;
        public ArrayList<FileItem> items;
        
        public Musicview(Buffer buf) {
            base();
            background_color = Utils.color_from_string("#201F1E");
            item_select_color = Utils.color_from_string("#121212");
            
            buffer = buf;
            items = new ArrayList<FileItem>();
            
            key_press_event.connect((w, e) => {
                    handle_key_press(w, e);
                    
                    return false;
                });
        }
        
        public void handle_key_press(Gtk.Widget widget, Gdk.EventKey key_event) {
            string keyname = Keymap.get_keyevent_name(key_event);
            if (keyname == "f") {
                buffer.play_music(items.get(current_row));
                
                queue_draw();
            } else if (keyname == "n") {
                play_next();
            } else if (keyname == "p") {
                play_prev();
            } else if (keyname == "Space") {
                scroll_vertical(true);
            } else if (keyname == ";") {
                buffer.play_or_pause();
            } else if (keyname == "h") {
                buffer.play_backward();
            } else if (keyname == "l") {
                buffer.play_forward();
            } else if (keyname == ",") {
                buffer.audio_minus();
            } else if (keyname == ".") {
                buffer.audio_plus();
            } else if (keyname == "g") {
                jump_to_playing();
            }
        }
        
        public void jump_to_playing() {
            var play_row = items.index_of(buffer.play_item);
            
            if (play_row > current_row) {
                current_row = play_row;
                visible_item(true);
            } else {
                current_row = play_row;
                visible_item(false);
            }
            
            
            queue_draw();
        }
        
        public void play_next() {
            var play_row = items.index_of(buffer.play_item);
            if (play_row < items.size - 1) {
                play_row++;
                buffer.play_music(items.get(play_row));
                
                queue_draw();
            }
        }
        
        public void play_prev() {
            var play_row = items.index_of(buffer.play_item);
            if (play_row > 0) {
                play_row--;
                buffer.play_music(items.get(play_row));
                
                queue_draw();
            }
        }
        
        public void load_buffer_items() {
            items.clear();
            
            items.add_all(buffer.file_items);
            
            add_items(items);
        }

        public override int get_item_height() {
            return height;
        }
        
        public override int[] get_column_widths() {
            return {20, -1, 150, 80};
        }
    }

    public class FileItem : ListItem {
        public Gdk.Color music_color = Utils.color_from_string("#B3B4B4");
        public Gdk.Color artist_color = Utils.color_from_string("#717171");
        public Gdk.Color duration_color = Utils.color_from_string("#5A5A5A");
        
        public FileInfo file_info;
        public string file_dir;
        public string duration;
        public Buffer buffer;
        public Tagle.Id3 tag;
        
        public int play_icon_padding_x = 5;
        public int play_icon_padding_y = 4;
        public int music_padding_x = 3;
        public int duration_padding_x = 20;
        
        public FileItem(Buffer buf, FileInfo info, string directory) {
            buffer = buf;
            file_info = info;
            file_dir = directory;
            
            var file_path = GLib.Path.build_filename(file_dir, file_info.get_name());
            try {
                tag = new Tagle.Id3(file_path);
                duration = format_duration(tag.duration);
            } catch (Error err) {
                stderr.printf ("Error: FileItem failed: %s\n", err.message);
            }
        }
        
        public string format_duration(int duration) {
            int duration_secs = duration / 1000;
            int duration_mins = duration / 60000;
            int duration_remaining_secs = duration_secs - duration_mins * 60;
            
            string min_string;
            string sec_string;
            if (duration_mins < 10) {
                min_string = "0%i".printf(duration_mins);
            } else {
                min_string = "%i".printf(duration_mins);
            }
            if (duration_remaining_secs < 10) {
                sec_string = "0%i".printf(duration_remaining_secs);
            } else {
                sec_string = "%i".printf(duration_remaining_secs);
            }
            
            return "%s:%s".printf(min_string, sec_string);
        }
        
        public override void render_column_cell(Gtk.Widget widget, Cairo.Context cr, int column_index, int x, int y, int w, int h) {
            if (column_index == 0) {
                if (this == buffer.play_item) {
                    Draw.draw_surface(cr, buffer.play_surface, x + play_icon_padding_x, y + play_icon_padding_y);
                }
            } else if (column_index == 1) {
                string? title_or_name;
                if (tag == null) {
                    title_or_name = file_info.get_name().split(".")[0];
                } else {
                    title_or_name = tag.title;
                    if (title_or_name == null || title_or_name == "") {
                        title_or_name = file_info.get_name().split(".")[0];
                    }
                }
                
                Utils.set_context_color(cr, music_color);
                Draw.draw_text(widget, cr, title_or_name, x + music_padding_x, y);
            } else if (column_index == 2) {
                if (tag != null && tag.artist != null) {
                    var font_description = widget.get_style_context().get_font(Gtk.StateFlags.NORMAL);
                    Utils.set_context_color(cr, artist_color);
                    Draw.render_text(cr, tag.artist, x, y, w, h, font_description, Pango.Alignment.RIGHT);
                }
            } else if (column_index == 3) {
                if (duration != null) {
                    Utils.set_context_color(cr, duration_color);
                    Draw.draw_text(widget, cr, duration, x + duration_padding_x, y);
                }
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
        
        public string get_path() {
            return GLib.Path.build_filename(file_dir, file_info.get_name());
        }
        
        public static int compare_file_item(FileItem a, FileItem b) {
            if (a.tag == null || a.tag.artist == null) {
                return -1;
            }

            if (a.tag.artist > b.tag.artist) {
                return 1;
            } else if (a.tag.artist == b.tag.artist) {
                if (a.file_info.get_name() > b.file_info.get_name()) {
                    return 1;
                } else {
                    return -1;
                }
            } else {
                return -1;
            }
        }        
    }

    public class Buffer : Interface.Buffer {
        public ArrayList<FileItem> file_items;
        public GLib.Pid process_id;
        public Cairo.ImageSurface play_surface;
        public FileItem play_item;
        public int time_offset;
        public int volume_offset;
        
        private int stderror;
        private int stdinput;
        private int stdoutput;
        private IOChannel io_write;
        private size_t bw;
        
        public Buffer(string path) {
            base(path);
            
            file_items = new ArrayList<FileItem>();
            string current_dir_path;
            current_dir_path = (string)current_dir();
            play_surface = new Cairo.ImageSurface.from_png(GLib.Path.build_filename(GLib.Path.get_dirname(current_dir_path), "image", "play.png"));
            time_offset = 5;
            volume_offset = 5;
            
            load_directory(buffer_path);
            
            quit.connect(() => {
                    if (io_write != null) {
                        flush_command("quit 0");
                    }
                });
        }
        
        public void load_directory(string path) {
            buffer_path = path;
            
            file_items.clear();
            load_files(buffer_path);
            
            if (file_items.size > 0) {
                play_music(file_items[0]);
            }
        }
        
        public void play_music(FileItem item) {
            play_item = item;

            quit();
            
            string spawn_command_line = "mplayer -slave -quiet \"%s\"".printf(play_item.get_path());
            string[] spawn_args;
            try {
                Shell.parse_argv(spawn_command_line, out spawn_args);
            } catch (ShellError e) {
                stderr.printf("%s\n", e.message);
            }
                        
            try {
                Process.spawn_async_with_pipes(
                    null,
                    spawn_args,
                    null,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    out process_id,
                    out stdinput,
                    out stdoutput,
                    out stderror);
            } catch (SpawnError e) {
                stderr.printf("%s\n", e.message);
            }
            
            io_write = new IOChannel.unix_new(stdinput);
        }
        
        public void play_or_pause() {
            flush_command("pause");
        }
         
        public void play_forward() {
            flush_command("seek +%d 0".printf(time_offset));
        }
        
        public void play_backward() {
            flush_command("seek -%d 0".printf(time_offset));
        }
        
        public void audio_plus() {
            flush_command("volume %i".printf(volume_offset));
        }
        
        public void audio_minus() {
            flush_command("volume -%i".printf(volume_offset));
        }
        
        private void flush_command(string command) {
            try {
                try {
                    io_write.write_chars("%s\n".printf(command).to_utf8(), out bw);
                } catch (ConvertError e) {
                    stderr.printf("%s\n", e.message);
                }
                
                io_write.flush();
            } catch (IOChannelError e) {
                stderr.printf("%s\n", e.message);
            }
        }
        
        public void load_files(string path) {
            try {
        	    FileEnumerator enumerator = File.new_for_path(path).enumerate_children (
        	    	"standard::*",
        	    	FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                
        	    FileInfo info = null;
        	    while (((info = enumerator.next_file()) != null)) {
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        load_files(GLib.Path.build_filename(path, info.get_name()));
                    } else if (info.get_content_type().split("/")[0] == "audio") {
                        file_items.add(new FileItem(this, info, path));
                    }
        	    }
                
                file_items.sort((CompareFunc) FileItem.compare_file_item);
            } catch (Error err) {
                stderr.printf ("Error: list_files failed: %s\n", err.message);
            }
        }
    }
}