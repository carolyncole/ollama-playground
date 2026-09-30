# Phase 4 — Flash notices and sessions

Goal: flash messages render correctly, and Hanami has a session backend (cookie-based) to store
them in.

## 1. Update templates to use Hanami's flash

Replace, across `bookshelf/app/templates/books/`:

```
notice
```

With:

```
flash[:notice]
```

## 2. Enable cookie sessions

In **bookshelf/config/app.rb**:

```ruby
config.actions.sessions = :cookie, { key: "bookshelf.session", secret: settings.session_secret, expire_after: 60*60*24*365 }
```

## 3. Add the session secret setting

In **bookshelf/config/settings.rb**:

```ruby
setting :session_secret, constructor: Types::String, default: "____local_development_secret_only____local_development_secret_only___"
```

Once sessions and flash are wired up, move to `references/05-book-show.md`.
