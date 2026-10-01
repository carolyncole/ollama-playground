# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `PATCH /books/:id` — ported from Rails' `BooksController#update` (no
      # model validations, so no failure branch — see {Create}).
      class Update < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Updates the book, then redirects to its show page.
        #
        # @param request [Hanami::Action::Request] `params[:id]` is the
        #   book's id, `params[:book]` holds the attributes to change
        # @param response [Hanami::Action::Response]
        # @return [void]
        # @raise [ROM::TupleCountMismatchError] if no book has that id
        def handle(request, response)
          id = request.params[:id].to_i
          book_repo.update(id, request.params[:book].to_h)
          response.flash[:notice] = "Book was successfully updated."
          response.redirect_to("/books/#{id}", status: 303)
        end
      end
    end
  end
end
