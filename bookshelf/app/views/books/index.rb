# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      # View for {Bookshelf::Actions::Books::Index}.
      class Index < Bookshelf::View
        include Deps["repos.book_repo"]

        # @!method books
        #   @return [Array<Bookshelf::Structs::Book>] every book
        expose :books do
          book_repo.all
        end
      end
    end
  end
end
