# Phase 3 — Port Rails views and specs

Goal: the Rails system specs and ERB views exist inside `bookshelf/`, and the specs run (they will
still fail — that's expected until later phases implement the real behavior).

## 1. Copy over the system specs and the Rails views

```
docker exec -w /usr/src/app/rails_bookshelf -it ollamaplayground cp -r spec/system ../bookshelf/spec/
docker exec -w /usr/src/app/rails_bookshelf -it ollamaplayground cp -r app/views/books ../bookshelf/app/templates/
```

## 2. Run all the tests

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec
```

Expect syntax/reference errors at this point — the specs and templates are still written in Rails
idioms. Fix them with the find/replace passes below.

## 3. Fix up the copied specs for Hanami

Make each of these replacements across `bookshelf/spec/`:

| Replace | With | Why |
|---|---|---|
| `require "rails_helper"` | `require "spec_helper"` | Hanami specs don't load Rails' spec helper. |
| `Book.create(` | `Bookshelf::Repos::BookRepo.new.create(` | No ActiveRecord model — go through the repo. |
| `Book.last` | `Bookshelf::Repos::BookRepo.new.last` | Same reason, for the delete-exercise spec. |
| `change(Book, :count)` | `change { Bookshelf::Repos::BookRepo.new.count }` | Hanami has no RSpec `change(Model, :count)` helper. |
| `book.reload` | `book = Bookshelf::Repos::BookRepo.new.get(book.id)` | Repo objects are immutable value objects — re-fetch instead of mutating in place. |
| `book_title` | `book-title` | Hanami's form helpers generate element ids with `-`, not `_`. |
| `book_author` | `book-author` | Same as above. |
| `@book` | `book` | Hanami views expose local variables, not instance variables. |

You could technically stop after just the first two replacements to get to the next failing test
faster, but for the sake of moving through the workshop, apply all of them now.

Once these replacements are done, the specs no longer have syntax errors — they run, and start
telling you which behaviors aren't implemented yet. Move to `references/04-flash-notices.md`.
