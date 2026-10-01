# frozen_string_literal: true

require "hanami/db/struct"

module Bookshelf
  module DB
    # App-wide base class for ROM structs (e.g. {Bookshelf::Structs::Book}).
    class Struct < Hanami::DB::Struct
    end
  end
end
