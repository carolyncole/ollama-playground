# Phase 7 — Application layout

Goal: the Hanami app uses the Rails app's layout and styling, with Hanami-appropriate
CSRF/CSP/favicon handling.

## 1. Copy over the Rails layout and stylesheet

```
docker exec -w /usr/src/app/rails_bookshelf -it ollamaplayground cp app/views/layouts/application.html.erb ../bookshelf/app/templates/layouts/app.html.erb
docker exec -w /usr/src/app/rails_bookshelf -it ollamaplayground cp app/assets/stylesheets/application.css ../bookshelf/app/assets/css/app.css
```

## 2. Drop the CSP meta tag

Hanami applies Content Security Policy by default, so the CSP tag isn't needed. Replace in
**bookshelf/app/templates/layouts/app.html.erb**:

```erb
<%= csrf_meta_tags %>
<%= csp_meta_tag %>
```

With:

```erb
<%= csrf_meta_tags&.html_safe %>
```

## 3. Fix asset tags

Replace in **bookshelf/app/templates/layouts/app.html.erb**:

```erb
<%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
<%= javascript_importmap_tags %>
```

With:

```erb
<%= stylesheet_tag "app", "data-turbo-track": "reload" %>
```

## 4. Use the Hanami favicon

Using the Hanami icon makes it easy to tell the Rails and Hanami tabs apart. Replace:

```erb
<link rel="icon" href="/icon.png" type="image/png">
<link rel="icon" href="/icon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/icon.png">
```

With:

```erb
<%= favicon_tag %>
```

## 5. Verify

Look at the [index page](http://localhost:2301/books).

If the server errors out, recompile assets and restart the dev server:

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami assets compile
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami dev
```

Once the layout renders correctly, move to `references/08-book-new.md`.
