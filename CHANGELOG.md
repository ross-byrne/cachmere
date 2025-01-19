# Changelog

## Unreleased
- Added examples demonstrating how to use the package

## v0.1.0
First release!

- Added `serve_static` function for serving static assets. Taken from wisp's `serve_static`.
- Added `serve_static_with` function that takes a config. This config can be used to define response headers to add to statically served files.
- Added `default_cache_settings` function which returns default settings for `serve_static_with`, which sets `cache-control` headers for `.js` and `.css` files.
