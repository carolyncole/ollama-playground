# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `GET /books/:id` — renders a single book.
      #
      # Has no logic of its own: {Bookshelf::Views::Books::Show} does the work of fetching the
      # book (via `id`) and exposing it to the template.
      #
      # @see Bookshelf::Views::Books::Show
      class Show < Bookshelf::Action
        # @api private
        def handle(request, response)
        end
      end
    end
  end
end
