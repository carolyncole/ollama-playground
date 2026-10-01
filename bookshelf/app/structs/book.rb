# frozen_string_literal: true

module Bookshelf
  module Structs
    class Book < Bookshelf::DB::Struct
      # @return [String] a DOM id unique to this book, for use as an element id
      def dom_id
        "book_#{id}"
      end
    end
  end
end
