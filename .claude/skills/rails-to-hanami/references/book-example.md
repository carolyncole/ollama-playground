# Worked example: porting a `Book` resource

This is the concrete, end-to-end version of the phases in `SKILL.md`, using the actual
`books`/`Book` example from the source workshop
(https://github.com/carolyncole/rails_to_hanami/blob/main/commands-to-copy.md). Read this
when you want exact file contents rather than the generalized instructions — the
mapping back to `SKILL.md`'s placeholders is `APP` = `Bookshelf`, `hanami_app` =
`bookshelf`, `resource` = `books`, `model` = `book`, `Model` = `Book`.

## Phase 1 — Bootstrap

```
hanami new bookshelf
cd bookshelf
bundle install
npm install
bundle exec hanami assets compile
bundle exec hanami dev
```

## Phase 2 — Database

```
bundle exec rails db:seed   # run from rails_bookshelf
cp ../rails_bookshelf/storage/development.sqlite3 db/
cp ../rails_bookshelf/storage/test.sqlite3 db/
```

`bookshelf/.env`:
```
DATABASE_URL=sqlite://db/development.sqlite3
```

## Phase 3 — Relation, repo, interface

```
bundle exec hanami generate relation books
bundle exec hanami generate repo book
```

`app/repos/book_repo.rb`:
```ruby
def all = books.to_a

def create(attributes)
  attributes[:created_at] = Time.now
  attributes[:updated_at] = Time.now
  books.changeset(:create, attributes).commit
end

def count = books.count

def delete(id)
  books.by_pk(id).changeset(:delete).commit
end

def get(id) = books.by_pk(id).one!

def last = books.last

def update(id, attributes)
  attributes[:updated_at] = Time.now
  books.by_pk(id).changeset(:update, attributes).commit
end
```

Sanity check in console:
```
bundle exec hanami console
puts Bookshelf::Repos::BookRepo.new.all.map(&:inspect)
```

## Phase 4 — Routes and actions

`config/routes.rb`:
```ruby
resources :books
```

```
bundle exec hanami routes
bundle exec hanami generate action books.show    --skip-route --skip-tests
bundle exec hanami generate action books.index   --skip-route --skip-tests
bundle exec hanami generate action books.new     --skip-route --skip-tests
bundle exec hanami generate action books.create  --skip-route --skip-tests
bundle exec hanami generate action books.edit    --skip-route --skip-tests
bundle exec hanami generate action books.update  --skip-route --skip-tests
bundle exec hanami generate action books.destroy --skip-route --skip-tests --skip-view
```

## Phase 5 — Views/specs port + idiom fixes

```
cp -r spec/system ../bookshelf/spec/          # from rails_bookshelf
cp -r app/views/books ../bookshelf/app/templates/
```

Then, across `bookshelf/spec/**`:

| Find | Replace |
|---|---|
| `require "rails_helper"` | `require "spec_helper"` |
| `Book.create(` | `Bookshelf::Repos::BookRepo.new.create(` |
| `Book.last` | `Bookshelf::Repos::BookRepo.new.last` |
| `change(Book, :count)` | `change { Bookshelf::Repos::BookRepo.new.count }` |
| `book.reload` | `book = Bookshelf::Repos::BookRepo.new.get(book.id)` |
| `book_title` | `book-title` |
| `book_author` | `book-author` |
| `@book` | `book` |

## Phase 6 — Layout

```
cp app/views/layouts/application.html.erb ../bookshelf/app/templates/layouts/app.html.erb
cp app/assets/stylesheets/application.css ../bookshelf/app/assets/css/app.css
```

In `bookshelf/app/templates/layouts/app.html.erb`:

- `<%= csrf_meta_tags %>` + `<%= csp_meta_tag %>` → `<%= csrf_meta_tags&.html_safe %>`
- `<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>` +
  `<%= javascript_importmap_tags %>` → `<%= stylesheet_tag "app", "data-turbo-track": "reload" %>`
- the three `<link rel="icon" ...>` tags → `<%= favicon_tag %>`

## Phase 7 — Wiring actions

### Show

`app/views/books/show.rb`:
```ruby
include Deps["repos.book_repo"]

expose :book do |id:|
  book_repo.get(id)
end
```

`app/templates/books/show.html.erb`: `<%= render book %>` → `<%= render "book", book: book %>`

Generate a struct and give it a `dom_id`:
```
bundle exec hanami generate struct book
```
`app/structs/book.rb`:
```ruby
def dom_id
  "book_#{id}"
end
```
`app/templates/books/_book.html.erb`: `<%= dom_id book %>` → `<%= book.dom_id %>`

Path helper swaps (across templates):
- `edit_book_path(book)` → `routes.path(:edit_book, id: book.id)`
- `books_path` → `routes.path(:books)` (appears in 3 templates)
- `<%= button_to "Destroy this book", book, method: :delete %>` →
  ```erb
  <%= form_for :book, routes.path(:book, id: book.id), method: :delete do |f| %>
    <%= f.submit "Destroy this book" %>
  <% end %>
  ```

### Index

`app/views/books/index.rb`:
```ruby
include Deps["repos.book_repo"]

expose :books do
  book_repo.books.to_a
end
```

Template swaps: `new_book_path` → `routes.path(:new_book)`;
`<%= link_to "Show this book", book %>` → `<%= link_to "Show this book", routes.path(:book, id: book.id) %>`.

### New / Create

`app/views/books/new.rb`:
```ruby
include Deps["repos.book_repo"]

expose :form_submit, default: "Create Book"
expose :book do |context:|
  context.request.params[:book]
end
```

`app/templates/books/_form.html.erb`:
- `<%= form_with(model: book) do |form| %>` → `<%= form_for :book, routes.path(:books), method: "POST" do |form| %>`
- `<%= form.submit %>` → `<%= form.submit form_submit %>`

`app/templates/books/new.html.erb`: `<%= render "form", book: book %>` →
`<%= render "form", book: book, form_submit: form_submit %>`

`app/actions/books/create.rb` — Rails source being ported
(`rails_bookshelf/app/controllers/books_controller.rb#create`):
```ruby
def handle(request, response)
  @book = Book.new(book_params)
  if @book.save
    redirect_to @book, notice: "Book was successfully created."
  else
    render :new, status: :unprocessable_entity
  end
end
```

Hanami version:
```ruby
class Create < Bookshelf::Action
  include Deps["repos.book_repo"]

  params do
    required(:book).hash do
      required(:title).filled(:string)
      required(:author).filled(:string)
    end
  end

  def handle(request, response)
    if request.params.valid?
      book = book_repo.create(request.params[:book])
      response.flash[:notice] = "Book was successfully created"
      response.redirect_to routes.path(:book, id: book[:id])
    else
      response.flash.now[:alert] = "Could not create book"
    end
  end
end
```

Flash needs cookie sessions enabled — `config/app.rb`:
```ruby
config.actions.sessions = :cookie, { key: "bookshelf.session", secret: settings.session_secret, expire_after: 60*60*24*365 }
```
`config/settings.rb`:
```ruby
setting :session_secret, constructor: Types::String, default: "____local_development_secret_only____local_development_secret_only___"
```

## Phase 8 — Exercises (as given to workshop participants — hints only, no solution)

### Exercise 1: Delete

Run `bundle exec rspec spec/system/book_delete_spec.rb` until it passes. Hints given to
participants (in this graduated order — don't skip ahead to the full snippet unless
they're stuck):

1. See the Hanami docs' "deleting a book" section of the getting-started guide.
2. All UI elements already exist; the delete link/button is on the show page already.
3. The repo's `delete` method already exists (from Phase 3) — call it in the action's
   `handle`: `include Deps["repos.book_repo"]`, then
   `result = book_repo.delete(request.params[:id])`.
4. Require an integer id param: `params do; required(:id).filled(:integer); end`.
5. Redirect with `response.redirect_to routes.path(:books)`.

### Exercise 2: Edit / Update

Run `bundle exec rspec spec/system/book_edit_spec.rb` until it passes. Hints given to
participants:

1. See the Hanami docs' "updating a book" section.
2. `new` and `edit` share one form partial — expose the submit label, HTTP method, and
   form path as view-local data so the partial doesn't need to know which page it's on.
   `app/views/books/edit.rb`:
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
   and matching defaults in `app/views/books/new.rb`:
   ```ruby
   expose :form_method, default: "POST"
   expose :form_path do |context:|
     context.routes.path(:books)
   end
   ```
3. Pass them into the partial from both templates:
   ```erb
   <%= render "form", book: book, form_submit: form_submit, form_path: form_path, form_method: form_method %>
   ```
   and use them in `_form.html.erb`:
   ```erb
   <%= form_for :book, form_path, method: form_method do |form| %>
   ```
4. `create` and `update` take almost the same params — copying `create`'s action as a
   starting point for `update` is reasonable. `update` additionally needs the id:
   ```ruby
   params do
     required(:id).filled(:integer)
     # ...same book params as create
   end
   ```
5. Call `book = book_repo.update(request.params[:id], request.params[:book])`.
