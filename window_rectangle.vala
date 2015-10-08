using Widgets;
using Gee;

namespace Utils {
    // Because widget's allocation won't change immediately even we call function 'set_size_request'.
    // So I build WindowRectangle re-build window's rectangle to calcuate which blank windows will be delete.
    public class WindowRectangle : Object {
        public int id;
        public int x;
        public int y;
        public int width;
        public int height;
        public int tab_numbers;
        
        public WindowRectangle(Widgets.Window window) {
            Gtk.Allocation alloc = window.get_allocate();
            
            id = window.window_xid;
            x = alloc.x;
            y = alloc.y;
            width = alloc.width;
            height = alloc.height;
            tab_numbers = window.tabbar.tab_list.size;
        }
    }

    public class WindowRectangleManager : Object {
        public ArrayList<WindowRectangle> window_rectangle_list;
        public ArrayList<WindowRectangle> window_remove_list;
        
        public WindowRectangleManager(ArrayList<Widgets.Window> window_list) {
            window_rectangle_list = new ArrayList<WindowRectangle>();
            window_remove_list = new ArrayList<WindowRectangle>();
            
            foreach (Widgets.Window window in window_list) {
                window_rectangle_list.add(new WindowRectangle(window));
            }
        }
        
        public void print_clean_result() {
            print("#######################\n");
            print("*** Rest windows:\n");
            foreach (WindowRectangle rect in window_rectangle_list) {
                print("%i %i %i %i %i\n", rect.id, rect.x, rect.y, rect.width, rect.height);
            }
            
            print("*** Remove windows:\n");
            foreach (WindowRectangle rect in window_remove_list) {
                print("%i %i %i %i %i\n", rect.id, rect.x, rect.y, rect.width, rect.height);
            }
            print("#######################\n");
        }
        
        public bool remove_window(int window_id) {
            WindowRectangle? match_window = null;
            foreach (WindowRectangle window in window_rectangle_list) {
                if (window.id == window_id) {
                    match_window = window;
                    break;
                }
            }
            
            if (match_window != null) {
                if (window_rectangle_list.size == 1) {
                    window_rectangle_list.remove(match_window);
                    window_remove_list.add(match_window);
                    
                    return true;
                } else {
                    var brother_window = find_brother_window(match_window);
                    if (brother_window != null) {
                        get_area_to_brother_window(match_window, brother_window);
                        
                        window_rectangle_list.remove(match_window);
                        window_remove_list.add(match_window);
                        return true;
                    }
                }
            }
            
            return false;
        }
        
        public void remove_blank_windows() {
            var windows = find_blank_windows();
            print("blank windows size: %i\n", windows.size);
            if (windows.size > 0) {
                foreach (WindowRectangle window in windows) {
                    remove_blank_window(window);
                }
                
                remove_blank_windows();
            }
        }
        
        private ArrayList<WindowRectangle> find_blank_windows() {
            var windows = new ArrayList<WindowRectangle>();
            foreach (WindowRectangle window in window_rectangle_list) {
                print("window tab nubmer: %i %i\n", window.id, window.tab_numbers);
                if (window.tab_numbers == 0) {
                    windows.add(window);
                }
            }
            
            return windows;
        }
        
        private bool remove_blank_window(WindowRectangle window) {
            return remove_window(window.id);
        }
        
        public WindowRectangle? find_brother_window(WindowRectangle window) {
            foreach (WindowRectangle brother_window in window_rectangle_list) {
                if (brother_window.id != window.id) {
                    // Find brother at left or right.
                    if (window.x == brother_window.x + brother_window.width || window.x + window.width == brother_window.x) {
                        if (window.y == brother_window.y && window.y + window.height == brother_window.y + brother_window.height) {
                            return brother_window;
                        }
                    }
                    
                    // Find brother at up or down.
                    if (window.y == brother_window.y + brother_window.height || window.y + window.height == brother_window.y) {
                        if (window.x == brother_window.x && window.x + window.width == brother_window.x + brother_window.width) {
                            return brother_window;
                        }
                    }
                }
            }
            
            return null;
        }
        
        private void get_area_to_brother_window(WindowRectangle window, WindowRectangle brother_window) {
            // Find brother at left.
            if (window.x == brother_window.x + brother_window.width) {
                brother_window.x = brother_window.x;
                brother_window.y = brother_window.y;
                brother_window.width = window.width + brother_window.width;
                brother_window.height = window.height;
            }
            
            // Find brother at right.
            if (window.x + window.width == brother_window.x) {
                brother_window.x = window.x;
                brother_window.y = window.y;
                brother_window.width = window.width + brother_window.width;
                brother_window.height = window.height;
            }
            
            // Find brother at up or down.
            if (window.y == brother_window.y + brother_window.height) {
                brother_window.x = brother_window.x;
                brother_window.y = brother_window.y;
                brother_window.width = window.width;
                brother_window.height = window.height + brother_window.height;
            }
            
            // Find brother at down.
            if (window.y + window.height == brother_window.y) {
                brother_window.x = window.x;
                brother_window.y = window.y;
                brother_window.width = window.width;
                brother_window.height = window.height + brother_window.height;
            }
        }
    }
}