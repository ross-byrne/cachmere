import cachmere/internal
import gleam/http
import gleam/http/response
import gleam/list
import gleam/result
import gleam/string
import marceau
import simplifile
import wisp.{type Request, type Response, File, response}

/// Options for `serve_static_with`.
///
/// - `etags` is a boolean that enables the use of entity tags. Enabling this will generate etags for all files served
/// from the location passed to `serve_static_with`.
/// - `response_headers` is a `ResponseHeaderOptions` type. This allows for defining a list of response headers, in a tuple format. eg. "cache-control": "max-age=31536000".
/// As well as optionally filtering by file type. Giving you control over which file types get the supplied headers added to them.
///
/// See `ResponseHeaderOptions` type for more details.
///
pub type ServeStaticOptions {
  ServeStaticOptions(etags: Bool, response_headers: ResponseHeaderOptions)
}

/// Options for adding response headers to a statically served file
/// Variant `ResponseHeaders` takes a list of response headers, in tuple format. eg. "cache-control": "max-age=31536000".
/// Headers defined will be added to all statically served files. An empty list will result in identical behaviour to `serve_static`.
///
/// Variant `ResponseHeadersFor` allows for filtering by file type. It takes a list of response header and a list of file types.
/// eg. ["js", "css"]. Response headers will only be added to files with the same file type.
/// Unlisted file types will still be served but they won't have the headers defined in `headers` applied to them.
///
pub type ResponseHeaderOptions {
  ResponseHeaders(List(#(String, String)))
  ResponseHeadersFor(headers: List(#(String, String)), file_types: List(String))
}

/// Returns `ServeStaticOptions` with a default config for caching
///
/// # Default Settings
/// ```gleam
/// ServeStaticOptions(
///   etags: False,
///   response_headers: ResponseHeadersFor(
///     headers: [#("cache-control", "max-age=31536000, immutable, private")],
///     file_types: ["js", "css"],
///   ),
/// )
/// ```
///
pub fn default_cache_settings() -> ServeStaticOptions {
  ServeStaticOptions(
    etags: False,
    response_headers: ResponseHeadersFor(
      headers: [#("cache-control", "max-age=31536000, immutable, private")],
      file_types: ["js", "css"],
    ),
  )
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
/// Typically your static assets may be kept in your project in a directory
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
      response_headers: ResponseHeaders([]),
    ),
    next: handler,
  )
}

/// Functions the same as `serve_static` but takes options for enabling etags and setting response headers for specific file types.
/// This allows for configuring headers such as Cache-Control etc.
///
/// # Examples
/// Serve files from static folder and apply cache-control header to `.js` and `.css` files.
/// All other file will be served but they won't have the defined response headers added to them.
/// ```gleam
/// fn handle_request(req: Request) -> Response {
///   let assert Ok(priv) = priv_directory("my_application")
///   use <- cachmere.serve_static_with(
///     req,
///     under: "/static",
///     from: priv,
///     options: cachmere.ServeStaticOptions(
///       etags: False,
///       response_headers: cachmere.ResponseHeadersFor(
///         headers: [#("cache-control", "max-age=31536000, immutable, private")],
///         file_types: ["js", "css"],
///       ),
///     ),
///   )
///   // ...
/// }
/// ```
///
/// Serve files from static folder using etags. If files have not been edited, `serve_static_with`
/// will return a status 304 allowing the browser to use the cached version of the file.
/// ```gleam
/// fn handle_request(req: Request) -> Response {
///   let assert Ok(priv) = priv_directory("my_application")
///   use <- cachmere.serve_static_with(
///     req,
///     under: "/static",
///     from: priv,
///     options: cachmere.ServeStaticOptions(
///       etags: True,
///       response_headers: cachmere.ResponseHeaders([]),
///     ),
///   )
///   // ...
/// }
/// ```
///
pub fn serve_static_with(
  req: Request,
  under prefix: String,
  from directory: String,
  options options: ServeStaticOptions,
  next handler: fn() -> Response,
) -> Response {
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

          // Handle Response headers
          let resp = case options.response_headers {
            // Add defined headers to response
            ResponseHeaders(headers) -> internal.set_headers(headers, resp)
            // check if file type matches, then add headers accordingly
            // if file type doesn't match, pass through response unedited
            ResponseHeadersFor(headers, file_types) ->
              case list.contains(file_types, file_type) {
                True -> internal.set_headers(headers, resp)
                False -> resp
              }
          }

          // Handle etag generation
          case options.etags {
            True -> internal.handle_etag(req, resp, path)
            False -> resp
          }
        }
        _ -> handler()
      }
    }
    _, _ -> handler()
  }
}
