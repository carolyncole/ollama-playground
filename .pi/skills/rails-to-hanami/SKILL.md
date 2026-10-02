---
name: rails-to-hanami
description: >-
  Converts a Ruby on Rails MVC application (ActiveRecord models, Devise auth,
  ApplicationController actions, Jbuilder/HAML views, Capistrano/Whenever) into
  an equivalent Hanami 3 + ROM/Sequel + dry-rb application. Use when migrating a
  Rails app to Hanami, when a user asks to "port" or "rewrite" a Rails controller,
  model, or route to Hanami, or when working in the orcid_princeton /
  orcid_princeton_hanami codebase. Provides a component-by-component mapping and a
  step-by-step playbook derived from a real production conversion.
license: MIT
compatibility: Ruby 3.4+, Hanami 3.x, ROM, dry-rb, PostgreSQL
---

# Rails → Hanami Conversion

This skill turns a Rails app into a Hanami 3 application by mapping each Rails
concept onto its Hanami/ROM/dry-rb equivalent, following the order and techniques
used in the real `pulibrary/orcid_princeton` → `pulibrary/orcid_princeton_hanami`
migration.

Read the references linked below as you work. Do not try to hold the whole
conversion in your head at once — go layer by layer.

## Reference material

- [references/mapping.md](references/mapping.md) — the authoritative
  Rails→Hanami translation table: every component (route, controller, model,
  relation, repo, view, template, auth, encryption, rake tasks, config, tests)
  with a before/after snippet.
- [references/step-by-step.md](references/step-by-step.md) — the ordered playbook
  (scaffold → DB → models → auth → actions → views → tests → deploy), derived from
  the actual merged PRs, with the gotchas the team hit.
- [references/examples/](references/examples/) — ready-to-adapt Hanami skeletons
  (db base classes, an action, a relation/repo, an operation, a view).
- [scripts/compare-pr.sh](scripts/compare-pr.sh) — fetch a merge diff from the
  reference repos to see how a specific piece was converted.

## When to use

- "Convert this Rails app to Hanami" / "port `<x>` to Hanami".
- A controller, model, route, or view from a Rails app needs a Hanami equivalent.
- Working inside `orcid_princeton` (Rails) and producing `orcid_princeton_hanami` code.

## How to work

1. Start from the **Hanami skeleton** in `references/examples/` or generate a new
   app with `hanami gen app MyApp` (Hanami 3).
2. Follow `references/step-by-step.md` in order. Do not skip the DB/ROM layer.
3. For each Rails file, look it up in `references/mapping.md` and translate it.
4. Keep a running diff against the Rails original. Use
   `scripts/compare-pr.sh <pr_number>` to check how the real conversion handled a
   component you are unsure about.
5. After each layer, run the equivalent Hanami command and the tests before moving
   on. Hanami has no "it just works" — the DB schema, migrations, and `structure.sql`
   must be right before anything renders.

## Mental model (the important part)

Rails collapses several concerns into a few big gems. Hanami/ROM fans them out:

| Rails (implicit) | Hanami (explicit) |
|---|---|
| `ActiveRecord::Base` model = record + queries + behavior | split into **3 layers**: `app/relations` (ROM schema + associations), `app/repos` (query/CRUD, may return `Dry::Monads` `Result`), `app/structs` (record + business logic) |
| `ApplicationController` + `has_many`/`before_action` | `OrcidPrinceton::Action` base with `before` hooks + `Deps[...]` injection |
| `ActionView` partials + `render` | `OrcidPrinceton::View` per action + `.html.erb`/`.jbuilder` templates under `app/templates` |
| `devise_for` + `sign_in` | OmniAuth strategies in Rack middleware + Warden session + a `create`/`failure`/`destroy` action per provider |
| `encrypts :token` (Active Record encryption) | a `Service::EncryptionHelper` wrapped by the repo (`encrypt_*`/`decrypt_*`) |
| `ActiveRecord` migrations + `db/schema.rb` | Hanami `config/db/migrate/*.rb` + `config/db/structure.sql`; Rails schema converted via `config/db/update_rails_migration.sql` |
| `HealthMonitor::Engine` + provider class | a `Health::Status` action + an `Operations::OrcidApiStatus` dry-operation |
| `rails`/`rake` tasks | `hanami/rake_tasks` + `lib/tasks/*.rake` calling repos/operations |

Everything under `app/` is auto-loaded. Base classes (`app/action.rb`,
`app/view.rb`, `app/operation.rb`, `app/db/`) get `# auto_register: false` because
they are not themselves a route or an injectable dependency.

## Key gotchas (do not reinvent these)

- **`structure.sql`, not `schema.rb`.** Hanami's ROM/Sequel DB expects
  `config/db/structure.sql`. Run `config/db/update_rails_migration.sql` against the
  existing Postgres `schema_migrations` table to re-key `version`→`filename`.
- **Timestamps are manual.** There are no `created_at`/`updated_at` callbacks in
  ROM. Set them explicitly in the repo's `create`/`update` (`attributes[:created_at] = Time.now`).
- **`current_user` becomes a `before` hook** that puts the user on `response[:current_user]`,
  and views get it via `expose :current_user, layout: true`.
- **Encryption moves out of the model into the repo.** The struct can't run
  `decrypt`; the repo does `encrypt_openssl_token`/`decrypt_openssl_token` around
  create/update/get, mirroring `encrypts :token`.
- **Auth is middleware, not a controller.** Register OmniAuth + Warden in
  `config/app.rb`, and each provider gets a `session#create_*` / `session#failure`
  action. The failure hook on `OmniAuth.config.on_failure` routes provider failures
  to the right action.
- **No `render`/`redirect_to path`.** Actions take `(request, response)`; use
  `response.redirect_to(routes.path(:named_route, ...))` and `response.flash[:notice] =`.
- **Views render JSON without a layout** — the base `View#call(format:)` passes
  `layout: nil` for `format: :json` (Jbuilder via Tilt).
- **Tests:** FactoryBot → ROM::Factory (`ROM::Factory.configure { |c| c.rom = Hanami.app['db.rom'] }`).
  Spec types `request`, `action`, `view`, `system` instead of `integration`/`controller`/`feature`.
  System specs use Capybara + Selenium headless Firefox.
- **Env is `HANAMI_*`** (`HANAMI_ENV`, `HANAMI_PORT`). Puma config reads these.

## Verify

After migrating a piece:

- `bundle exec rspec` — full suite (system specs are headless).
- `bundle exec hanami console` — boot check.
- `bundle exec rubocop` — the repo uses omakase config.
- For the bookshelf-style app: run the project's `bin/ci` order
  (rubocop → bundler-audit → importmap/brakeman as configured).

## Reference repos

- Rails original: https://github.com/pulibrary/orcid_princeton
- Hanami target (full conversion PR history):
  https://github.com/pulibrary/orcid_princeton_hanami

Fetch any merge diff with:
```
scripts/compare-pr.sh <pr_number>            # from the hanami repo
scripts/compare-pr.sh <pr_number> rails      # from the rails repo
```
Notable early PRs that establish the pattern: #8 (User model + ROM + migration
converter), #20 (Token model + repo encryption), #22 (guarded report action),
#23 (OmniAuth ORCID callback), #27 (user show), #30 (Jbuilder+Tilt), #60 (logout).
