using Cairo;

namespace Draw {
    public void draw_surface(Cairo.Context cr, ImageSurface surface, int x = 0, int y = 0, double alpha = 1.0) {
        if (surface != null) {
            cr.set_source_surface(surface, x, y);
            cr.paint_with_alpha(alpha);
        }
    }
}