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
