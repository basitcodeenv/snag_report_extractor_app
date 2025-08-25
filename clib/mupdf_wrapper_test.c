#include "mupdf/include/mupdf/fitz.h"
#include <string.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdbool.h>

// ----------------------------- Error Handling ---------------------------
static void my_error(void *user, const char *message)
{
    fprintf(stderr, "MuPDF error: %s\n", message);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <pdf-file>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *filename = argv[1];
    fz_context *ctx = NULL;
    fz_document *doc = NULL;
    char *result = NULL;

    ctx = fz_new_context(NULL, NULL, FZ_STORE_UNLIMITED);
    if (!ctx) {
        fprintf(stderr, "Cannot create MuPDF context\n");
        return EXIT_FAILURE;
    }

    fz_set_error_callback(ctx, my_error, NULL);
    fz_register_document_handlers(ctx);

    fz_try(ctx)
    {
        doc = fz_open_document(ctx, filename);
        int page_count = fz_count_pages(ctx, doc);
        bool include_image_data = 1;
        printf("Page count: %d\n", page_count);

        for (int i = 0; i < page_count; i++) {
            fz_page *page = NULL;
            fz_stext_page *stext = NULL;
            fz_device *dev = NULL;

            fz_try(ctx)
            {
                page = fz_load_page(ctx, doc, i);

                fz_rect mediabox = fz_bound_page(ctx, page);
                stext = fz_new_stext_page(ctx, mediabox);

                fz_stext_options opts = {0};
                opts.flags = FZ_STEXT_PRESERVE_IMAGES;

                dev = fz_new_stext_device(ctx, stext, &opts);
                fz_run_page(ctx, page, dev, fz_identity, NULL);
                fz_close_device(ctx, dev);

                // Capture JSON into buffer
                fz_buffer *buf = fz_new_buffer(ctx, 1024);

                fz_output *out = fz_new_output_with_buffer(ctx, buf);

                int block_comma = 0;
                for (fz_stext_block *block = stext->first_block; block; block = block->next)
                {
                    if (block_comma) fz_write_string(ctx, out, ",");
                    block_comma = 1;

                    if (block->type == FZ_STEXT_BLOCK_TEXT) {
                        /* ---- TEXT BLOCK ---- */
                        fz_write_string(ctx, out, "{");
                        fz_write_printf(ctx, out, "%q:%q,", "type", "text");
                        fz_write_printf(ctx, out, "%q:[%d,%d,%d,%d],", "bbox",
                            block->bbox.x0, block->bbox.y0,
                            block->bbox.x1, block->bbox.y1
                        );
                        fz_write_string(ctx, out, "\"lines\":[");

                        int line_comma = 0;
                        for (fz_stext_line *line = block->u.t.first_line; line; line=line->next) {
                            if (line_comma) fz_write_string(ctx, out, ",");
                            line_comma = 1;

                            fz_write_string(ctx, out, "{");


                            fz_write_printf(ctx, out, "\"bbox\":[%g,%g,%g,%g],",
                                    line->bbox.x0, line->bbox.y0,
                                    line->bbox.x1, line->bbox.y1);

                            // Font info
                            if (line->first_char) {
                                fz_font *font = line->first_char->font;
                                const char *family = "sans-serif";
                                const char *weight = "normal";
                                const char *style  = "normal";
                                if (fz_font_is_monospaced(ctx, font)) family = "monospace";
                                else if (fz_font_is_serif(ctx, font)) family = "serif";
                                if (fz_font_is_bold(ctx, font)) weight = "bold";
                                if (fz_font_is_italic(ctx, font)) style = "italic";

                                fz_write_printf(ctx, out, "%q:{", "font");
                                fz_write_printf(ctx, out, "%q:%q,", "name", fz_font_name(ctx, font));
                                fz_write_printf(ctx, out, "%q:%q,", "family", family);
                                fz_write_printf(ctx, out, "%q:%q,", "weight", weight);
                                fz_write_printf(ctx, out, "%q:%q,", "style", style);
                                fz_write_printf(ctx, out, "%q:%d},", "size", (int)(line->first_char->size));
                                fz_write_printf(ctx, out, "%q:%d,", "x", (int)(line->first_char->origin.x));
                                fz_write_printf(ctx, out, "%q:%d,", "y", (int)(line->first_char->origin.y));
                            }

                            // Extract text

                            fz_write_printf(ctx, out, "%q:\"", "text");
                            for (fz_stext_char* ch = line->first_char; ch; ch = ch->next)
                            {
                                if (ch->c == '"' || ch->c == '\\')
                                    fz_write_printf(ctx, out, "\\%c", ch->c);
                                else if (ch->c < 32)
                                    fz_write_printf(ctx, out, "\\u%04x", ch->c);
                                else
                                    fz_write_printf(ctx, out, "%C", ch->c);
                            }
                            fz_write_printf(ctx, out, "\"}");
                        }
                        fz_write_string(ctx, out, "]}");
                    }
                    else if (block->type == FZ_STEXT_BLOCK_IMAGE) {
                        /* ---- IMAGE BLOCK ---- */
                        fz_image *img = NULL;
                        fz_buffer *png_buf = NULL;

                        fz_write_string(ctx, out, "{");
                        fz_write_printf(ctx, out, "%q:%q,", "type", "image");
                        fz_write_printf(ctx, out, "%q:[%d,%d,%d,%d]", "bbox",
                            block->bbox.x0, block->bbox.y0,
                            block->bbox.x1, block->bbox.y1
                        );

                        if (include_image_data) {
                            fz_try(ctx) {
                                img = block->u.i.image;
                                int w = block->bbox.x1 - block->bbox.x0;
                                int h = block->bbox.y1 - block->bbox.y0;
                                if (w * h > 16777216) { // 4K * 4K pixels max
                                    fz_write_string(ctx, out, ",\"data\":null,\"error\":\"Image too large\"");
                                } else {
                                    png_buf = fz_new_buffer_from_image_as_png(ctx, img, fz_default_color_params);

                                    fz_write_string(ctx, out, ",\"data\":\"");

                                    fz_write_base64_buffer(ctx, out, png_buf, 0);

                                    fz_write_string(ctx, out, "\"");

                                }
                            }
                            fz_always(ctx) {
                                fz_drop_buffer(ctx, png_buf);
                            }
                            fz_catch(ctx) {
                                fz_write_string(ctx, out, ",\"data\":null");
                            }
                        }
                        fz_write_string(ctx, out, "}");
                    }
                    else {
                        fz_write_string(ctx, out, "{\"type\":\"other\"}");
                    }
                }

                fz_write_printf(ctx, out, "]}");
                fz_close_output(ctx, out);

                // Extract JSON string from buffer
                unsigned char *data = NULL;
                size_t size = fz_buffer_storage(ctx, buf, &data);
                printf("Page %d JSON:\n%.*s\n", i + 1, (int)size, data);

            }
            fz_always(ctx)
            {
                fz_drop_device(ctx, dev);
                fz_drop_stext_page(ctx, stext);
                fz_drop_page(ctx, page);
            }
            fz_catch(ctx)
            {
                fprintf(stderr, "Failed to process page %d\n", i + 1);
            }
        }
    }
    fz_always(ctx)
    {
        fz_drop_document(ctx, doc);
        fz_drop_context(ctx);
    }
    fz_catch(ctx)
    {
        fprintf(stderr, "Failed to process file: %s\n", filename);
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}