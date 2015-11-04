using Gtk;

namespace Interface {
    public class Buffer : Object {
        public string buffer_path;

        public Buffer(string path) {
            buffer_path = path;
        }
    }
}