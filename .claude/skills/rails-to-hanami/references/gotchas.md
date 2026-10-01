# Rails → Hanami idiom crib sheet

Quick lookup when a ported spec or view fails for what looks like a syntax/idiom
mismatch rather than a logic bug. Each row is "what Rails does" → "what Hanami does
instead", plus the *why* so you can recognize variants not listed here.

| Rails idiom | Hanami equivalent | Why |
|---|---|---|
| `Model.create(attrs)` / `.save` / `.update` / `.destroy` | `repo.create(attrs)` / `repo.update(id, attrs)` / `repo.delete(id)` via a `changeset` | No ActiveRecord. Repos wrap rom-rb relations; all writes go through `relation.changeset(:create/:update/:delete, ...).commit`. |
| `Model.find(id)` | `repo.get(id)` (`relation.by_pk(id).one!`) | Same reason — no `find` class method exists. |
| `Model.last` | `repo.last` | Same. |
| `model.reload` | `model = repo.get(model.id)` | Hanami structs returned from repos are immutable value objects, not mutable AR instances — there's nothing to reload in place, you re-fetch. |
| `change(Model, :count)` (RSpec) | `change { repo.count }` | No AR class to introspect a `.count` method on; use a block that calls the repo. |
| `<model>_path`, `edit_<model>_path`, `<resource>_path`, `new_<model>_path` | `routes.path(:<model>, id: ...)`, `routes.path(:edit_<model>, id: ...)`, `routes.path(:<resource>)`, `routes.path(:new_<model>)` | Hanami has no generated path-helper methods; `routes.path(:name, **params)` is the one mechanism, named after the route in `config/routes.rb`. |
| `button_to "Destroy", model, method: :delete` | `form_for :model, routes.path(:model, id: ...), method: :delete do \|f\| ... end` with `f.submit` | Hanami has no `button_to` helper. |
| `form_with(model: model) do \|form\| ... end` | `form_for :model, routes.path(...), method: "POST"/"PATCH" do \|form\| ... end` | Different form-builder API; `form_for` needs an explicit path and method rather than inferring them from a model instance. |
| Form field ids: `book_title`, `book_author` | `book-title`, `book-author` | Hanami's form builder joins nested param names with `-`, not `_`. Any spec selector (`find("#book_title")`, `fill_in "book_title"`) needs updating. |
| `notice` / `alert` (flash helpers in views) | `flash[:notice]` / `flash[:alert]` | Hanami templates read flash explicitly via the `flash` object rather than Rails' implicit view-local `notice`/`alert`. |
| `redirect_to model, notice: "..."` | `response.redirect_to routes.path(:model, id: ...)` then `response.flash[:notice] = "..."` | Two explicit steps instead of one Rails call. |
| `@book` (controller ivar read in view) | `book` (local exposed via `expose`) | Hanami views declare `expose :book do ... end`; there's no implicit controller-ivar-to-view bridge, so ported templates need `@book` → `book`. |
| `dom_id(book)` | `book.dom_id` (method added to the generated struct) | No `dom_id` helper ships with Hanami structs; add the method yourself on the struct if templates need it. |
| `<%= csp_meta_tag %>` | *(delete — no equivalent needed)* | Hanami ships a secure default CSP; there's no per-page opt-in tag because it's not opt-in. |
| `<%= csrf_meta_tags %>` | `<%= csrf_meta_tags&.html_safe %>` | Same helper name, but Hanami's version can return `nil` in some contexts, so guard with `&.`. |
| `stylesheet_link_tag :app, ...` + `javascript_importmap_tags` | `stylesheet_tag "app", ...` | Hanami's default asset pipeline isn't importmap-based; there's no JS tag to emit unless a separate JS bundler is wired up. |
| Manual `<link rel="icon" ...>` x3 | `<%= favicon_tag %>` | One helper replaces the multiple manual Rails icon `<link>` tags. |
| Cookie sessions "just work" | Must declare `config.actions.sessions = :cookie, { key:, secret:, expire_after: }` in `config/app.rb`, plus a `setting :session_secret` in `config/settings.rb` | Hanami doesn't enable sessions by default; flash depends on sessions, so no flash without this. |
| `hanami generate action <resource>.<verb>` without flags | Pass `--skip-route` (route already exists from `resources :x`) and `--skip-tests` (specs are ported wholesale, not generated) | Avoids generating duplicate routes or throwaway spec stubs during a port. |
