# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `GET /books/:id` — ported from Rails' `BooksController#show`.
      class Show < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Exposes the requested book, plus any flash notice, to the paired
        # view ({Bookshelf::Views::Book::Show}).
        #
        # @param request [Hanami::Action::Request] `params[:id]` is the book's id
        # @param response [Hanami::Action::Response]
        # @return [void]
        # @raise [ROM::TupleCountMismatchError] if no book has that id
        def handle(request, response)
          response[:book] = book_repo.get(request.params[:id].to_i)
          response[:notice] = request.flash[:notice]
        end
      end
    end
  end
end
