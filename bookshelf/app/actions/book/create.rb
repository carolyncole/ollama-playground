# frozen_string_literal: true

module Bookshelf
  module Actions
    module Book
      # `POST /books` — ported from Rails' `BooksController#create`. The
      # Rails `Book` model has no validations, so (unlike a typical Rails
      # scaffold) there's no failure branch to handle — `book_repo.create`
      # always succeeds.
      class Create < Bookshelf::Action
        include Deps["repos.book_repo"]

        # Creates the book, then redirects to its show page.
        #
        # @param request [Hanami::Action::Request] `params[:book]` holds
        #   `:title`/`:author`
        # @param response [Hanami::Action::Response]
        # @return [void]
        def handle(request, response)
          book = book_repo.create(request.params[:book].to_h)
          response.flash[:notice] = "Book was successfully created."
          response.redirect_to("/books/#{book.id}")
        end
      end
    end
  end
end
