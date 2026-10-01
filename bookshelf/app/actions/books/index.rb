# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `GET /books` — renders every book.
      #
      # Has no logic of its own: {Bookshelf::Views::Books::Index} does the work of fetching all
      # books and exposing them to the template.
      #
      # @see Bookshelf::Views::Books::Index
      class Index < Bookshelf::Action
        # @api private
        def handle(request, response)
        end
      end
    end
  end
end
