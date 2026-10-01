# frozen_string_literal: true

require "hanami/db/relation"

module Bookshelf
  # Persistence layer base classes ({DB::Relation}, {DB::Repo}, {DB::Struct}),
  # each subclassed once here and then again per table under `app/relations`,
  # `app/repos`, and `app/structs`.
  module DB
    # App-wide base class for ROM relations (e.g. {Bookshelf::Relations::Books}).
    class Relation < Hanami::DB::Relation
    end
  end
end
