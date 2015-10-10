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
        
        public void remove_blank_windows() {
            var windows = find_blank_windows();
            if (windows.size > 0) {
                foreach (WindowRectangle window in windows) {
                    remove_window(window.id);
                    break;
                }
                
                remove_blank_windows();
            }
        }
        
        private ArrayList<WindowRectangle> find_blank_windows() {
            var windows = new ArrayList<WindowRectangle>();
            foreach (WindowRectangle window in window_rectangle_list) {
                if (window.tab_numbers == 0) {
                    windows.add(window);
                }
            }
            
            return windows;
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
                    } else {
                        var neighblor_windows = find_neighblor_windows(match_window);
                        if (neighblor_windows.length > 0) {
                            get_area_to_neighblor_windows(match_window, neighblor_windows);
                            
                            window_rectangle_list.remove(match_window);
                            window_remove_list.add(match_window);
                            return true;
                        }
                    }
                }
            }
            
            return false;
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
            
            // Find brother at up.
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
        
        public WindowRectangle[] find_neighblor_windows(WindowRectangle window) {
            WindowRectangle[] rectangle_list = {};
            foreach (WindowRectangle neighblor_window in window_rectangle_list) {
                if (neighblor_window.id != window.id) {
                    // Find neighblor at left or right.
                    if (window.x == neighblor_window.x + neighblor_window.width) {
                        rectangle_list += neighblor_window;
                    }
                }
            }
            if (rectangle_list.length > 0) {
                return rectangle_list;
            }

            foreach (WindowRectangle neighblor_window in window_rectangle_list) {
                if (neighblor_window.id != window.id) {
                    // Find neighblor at left or right.
                    if (window.x + window.width == neighblor_window.x) {
                        rectangle_list += neighblor_window;
                    }
                }
            }
            if (rectangle_list.length > 0) {
                return rectangle_list;
            }

            foreach (WindowRectangle neighblor_window in window_rectangle_list) {
                if (neighblor_window.id != window.id) {
                    // Find neighblor at left or right.
                    if (window.y == neighblor_window.y + neighblor_window.height) {
                        rectangle_list += neighblor_window;
                    }
                }
            }
            if (rectangle_list.length > 0) {
                return rectangle_list;
            }

            foreach (WindowRectangle neighblor_window in window_rectangle_list) {
                if (neighblor_window.id != window.id) {
                    // Find neighblor at left or right.
                    if (window.y + window.height == neighblor_window.y) {
                        rectangle_list += neighblor_window;
                    }
                }
            }
            if (rectangle_list.length > 0) {
                return rectangle_list;
            }
            
            return rectangle_list;
        }
        
        private void get_area_to_neighblor_windows(WindowRectangle window, WindowRectangle[] neighblor_windows) {
            WindowRectangle neighblor_window = neighblor_windows[0];
            // Find neighblor at left.
            if (window.x == neighblor_window.x + neighblor_window.width) {
                foreach (WindowRectangle rect in neighblor_windows) {
                    rect.width = window.width + rect.width;
                }
            // Find neighblor at right.
            } else if (window.x + window.width == neighblor_window.x) {
                foreach (WindowRectangle rect in neighblor_windows) {
                    rect.x = window.x;
                    rect.width = window.width + rect.width;
                }
            // Find neighblor at up.
            } else if (window.y == neighblor_window.y + neighblor_window.height) {
                foreach (WindowRectangle rect in neighblor_windows) {
                    rect.height = window.height + rect.height;
                }
            // Find neighblor at down.
            } else if (window.y + window.height == neighblor_window.y) {
                foreach (WindowRectangle rect in neighblor_windows) {
                    rect.y = window.y;
                    rect.height = window.height + rect.height;
                }
            }
        }
    }
}