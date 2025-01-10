import gleam/http/response
import gleam/string
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
