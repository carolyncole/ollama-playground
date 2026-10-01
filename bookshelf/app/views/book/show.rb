# frozen_string_literal: true

module Bookshelf
  module Views
    module Book
      # Presenter for the book show page. Ported from Rails'
      # app/views/books/show.html.erb.
      class Show < Bookshelf::View
        expose :book
        expose :notice
      end
    end
  end
end
