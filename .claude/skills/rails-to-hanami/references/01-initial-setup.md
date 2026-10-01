# Phase 1 — Initial Hanami app setup

Goal: a running Hanami app at `/usr/src/app/bookshelf` that reads the same SQLite data as the
Rails app, with a `books` relation and repo.

## 1. Generate the app

```
docker exec -w /usr/src/app -it ollamaplayground bash
```

```
hanami new bookshelf
ls bookshelf
exit
```

## 2. Install dependencies and run the dev server

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle install
docker exec -w /usr/src/app/bookshelf -it ollamaplayground npm install
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami assets compile
```

Run the Hanami dev server:

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami dev
```

Look at the [Hanami application](http://localhost:2301).

## 3. Seed the Rails database and copy it over to Hanami

```
docker exec -w /usr/src/app/rails_bookshelf -it ollamaplayground bin/rails db:seed
docker exec -w /usr/src/app/bookshelf -it ollamaplayground cp ../rails_bookshelf/storage/development.sqlite3 db/
docker exec -w /usr/src/app/bookshelf -it ollamaplayground cp ../rails_bookshelf/storage/test.sqlite3 db/
```

This relies on `bookshelf/` and `rails_bookshelf/` being siblings under `/usr/src/app/` — which
they are in this repo, so the `../rails_bookshelf/...` relative path works as-is.

## 4. Point Hanami at the copied database

In **bookshelf/.env** replace all contents with:

```
DATABASE_URL=sqlite://db/development.sqlite3
```

## 5. Generate the Hanami relation and repository

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate relation books
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami generate repo book
```

Examples of Hanami syntax can be found in the docs, specifically the web app tutorial:
https://hanakai.org/learn/hanami/v3.0/getting-started/building-a-web-app

## 6. Add the book interface methods

Add to **bookshelf/app/repos/book_repo.rb**, inside the class:

```ruby
def all = books.to_a

def create(attributes)
  attributes[:created_at] = Time.now
  attributes[:updated_at] = Time.now
  books.changeset(:create, attributes).commit
end

def count = books.count

def delete(id)
  books.by_pk(id).changeset(:delete).commit
end

def get(id) = books.by_pk(id).one!

def last = books.last

def update(id, attributes)
  attributes[:updated_at] = Time.now
  books.by_pk(id).changeset(:update, attributes).commit
end
```

## 7. Verify: view the Rails data from the Hanami console

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami console
```

```ruby
puts Bookshelf::Repos::BookRepo.new.all.map(&:inspect)
exit
```

If this prints the same books that are in the Rails app, phase 1 is done — move to
`references/02-routes-actions.md`.
