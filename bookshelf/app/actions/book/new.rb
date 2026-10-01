# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `GET /books/new` — ported from Rails' `BooksController#new`. No
      # exposure needed — the paired view ({Bookshelf::Views::Book::New})
      # provides its own blank book.
      class New < Bookshelf::Action
        # No-op — the paired view supplies its own blank book.
        #
        # @param request [Hanami::Action::Request]
        # @param response [Hanami::Action::Response]
        # @return [void]
        def handle(request, response)
        end
      end
    end
  end
end
