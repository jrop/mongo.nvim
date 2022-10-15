# mongo.nvim

> Note: I developed/tested this plugin on NeoVim 0.7.2, and 0.8.0. I have not
> tested it on any other versions

Provides utilities for exploring, querying, and editing Mongo documents.

## Requirements

- `mongosh` executable
- [prettier/vim-prettier](https://github.com/prettier/vim-prettier) for formatting generated queries

## Commands

1. `:Mongoconnect [--host=localhost:27017] --db=some_db`
2. `:Mongocollections` - open a buffer that lists the collections in the DB we
   are currently connected to. Press `<Enter>` on a collection to open a
   stub-query.
3. `:Mongoquery db.some_db.find({})`
4. `:Mongoquery` - use the current buffer as the Mongo query
5. `:'<,'>Mongoquery` - use the current selection as the Mongo query
6. `:Mongoexecute` - like `:Mongoquery` but do not "process" the result set to
   display it in a buffer: just print the response to Vim's messages
7. `:Mongoedit --collection=some_collection --id=SOME_ID` - a shorthand for
   finding a given document, and generating a `db.*.replaceOne(...)` query so
   that the document can easily be edited
8. `:Mongoedit --coll=some_collection --id=SOME_ID` - shorthand option

## TODO

- [ ] Remove dependency on vim-prettier
- [ ] Consider supporting pagination

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
