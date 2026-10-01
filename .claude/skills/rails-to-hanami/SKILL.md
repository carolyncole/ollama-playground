---
name: rails-to-hanami
description: Guides converting a Ruby on Rails application (or any Rails-shaped codebase) to Hanami 2.x — models to relations/repos/structs, controllers to actions, ERB views to Hanami views/templates, Devise/OmniAuth to Warden+OmniAuth, ActiveRecord migrations to ROM migrations, and Rails service objects to dry-operation. Use this whenever the user asks to port, migrate, or rewrite a Rails app (or a slice of one — a model, a controller, an auth flow) to Hanami, asks how a specific Rails concept (a model, a controller action, a rake task, jbuilder JSON, Devise, rolify/roles, Capistrano deploy) maps onto Hanami, or is actively working inside a Hanami app that started life as a Rails port and needs the next Rails feature ported over. Also trigger if the user mentions Hanami alongside ActiveRecord, dry-operation, dry-monads, ROM/Sequel relations, or asks to set up a Hanami action/view/operation from scratch in a Rails-migration context.
---

# Rails → Hanami conversion

Patterns here are distilled from a real, completed migration — `pulibrary/orcid_princeton` (Rails 7/8, Devise, ActiveRecord, Postgres) ported PR-by-PR to `pulibrary/orcid_princeton_hanami` (Hanami 2.x, ROM/Sequel, Warden+OmniAuth, dry-operation) — not from Hanami's docs in the abstract. Every pattern below is what that team actually shipped, including the parts they got wrong on the first try and fixed in a follow-up PR. Lean on that: it tells you not just the target shape but the safe order to build it in.

Read `references/layer-mapping.md` before touching code for any specific layer (models, actions, auth, JSON, rake, deploy, service objects) — it has concrete before/after snippets for each. Read `references/sequencing-checklist.md` before planning the overall migration — it has the phase order that worked and the specific mistakes to skip past instead of repeating.

## The core mental shift

Rails is "fat model, fat-ish controller." Hanami is six thin layers, each with one job:

```
relation (schema)  →  repo (queries/commands)  →  struct (pure logic on attributes)
                                                         ↓
                         operation (fallible business logic, Success/Failure)
                                                         ↓
                    action (HTTP: params, auth, call collaborators, render/redirect)
                                                         ↓
                         view (presenter: exposes data to the template)
                                                         ↓
                              template (still ERB — this barely changes)
```

One Rails `User < ApplicationRecord` becomes **four** Hanami files (relation + repo + struct + migration). One Rails `UsersController` with several actions becomes **one class per action** (`Actions::User::Show`, `Actions::User::ValidateTokens`, ...), not one big class with several methods. Don't try to preserve Rails' file:class ratio — expect more, smaller files.

## Before starting: assess what you're porting

Ask (or infer from the repo) which of these apply, since they change the plan:
- Is this a full-app port, or one slice (e.g. "port just the auth flow" or "port the User model")? Reference files cover both; don't run the full sequencing checklist for a single-model port.
- What does the Rails app use for auth? Devise+OmniAuth ports differently than a plain session-based login (see `layer-mapping.md` §4).
- Does it use `rolify`/CanCan/Pundit for authorization? There's a much simpler direct pattern that replaces all three (§5).
- Any endpoints serving both HTML and JSON (jbuilder)? There's a specific Tilt-based trick for this — don't rewrite the jbuilder templates (§6).
- Rake tasks, Capistrano deploy — these port with far less change than the app layer itself; don't over-invest time here relative to the model/action/view work (§8, §11).

## Migration order (short version — see the checklist file for the full rationale)

1. Skeleton: CI, linting, an empty Hanami app deployed through the same pipeline as Rails.
2. Static, no-DB, no-auth pages (a health check, a version/about page) — proves the action→operation→view→template plumbing end to end before the database is involved.
3. The one core DB model everything else hangs off of: relation + repo + struct + migrations (same migration filenames/timestamps as Rails, translated to ROM syntax).
4. Shared UI chrome (header/footer/layout) — needed early since most later specs render through it.
5. Associated models (roles, tokens, etc.), each as its own small change once the core model is solid.
6. Authentication (Warden + OmniAuth), then authorization (a struct boolean + a reusable `before` hook).
7. The primary user-facing feature, in whichever formats Rails served it (HTML, JSON, CSV...).
8. Supporting actions, rake tasks, deployment config.
9. A hardening pass: idempotency on anything rake-driven, consistency cleanup on Success/Failure pattern matching once several operations exist. This is real, expected work — budget for it, don't treat "it's ported" as "it's done."

Don't try to make every layer perfect on the first PR for a given feature. The source migration's own history shows `current_user` logic landing in the wrong layer and getting moved one PR later, naive `if x.is_a? Success` becoming `case/in Success` once the idiom stabilized, and a rake-file location getting corrected two PRs after it was first added. Ship the simplest working version of a layer, then follow up — that's the pattern that actually happened, not a hypothetical ideal.

## Quick-reference layer mapping

| Rails | Hanami | Detail |
|---|---|---|
| `app/models/foo.rb` (ActiveRecord) | `app/relations/foos.rb` + `app/repos/foo_repo.rb` + `app/structs/foo.rb` | §2 |
| `app/controllers/foos_controller.rb` | `app/actions/foo/<verb>.rb`, one class per action | §3 |
| Devise / `omniauth-cas` | Warden + OmniAuth wired directly in `config/app.rb`, no Devise | §4 |
| `rolify` / CanCan / Pundit | two relations (`roles`, `join_table`) + a struct boolean + a `before` hook | §5 |
| `*.json.jbuilder` | same jbuilder templates, registered with Tilt for the `:json` format | §6 |
| `app/views/**/*.html.erb` + helpers | `app/templates/**/*.html.erb` (same ERB) + `app/views/**/*.rb` presenter with `expose` | §7 |
| `lib/tasks/*.rake` | same path, same namespaces; bodies call repos/operations instead of AR | §8 |
| `spec/models`, `spec/controllers` | `spec/structs`, `spec/repos`, `spec/operations`, `spec/actions`, `spec/views` | §9 |
| `app/services/*.rb` | `app/operations/*.rb` if it can fail (Success/Failure), `app/service/*.rb` (singular) if it can't | §10, §12 |
| Capistrano | same `Capfile`/`config/deploy*.rb`, only asset-compile command + deploy hooks change | §11 |
| `db/migrate/*.rb` (`ActiveRecord::Migration`) | `config/db/migrate/*.rb` (`ROM::SQL.migration do ... end`) | §2 |

Section numbers above refer to `references/layer-mapping.md`.

## Testing note (easy to miss)

Rails gives you free transactional test isolation. Hanami/ROM does not — wire `database_cleaner-sequel` yourself (`spec/support/db/cleaning.rb` in the reference migration) or every `:db`-tagged spec will leak state into the next one. Do this when you set up the Hanami app's spec suite, not after you've already written fifty specs that pass in isolation but fail in combination.

If the Rails app has an existing RSpec system-test suite (Capybara), the fastest path is: copy those spec files into the Hanami app's `spec/system/` almost unchanged, mark every example `pending` with a note on what Hanami layer is missing, then un-pend each one as you build that layer. This gives you a literal checklist of "is the port done yet" instead of having to reconstruct test coverage from scratch.
