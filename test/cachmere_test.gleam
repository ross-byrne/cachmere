import cachmere
import gleam/http/request
import gleeunit
import gleeunit/should
import wisp
import wisp/testing

pub fn main() {
  wisp.configure_logger()
  gleeunit.main()
}

pub fn serve_static_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static(request, under: "/stuff", from: "./")
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "text/plain; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.txt"))

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "application/json; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.json"))

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "application/octet-stream")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.dat"))

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([])
  response.body
  |> should.equal(wisp.Empty)
}

pub fn serve_static_under_has_no_trailing_slash_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/stuff/test/fixtures/fixture.txt")
  let response = {
    use <- cachmere.serve_static(request, under: "stuff", from: "./")
    wisp.ok()
  }
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "text/plain; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.txt"))
}

pub fn serve_static_from_has_no_trailing_slash_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/stuff/test/fixtures/fixture.txt")
  let response = {
    use <- cachmere.serve_static(request, under: "stuff", from: ".")
    wisp.ok()
  }
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "text/plain; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.txt"))
}

pub fn serve_static_not_found_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/stuff/credit_card_details.txt")
  {
    use <- cachmere.serve_static(request, under: "/stuff", from: "./")
    wisp.ok()
  }
  |> should.equal(wisp.ok())
}

pub fn serve_static_go_up_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/../test/fixtures/fixture.txt")
  {
    use <- cachmere.serve_static(request, under: "/stuff", from: "./src/")
    wisp.ok()
  }
  |> should.equal(wisp.ok())
}

pub fn serve_static_with_default_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions([], []),
    )
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "text/plain; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.txt"))

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "application/json; charset=utf-8")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.json"))

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "application/octet-stream")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.dat"))

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([])
  response.body
  |> should.equal(wisp.Empty)
}

pub fn serve_static_with_applies_to_correct_file_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions([#("cache-control", "immutable")], [
        "txt", "json",
      ]),
    )
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([
    #("content-type", "text/plain; charset=utf-8"),
    #("cache-control", "immutable"),
  ])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.txt"))

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([
    #("content-type", "application/json; charset=utf-8"),
    #("cache-control", "immutable"),
  ])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.json"))

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([#("content-type", "application/octet-stream")])
  response.body
  |> should.equal(wisp.File("./test/fixtures/fixture.dat"))

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  response.status
  |> should.equal(200)
  response.headers
  |> should.equal([])
  response.body
  |> should.equal(wisp.Empty)
}

pub fn default_cache_settings_test() {
  let result = cachmere.default_cache_settings()
  let expected =
    cachmere.ServeStaticOptions(file_types: ["js", "css"], response_headers: [
      #("cache-control", "max-age=31536000, immutable"),
    ])

  should.equal(result, expected)
}
