# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `DELETE /books/:id` — ported from Rails' `BooksController#destroy`.
      class Destroy < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Deletes the book, then redirects to the index.
        #
        # @param request [Hanami::Action::Request] `params[:id]` is the book's id
        # @param response [Hanami::Action::Response]
        # @return [void]
        def handle(request, response)
          book_repo.delete(request.params[:id].to_i)
          response.flash[:notice] = "Book was successfully destroyed."
          response.redirect_to("/books", status: 303)
        end
      end
    end
  end
end
