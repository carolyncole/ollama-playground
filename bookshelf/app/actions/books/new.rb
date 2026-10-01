# frozen_string_literal: true

module Bookshelf
  module Actions
    module Books
      # `GET /books/new` — renders the empty new-book form.
      #
      # Has no logic of its own: {Bookshelf::Views::Books::New} exposes the (empty) form fields.
      #
      # @see Bookshelf::Views::Books::New
      # @see Bookshelf::Actions::Books::Create
      class New < Bookshelf::Action
        # @api private
        def handle(request, response)
        end
      end
    end
  end
end
