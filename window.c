#include <clutter/clutter.h>
#include <gtk/gtk.h>
#include "utils.h"

gboolean window_is_max(GtkWindow *window) {
    GdkWindowState state = gdk_window_get_state(gtk_widget_get_window(GTK_WIDGET(window)));
    gboolean result;
    result = state & GDK_WINDOW_STATE_MAXIMIZED;
    return result;
}

void toggle_window(GtkWindow *window) {
    if (window_is_max(window)) {
        gtk_window_unmaximize(window);
    } else {
        gtk_window_maximize(window);
    }
}

void min_window(ClutterEvent *area, ClutterEvent *event, GtkWindow *window) {
    gtk_window_iconify(window);
}

void move_window(ClutterActor *area, ClutterEvent *event, GtkWindow *window) {
    if (is_left_button(event)) {
        if (clutter_event_get_click_count(event) == 2) {
            toggle_window(window);
        } else {
            GdkWindow *gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
            gfloat x = 0;
            gfloat y = 0;
            gint window_x = 0;
            gint window_y = 0;
            clutter_event_get_coords(event, &x, &y);
            gdk_window_get_origin(GDK_WINDOW(gdk_window), &window_x, &window_y);
            gtk_window_begin_move_drag(window,
                                       CLUTTER_BUTTON_PRIMARY,
                                       window_x + x,
                                       window_y + y,
                                       clutter_event_get_time(event)
                                       );
        }
    }
}

