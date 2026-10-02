# Rails → Hanami Translation Table

Authoritative mapping of each Rails concept onto its Hanami 3 + ROM + dry-rb
equivalent. Snippets are written for:

- the real `orcid_princeton` → `orcid_princeton_hanami` conversion
- the small `rails_bookshelf` app used in this playground (a `Book` model with
  `title`/`author` columns)

Use the bookshelf examples as the "tiny version"; use the orcid examples as the
"production version".

---

## Layout / namespace

```
# Rails
app/controllers/  app/models/  app/views/  app/helpers/
config/routes.rb  db/schema.rb

# Hanami 3
app/actions/       # one class per route
app/views/         # one View per action (+ .html.erb / .jbuilder templates)
app/templates/     # layout + template fragments
app/relations/     # ROM schemas + associations
app/repos/         # query + CRUD (may return Dry::Monads::Result)
app/structs/       # record + business logic (replaces "smart" AR models)
app/operations/    # dry-rb / dry-transaction style operations
app/action.rb      # base Action   (# auto_register: false)
app/view.rb        # base View     (# auto_register: false)
app/operation.rb   # base Operation(# auto_register: false)
app/db.rb          # ROM/Sequel config
config/routes.rb   # Hanami router
config/app.rb      # app config: middleware, env
config/db/         # migrations + structure.sql
```

Everything under `app/` is auto-loaded and injectable by name. Base classes get
`# auto_register: false` because they are not a route or a dependency.

---

## Routes

```ruby
# Rails
Rails.application.routes.draw do
  resources :books
  devise_for :users
end

# Hanami 3 (config/routes.rb)
map "books#index", to: Books::Index, as: :books_index,  path: "/books"
map "books#show",  to: Books::Show,  as: :book,         path: "/books/:id"
map "books#new",   to: Books::New,   as: :new_book,     path: "/books/new"
map "books#create",to: Books::Create,as: :books,        path: "/books"
map "books#edit",  to: Books::Edit,  as: :edit_book,    path: "/books/:id/edit"
map "books#update",to: Books::Update,as: :book,         path: "/books/:id"
map "books#destroy",to: Books::Destroy,as: :book,       path: "/books/:id"
```

Route helpers (`books_path`, `book_url(book)`) become `routes.books_index`,
`routes.book(id: 4)`. Actions reference `routes` (injected via `Deps` or
`routes` in the base `Action`).

---

## Models (the big one)

Rails folds record + queries + behavior into `ActiveRecord::Base`. **Split into
three layers.**

### relations — ROM schema + associations

```ruby
# app/structs/book.rb? NO. This is a relation (schema + keys).
# app/relations/book.rb
class Book < Relations::Base
  model do
    columns(
      :id      do { Integer; primary_key }.end,
      :title   do { String }.end,
      :author  do { String }.end,
      :created_at do { Time }.end,
      :updated_at do { Time }.end,
    )
  end
end
```

```ruby
# app/relations/base.rb
class Base < Relations::Base? ... end
# In practice:
# app/relations/base.rb
#   class Base = Hanami::App::Relations::Base   # or Sequel::Model with ROM::SQL
# with associations declared via Sequel or a separate associations map.
```

> For the bookshelf: `Book` had no associations, so the relation is just columns.
> For orcid, a `User` relation declares `has_many :tokens`, `OneToMany`, etc.

### repos — queries + CRUD

```ruby
# Rails
Book.all
Book.find(params.expect(:id))
b = Book.new(title: 'T', author: 'A'); b.save
b.update(title: 'T2')
b.destroy!

# Hanami — app/repos/books.rb
class Books < Repo
  include Dry::Monads[:result]
  def all
    Success(Hanami.app.db.rom.commands(:sql).call do |rs|
      rs.filter { ... }
    end)
  end

  def get(id:)
    case (record = rom.relations[:books].where(id: id).one)
    when nil then Failure(BookNotFound.new(id: id))
    else Success(Structs::Book.new(record))
    end
  end

  def create(args)
    now = Time.now
    rom.commands(:sql).Insert.from(:books).call(
      title: args[:title], author: args[:author],
      created_at: now, updated_at: now,
    )
    get(id: ... )
  end

  def update(id:, args)
    rom.commands(:sql).Update.from(:books).where(id: id).call(
      title: args[:title], author: args[:author], updated_at: Time.now,
    )
    get(id: id)
  end

  def delete(id:)
    rom.commands(:sql).Update.from(:books).where(id: id).call
  end
end
```

Note: **timestamps are set explicitly** (`created_at`/`updated_at = Time.now`).
ROM has no save callbacks.

### structs — record + business logic

```ruby
# app/structs/book.rb
class Book < Struct # Hanami's immutable value object
  attributes :id, :title, :author, :created_at, :updated_at

  # any old model instance methods live here:
  # def to_s; title; end
  # def full_citation; "#{author}, #{title}"; end
end
```

A struct is immutable. You cannot call `struct.save`; you call `Repo.update`.
A struct may be built from a ROM record: `Structs::Book.new(record)`.

---

## Controllers → Actions

```ruby
# Rails
def index
  @books = Book.all
end
def create
  @book = Book.new(book_params)
  if @book.save
    redirect_to @book, notice: "..."
  else
    render :new, status: :unprocessable_entity
  end
end
def set_book
  @book = Book.find(params.expect(:id))
end
def book_params
  params.expect(book: [:title, :author])
end

# Hanami — app/actions/books/index.rb
class Index < Action
  include Dry::Monads[:result]
  params do
    required(:q).filled?(String, optional: true)
  end

  def call(request, response)
    books = deps.books_repo.all
    response.render(Books::Views::Index, books: books, current_user: response[:current_user])
  end
end

# app/actions/books/create.rb
class Create < Action
  params do
    required(:title).filled?(String)
    optional(:author).filled?(String).default("")
  end
  def call(request, response)
    case (result = deps.books_repo.create(params))
    in Success(result)
      response.redirect_to(routes.book(id: result.id),
                           flash: { notice: "Book was successfully created." })
    in Failure(result)
      response.status = :unprocessable_entity
      response.render(Books::Views::New, book: result, flash: nil,
                      current_user: response[:current_user])
    end
  end
end
```

Key changes:
- No `@ivars`. Data flows: action → `response.render(View, ...)` → template.
- `params.expect(...)` → dry-`params` contract block (`required`/`optional`).
- `redirect_to @book, notice:` → `response.redirect_to(routes.book(id:), flash: {...})`.
- `render :new, status: :unprocessable_entity` →
  `response.status = :unprocessable_entity; response.render(View, ...)`.
- `set_book` / strong params → explicit `deps.books_repo.get(id: params[:id])`
  + params contract.

---

## ApplicationController → base Action

```ruby
# app/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!   # devise
  helper_method :current_user
end

# app/action.rb
module OrcidPrinceton # (or Bookshelf)
  class Action < Hanami::Action
    # auto_register: false
    include Dry::Monads[:result]

    # shared before-hook; in Hanami this is explicit composition, e.g.:
    # def before
    #   result = deps.auth.authenticate
    #   in Success(user) -> response[:current_user] = user; true
    #   in Failure      -> response.redirect_to(routes.session_new); ...
    # end

    def call(request, response); end
  end
end
```

`current_user` becomes a `before`-style hook that puts the user on
`response[:current_user]`; views pull it via `expose :current_user, layout: true`.

---

## Views / Templates

```
# Rails
app/views/books/index.html.erb
app/views/books/_book.html.erb          (partial, rendered inline)
app/views/books/_book.json.jbuilder

# Hanami 3
app/views/books/index.rb                (one View class per action)
app/templates/books/index.html.erb      (the template)
app/templates/books/index.jbuilder      (optional, for JSON via Tilt)
app/templates/application.html.erb      (layout)
```

```ruby
# app/views/books/index.rb
module OrcidPrinceton
  module Books
    module Views
      class Index < View
        expose :routes, :current_user, layout: :application
        expose :books
      end
    end
  end
end
```

```erb
<%# app/templates/books/index.html.erb %>
<h1>Welcome to the Bookshelf</h1>
<%= books.map do |book| %>
  <div class="book">
    <p><strong>Author:</strong> <%= book.author %></p>
    <p><strong>Title:</strong>  <%= book.title %></p>
    <%= link_to "Show", routes.book(id: book.id) %>
  </div>
<% end %>
<%= link_to "New book", routes.new_book, class: "btn btn-primary" %>
```

Rules:
- One `View` per action; `expose :x` declares which action data the template
  may read.
- Partial `_book` becomes either a template helper or an inline `.map`/`.each`.
- **JSON without layout**: the base `View#call(format:)` passes `layout: nil`
  when `format: :json` (Jbuilder templates render via Tilt).
- `render book` → just iterate `books` and call the template; no partial magic.

---

## Auth (Devise → middleware + actions per provider)

```
# Rails
devise_for :users                 # routes + controller + ORM integration
sign_in @user                     # in controller
current_user                      # helper
encrypts :token                   # AR encryption

# Hanami
# 1. Middleware in config/app.rb:
use OmniAuth::Builder
use Warden::Manager

# 2. One action per provider/callback:
map "sessions#orcid_create", to: Sessions::OrcidCreate, ...
map "sessions#failure",      to: Sessions::Failure,      ...
map "sessions#destroy",      to: Sessions::Logout,       ...

# 3. current_user -> before hook putting user on response[:current_user],
#    exposed to views via `expose :current_user, layout: true`.

# 4. OmniAuth.config.on_failure routing: hook sends failures to Sessions::Failure.

# 5. AR encryption -> Service::EncryptionHelper wrapped by the repo
#    (encrypt_openssl_token / decrypt_openssl_token around create/update/get).
```

---

## Encryption

```ruby
# Rails
class User < ApplicationRecord
  encrypts :token
end

# Hanami — move into the repo, out of the struct
# app/repos/users.rb
def get(id:)
  record = rom.relations[:users].where(id: id).one
  record[:token] = deps.encryption.decrypt_openssl_token(record[:token])
  Success(Structs::User.new(record))
end
def create(args)
  rom.commands(:sql).Insert.from(:users).call(
    **args,
    token: deps.encryption.encrypt_openssl_token(args[:token]),
  )
end
```

The struct cannot decrypt; the repo owns it.

---

## Migrations / schema

```
# Rails
db/migrate/001_create_user.rb
db/schema.rb

# Hanami 3
config/db/migrate/001_create_users.rb
config/db/structure.sql                     <- ROM/Sequel reads this, NOT schema.rb
config/db/update_rails_migration.sql        <- re-keys schema_migrations version->filename
```

`config/db/update_rails_migration.sql` mutates the existing Postgres
`schema_migrations` table so `version` becomes `filename`.

---

## Rake tasks

```
# Rails
lib/tasks/foo.rake;  rake foo:bar

# Hanami 3
add gem 'hanami/rake_tasks'
lib/tasks/foo.rake   # calls repos / operations, not AR
# invoked via `bin/hanami rake foo:bar`
```

---

## Tests

| Rails | Hanami |
|---|---|
| `FactoryBot` | `ROM::Factory` — `ROM::Factory.configure { |c| c.rom = Hanami.app['db.rom'] }` |
| integration specs | `request` specs — `get routes.book(id: 1)` |
| controller specs | `action` specs — call the action with a fake request/response |
| view specs | `view` specs — render a `View` with exposed data |
| feature/system (Capybara+Selenium) | `system` specs — capybara + Selenium headless Firefox |
| `RSpec::Mocks` | same, plus dry-mock |

---

## Config / env

| Rails | Hanami |
|---|---|
| `RAILS_ENV` / `RAILS_PORT` | `HANAMI_ENV` / `HANAMI_PORT` |
| `config/environments/*.rb` | `config/app.rb` + `config/puma.rb` (reads `HANAMI_*`) |
| `config/routes.rb` (Rails DSL) | `config/routes.rb` (`map ... to:`) |
