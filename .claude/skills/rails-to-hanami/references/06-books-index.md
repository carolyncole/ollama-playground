# Phase 6 — Books index page

Goal: `spec/system/book_index_spec.rb` passes.

## 1. Run the index spec (keep re-running it as you go)

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec spec/system/book_index_spec.rb
```

## 2. Wire the view up to the repo

Add to **bookshelf/app/views/books/index.rb**:

```ruby
include Deps["repos.book_repo"]

expose :books do
  book_repo.books.to_a
end
```

## 3. Fix the "new book" link

Replace in **bookshelf/app/templates/books/index.html.erb**:

```erb
new_book_path
```

With:

```erb
routes.path(:new_book)
```

Look at the [index page](http://localhost:2301/books). Note: the "Show this book" link doesn't
work yet — that's expected until the next step.

## 4. Fix the "show" link

Replace in **bookshelf/app/templates/books/index.html.erb**:

```erb
<%= link_to "Show this book", book %>
```

With:

```erb
<%= link_to "Show this book", routes.path(:book, id: book.id) %>
```

Look at the [index page](http://localhost:2301/books) again — the show link should work now.

Once the index spec is green, move to `references/07-application-layout.md`.
