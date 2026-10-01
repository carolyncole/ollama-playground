# frozen_string_literal: true

module Bookshelf
  # ROM relations, one per table, schema-only.
  module Relations
    # ROM relation for the `books` table.
    #
    # Schema only — no query or persistence behavior lives here. See
    # {Bookshelf::Repos::BookRepo} for querying and persistence, and
    # {Bookshelf::Structs::Book} for the struct returned by the repo.
    #
    # @see Bookshelf::Repos::BookRepo
    class Books < Bookshelf::DB::Relation
      schema :books, infer: true
    end
  end
end
