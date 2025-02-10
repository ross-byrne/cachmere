# cachmere

[![Package Version](https://img.shields.io/hexpm/v/cachmere)](https://hex.pm/packages/cachmere)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/cachmere/)

A caching solution for Gleam web apps, designed to be used with Wisp. Currently
a work-in-progress. Breaking changes may be made to the API.

The goal with `cachmere` is to provide more control over the static assets you
have to serve from your backend.

### Use Case

Some times you want to have the browser cache statically served assets. This is
desierable for a number of reasons, such as increasing page load times, as the
browser already has the files, and saving server bandwith.

One such scenario could be, you have a SPA (single page application) built using
a modern javascript framework and you are serving it from your backend. The
initial download might be big, so having the browser cache the unchanged files
could drastically improve page load times after initial load.

#### Custom Response Headers

If you use a modern build tool, such as vite, your files can be fingerprinted
with unique names that change when the content changes. In this case, you can
set the Cache-Control header in the server response to cache your files for the
longest possible time.

#### ETags

If you don't have file fingerprinting or aren't using a build tool at all, you
could enable ETags. This will allow the browser to cache the file and ask the
server if the file has changed. This option will result in more server requests
than the latter but will still save you bandwith as the server will only return
the file if the etag has changed. If the file hasn't been updated, the server
will return a 304 Not Modified response.

For more details and code examples, see the [docs](cachmere.html).

## Development

```sh
mise up # install development environment dependencies
gleam test  # Run the tests
```
