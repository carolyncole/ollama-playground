# frozen_string_literal: true

module Bookshelf
  module Structs
    class Book < Bookshelf::DB::Struct
      def dom_id
        "book_#{id}"
      end
    end
  end
end
