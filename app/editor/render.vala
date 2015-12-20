namespace Render {
    public void render_line(Cairo.Context cr, string text, int x, int y, int height, int width,
                            Pango.FontDescription font_description) {
        var layout = Pango.cairo_create_layout(cr);
        layout.set_text(text, (int)text.length);
        layout.set_height((int)(height * Pango.SCALE));
        layout.set_width((int)(width * Pango.SCALE));
        layout.set_wrap(Pango.WrapMode.WORD_CHAR);
        layout.set_font_description(font_description);
        layout.set_alignment(Pango.Alignment.LEFT);
		
        cr.move_to(x, y);
        Pango.cairo_update_layout(cr, layout);
        Pango.cairo_show_layout(cr, layout);
    }

    public int[] get_context_size(string text, int height, int width, Pango.FontDescription font_description) {
        int[] context_size = new int[2];
        Cairo.ImageSurface context_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 0, 0);
        Cairo.Context cr = new Cairo.Context(context_surface);

        var layout = Pango.cairo_create_layout(cr);
        layout.set_text(text, (int)text.length);
        layout.set_height((int)(height * Pango.SCALE));
        layout.set_width((int)(width * Pango.SCALE));
        layout.set_single_paragraph_mode(false);
        layout.set_wrap(Pango.WrapMode.WORD_CHAR);
        layout.set_font_description(font_description);
        layout.set_alignment(Pango.Alignment.LEFT);

        layout.get_pixel_size(out context_size[0], out context_size[1]);
        
        return context_size;
    }
}