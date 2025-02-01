import cachmere/internal
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import marceau
import simplifile
import wisp.{type Request, type Response, File, response}

/// Options for `serve_static_with`.
///
/// - `response_headers` is a list of response headers, in a tuple format. eg. "cache-control": "max-age=31536000".
/// - `file_types` is a list of file types to apply the defined response headers to.
/// This allows you to control the headers, such as cache-control, on a per file type basis.
/// Unlisted file types will still be served but they won't have the headers defined in `response_headers` applied to them.
/// An empty list will result in identical behaviour to `cachmere.serve_static`.
///
pub type ServeStaticOptions {
  ServeStaticOptions(
    etags: Bool,
    response_headers: List(#(String, String)),
    file_types: List(String),
  )
}

/// Returns `ServeStaticOptions` with a default config for caching
///
/// # Default Settings
/// ```gleam
/// ServeStaticOptions(
///   file_types: ["js", "css"],
///   response_headers: [#("cache-control", "max-age=31536000, immutable")]
/// )
/// ```
///
pub fn default_cache_settings() -> ServeStaticOptions {
  ServeStaticOptions(etags: False, file_types: ["js", "css"], response_headers: [
    #("cache-control", "max-age=31536000, immutable"),
  ])
}

/// A middleware function that serves files from a directory, along with a
/// suitable `content-type` header for known file extensions.
///
/// Files are sent using the `File` response body type, so they will be sent
/// directly to the client from the disc, without being read into memory.
///
/// The `under` parameter is the request path prefix that must match for the
/// file to be served.
///
/// | `under`   | `from`  | `request.path`     | `file`                  |
/// |-----------|---------|--------------------|-------------------------|
/// | `/static` | `/data` | `/static/file.txt` | `/data/file.txt`        |
/// | ``        | `/data` | `/static/file.txt` | `/data/static/file.txt` |
/// | `/static` | ``      | `/static/file.txt` | `file.txt`              |
///
/// This middleware will discard any `..` path segments in the request path to
/// prevent the client from accessing files outside of the directory. It is
/// advised not to serve a directory that contains your source code, application
/// configuration, database, or other private files.
///
/// # Examples
///
/// ```gleam
/// fn handle_request(req: Request) -> Response {
///   use <- cachmere.serve_static(req, under: "/static", from: "/public")
///   // ...
/// }
/// ```
///
/// Typically you static assets may be kept in your project in a directory
/// called `priv`. The `priv_directory` function can be used to get a path to
/// this directory.
///
/// ```gleam
/// fn handle_request(req: Request) -> Response {
///   let assert Ok(priv) = priv_directory("my_application")
///   use <- cachmere.serve_static(req, under: "/static", from: priv)
///   // ...
/// }
/// ```
///
pub fn serve_static(
  req: Request,
  under prefix: String,
  from directory: String,
  next handler: fn() -> Response,
) -> Response {
  // Call serve_static_with with empty options
  serve_static_with(
    req,
    under: prefix,
    from: directory,
    options: ServeStaticOptions(
      etags: False,
      file_types: [],
      response_headers: [],
    ),
    next: handler,
  )
}

/// Functions the same as `serve_static` but takes options for setting response headers for specific file types.
/// This allows for configuring headers such as Cache-Control etc.
///
/// # Examples
/// ```gleam
/// fn handle_request(req: Request) -> Response {
///   let assert Ok(priv) = priv_directory("my_application")
///   use <- cachmere.serve_static_with(
///     req,
///     under: "/static",
///     from: priv,
///     options: cachmere.ServeStaticOptions(
///       file_types: ["js", "css"],
///       response_headers: [#("cache-control", "max-age=31536000, immutable")],
///     ),
///   )
///   // ...
/// }
/// ```
///
/// ## ServeStaticOptions
/// The options for `cachmere.ServeStaticOptions` are as follows:
///
/// - `response_headers` is a list of response headers, in a tuple format. eg. "cache-control": "max-age=31536000".
/// - `file_types` is a list of file types to apply the defined response headers to.
/// This allows you to control the headers, such as cache-control, on a per file type basis.
/// Unlisted file types will still be served but they won't have the headers defined in `response_headers` applied to them.
/// An empty list will result in identical behaviour to `cachmere.serve_static`.
///
/// See: `cachmere.default_cache_settings()` for a default config for caching.
///
pub fn serve_static_with(
  req: Request,
  under prefix: String,
  from directory: String,
  options options: ServeStaticOptions,
  next handler: fn() -> Response,
) {
  let path = internal.remove_preceeding_slashes(req.path)
  let prefix = internal.remove_preceeding_slashes(prefix)
  case req.method, string.starts_with(path, prefix) {
    http.Get, True -> {
      let path =
        path
        |> string.drop_start(string.length(prefix))
        |> string.replace(each: "..", with: "")
        |> internal.join_path(directory, _)

      let file_type =
        req.path
        |> string.split(on: ".")
        |> list.last
        |> result.unwrap("")

      let mime_type = marceau.extension_to_mime_type(file_type)
      let content_type = case mime_type {
        "application/json" | "text/" <> _ -> mime_type <> "; charset=utf-8"
        _ -> mime_type
      }

      case simplifile.is_file(path) {
        Ok(True) -> {
          let resp =
            response.new(200)
            |> response.set_header("content-type", content_type)
            |> response.set_body(File(path))

          // Check if file type is in options
          let resp = case list.contains(options.file_types, file_type) {
            True -> internal.set_headers(options.response_headers, resp)
            False -> resp
          }

          // Handle etag generation
          case options.etags {
            True -> {
              let assert Ok(etag) = internal.generate_etag(path)
              case request.get_header(req, "if-none-match") {
                // Compare old etag to current one
                Ok(old_etag) -> {
                  case string.compare(old_etag, etag) {
                    // etags match, return status 304
                    order.Eq -> wisp.response(304)
                    // didn't match, return file with new etag
                    _ -> response.set_header(resp, "etag", etag)
                  }
                }
                // set etag header
                _ -> response.set_header(resp, "etag", etag)
              }
            }
            False -> resp
          }
        }
        _ -> handler()
      }
    }
    _, _ -> handler()
  }
}
