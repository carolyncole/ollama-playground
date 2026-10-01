# Phase 2 — Hanami routes and actions

Goal: a full set of RESTful routes and generated (empty) actions/views/templates for `books`.

## 1. Define the resource routes

In **bookshelf/config/routes.rb** add:

```ruby
resources :books
```

## 2. View the routes created by the resource

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami routes
```

## 3. Generate the actions for each route

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.show --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.index --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.new --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.create --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.edit --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.update --skip-route --skip-tests
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate action books.destroy --skip-route --skip-tests --skip-view
```

Verify what was generated:

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground ls app/actions/books
docker exec -w /usr/src/app/bookshelf -it ollamaplayground ls app/views/books
docker exec -w /usr/src/app/bookshelf -it ollamaplayground ls app/templates/books
```

You should see actions, views, and templates for each of `show`, `index`, `new`, `create`, `edit`,
`update` (and just an action for `destroy`, since it has no view). Once these exist, move to
`references/03-views-specs.md`.
