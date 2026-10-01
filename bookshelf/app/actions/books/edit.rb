# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `GET /books/:id/edit` — renders the edit form, pre-filled with the book's current values.
      #
      # Has no logic of its own: {Bookshelf::Views::Books::Edit} does the work of fetching the
      # book (via `id`) and exposing it to the form.
      #
      # @see Bookshelf::Views::Books::Edit
      # @see Bookshelf::Actions::Books::Update
      class Edit < Bookshelf::Action
        # @api private
        def handle(request, response)
        end
      end
    end
  end
end
