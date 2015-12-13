namespace Render {
    public void render_line(Cairo.Context cr, string text, int x, int y, int height,
                                Pango.FontDescription font_description) {
        var layout = Pango.cairo_create_layout(cr);
        layout.set_text(text, (int)text.length);
        layout.set_height((int)(height * Pango.SCALE));
        layout.set_width(-1);
        layout.set_font_description(font_description);
        layout.set_alignment(Pango.Alignment.LEFT);
		
        cr.move_to(x, y);
        Pango.cairo_update_layout(cr, layout);
        Pango.cairo_show_layout(cr, layout);
    }
}