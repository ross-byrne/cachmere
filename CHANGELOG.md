# Changelog

## v0.3.1

- Added deprecation warnings. Wisp now uses etags for all assets served with
  `wisp.serve_static`. While not a one to one replacement, it solves the general
  problem.
- Updated dependencies

## v0.3.0

- **Breaking Change:** Added new options type for configuring
  `serve_static_with`.

## v0.2.2

- Updated dependencies to more closely match Wisp

## v0.2.1

- Updated documentation

## v0.2.0

- Added examples demonstrating how to use the package
- Added support for etags

## v0.1.0

First release!

- Added `serve_static` function for serving static assets. Taken from wisp's
  `serve_static`.
- Added `serve_static_with` function that takes a config. This config can be
  used to define response headers to add to statically served files.
- Added `default_cache_settings` function which returns default settings for
  `serve_static_with`, which sets `cache-control` headers for `.js` and `.css`
  files.
