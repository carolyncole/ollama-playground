# Phase 5 — Book show page

Goal: `spec/system/book_show_spec.rb` passes.

## 1. Run the show spec (keep re-running it as you go, until it passes)

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec spec/system/book_show_spec.rb
```

## 2. Wire the view up to the repo

Add to **bookshelf/app/views/books/show.rb**:

```ruby
include Deps["repos.book_repo"]

expose :book do |id:|
  book_repo.get(id)
end
```

## 3. Fix the partial render

Replace in **bookshelf/app/templates/books/show.html.erb**:

```erb
<%= render book %>
```

With:

```erb
<%= render "book", book: book %>
```

## 4. Create a Book struct

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate struct book
```

Add to **bookshelf/app/structs/book.rb**:

```ruby
def dom_id
  "book_#{id}"
end
```

## 5. Fix the dom_id helper call

Replace in **bookshelf/app/templates/books/_book.html.erb**:

```erb
<%= dom_id book %>
```

With:

```erb
<%= book.dom_id %>
```

## 6. Fix route helpers

Replace in **bookshelf/app/templates/books/show.html.erb**:

```erb
edit_book_path(book)
```

With:

```erb
routes.path(:edit_book, id: book.id)
```

Replace in `bookshelf/app/templates/books/` (this will touch 3 templates):

```erb
books_path
```

With:

```erb
routes.path(:books)
```

## 7. Fix the destroy button

Rails' `button_to` has no Hanami equivalent — replace in
**bookshelf/app/templates/books/show.html.erb**:

```erb
<%= button_to "Destroy this book", book, method: :delete %>
```

With:

```erb
<%= form_for :book, routes.path(:book, id: book.id), method: :delete do |f| %>
  <%= f.submit "Destroy this book" %>
<% end %>
```

## 8. Restart the dev server and check

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami dev
```

Look at the [show page](http://localhost:2301/books/2).

Once the show spec is green, move to `references/06-books-index.md`.
