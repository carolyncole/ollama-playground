# frozen_string_literal: true

module Bookshelf
  module Repos
    class BookRepo < Bookshelf::DB::Repo
      def all = books.to_a

      def get(id) = books.by_pk(id).one!

      def create(attributes)
        attributes[:created_at] = Time.now
        attributes[:updated_at] = Time.now
        books.changeset(:create, attributes).commit
      end

      def update(id, attributes)
        attributes[:updated_at] = Time.now
        books.by_pk(id).changeset(:update, attributes).commit
        get(id)
      end

      def delete(id) = books.by_pk(id).changeset(:delete).commit
    end
  end
end
