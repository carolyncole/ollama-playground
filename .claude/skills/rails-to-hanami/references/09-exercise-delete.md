# Phase 9 — Exercise: Book delete

Goal: `spec/system/book_delete_spec.rb` passes. This is an exercise — implement it yourself using
the `books.destroy` action generated in phase 2 and the patterns from phases 5–8, before reaching
for the hints below.

## Run the delete spec (keep re-running it as you go)

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec spec/system/book_delete_spec.rb
```

## Hints (use only if stuck)

1. The Hanami docs have a worked example for deleting a Book:
   https://hanakai.org/learn/hanami/v3.0/getting-started/building-a-web-app#deleting-a-book

2. All the UI elements needed are already visible to the user — the deletion link/form lives on
   the show page (from phase 5's destroy button).

3. The repo already has the delete method (from phase 1). You'd call it from the `destroy` action
   with something like:

   ```ruby
   include Deps["repos.book_repo"]
   # ...
   # in handle method
   result = book_repo.delete(request.params[:id])
   ```

4. You can require an integer `id` param via:

   ```ruby
   params do
     required(:id).filled(:integer)
   end
   ```

5. You can redirect to the books index with:

   ```ruby
   response.redirect_to routes.path(:books)
   ```

Once the delete spec is green, move to `references/10-exercise-edit.md`.
