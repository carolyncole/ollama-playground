# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      class Destroy < Bookshelf::Action
        include Deps["repos.book_repo"]

        params do
          required(:id).filled(:integer)
        end

        def handle(request, response)
          book_repo.delete(request.params[:id])
          response.flash[:notice] = "Book was successfully destroyed"
          response.redirect_to routes.path(:books)
        end
      end
    end
  end
end
