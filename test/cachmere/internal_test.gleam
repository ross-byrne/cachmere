import cachmere/internal
import gleam/int
import gleeunit/should
import simplifile

pub fn etag_generation_test() {
  let file_path = "test/fixtures/fixture.txt"

  let assert Ok(file_info) = simplifile.file_info(file_path)
  let result = internal.generate_etag(file_path)
  let expected =
    Ok(
      int.to_base16(file_info.size)
      <> "-"
      <> int.to_base16(file_info.mtime_seconds),
    )

  should.equal(expected, result)
}
