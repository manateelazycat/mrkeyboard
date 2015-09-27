#include <clutter/clutter.h>
#include <clutter-gtk/clutter-gtk.h>
#include <clutter/x11/clutter-x11-texture-pixmap.h>
#include <mx/mx.h>
#include <gtk/gtk.h>
#include <stdlib.h>
#include "window.h"

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
    
    ClutterConstraint *stage_width_constraint;
    stage_width_constraint = clutter_bind_constraint_new(CLUTTER_ACTOR(stage), CLUTTER_BIND_WIDTH, 0);
    
    /* Init actor */
    gint top_box_height = 40;
    ClutterActor *top_box = mx_box_layout_new();
    mx_box_layout_set_orientation(MX_BOX_LAYOUT(top_box), MX_ORIENTATION_HORIZONTAL);
    clutter_actor_set_position(top_box, 0, 0);
    clutter_actor_add_child(CLUTTER_ACTOR(stage), top_box);
    clutter_actor_set_height(top_box, top_box_height);
    clutter_actor_show(top_box);
    clutter_actor_add_constraint(CLUTTER_ACTOR(top_box), stage_width_constraint);

    gint name_text_width = 150;
    ClutterColor name_color = {80, 80, 80, 255};
    ClutterActor *name_text = clutter_text_new_full("Mono 12", "Mr. keyboard", &name_color);
    mx_box_layout_add_actor(MX_BOX_LAYOUT(top_box), CLUTTER_ACTOR(name_text), -1);
    clutter_actor_set_margin_left(CLUTTER_ACTOR(name_text), 10);
	clutter_actor_set_width(CLUTTER_ACTOR(name_text), name_text_width);
    clutter_actor_set_reactive(name_text, TRUE);
    clutter_container_child_set(CLUTTER_CONTAINER(top_box),
                                name_text,
                                "expand", FALSE,
                                "x-fill", FALSE,
                                "y-fill", FALSE,
                                "y-align", MX_ALIGN_MIDDLE,
                                "x-align", MX_ALIGN_START,
                                NULL);    
    g_signal_connect(name_text, "button-press-event", G_CALLBACK(move_window), window);
    
    ClutterActor *search_entry = mx_entry_new();
    mx_entry_set_hint_text(MX_ENTRY(search_entry), "Type you want");
    mx_box_layout_add_actor(MX_BOX_LAYOUT(top_box), CLUTTER_ACTOR(search_entry), -1);
	clutter_container_child_set(CLUTTER_CONTAINER(top_box),
                                search_entry,
                                "expand", TRUE,
                                "x-fill", TRUE,
                                "y-fill", FALSE,
                                "y-align", MX_ALIGN_MIDDLE,
                                "x-align", MX_ALIGN_MIDDLE,
                                NULL);    
    
    gint status_text_width = 150;
    ClutterColor status_color = {80, 80, 80, 255};
    ClutterActor *status_text = clutter_text_new_full("Mono 12", "", &status_color);
    mx_box_layout_add_actor(MX_BOX_LAYOUT(top_box), CLUTTER_ACTOR(status_text), -1);
    clutter_actor_set_reactive(status_text, TRUE);
	clutter_actor_set_width(CLUTTER_ACTOR(status_text), status_text_width);
    g_signal_connect(status_text, "button-press-event", G_CALLBACK(move_window), window);
    
    ClutterActor *window_button_box = mx_box_layout_new();
    mx_box_layout_set_orientation(MX_BOX_LAYOUT(window_button_box), MX_ORIENTATION_HORIZONTAL);
    mx_box_layout_add_actor(MX_BOX_LAYOUT(top_box), CLUTTER_ACTOR(window_button_box), -1);
	clutter_container_child_set(CLUTTER_CONTAINER(top_box),
                                window_button_box,
                                "expand", FALSE,
                                "x-fill", FALSE,
                                "y-fill", FALSE,
                                "y-align", MX_ALIGN_MIDDLE,
                                "x-align", MX_ALIGN_END,
                                NULL);    
    
    ClutterActor *min_button = mx_button_new_with_label("-");
    mx_box_layout_add_actor(MX_BOX_LAYOUT(window_button_box), CLUTTER_ACTOR(min_button), -1);

    ClutterActor *max_button = mx_button_new_with_label("+");
    mx_box_layout_add_actor(MX_BOX_LAYOUT(window_button_box), CLUTTER_ACTOR(max_button), -1);

    ClutterActor *close_button = mx_button_new_with_label("x");
    mx_box_layout_add_actor(MX_BOX_LAYOUT(window_button_box), CLUTTER_ACTOR(close_button), -1);

    ClutterActor *window_texture = clutter_x11_texture_pixmap_new_with_window(0x540002b);
    clutter_x11_texture_pixmap_set_automatic(CLUTTER_X11_TEXTURE_PIXMAP(window_texture), TRUE);
    clutter_actor_set_position(window_texture, 0, top_box_height);
    clutter_actor_add_child(CLUTTER_ACTOR(stage), window_texture);
    clutter_actor_show(window_texture);
    
    /* Show window */
    gtk_widget_show_all(window);
    gtk_main();
      
    return EXIT_SUCCESS;
}

