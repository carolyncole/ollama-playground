# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `POST /books` — creates a book from `book: {title:, author:}` params.
      #
      # On success, redirects to the new book's show page with a flash notice. On failure,
      # re-renders {Bookshelf::Views::Books::New} (status 200) with a flash alert.
      #
      # @see Bookshelf::Actions::Books::New
      class Create < Bookshelf::Action
        include Deps["repos.book_repo"]

        params do
          required(:book).hash do
            required(:title).filled(:string)
            required(:author).filled(:string)
          end
        end

        # @api private
        def handle(request, response)
          if request.params.valid?
            book = book_repo.create(request.params[:book])
            response.flash[:notice] = "Book was successfully created"
            response.redirect_to routes.path(:book, id: book[:id])
          else
            response.flash.now[:alert] = "Could not create book"
          end
        end
      end
    end
  end
end
