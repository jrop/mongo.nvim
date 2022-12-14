# mongo.nvim

> A NeoVim frontend for mongosh

[![asciicast](https://asciinema.org/a/MHHlLdHfIGkA6Sswtp4PfW9E0.svg)](https://asciinema.org/a/MHHlLdHfIGkA6Sswtp4PfW9E0)

> Note: I developed/tested this plugin on NeoVim 0.7.2, and 0.8.0. I have not
> tested it on any other versions

MongoDB Compass is a great tool, but when you want to edit a large document, it
really begins to slow down, and on top of that, a Vimmer really begins to miss
all the editing capabilities not found in Compass' document editor. Enter this
plugin: I wanted something that would let me:

1. Write MongoDB queries and execute them from Vim
2. Edit documents with ease and write them back to the database simply

This plugin does just that by acting as a frontend for the excellent
[mongosh](https://www.mongodb.com/docs/mongodb-shell/write-scripts/). Send
mongosh scripts to be executed with `:Mongoquery` and have the results displayed
in a temporary unlisted buffer. Generate the appropriate "replaceOne(...)"
script for easy single-document editing with the `:Mongoedit --collection=... --id=...`
command.

## Requirements

- The `mongosh` executable should be in your `PATH`

## Installation

**Packer**:

```lua
use { 'jrop/mongo.nvim' }
```

## Commands

1. `:Mongoconnect [--host=localhost:27017] --db=some_db` - this is a convenience
   for "caching" a connection string globally so that you don't have to
   repeatedly set the DB you want to connect to for each query you run: use this
   when you need to connect to a specific DB across several repeated calls
2. `:Mongocollections` - open a buffer that lists the collections in the DB we
   are currently connected to. Press `<Enter>` on a collection to open a
   stub-query.
3. `:Mongoquery db.some_db.find({})`
4. `:Mongoquery` - use the current buffer as the Mongo query
5. `:'<,'>Mongoquery` - use the current selection as the Mongo query
6. `:Mongoexecute` - like `:Mongoquery` but do not display the result set in a
   buffer: just print the response to Vim's messages
7. `:Mongoedit --collection=some_collection --id=SOME_ID` - a shorthand for
   finding a given document, and generating a `db.*.replaceOne(...)` query so
   that the document can easily be edited (by a subsequent call to
   `:Mongoexecute`)
8. `:Mongoedit --coll=some_collection --id=SOME_ID` - shorthand option (`--coll`
   instead of `--collection`)
9. `:Mongoedit` - with no parameters, the plugin will try to infer
   the collection and relevant id by doing a few things:
   - if the query that produced the current buffer/split is simple enough, the
     plugin will have extracted the collection and stores that as tag-data on
     the current buffer. In order to take advantage of this, the current buffer
     has to have been produced by running `:Mongoquery`
   - the nearest `_id` is extracted based on the current cursor position using
     the current Treesitter context for the current buffer
10. `:Mongorefresh` - refresh data in the current buffer

## TODO

- [X] Remove dependency on vim-prettier
- [ ] Consider supporting pagination
- [ ] Consider writing a custom data format (built on top of EJSON) that
      displays things in a more JS-like way

## Changelog

**November 4, 2022**
- Remove JS-style output of queries as it was too error-prone. Use EJSON
  everywhere.

**November 2, 2022**
- Utilize Treesitter when executing a query to keep track of what collection a
  data-results split originated from
- When `:Mongoedit` is run without `--coll`/`--id`, try to infer the collection
  from the data stored in the previous bullet, and also try to infer the nearest
  `_id` (based on cursor position) using the current Treesitter context.

**October 31st, 2022**
- Make certain operations "refreshable" and add the `:Mongorefresh` command
- Fix a bug when the resulting executed expression returns undefined (e.g., IIFE
  that return void)
- Make `:Mongoconnect` more robust: if there are multiple DBs, show them in a
  selector to the user via `vim.ui.select(..)`

## Licence (MIT)

Copyright (c) 2022 <jrapodaca@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
