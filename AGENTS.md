# AGENTS.md

## Project layout

- `rails_bookshelf/` — the actual Rails 8.1 app (SQLite, Hotwire/Turbo, importmap, Stimulus). All app commands run from here.
- `Dockerfile` / `docker-files/` — Docker build that bundles Ruby, Node, and Firefox into a single container.
- Root `package.json` is empty; there is no root-level Node project.

## Docker workflow

```bash
docker build -t ollamaplayground .
docker run -it --name ollamaplayground \
  --publish 3001:3000 --publish 2301:2300 \
  --volume .:/usr/src/app ollamaplayground
```

To attach a shell: `docker exec -w /usr/src/app -it ollamaplayground bash`

## Developer commands (run from `rails_bookshelf/`)

| Task | Command |
|------|---------|
| Setup DB / deps | `bin/setup --skip-server` |
| Start dev server | `bin/dev` (port 3000) |
| Lint | `bin/rubocop` |
| Security audit | `bin/bundler-audit` |
| Importmap audit | `bin/importmap audit` |
| Static security scan | `bin/brakeman --quiet --no-pager` |
| Run full CI locally | `bin/ci` |
| Run all tests | `bundle exec rspec` |
| Run a single spec | `bundle exec rspec spec/models/book_spec.rb` |
| DB migrate | `bin/rails db:migrate` |

CI order (from `config/ci.rb`): setup → rubocop → bundler-audit → importmap audit → brakeman.

## Linting / style

RuboCop with `rubocop-rails-omakase` (`.rubocop.yml`). Run `bin/rubocop` — it's fast because of the explicit config flag in the binstub.

## Testing

RSpec (not Minitest). Capybara + Selenium for system tests (headless Firefox via `selenium_headless`). Tests live in `spec/`. Transactional fixtures are on. To run a single spec: `bundle exec rspec spec/path/to/file_spec.rb`.

## Gotchas

- `bin/setup` starts the server by default. Pass `--skip-server` to skip.
- `.ruby-version` says `ruby-3.2.0` but the Dockerfile uses `ruby:4.0` — version mismatch may exist outside Docker.
- SQLite databases live in `rails_bookshelf/storage/`.
- Brakeman is configured to exit on warnings (`--exit-on-warn`); treat all warnings as blockers.
