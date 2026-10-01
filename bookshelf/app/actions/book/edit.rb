# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `GET /books/:id/edit` — ported from Rails' `BooksController#edit`.
      class Edit < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Exposes the book being edited to the paired view
        # ({Bookshelf::Views::Book::Edit}).
        #
        # @param request [Hanami::Action::Request] `params[:id]` is the book's id
        # @param response [Hanami::Action::Response]
        # @return [void]
        # @raise [ROM::TupleCountMismatchError] if no book has that id
        def handle(request, response)
          response[:book] = book_repo.get(request.params[:id].to_i)
        end
      end
    end
  end
end
