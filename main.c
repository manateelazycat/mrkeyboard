#include <clutter/clutter.h>
#include <clutter-gtk/clutter-gtk.h>
#include <clutter/x11/clutter-x11-texture-pixmap.h>
#include <mx/mx.h>
#include <gtk/gtk.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    /* Init clutter */
    if (gtk_clutter_init(&argc, &argv) != CLUTTER_INIT_SUCCESS) {
        return EXIT_FAILURE;
    }
    
    /* Init gtk window */
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_decorated(GTK_WINDOW(window), FALSE);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_window_set_default_size(GTK_WINDOW(window), 800, 600);
    
    GtkWidget *box = gtk_box_new(FALSE, 6);
    gtk_container_add(GTK_CONTAINER(window), box);
    gtk_widget_show(box);
    
    /* Init clutter embed widget */
    GtkWidget *clutter_widget = gtk_clutter_embed_new();
    gtk_box_pack_start(GTK_BOX(box), clutter_widget, TRUE, TRUE, 0);
    gtk_widget_show(clutter_widget);
    
    /* Init clutter stage */
    ClutterActor *stage = gtk_clutter_embed_get_stage(GTK_CLUTTER_EMBED(clutter_widget));
    ClutterColor stage_color = {23, 24, 20, 255};
    clutter_actor_set_background_color(CLUTTER_ACTOR(stage), &stage_color);
    clutter_actor_show(stage);
    
    /* Init actor */
    ClutterColor name_color = {80, 80, 80, 255};
    ClutterActor *name_text = clutter_text_new_full("Mono 12", "Mr. keyboard", &name_color);
    clutter_actor_set_position(name_text, 0, 0);
    clutter_actor_add_child(CLUTTER_ACTOR(stage), name_text);
    
    ClutterActor *search_entry = mx_entry_new();
    clutter_actor_set_position(search_entry, 200, 0);
    clutter_actor_add_child(CLUTTER_ACTOR(stage), search_entry);
    
    ClutterActor *window_texture = clutter_x11_texture_pixmap_new_with_window(0x540002b);
    clutter_x11_texture_pixmap_set_automatic(CLUTTER_X11_TEXTURE_PIXMAP(window_texture), TRUE);
    clutter_actor_set_position(window_texture, 0, 40);
    clutter_actor_add_child(CLUTTER_ACTOR(stage), window_texture);
    clutter_actor_show(window_texture);
    
    /* Show window */
    gtk_widget_show_all(window);
    gtk_main();
      
    return EXIT_SUCCESS;
}

