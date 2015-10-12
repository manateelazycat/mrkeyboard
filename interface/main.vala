using Interface;
using Gtk;

int main(string[] args) {
    var client_server = new Interface.ClientServer();
    client_server.start(args);
    
    Gtk.main();
    
    return 0;
}

