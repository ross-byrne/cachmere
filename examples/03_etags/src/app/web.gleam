import cachmere
import wisp

pub type Context {
  Context(static_directory: String)
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  // Serve static files using etags
  use <- cachmere.serve_static_with(
    req,
    under: "/static",
    from: ctx.static_directory,
    options: cachmere.ServeStaticOptions(
      etags: True,
      response_headers: [],
      file_types: [],
    ),
  )

  handle_request(req)
}
