#include <clutter/clutter.h>

gboolean set_button_status(ClutterActor *image_button, ClutterEvent *event, gchar *image_path);

ClutterActor* create_button(gchar* normal_path, gchar* hover_path, gchar* press_path);
