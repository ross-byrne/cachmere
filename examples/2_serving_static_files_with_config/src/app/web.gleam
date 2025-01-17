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

  // Serve static files using cachmeres default cache settings
  // default_cache_settings() adds a config with cache-control response headers
  use <- cachmere.serve_static_with(
    req,
    under: "/static",
    from: ctx.static_directory,
    options: cachmere.default_cache_settings(),
  )

  handle_request(req)
}
