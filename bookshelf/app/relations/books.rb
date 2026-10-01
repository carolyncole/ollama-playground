# frozen_string_literal: true

module Bookshelf
  module Relations
    # ROM relation over the `books` table, shared with the rails_bookshelf
    # app's SQLite database.
    #
    # @see Bookshelf::Repos::BookRepo
    class Books < Bookshelf::DB::Relation
      schema :books, infer: true
    end
  end
end
