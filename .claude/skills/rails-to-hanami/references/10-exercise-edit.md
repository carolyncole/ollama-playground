# Phase 10 — Exercise: Book edit/update

Goal: `spec/system/book_edit_spec.rb` passes. This is the last phase — an exercise. Implement it
yourself using the `books.edit`/`books.update` actions generated in phase 2 and the patterns from
phase 8 (new/create), before reaching for the hints below.

## Run the edit spec (keep re-running it as you go)

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec spec/system/book_edit_spec.rb
```

## Hints (use only if stuck)

1. The Hanami docs have a worked example for updating a Book:
   https://hanakai.org/learn/hanami/v3.0/getting-started/building-a-web-app#updating-a-book

2. The new and edit templates share the same form partial. Expose the submit label, form method,
   and form path from each view so the shared partial can adapt. In **bookshelf/app/views/books/edit.rb**:

   ```ruby
   include Deps["repos.book_repo"]

   expose :book do |context:, id:|
     book_repo.get(id)
   end

   expose :form_submit, default: "Update Book"
   expose :form_method, default: "PATCH"
   expose :form_path do |context:, id:|
     context.routes.path(:book, id: id)
   end
   ```

   And in **bookshelf/app/views/books/new.rb** (added to phase 8's version):

   ```ruby
   expose :form_method, default: "POST"
   expose :form_path do |context:|
     context.routes.path(:books)
   end
   ```

3. Pass the exposed vars into the form partial from both `new.html.erb` and `edit.html.erb`:

   ```erb
   <%= render "form", book: book, form_submit: form_submit, form_path: form_path, form_method: form_method %>
   ```

4. Use all four form vars in `_form.html.erb`:

   ```erb
   <%= form_for :book, form_path, method: form_method do |form| %>
   ```

5. The create and update actions take almost identical parameters — copying `create.rb` as a
   starting point for `update.rb` is reasonable.

6. The update action needs both the `id` and the `book` params:

   ```ruby
   params do
     required(:id).filled(:integer)
     # ...same :book hash validation as create
   end
   ```

7. Update a book by calling:

   ```ruby
   book = book_repo.update(request.params[:id], request.params[:book])
   ```

Once the edit spec is green, the conversion is complete — `bundle exec rspec` in `bookshelf/`
should be fully passing.
