---
name: rails-to-hanami
description: Step-by-step procedure for porting a Rails MVC resource or whole app to Hanami 2.x (dry-rb/rom-rb repos, dry-validation params, ERB templates/actions). Covers bootstrapping the Hanami app, wiring the existing Rails sqlite database in, generating relations/repos/routes/actions, porting Rails views and system specs over (with the exact idiom fixes Hanami needs), porting the layout, and wiring each CRUD action. Use this whenever the user wants to migrate, port, or convert a Rails app/controller/resource to Hanami, is running `hanami generate` commands to mirror Rails code, is stuck on a ported RSpec system spec failing only in Hanami, or asks about Hanami equivalents for Rails idioms (path helpers, `form_with`, `.reload`, `change(Model, :count)`, CSP/importmap tags, form field ids). Also trigger on generic "how do I do X the Hanami way" questions once a Rails app is already in play, since this skill's gotchas reference (`references/gotchas.md`) is the fastest path to the answer.
---

# Rails → Hanami conversion

Hanami 2.x is not Rails with different names — it has no ActiveRecord, no implicit
instance-variable-to-view leakage, and a default-secure CSP. Every phase below exists
because something Rails does implicitly has to become explicit in Hanami. Work through
the phases in order: each one depends on the Hanami app booting and the previous
generators having run.

Throughout, substitute the project's real names for these placeholders:

| Placeholder | Meaning | Worked example |
|---|---|---|
| `APP` | Hanami app/slice module name | `Bookshelf` |
| `hanami_app` | Hanami app directory name passed to `hanami new` | `bookshelf` |
| `resource` | plural resource / table / route name | `books` |
| `model` | singular resource name used in repo/struct generators | `book` |
| `Model` | Rails model class name | `Book` |

`references/book-example.md` has this entire flow already worked through end-to-end for
a `Book`/`books` resource — read it when you want to see concrete file contents rather
than the generalized instructions below. `references/gotchas.md` is a quick
Rails-idiom → Hanami-idiom crib sheet; consult it any time a ported spec fails for a
reason that looks like a syntax/idiom mismatch rather than a logic bug.

## Phase 0 — Confirm the environment

This workshop repo runs both apps inside one Docker container with the Rails app and
Hanami app as sibling directories (e.g. `rails_bookshelf/` and `hanami_app/`), so Hanami
can read the Rails sqlite files by relative path. Check `AGENTS.md` / `docker-files` for
the exact container name and port mapping before running commands — don't assume
`docker exec -it <container>` without checking what the container is actually called in
this repo, and don't invent a container name.

## Phase 1 — Bootstrap the Hanami app

```
hanami new <hanami_app>
cd <hanami_app>
bundle install
npm install
bundle exec hanami assets compile
bundle exec hanami dev
```

Confirm the app boots at its dev port before moving on — every later phase assumes a
working Hanami process to restart.

## Phase 2 — Wire in the existing database

Hanami has no migrations-from-Rails story, so the fastest path for a port is to seed the
Rails database and hand the same sqlite file to Hanami directly:

```
# from the Rails app
bundle exec rails db:seed

# copy the sqlite files into Hanami's db/
cp <rails_app>/storage/development.sqlite3 <hanami_app>/db/
cp <rails_app>/storage/test.sqlite3 <hanami_app>/db/
```

Then point Hanami's `.env` at it:

```
DATABASE_URL=sqlite://db/development.sqlite3
```

Verify with `bundle exec hanami console` and inspect a repo once Phase 3 has generated
one.

## Phase 3 — Generate the relation and repo, add the CRUD interface

```
bundle exec hanami generate relation <resource>
bundle exec hanami generate repo <model>
```

Hanami repos wrap rom-rb relations and use **changesets**, not ActiveRecord-style
`.save`/`.update`/`.destroy`. Add the interface your actions will need directly to
`app/repos/<model>_repo.rb` — this is the one place ActiveRecord-shaped calls
(`Model.create`, `Model.find`, `Model.last`, `model.update`, `model.destroy`) get
translated into rom-rb once, so every action and spec downstream can call plain Ruby
methods instead of relearning the changeset API:

```ruby
def all = <resource>.to_a
def count = <resource>.count
def last = <resource>.last
def get(id) = <resource>.by_pk(id).one!

def create(attributes)
  attributes[:created_at] = Time.now
  attributes[:updated_at] = Time.now
  <resource>.changeset(:create, attributes).commit
end

def update(id, attributes)
  attributes[:updated_at] = Time.now
  <resource>.by_pk(id).changeset(:update, attributes).commit
end

def delete(id)
  <resource>.by_pk(id).changeset(:delete).commit
end
```

Only add the methods the resource's controller actions actually call — don't pre-build
the full set if, say, there's no `destroy` action for this resource.

## Phase 4 — Routes and actions

```ruby
# config/routes.rb
resources :<resource>
```

```
bundle exec hanami routes   # sanity-check the generated routes match Rails'
bundle exec hanami generate action <resource>.show    --skip-route --skip-tests
bundle exec hanami generate action <resource>.index   --skip-route --skip-tests
bundle exec hanami generate action <resource>.new     --skip-route --skip-tests
bundle exec hanami generate action <resource>.create  --skip-route --skip-tests
bundle exec hanami generate action <resource>.edit    --skip-route --skip-tests
bundle exec hanami generate action <resource>.update  --skip-route --skip-tests
bundle exec hanami generate action <resource>.destroy --skip-route --skip-tests --skip-view
```

`--skip-route` because the route already exists from `resources`; `--skip-tests`
because the Rails system specs will be ported in wholesale in Phase 5 instead;
`destroy` additionally skips the view since it never renders a template.

## Phase 5 — Port views/templates and specs, fix the idioms

```
cp -r <rails_app>/spec/system <hanami_app>/spec/
cp -r <rails_app>/app/views/<resource> <hanami_app>/app/templates/
```

Run the full Hanami spec suite and fix failures **in this order** — each fix tends to
unblock the next failure rather than all needing to happen at once:

1. `require "rails_helper"` → `require "spec_helper"`
2. `<Model>.create(...)` → `APP::Repos::<Model>Repo.new.create(...)` (same for any other
   ActiveRecord-style class method the specs call)
3. `<Model>.last` → `APP::Repos::<Model>Repo.new.last`
4. `change(<Model>, :count)` → `change { APP::Repos::<Model>Repo.new.count }` — Hanami
   has no RSpec `change(Model, :count)` matcher equivalent since there's no AR class to
   introspect
5. `<model>.reload` → re-fetch instead: `<model> = APP::Repos::<Model>Repo.new.get(<model>.id)`
   — Hanami structs are immutable value objects, not mutable AR instances, so "reload"
   isn't a method, it's a new fetch
6. Rails form field ids use underscores (`<model>_<field>`); Hanami's form helpers
   generate ids with dashes (`<model>-<field>`) — update any spec selectors
   (`find("#book_title")` → `find("#book-title")`)
7. Any remaining `@<model>` instance-variable references → local variable `<model>` —
   Hanami views expose data explicitly via `expose`, there's no implicit
   controller-ivar-to-view bridge

See `references/gotchas.md` for the full idiom table with the "why" behind each one.

## Phase 6 — Port the application layout

```
cp <rails_app>/app/views/layouts/application.html.erb <hanami_app>/app/templates/layouts/app.html.erb
cp <rails_app>/app/assets/stylesheets/application.css <hanami_app>/app/assets/css/app.css
```

Then, in the copied layout:

- Drop `<%= csp_meta_tag %>` entirely — Hanami applies a secure CSP by default, so there's
  no Rails-style meta-tag opt-in needed. Keep only `<%= csrf_meta_tags&.html_safe %>`
  (note the `&.` — Hanami's helper can return nil where Rails' never would).
- Replace `stylesheet_link_tag :app, ... ; javascript_importmap_tags` with
  `<%= stylesheet_tag "app", "data-turbo-track": "reload" %>` — Hanami's asset pipeline
  isn't importmap-based, so there's no JS tag to emit unless the app also wires up
  esbuild/webpack assets separately.
- Replace the three manual `<link rel="icon" ...>` tags with `<%= favicon_tag %>`.

If the page breaks after this, re-run `bundle exec hanami assets compile` and restart
`hanami dev` — asset/layout changes need both.

## Phase 7 — Wire each action

Work through `index`, `show`, and `new`/`create` in that order (they build on each
other); leave `destroy` and `edit`/`update` for Phase 8 if the user is doing this as a
learning exercise rather than a straight port.

Common pattern per action:

1. **View** (`app/views/<resource>/<action>.rb`): `include Deps["repos.<model>_repo"]`,
   then `expose` whatever the template needs, fetched through the repo — never through
   the model class directly.
2. **Template**: swap Rails path helpers for `routes.path(:<name>, id: ...)`, swap
   `link_to`/`button_to`/`form_with` targets accordingly (Hanami has no `button_to`; use
   a `form_for ... method: :delete` block instead), and swap `notice`/`alert` for
   `flash[:notice]`/`flash[:alert]`.
3. **Action** (`app/actions/<resource>/<action>.rb`): port the Rails controller's
   `handle`-equivalent logic, add a `params do ... end` block for any validated input,
   call the repo (never the model class) to read/write, and use
   `response.redirect_to routes.path(...)` / `response.flash[...]` in place of Rails'
   `redirect_to`/`flash`.

For `show`, also generate a struct (`bundle exec hanami generate struct <model>`) and
add any view-model-only methods the templates need (e.g. a `dom_id` method), since
Hanami structs don't get Rails' `dom_id` helper for free.

For sessions/flash to work at all, confirm `config/app.rb` has
`config.actions.sessions = :cookie, { key: ..., secret: ..., expire_after: ... }` and
that `config/settings.rb` defines the referenced secret setting — Hanami doesn't enable
cookie sessions by default the way Rails does.

Restart `hanami dev` after every action/view/template change in this phase — Hanami's
autoloading of new action classes doesn't always pick up mid-process for
newly-registered deps.

## Phase 8 — Delete and edit/update: do these as exercises, not handed solutions

If the user is running this as a learning workshop (the framing the source material
uses), **don't just write the delete and edit/update code for them.** Point them at:

- The repo already has `delete`/`update` methods from Phase 3 — the action just needs to
  call them.
- `delete` needs: an integer `id` param (`required(:id).filled(:integer)`), a call to
  `<model>_repo.delete(request.params[:id])`, and a redirect to
  `routes.path(:<resource>)`.
- `edit`/`update` needs the `new`/`create` view+template+action pattern from Phase 7,
  but with the form's submit label, HTTP method, and target path all made
  situational (default to "Create"/`POST`/the index route in `new`, "Update"/`PATCH`/the
  member route in `edit`) so `new.html.erb` and `edit.html.erb` can share one `_form`
  partial.
- The Hanami getting-started guide's "deleting a book" / "updating a book" sections are
  the canonical reference if the user wants to read ahead.

Only write the full implementation if the user explicitly asks for the complete
solution rather than hints — check `references/book-example.md`'s "Exercise hints"
section for the exact hint wording this workshop uses, and offer hints in that same
graduated style (nudge → API shape → still let them assemble it) before jumping to
code.
