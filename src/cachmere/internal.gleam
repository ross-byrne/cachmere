import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/order
import gleam/result
import gleam/string
import simplifile
import wisp.{type Request, type Response}

// HELPERS
//
// Middleware Helpers
//

pub fn remove_preceeding_slashes(string: String) -> String {
  case string {
    "/" <> rest -> remove_preceeding_slashes(rest)
    _ -> string
  }
}

// TODO: replace with simplifile function when it exists
pub fn join_path(a: String, b: String) -> String {
  let b = remove_preceeding_slashes(b)
  case string.ends_with(a, "/") {
    True -> a <> b
    False -> a <> "/" <> b
  }
}

/// Recursively adds headers to a response
pub fn set_headers(headers: List(#(String, String)), resp: Response) -> Response {
  case headers {
    [] -> resp
    [#(key, value), ..rest] ->
      set_headers(rest, response.set_header(resp, key, value))
  }
}

/// Generates etag using file size + file mtime as seconds
///
/// Exmaple etag value: `2C-67A4D2F1`
pub fn generate_etag(path: String) -> Result(String, simplifile.FileError) {
  use file_info <- result.try(simplifile.file_info(path))
  Ok(
    int.to_base16(file_info.size)
    <> "-"
    <> int.to_base16(file_info.mtime_seconds),
  )
}

/// Calculates etag for requested file and then checks for the request header `if-none-match`.
///
/// If the header isn't present, it returns the file with a generated etag. If the header is present,
/// it compares the old etag with the new one and returns the file with the new etag if they don't match.
///
/// Otherwise it returns status 304 without the file, allowing the browser to use the cached version.
///
pub fn handle_etag(req: Request, resp: Response, path: String) -> Response {
  case generate_etag(path) {
    Ok(etag) -> {
      case request.get_header(req, "if-none-match") {
        Ok(old_etag) -> {
          case string.compare(old_etag, etag) {
            order.Eq -> wisp.response(304)
            _ -> response.set_header(resp, "etag", etag)
          }
        }
        _ -> response.set_header(resp, "etag", etag)
      }
    }
    _ -> resp
  }
}
