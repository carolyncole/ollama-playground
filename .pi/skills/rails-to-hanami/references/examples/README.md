# Ready-to-adapt Hanami 3 skeleton

Drop-in starting points. Names below use the `Book` model (bookshelf) and the
`User` model (orcid) so you can see both the tiny and the production shape.

Files in this folder:

- `db.rb`              — ROM/Sequel config (`app/db.rb`)
- `relations_book.rb`  — `app/relations/book.rb`
- `struct_book.rb`     — `app/structs/book.rb`
- `repo_books.rb`      — `app/repos/books.rb` (with encryption variant)
- `action_index.rb`    — `app/actions/books/index.rb`
- `action_create.rb`   — `app/actions/books/create.rb`
- `action_show.rb`     — guarded `show` (set_book equivalent)
- `operation_status.rb`— `app/operations/orcid_api_status.rb`
- `view_books_index.rb`— `app/views/books/index.rb` + template
- `template_index.erb` — `app/templates/books/index.html.erb`
