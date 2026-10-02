# Rails → Hanami: ordered playbook

Derived from the actual merged PRs of `pulibrary/orcid_princeton` →
`pulibrary/orcid_princeton_hanami`, condensed to the layer-by-layer order the
team used. Do **not** skip the DB layer — nothing renders until `structure.sql`
and migrations are right.

Run `../scripts/compare-pr.sh <n>` (and `<n> rails` for the Rails side) to see
how a specific step was actually done. Notable PRs:

- #8  User model + ROM + migration converter
- #20 Token model + repo-side encryption
- #22 a guarded report action
- #23 OmniAuth ORCID callback
- #27 user show
- #30 Jbuilder + Tilt (JSON views)
- #60 logout / session destroy

---

## 0. Bootstrap the target

```bash
gem install hanami
hanami gen app MyApp            # Hanami 3 skeleton
# add: rom, rom-rsql/rom-sql, dry-*, dry-rb; rom-factory; rack-test
# add: hanami/rake_tasks if you have rake tasks
```

Base classes `app/action.rb`, `app/view.rb`, `app/operation.rb`, `app/db.rb` get
`# auto_register: false`.

## 1. DB / ROM layer first

1. Convert `db/schema.rb` → `config/db/structure.sql` (Postgres DDL).
2. Convert each `db/migrate/*` into `config/db/migrate/*` in ROM/Sequel terms
   (or keep raw SQL DDL if the converter isn't ready).
3. Run `config/db/update_rails_migration.sql` against the live Postgres
   `schema_migrations` table to re-key `version` → `filename`.
4. Configure `app/db.rb` (ROM + ROM::SQL or Sequel + ROM). Point it at `structure.sql`.
5. Boot check: `bundle exec hanami console` — confirm `db.rom` is available.

> Gotcha: ROM/Sequel expect `structure.sql`, **not** `schema.rb`. If you load
> `schema.rb` you will get load errors at boot.

## 2. Relations + Structs

For each AR model:
- `app/relations/<name>.rb` — ROM schema (columns + types + primary key) and any
  associations (Sequels `OneToMany`, or a hand-written associations map).
- `app/structs/<name>.rb` — immutable record (value object) + any old model
  instance methods.
- If the model had `encrypts :col`, **do not put encryption on the struct**; it
  goes in the repo (step 3 / #20).

## 3. Repos

For each model, an `app/repos/<name>s.rb`:
- `all`, `get(id:)`, `create(args)`, `update(id:, args)`, `delete(id:)`.
- Return `Dry::Monads::Result` (`Success`/`Failure` with typed errors like
  `BookNotFound`).
- **Set timestamps explicitly**: `created_at`/`updated_at = Time.now` — ROM has
  no callbacks.
- Wrap `encrypt_*`/`decrypt_*` around create/update/get for encrypted columns.

## 4. Auth

1. Register OmniAuth + Warden in `config/app.rb`.
2. `OmniAuth.config.on_failure` routes provider failures to a `Sessions::Failure`.
3. One action per provider/callback: `Sessions::OrcidCreate` (success),
   `Sessions::Failure`, `Sessions::Logout` (`#destroy`).
4. `current_user` = a `before`-style hook putting the user on
   `response[:current_user]`.
5. Views expose it: `expose :current_user, layout: true`.

## 5. Actions

For each controller action:
- `params` contract (dry) replaces `strong params` / `params.expect`.
- Pull data via `deps.<repo>.<method>`; no `@ivars`.
- `redirect_to x, notice:` → `response.redirect_to(routes.x, flash: { notice: ... })`.
- `render :view, status: :unprocessable_entity` →
  `response.status = :unprocessable_entity; response.render(View, ...)`.
- Before-action guards (`set_book`) → explicit repo call + failure handling that
  redirects/re-renders.

## 6. Views + templates

- One `View` per action under `app/views/`; templates under `app/templates/`.
- `expose :foo` for each datum the template reads.
- Inline partials: `render book` → iterate + template; or a template partial
  included explicitly.
- JSON: add a `.jbuilder` template; base `View#call(format:)` passes
  `layout: nil` when `format: :json`.

## 7. Routes

Translate `resources :x` → six `map` lines (index/show/new/create/edit/update/
destroy) with `as:` names matching the old helpers. `devise_for` → the session
actions from step 4.

## 8. Tests

- `ROM::Factory.configure { |c| c.rom = Hanami.app['db.rom'] }` replaces
  FactoryBot.
- Convert spec types: `feature` → `system` (Capybara + Selenium headless
  Firefox), `spec/integration` → `request`, `spec/requests`/controller →
  `action`, view specs → `view`.
- Keep transactional fixtures on.

## 9. Rake tasks / config

- `hanami/rake_tasks`; rewrite `lib/tasks/*.rake` to call repos/operations, not
  AR.
- Switch env reads to `HANAMI_*` (Puma, config). `config.ru` →
  `use Hanami.app`.

## 10. Verify per layer

After **each** layer (do not batch):
- `bundle exec rspec` (system specs headless)
- `bundle exec hanami console` — boot check
- `bundle exec rubocop` (omakase config)
- For the bookshelf app specifically: the project's `bin/ci` order
  (rubocop → bundler-audit → importmap audit → brakeman; brakeman exits on
  warn, so every warning blocks).

---

## Gotchas index

- **structure.sql not schema.rb.**
- **Timestamps are manual** (`Time.now` in the repo).
- **current_user is a before hook**, exposed to views via `layout: true`.
- **Encryption is a repo responsibility**, not the struct.
- **Auth = middleware + one action per provider**, not a controller.
- **No `render`/`redirect_to path`.** Actions take `(request, response)`.
- **JSON views render without a layout.**
- **Env is `HANAMI_*`.**
