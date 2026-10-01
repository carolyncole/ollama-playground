# Phase 8 — Book new/create

Goal: `spec/system/book_create_spec.rb` passes.

## 1. Run the create spec (keep re-running it as you go)

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec rspec spec/system/book_create_spec.rb
```

## 2. Wire up the new view

Add to **bookshelf/app/views/books/new.rb**:

```ruby
include Deps["repos.book_repo"]

expose :form_submit, default: "Create Book"
expose :book do |context:|
  context.request.params[:book]
end
```

## 3. Fix the shared form partial

Replace in **bookshelf/app/templates/books/_form.html.erb**:

```erb
<%= form_with(model: book) do |form| %>
```

With:

```erb
<%= form_for :book, routes.path(:books), method: "POST" do |form| %>
```

Replace in the same file:

```erb
<%= form.submit %>
```

With:

```erb
<%= form.submit form_submit %>
```

## 4. Pass the new local through when rendering the form

Replace in **bookshelf/app/templates/books/new.html.erb**:

```erb
<%= render "form", book: book %>
```

With:

```erb
<%= render "form", book: book, form_submit: form_submit %>
```

## 5. Port the create action's logic

Look at the Rails version for reference: `rails_bookshelf/app/controllers/books_controller.rb#create`.
It looks roughly like:

```ruby
def handle(request, response)
  @book = Book.new(book_params)
  if @book.save
    redirect_to @book, notice: "Book was successfully created."
  else
    render :new, status: :unprocessable_entity
  end
end
```

In **bookshelf/app/actions/books/create.rb**, inside `class Create < Bookshelf::Action`, add:

```ruby
include Deps["repos.book_repo"]

params do
  required(:book).hash do
    required(:title).filled(:string)
    required(:author).filled(:string)
  end
end
```

Then rewrite the `handle` method to validate params and go through the repo:

```ruby
def handle(request, response)
  if request.params.valid?
    book = book_repo.create(request.params[:book])
    response.flash[:notice] = "Book was successfully created"
    response.redirect_to routes.path(:book, id: book[:id])
  else
    response.flash.now[:alert] = "Could not create book"
  end
end
```

## 6. Restart and check manually

```
docker exec -w /usr/src/app/bookshelf -it ollamaplayground bundle exec hanami dev
```

Visit the [index page](http://localhost:2301/books) and create a new book by hand to confirm it
works, in addition to the spec passing.

Once the create spec is green, move to `references/09-exercise-delete.md`.
