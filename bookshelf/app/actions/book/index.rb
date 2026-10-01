# frozen_string_literal: true

module Bookshelf
  # HTTP actions, one per Rails controller action.
  module Actions
    # Actions for the `Book` resource.
    module Book
      # `GET /books` and `GET /` — ported from Rails' `BooksController#index`.
      class Index < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Exposes every book, plus any flash notice, to the paired view
        # ({Bookshelf::Views::Book::Index}).
        #
        # @param request [Hanami::Action::Request]
        # @param response [Hanami::Action::Response]
        # @return [void]
        def handle(request, response)
          response[:books] = book_repo.all
          response[:notice] = request.flash[:notice]
        end
      end
    end
  end
end
