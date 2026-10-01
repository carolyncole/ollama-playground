# frozen_string_literal: true

module Bookshelf
  module Relations
    class Books < Bookshelf::DB::Relation
      schema :books, infer: true
    end
  end
end
