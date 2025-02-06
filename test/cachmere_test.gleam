import cachmere
import cachmere/internal
import common/common
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
  common.expect_txt_file_with_status_ok(response)

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  common.expect_json_file_with_status_ok(response)

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  common.expect_data_file_with_status_ok(response)

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  common.expect_empty_response_with_status_ok(response)
}

pub fn serve_static_under_has_no_trailing_slash_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/stuff/test/fixtures/fixture.txt")
  let response = {
    use <- cachmere.serve_static(request, under: "stuff", from: "./")
    wisp.ok()
  }

  common.expect_txt_file_with_status_ok(response)
}

pub fn serve_static_from_has_no_trailing_slash_test() {
  let request =
    testing.get("/", [])
    |> request.set_path("/stuff/test/fixtures/fixture.txt")
  let response = {
    use <- cachmere.serve_static(request, under: "stuff", from: ".")
    wisp.ok()
  }

  common.expect_txt_file_with_status_ok(response)
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

pub fn default_cache_settings_test() {
  let result = cachmere.default_cache_settings()
  let expected =
    cachmere.ServeStaticOptions(
      etags: False,
      file_types: ["js", "css"],
      response_headers: [#("cache-control", "max-age=31536000, immutable")],
    )

  should.equal(result, expected)
}

pub fn serve_static_with_default_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions(
        etags: False,
        response_headers: [],
        file_types: [],
      ),
    )
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  common.expect_txt_file_with_status_ok(response)

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  common.expect_json_file_with_status_ok(response)

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  common.expect_data_file_with_status_ok(response)

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  common.expect_empty_response_with_status_ok(response)
}

pub fn serve_static_with_applies_to_correct_file_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions(
        etags: False,
        response_headers: [#("cache-control", "immutable")],
        file_types: ["txt", "json"],
      ),
    )
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("cache-control", "immutable"),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "application/json; charset=utf-8"),
    #("cache-control", "immutable"),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.json"))

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  common.expect_data_file_with_status_ok(response)

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  common.expect_empty_response_with_status_ok(response)
}

pub fn serve_static_with_etags_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions(
        etags: True,
        response_headers: [],
        file_types: [],
      ),
    )
    wisp.ok()
  }

  // Get a text file
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  let assert Ok(etag) = internal.generate_etag("test/fixtures/fixture.txt")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("etag", etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a json file
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  let assert Ok(etag) = internal.generate_etag("test/fixtures/fixture.json")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "application/json; charset=utf-8"),
    #("etag", etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.json"))

  // Get some other file
  let response =
    testing.get("/stuff/test/fixtures/fixture.dat", [])
    |> handler
  let assert Ok(etag) = internal.generate_etag("test/fixtures/fixture.dat")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "application/octet-stream"),
    #("etag", etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.dat"))

  // Get something not handled by the static file server
  let response =
    testing.get("/stuff/this-does-not-exist", [])
    |> handler
  common.expect_empty_response_with_status_ok(response)
}

pub fn serve_static_with_etags_returns_304_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions(
        etags: True,
        response_headers: [],
        file_types: [],
      ),
    )
    wisp.ok()
  }

  // Get a text file without any headers
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  let assert Ok(txt_etag) = internal.generate_etag("test/fixtures/fixture.txt")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("etag", txt_etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a text file with outdated if-none-match header
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [
      #("if-none-match", "invalid-etag"),
    ])
    |> handler

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("etag", txt_etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a text file with current etag in if-none-match header
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [
      #("if-none-match", txt_etag),
    ])
    |> handler

  should.equal(response.status, 304)
  should.equal(response.headers, [])
  should.equal(response.body, wisp.Empty)
}

pub fn serve_static_with_etags_and_custom_headers_test() {
  let handler = fn(request) {
    use <- cachmere.serve_static_with(
      request,
      under: "/stuff",
      from: "./",
      options: cachmere.ServeStaticOptions(
        etags: True,
        response_headers: [#("cache-control", "max-age=604800")],
        file_types: ["txt"],
      ),
    )
    wisp.ok()
  }

  // Get a text file without any headers
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [])
    |> handler
  let assert Ok(txt_etag) = internal.generate_etag("test/fixtures/fixture.txt")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("cache-control", "max-age=604800"),
    #("etag", txt_etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a text file with outdated if-none-match header
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [
      #("if-none-match", "invalid-etag"),
    ])
    |> handler

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
    #("cache-control", "max-age=604800"),
    #("etag", txt_etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))

  // Get a text file with current etag in if-none-match header
  let response =
    testing.get("/stuff/test/fixtures/fixture.txt", [
      #("if-none-match", txt_etag),
    ])
    |> handler

  should.equal(response.status, 304)
  should.equal(response.headers, [])
  should.equal(response.body, wisp.Empty)

  // Get a json file, custom header should not be applied
  let response =
    testing.get("/stuff/test/fixtures/fixture.json", [])
    |> handler
  let assert Ok(json_etag) =
    internal.generate_etag("test/fixtures/fixture.json")

  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "application/json; charset=utf-8"),
    #("etag", json_etag),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.json"))
}
