import gleeunit/should
import wisp

pub fn expect_txt_file_with_status_ok(response: wisp.Response) {
  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "text/plain; charset=utf-8"),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.txt"))
}

pub fn expect_json_file_with_status_ok(response: wisp.Response) {
  should.equal(response.status, 200)
  should.equal(response.headers, [
    #("content-type", "application/json; charset=utf-8"),
  ])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.json"))
}

pub fn expect_data_file_with_status_ok(response: wisp.Response) {
  should.equal(response.status, 200)
  should.equal(response.headers, [#("content-type", "application/octet-stream")])
  should.equal(response.body, wisp.File("./test/fixtures/fixture.dat"))
}
