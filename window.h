#include <clutter/clutter.h>
#include <gtk/gtk.h>

gboolean window_is_max(GtkWindow *window);
void min_window(ClutterEvent *area, ClutterEvent *event, GtkWindow *window);
void move_window(ClutterActor *area, ClutterEvent *event, GtkWindow *window);
void toggle_window(GtkWindow *window);

