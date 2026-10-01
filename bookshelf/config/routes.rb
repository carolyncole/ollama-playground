# frozen_string_literal: true

module Bookshelf
  class Routes < Hanami::Routes
    root to: "book.index"

    get "/books", to: "book.index"
    get "/books/new", to: "book.new"
    post "/books", to: "book.create"
    get "/books/:id", to: "book.show"
    get "/books/:id/edit", to: "book.edit"
    patch "/books/:id", to: "book.update"
    delete "/books/:id", to: "book.destroy"
  end
end
