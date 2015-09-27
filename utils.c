#include <clutter/clutter.h>

gboolean is_left_button(ClutterEvent *event) {
    return (clutter_event_type(event) == CLUTTER_BUTTON_PRESS && clutter_event_get_button(event) == CLUTTER_BUTTON_PRIMARY);
}

