#include <stdbool.h>

#ifndef MUPDF_WRAPPER_H
#define MUPDF_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// ------------------------- DLL Export Macro ---------------------------
#ifdef _WIN32
#define DLL_EXPORT __declspec(dllexport)
#else
#define DLL_EXPORT
#endif

// ------------------------- Document Management -----------------------
DLL_EXPORT int mw_count_pages(const char* filename);

// ------------------------- Page Extraction ---------------------------
DLL_EXPORT char* extract_page_json(const char* filename, int page_number, bool include_image_data);

// ------------------------- Utility Functions -------------------------
DLL_EXPORT const char* mw_get_last_error();
DLL_EXPORT void mw_free_string(char* s);

#ifdef __cplusplus
}
#endif

#endif // MUPDF_WRAPPER_H
