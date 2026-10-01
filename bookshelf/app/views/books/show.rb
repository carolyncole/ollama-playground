# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      # View for {Bookshelf::Actions::Books::Show}.
      class Show < Bookshelf::View
        include Deps["repos.book_repo"]

        # @!method book
        #   @return [Bookshelf::Structs::Book] the book matching the `id` route param
        #   @raise [ROM::TupleCountMismatchError] if no book matches `id`
        expose :book do |id:|
          book_repo.get(id)
        end
      end
    end
  end
end
