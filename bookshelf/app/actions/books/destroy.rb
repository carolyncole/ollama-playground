# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `DELETE /books/:id` — deletes a book, then redirects to the books index with a flash
      # notice.
      class Destroy < Bookshelf::Action
        include Deps["repos.book_repo"]

        params do
          required(:id).filled(:integer)
        end

        # @api private
        def handle(request, response)
          if request.params.valid?
            book_repo.delete(request.params[:id])
            response.flash[:notice] = "Book was successfully destroyed"
            response.redirect_to routes.path(:books)
          end
        end
      end
    end
  end
end
