# frozen_string_literal: true

module Bookshelf
  module Views
    module Book
      # Presenter for the edit-book form page. Ported from Rails'
      # app/views/books/edit.html.erb.
      class Edit < Bookshelf::View
        expose :book
      end
    end
  end
end
