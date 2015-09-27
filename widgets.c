#include <clutter/clutter.h>
#include <mx/mx.h>

gboolean set_button_status(ClutterActor *image_button, ClutterEvent *event, gchar *image_path) {
    mx_image_set_from_file(MX_IMAGE(image_button), image_path, NULL);
    
    return FALSE;
}

ClutterActor* create_button(gchar* normal_path, gchar* hover_path, gchar* press_path) {
    ClutterActor *image_button = mx_image_new();
    mx_image_set_from_file(MX_IMAGE(image_button), normal_path, NULL);
    clutter_actor_set_reactive(image_button, TRUE);

    g_signal_connect(image_button, "enter-event", G_CALLBACK(set_button_status), hover_path);
    g_signal_connect(image_button, "leave-event", G_CALLBACK(set_button_status), normal_path);
    g_signal_connect(image_button, "button-press-event", G_CALLBACK(set_button_status), press_path);
    
    return image_button;
}
