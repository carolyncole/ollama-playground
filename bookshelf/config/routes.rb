# frozen_string_literal: true

module Bookshelf
  class Routes < Hanami::Routes
    root to: "books.index"
    resources :books
  end
end
