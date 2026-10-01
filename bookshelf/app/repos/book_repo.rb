# frozen_string_literal: true

module Bookshelf
  # Repos: all querying and persistence, one per table.
  module Repos
    # Persistence and querying for {Bookshelf::Structs::Book}.
    #
    # This is the only place in the app that should talk to the `books`
    # relation directly — callers (actions, operations, rake tasks) go
    # through these methods instead of touching {Bookshelf::Relations::Books}.
    #
    # ROM does not manage `created_at`/`updated_at` automatically, so every
    # write method below stamps them by hand.
    class BookRepo < Bookshelf::DB::Repo
      # All books in the store.
      #
      # @return [Array<Bookshelf::Structs::Book>]
      def all = books.to_a

      # Find a single book by primary key.
      #
      # @param id [Integer] the book's id
      # @return [Bookshelf::Structs::Book]
      # @raise [ROM::TupleCountMismatchError] if no book has that id
      def get(id) = books.by_pk(id).one!

      # Create a new book.
      #
      # @param attributes [Hash] attributes for the new book (e.g. `:title`, `:author`)
      # @return [Bookshelf::Structs::Book] the created book
      def create(attributes)
        attributes[:created_at] = Time.now
        attributes[:updated_at] = Time.now
        books.changeset(:create, attributes).commit
      end

      # Update an existing book.
      #
      # @param id [Integer] the book's id
      # @param attributes [Hash] attributes to change
      # @return [Bookshelf::Structs::Book] the updated book
      def update(id, attributes)
        attributes[:updated_at] = Time.now
        books.by_pk(id).changeset(:update, attributes).commit
        get(id)
      end

      # Delete a book.
      #
      # @param id [Integer] the book's id
      # @return [Bookshelf::Structs::Book] the deleted book, as it was before deletion
      def delete(id) = books.by_pk(id).changeset(:delete).commit
    end
  end
end
