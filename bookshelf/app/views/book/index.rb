# frozen_string_literal: true

module Bookshelf
  module Views
    module Book
      # Presenter for the books index page. Ported from Rails'
      # app/views/books/index.html.erb — `@books` becomes the `books`
      # exposure, flash `notice` becomes a plain exposure (nil until the
      # index action sets it from flash).
      class Index < Bookshelf::View
        expose :books
        expose :notice
      end
    end
  end
end
