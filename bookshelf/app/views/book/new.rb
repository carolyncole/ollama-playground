# frozen_string_literal: true

module Bookshelf
  module Views
    # View classes for the `Book` resource, one per action.
    module Book
      # Presenter for the new-book form page. Ported from Rails'
      # app/views/books/new.html.erb (`@book = Book.new`).
      #
      # There's no Hanami equivalent of an unsaved `ActiveRecord` instance —
      # {Bookshelf::Structs::Book} is immutable and backed by a real row, so
      # it can't represent a blank, not-yet-persisted book. A plain
      # `Struct` with the same `id`/`title`/`author` readers (all nil)
      # stands in instead; the `_form` partial only needs those readers.
      class New < Bookshelf::View
        # Stand-in for an unsaved book — same reader interface as
        # {Bookshelf::Structs::Book} (`id`, `title`, `author`), all nil.
        BLANK_BOOK = Struct.new(:id, :title, :author).new(nil, nil, nil)

        expose(:book) { BLANK_BOOK }
      end
    end
  end
end
