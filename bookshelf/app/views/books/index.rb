# frozen_string_literal: true

module Bookshelf
  module Views
    module Books
      class Index < Bookshelf::View
        include Deps["repos.book_repo"]

        expose :books do
          book_repo.all
        end
      end
    end
  end
end
