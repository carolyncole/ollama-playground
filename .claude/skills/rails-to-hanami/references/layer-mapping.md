# Layer-by-layer mapping, with real before/after code

All snippets below are lightly adapted from an actual completed migration (`pulibrary/orcid_princeton` → `pulibrary/orcid_princeton_hanami`), not invented for illustration. Where a Rails snippet is shown, it's the literal code that was ported; where only Hanami is shown, the Rails equivalent was materially the same shape (e.g. rake task bodies).

## Table of contents
1. Directory structure
2. Models → Relations / Repos / Structs / Migrations
3. Controllers → Actions
4. Authentication (Devise/OmniAuth → Warden/OmniAuth)
5. Authorization (rolify → relations + struct + guard hook)
6. JSON rendering (jbuilder kept, wired through Tilt)
7. Views/templates (ERB kept, view class becomes a presenter)
8. Rake tasks
9. Testing
10. Service objects vs. operations
11. Deployment (Capistrano)
12. The operations/dry-monads idiom in depth

---

## 1. Directory structure

| Rails | Hanami |
|---|---|
| `app/models/*.rb` | `app/relations/*.rb`, `app/repos/*.rb`, `app/structs/*.rb` |
| `app/controllers/**/*.rb` | `app/actions/<resource>/<verb>.rb` |
| `app/views/**/*.html.erb`, `app/helpers/*.rb` | `app/templates/**/*.html.erb`, `app/views/**/*.rb` |
| `config/routes.rb` (resourceful DSL) | `config/routes.rb` (`Hanami::Routes`, every path spelled out explicitly) |
| `db/migrate/*.rb`, `db/schema.rb` | `config/db/migrate/*.rb` (same filenames), `config/db/structure.sql` |
| `lib/tasks/*.rake` | `lib/tasks/*.rake` (same path — see §8 for why not `rakelib/`) |
| `config/initializers/*.rb` | folded into `config/app.rb` (middleware, OmniAuth, CSP) and `config/settings.rb` (`Hanami::Settings` subclass) |
| `config/deploy*.rb`, `Capfile` | same paths, same Capistrano (§11) |
| `spec/models`, `spec/controllers`, `spec/requests` | `spec/structs`, `spec/repos`, `spec/operations`, `spec/actions`, `spec/views`, `spec/requests`, `spec/system` |
| `app/services/*.rb` | `app/service/*.rb` (singular — non-fallible POROs) **or** `app/operations/*.rb` (fallible, Success/Failure) |
| — | `app/action.rb`, `app/view.rb`, `app/operation.rb` — app-wide base classes |
| — | `app/db/relation.rb`, `app/db/repo.rb`, `app/db/struct.rb` — tiny abstract bases to subclass `Hanami::DB::*` once |

If you generated the Hanami app with `hanami new`, these base classes and empty dirs (`.keep` files) already exist — fill them in, don't recreate the scaffold.

---

## 2. Models → Relations / Repos / Structs / Migrations

A Rails model decomposes into four pieces. Introduce them together for the first model; for associated models added later (roles, tokens), each gets its own small PR/commit once the core model is stable.

**Relation** — schema + associations only, no behavior:
```ruby
module OrcidPrinceton
  module Relations
    class Users < OrcidPrinceton::DB::Relation
      schema :users, infer: true do
        associations do
          has_many :users_roles
          has_many :roles, through: :users_roles
        end
      end
    end
  end
end
```

**Repo** — all querying and persistence (this replaces `User.find`/`.create`/`.where` and Rails class methods like `User.from_cas`). ROM does **not** auto-manage `created_at`/`updated_at` — set them by hand in every write method:
```ruby
class UserRepo < OrcidPrinceton::DB::Repo
  def get(id) = user_with_roles_and_tokens.by_pk(id).one!

  def create(attributes)
    attributes[:created_at] = Time.now
    attributes[:updated_at] = Time.now
    users.changeset(:create, attributes).commit
  end

  def update(id, attributes)
    attributes[:updated_at] = Time.now
    users.by_pk(id).changeset(:update, attributes).commit
    get(id)
  end

  def user_with_roles_and_tokens = users.combine(:roles).combine(:tokens)
end
```

**Struct** — the immutable read-only entity the repo returns. Rails instance methods that are pure logic over attributes (no persistence) move here:
```ruby
class User < OrcidPrinceton::DB::Struct
  def admin? = (@admin ||= roles.any? { |role| role.name == 'admin' })
  def tokens_expired? = tokens.all?(&:expired?)
  def valid_token = tokens.reject(&:expired?).first
end
```
Structs are immutable (`Dry::Struct` under the hood) — anything that needs to *save* state belongs in the repo or an operation, never in the struct.

A value object that isn't backed by any DB relation (a report row, a DTO) is still a struct, just a plain `Dry::Struct` rather than `OrcidPrinceton::DB::Struct`:
```ruby
class PeopleSoftRow < Dry::Struct
  attribute :full_name, Types::String
  attribute :university_id, Types::String.optional
end
```

**Migration** — same filename/timestamp as the original Rails migration (keeps history comparable across both codebases), rewritten from `ActiveRecord::Migration` to `ROM::SQL.migration`:
```ruby
# config/db/migrate/20231009181647_create_users.rb
ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id
      column(:uid, String, null: false, index: true, unique: true)
      column(:created_at, :timestamp, null: false)
      column(:updated_at, :timestamp, null: false)
    end
  end
end
```
For a single-column `add_column` migration, write explicit `up`/`down` blocks rather than relying on `change` reversibility:
```ruby
ROM::SQL.migration do
  up   { add_column :users, :email, String }
  down { drop_column :users, :email }
end
```
Join tables (Rails `has_many :through` via a gem like `rolify`) become a third explicit relation with `belongs_to` on both sides — there's no polymorphic-association magic in plain ROM:
```ruby
class UsersRoles < OrcidPrinceton::DB::Relation
  schema :users_roles, infer: true do
    associations do
      belongs_to :user
      belongs_to :role
    end
  end
end
```

---

## 3. Controllers → Actions

Every controller action becomes its own class, `app/actions/<controller>/<action>.rb`, inheriting the app's base `Action`. There's no filter inheritance to manage (`before_action ..., only: [...]`) — each class only includes what it needs:
```ruby
class Show < OrcidPrinceton::Action
  include Deps['repos.user_repo',
               alternative_view: 'views.errors.forbidden',
               valid_view: 'views.user.show']
  before :require_authentication

  params do
    required(:id).value(:string)
  end

  def handle(request, response)
    user_id = request.params[:id].split('.').first.to_i
    if response[:current_user].id == user_id
      response[:user] = user_repo.get(user_id)
      response.render(valid_view, format: response.format)
    else
      response.render(alternative_view)
    end
  end
end
```
Key differences from a Rails controller action:
- **`include Deps[...]`** (dry-system container) makes every collaborator explicit instead of calling `User.find` / a global constant directly.
- **`params do ... end`** is a built-in `dry-schema` validation, replacing Rails strong params.
- **One class per action** means what used to be `before_action :set_user, only: [:show]` is just... the body of the one `handle` method that needs it.
- **`response.render(view, format:)`** is explicit — this is how one action serves multiple formats (§6).

Shared behavior (auth checks, current_user, version info) lives on the app-wide base `Action`, used via `before`:
```ruby
class Action < Hanami::Action
  include Dry::Monads[:result]
  include Deps['repos.user_repo']

  before :current_user
  before :code_version

  def current_user(request, response)
    if warden_session(request)
      response[:current_user] = user_repo.find_by_uid(warden_session(request).user)
    end
  end

  def require_authentication(request, response)
    response.redirect_to '/auth/entra_id' unless warden_session(request)&.user
  end

  def require_admin(_request, response)
    unless response[:current_user]&.admin?
      response.flash[:notice] = 'You are not authorized'
      response.redirect_to routes.path(:root)
    end
  end

  def warden_session(request) = request.env['warden']
end
```

---

## 4. Authentication: Devise/OmniAuth → Warden + OmniAuth by hand

Hanami has no Devise equivalent. The migration wired **Warden** (the middleware Devise itself sits on) plus OmniAuth as plain Rack middleware, with zero controller-level DSL:
```ruby
# config/app.rb
config.middleware.use Warden::Manager
config.middleware.use OmniAuth::Builder do
  provider :orcid, Hanami.app.settings.orcid_client_id, Hanami.app.settings.orcid_client_secret,
           callback_path: Hanami.app.router.path(:orcid_callback)
  provider :entra_id, client_id: Hanami.app.settings.entra_client_id,
                      client_secret: Hanami.app.settings.entra_client_secret,
                      tenant_id: Hanami.app.settings.entra_tenant_id
end
```
The OmniAuth callback action loads/creates the user via an **operation** (§12), sets the Warden session, and redirects:
```ruby
class CreateEntra < OrcidPrinceton::Action
  include Deps['repos.user_repo']

  def handle(request, response)
    auth_hash = request.env['omniauth.auth']
    return notify_missing_hash(response) if auth_hash.nil?
    authenticate_entra_user(auth_hash, request, response)
  end

  private

  def authenticate_entra_user(auth_hash, request, response)
    user = user_repo.from_entra_id(auth_hash)
    user.nil? ? handle_error(response) : handle_user(user, request, response)
  rescue StandardError => e
    Honeybadger.notify(e, context: { auth_hash: auth_hash.to_h })
    handle_error(response)
  end

  def handle_user(user, request, response)
    warden_session(request).set_user user.uid
    response.flash[:notice] = 'You were successfully authenticated'
    response.redirect_to request.session[:login_redirect_url] || routes.path(:root)
  end
end
```
Logout is direct, no Devise `destroy_user_session`:
```ruby
class Destroy < OrcidPrinceton::Action
  def handle(request, response)
    warden_session(request)&.logout(:default) if warden_session(request)&.user
    response.redirect_to routes.path(:root)
  end
end
```
"Login" is often just a link to the OmniAuth middleware path (`/auth/entra_id`) — you may not need a `session/new` action at all if there's no local login form, only SSO.

**Mistake to skip, not repeat**: an early cut of this migration put the `current_user` lookup in the View `Context` class, keyed off a value stashed in the session, and re-looked-it-up from the repo on every template render. That was wrong — it means the view layer talks to the database. The fix: do the lookup exactly once, in a `before :current_user` hook on the base `Action`, and hand the already-loaded struct to the view via `expose`/`response[:current_user]`. Do it this way from the start.

**Supporting two auth backends at once** (e.g. legacy CAS during a transition to SSO/OIDC): don't branch inside one method. Give each backend its own operation subclass overriding just the attribute-extraction step (see §12's `UserFromEntraAttributes < UserFromAttributes`), and wire both providers into the same OmniAuth middleware block above.

Test support: `Warden::Test::Helpers`/`Mock` in `spec/support/warden.rb` gives you `login_as user.uid` in specs, replacing Devise's `sign_in` test helper.

---

## 5. Authorization: rolify/CanCan/Pundit → two relations + a struct boolean + a guard hook

No role/authorization gem needed. Two plain relations (a `roles` table and a `users_roles` join table, §2) plus one struct method:
```ruby
def admin? = (@admin ||= roles.any? { |role| role.name == 'admin' })
```
plus one reusable `before` hook on the base Action (shown in §3) used as:
```ruby
before :require_authentication
before :require_admin
```
That's the entire authorization system for a binary admin/non-admin app. If you need more roles than "admin", extend the struct method and the relation query, not a new gem.

Rake tasks manage grants, ported near-verbatim from Rails (same task names, same `desc` strings — only the bodies change from AR calls to repo calls):
```ruby
task create_admin_users: :environment do
  OrcidPrinceton::Repos::UserRepo.new.create_default_users
end

task reset_default: :environment do
  users = OrcidPrinceton::Repos::UserRepo.new
  users.delete_all_roles
  users.create_default_users
end
```
Make `make_admin`/grant logic idempotent from the start (check `return user if user.admin?` before granting) — the reference migration had to fix this in a follow-up PR after shipping a version that re-added the role on every run.

---

## 6. JSON rendering: keep jbuilder, wire it through Tilt

Don't rewrite `.json.jbuilder` templates — register jbuilder as a Tilt engine for Hanami's `:json` format and reuse them as-is:
```ruby
# app/view.rb
require 'tilt/jbuilder'
Tilt.register Tilt[:jbuilder], :json

class View < Hanami::View
  # Disables layout when rendering with format: :json
  def call(format: :html, **options)
    format == :json ? super(**options, format:, layout: nil) : super
  end
end
```
```ruby
# app/templates/user/show.json.jbuilder — identical to the Rails source file
json.extract! user, :id, :uid, :provider, :orcid, :given_name, :family_name, :display_name, :created_at, :updated_at
json.url user_url(user, format: :json)
```
One action serves both formats by declaring accepted formats and sniffing the requested one:
```ruby
config.formats.accept :html, :json
before :set_format_for_json_extension

def handle(request, response)
  response[:user] = user_repo.get(user_id)
  response.render(valid_view, format: response.format)
end

private

def set_format_for_json_extension(request, response)
  response.format = :json if request.params[:id].to_s.end_with?('.json')
end
```
and the route just adds a second path to the same action:
```ruby
get '/users/:id', to: 'user.show', as: :user
get '/users/:id.json', to: 'user.show', as: :user_json
```

---

## 7. Views/templates: ERB stays, the "View" class becomes a presenter

Templates keep their `.html.erb` syntax essentially verbatim — copy Rails partials into `app/templates/**` with minimal changes (shared header/footer/layout chrome is close to copy-paste). What changes is how data reaches the template:
```ruby
class Show < OrcidPrinceton::View
  expose :user

  expose :orcid_url do |user|
    Hanami.app.settings.orcid_sandbox ? "https://sandbox.orcid.org/#{user.orcid}" : "https://orcid.org/#{user.orcid}"
  end

  expose :display_name do |user|
    user.admin? ? "#{user.display_name} (Administrator)" : user.display_name
  end
end
```
This is a direct replacement for a Rails helper method (`UsersHelper#display_name_for`) — the logic moves from a shared helper module into an `expose` block scoped to the one view that needs it. Use `expose :name, layout: true` for anything the shared layout itself needs (current_user, flash, nav state).

`app/views/context.rb` (`Hanami::View::Context` subclass) is available for logic every template needs regardless of which View rendered it — but keep it to pure, side-effect-free helpers. Don't put repo/DB lookups there (see the `current_user` mistake in §4); prefer `expose` on the specific View class.

---

## 8. Rake tasks

Task namespaces, names, and `desc` strings port essentially unchanged. Only the bodies change — AR calls become repo/operation calls, and anything that can fail gets Success/Failure handling instead of relying on exceptions:
```ruby
# lib/tasks/people_soft.rake
namespace :people_soft do
  desc 'Saves a CSV report for PeopleSoft'
  task :report, [:filename] => [:environment] do |_, args|
    report = OrcidPrinceton::Operations::PeopleSoftReport.new
    case report.call(args[:filename])
    in Dry::Monads::Result::Success(path)
      puts "ORCID report was created at #{path}"
    in Dry::Monads::Result::Failure(error)
      puts "ERROR:  Could not generate ORCID Report: #{error}"
    end
  end
end
```
Put task files directly at `lib/tasks/*.rake`, same as Rails — not at `rakelib/*.rake` (plain Rake's own default convention). The reference migration tried `rakelib/` first and moved the files to `lib/tasks/` in an immediate follow-up commit once it was clear that's "the usual location" for this team's other apps. Skip that detour.

Require `hanami/setup` at the top of each rake file instead of relying on an automatic Rails-style environment load:
```ruby
require 'hanami/setup'
namespace :users do
  ...
end
```

---

## 9. Testing

- The Rails app's RSpec system specs (`spec/system/*_spec.rb`, Capybara/Selenium) port over with very little change — the assertions and user-flow steps stay the same; only factory/login helper calls change.
- New spec directories that don't exist in Rails, one per new architectural layer: `spec/repos`, `spec/structs`, `spec/operations` (in addition to `spec/actions`, `spec/views`, `spec/requests`, `spec/system`, which map fairly directly to Rails' controller/request/system specs).
- **rom-factory** replaces FactoryBot — syntax is deliberately similar:
  ```ruby
  Factory.define(:user) do |f|
    f.provider { 'cas' }
    f.given_name { FFaker::Name.first_name }
  end
  ```
- `Warden::Test::Helpers`/`Mock`, wired in `spec/support/warden.rb`, gives you `login_as user.uid` — the replacement for Devise's `sign_in` test helper.
- **Hanami/ROM gives you no free transactional test isolation.** Rails' "transactional fixtures are on by default" safety net does not exist here — wire `database_cleaner-sequel` explicitly against every ROM gateway/slice:
  ```ruby
  RSpec.configure do |config|
    config.before(:each, :db) { all_databases.each { |db| DatabaseCleaner[:sequel, db:].clean_with(:truncation, except: ['schema_migrations']) } }
    config.after(:each, :db)  { all_databases.each { |db| DatabaseCleaner[:sequel, db:].clean } }
  end
  ```
  Set this up when you scaffold the spec suite, not after specs start leaking state into each other.
- Headless-browser config (Firefox/Chrome via Selenium) and a retry shim for flaky JS specs are both worth setting up early — real-browser system tests are exactly as flaky in Hanami as they were in Rails:
  ```ruby
  RSpec.configure do |config|
    config.around(:each, :js) { |ex| ex.run_with_retry retry: 3 }
  end
  ```
- **Recommended workflow**: copy the Rails system-test files into the Hanami app's `spec/system/` near-verbatim, `pending` every example with a one-line note on what Hanami layer is missing (`pending 'We have a user show'`), then un-pend each one as its corresponding layer (struct → repo → operation → action → view) gets built. This gives you a literal, runnable checklist of migration progress instead of a vague sense of "mostly done."

---

## 10. Service objects vs. operations — where plain Ruby classes go

- If a Rails "service object" / PORO class **can fail** in a meaningful way (network call, missing data, validation) → `app/operations/*.rb`, subclassing the app's `Operation < Dry::Operation` base, returning `Success`/`Failure` (§12). Examples from the reference migration: a report generator, an external API health check, a token-validation workflow.
- If it **cannot fail** (reads local files/git metadata, pure computation, encryption helper) → `app/service/*.rb` (note: **singular** `service`, unlike the plural `operations`/`structs`/`repos`), a plain class with no Success/Failure wrapping:
  ```ruby
  # app/service/encryption_helper.rb
  class EncryptionHelper
    def encrypt(value) = ...
    def decrypt(value) = ...
  end
  ```
- A value object with no DB backing (a report row, a DTO) is a plain `Dry::Struct` in `app/structs/*.rb`, not `OrcidPrinceton::DB::Struct` (§2).

---

## 11. Deployment: Capistrano barely changes

`Capfile` and `config/deploy*.rb` port with almost no changes. The only Hanami-specific additions:
```ruby
namespace :hanami do
  desc 'Compile and install javascript dependencies'
  task :asset_compile do
    on roles(:app) do
      within release_path do
        execute 'yarn', 'install'
        execute 'bundle', 'exec hanami assets compile'
      end
    end
  end

  desc 'Update the administrators to match the current settings'
  task :create_admin_users do
    on roles(:app) do
      within release_path do
        execute 'bundle', 'exec rake users:create_admin_users'
      end
    end
  end
end

before 'deploy:publishing', 'hanami:asset_compile'
before 'deploy:publishing', 'hanami:create_admin_users'
```
`set :linked_dirs, %w[log public/assets node_modules]` — same linked-dirs pattern as Rails Capistrano setups, `node_modules` added because Hanami's esbuild-based asset pipeline needs it across releases. Load-balancer drain/rejoin tasks and server/role definitions are generic Capistrano and need no changes at all.

---

## 12. The operations/dry-monads idiom, in depth

This is the single biggest idiomatic habit to adopt. Anything in Rails that was "a model class method with ad hoc nil/exception handling" becomes a `Dry::Operation` subclass built from `step` calls, each returning `Success(value)` or `Failure(reason)`. `step` short-circuits the whole `call` to the first `Failure` — Ruby's version of railway-oriented programming, replacing scattered `if x.nil?` / `rescue` checks:
```ruby
class UserFromAttributes < OrcidPrinceton::Operation
  include Deps['repos.user_repo']

  def call(uid:, access_token:)
    user_attributes = step basic_user_attributes(uid:, access_token:)
    final_attributes = step add_ldap_attributes(uid:, combined_attributes: user_attributes, access_token:)
    user_attributes[:id].nil? ? step(create(final_attributes)) : step(update(final_attributes))
  end

  private

  def add_ldap_attributes(uid:, combined_attributes:, access_token:)
    return Success(combined_attributes) unless combined_attributes[:university_id].nil?

    ldap_attr = ldap_info(uid)
    ldap_attr.nil? ? Failure("Can not find the university id for #{uid}") : Success(merge_attributes(combined_attributes, ldap_attributes(ldap_attr)))
  end
end
```
Callers (actions, rake tasks) consume the result with pattern matching:
```ruby
case validate_user_tokens.call(user_id)
in Failure(error)
  response.flash[:notice] = error
in Success
  nil
end
```
**Model auth-backend or workflow variants as a subclass overriding one method, not as branches inside one big method:**
```ruby
class UserFromEntraAttributes < UserFromAttributes
  private

  # only the claim-shape parsing differs between CAS and Entra/OIDC — everything else
  # (fetch-or-create, LDAP enrichment, create/update) is inherited unchanged
  def attributes_from_token(access_token)
    { university_id: ..., email: access_token.extra.raw_info.email, ... }
  end
end
```
**When to extract an operation out of an action**: if an action's `handle` method is doing more than fetch params → call one collaborator → render/redirect, that's the signal. The reference migration's own history shows business logic starting out inline in an OmniAuth callback action and getting extracted into a standalone operation once it needed to be unit-tested and reused by a second auth backend.

Don't over-invest in getting monad pattern-matching style perfectly consistent (`if x.is_a? Success` vs. `case/in Success`) while you're first landing a feature — the reference migration used both styles at different points and only unified on `case/in` in a later cleanup pass once several operations existed and the idiom had settled. Ship working Success/Failure handling first; standardize the style once you have enough operations to see the pattern clearly.
