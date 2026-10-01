# frozen_string_literal: true

module Bookshelf
  # Immutable read-only entities returned by repos, one per table.
  module Structs
    # Immutable read-only entity for a row in the `books` table.
    #
    # Returned by {Bookshelf::Repos::BookRepo}. Ported from the Rails
    # `Book < ApplicationRecord` model, which had no custom instance
    # behavior — if book-specific logic is added later (e.g. a
    # `#display_title`), it belongs here, not in the repo or an action.
    #
    # @!attribute [r] id
    #   @return [Integer]
    # @!attribute [r] title
    #   @return [String, nil]
    # @!attribute [r] author
    #   @return [String, nil]
    # @!attribute [r] created_at
    #   @return [Time]
    # @!attribute [r] updated_at
    #   @return [Time]
    class Book < Bookshelf::DB::Struct
    end
  end
end
