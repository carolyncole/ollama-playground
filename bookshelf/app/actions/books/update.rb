# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `PATCH /books/:id` — updates a book from `book: {title:, author:}` params.
      #
      # On success, redirects to the book's show page with a flash notice. On failure,
      # re-renders {Bookshelf::Views::Books::Edit} (status 200) with a flash alert.
      #
      # @see Bookshelf::Actions::Books::Edit
      class Update < Bookshelf::Action
        include Deps["repos.book_repo"]

        params do
          required(:id).filled(:integer)
          required(:book).hash do
            required(:title).filled(:string)
            required(:author).filled(:string)
          end
        end

        # @api private
        def handle(request, response)
          if request.params.valid?
            book = book_repo.update(request.params[:id], request.params[:book])
            response.flash[:notice] = "Book was successfully updated"
            response.redirect_to routes.path(:book, id: book[:id])
          else
            response.flash.now[:alert] = "Could not update book"
          end
        end
      end
    end
  end
end
