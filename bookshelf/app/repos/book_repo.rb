# frozen_string_literal: true

module Bookshelf
  module Repos
    # Repository for persisting and querying {Bookshelf::Structs::Book} records.
    #
    # @see Bookshelf::Relations::Books
    class BookRepo < Bookshelf::DB::Repo
      # @return [Array<Bookshelf::Structs::Book>] every book in the table
      def all = books.to_a

      # Creates a new book, stamping `created_at`/`updated_at` with the
      # current time.
      #
      # @param attributes [Hash] book attributes, e.g. `title:` and `author:`
      # @return [Bookshelf::Structs::Book] the created book
      def create(attributes)
        attributes[:created_at] = Time.now
        attributes[:updated_at] = Time.now
        books.changeset(:create, attributes).commit
      end

      # @return [Integer] the number of books in the table
      def count = books.count

      # Deletes the book with the given id.
      #
      # @param id [Integer] primary key of the book to delete
      # @return [Bookshelf::Structs::Book] the deleted book
      def delete(id)
        books.by_pk(id).changeset(:delete).commit
      end

      # @param id [Integer] primary key of the book to fetch
      # @return [Bookshelf::Structs::Book] the matching book
      # @raise [ROM::TupleCountMismatchError] if no book matches the id
      def get(id) = books.by_pk(id).one!

      # @return [Bookshelf::Structs::Book, nil] the most recently inserted book
      def last = books.last

      # Updates the given attributes on a book, stamping `updated_at` with
      # the current time.
      #
      # @param id [Integer] primary key of the book to update
      # @param attributes [Hash] attributes to merge into the existing record
      # @return [Bookshelf::Structs::Book] the updated book
      def update(id, attributes)
        attributes[:updated_at] = Time.now
        books.by_pk(id).changeset(:update, attributes).commit
      end
    end
  end
end
