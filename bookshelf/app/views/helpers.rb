# auto_register: false
# frozen_string_literal: true

module Bookshelf
  module Views
    # Pure, side-effect-free helpers available to every template. Don't put
    # repo/DB lookups here — that belongs in a View's `expose`, not the
    # shared context (see the rails-to-hanami skill, layer-mapping.md §7).
    module Helpers
      # Mirrors Rails' `dom_id` for the one place the ported views use it
      # (the `_book` partial's wrapper `id`).
      def dom_id(book) = "book_#{book.id}"
    end
  end
end
