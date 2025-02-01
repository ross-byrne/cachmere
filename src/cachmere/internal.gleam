import gleam/http/response
import gleam/int
import gleam/result
import gleam/string
import simplifile
import wisp.{type Response}

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

/// Generates etag using file size + file mtime in micro seconds
///
/// Exmaple etag value: `2C-62D123DB1FD00`
pub fn generate_etag(path: String) -> Result(String, simplifile.FileError) {
  use file_info <- result.try(simplifile.file_info(path))
  let micro_seconds = file_info.mtime_seconds * 1_000_000
  Ok(int.to_base16(file_info.size) <> "-" <> int.to_base16(micro_seconds))
}
