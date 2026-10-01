# frozen_string_literal: true

RSpec.describe Bookshelf::Repos::BookRepo, :db do
  subject(:repo) { described_class.new }

  describe "#create" do
    it "persists a book and stamps timestamps" do
      book = repo.create(title: "Hanami in Action", author: "Sean Collins")

      expect(book.title).to eq("Hanami in Action")
      expect(book.author).to eq("Sean Collins")
      expect(book.created_at).to be_a(Time)
      expect(book.updated_at).to be_a(Time)
    end
  end

  describe "#all" do
    it "returns every book" do
      repo.create(title: "Book One", author: "Author One")
      repo.create(title: "Book Two", author: "Author Two")

      expect(repo.all.map(&:title)).to contain_exactly("Book One", "Book Two")
    end
  end

  describe "#get" do
    it "returns the book with the given id" do
      book = repo.create(title: "Hanami in Action", author: "Sean Collins")

      expect(repo.get(book.id).id).to eq(book.id)
    end

    it "raises when the book does not exist" do
      expect { repo.get(-1) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end

  describe "#update" do
    it "updates the given attributes and bumps updated_at" do
      book = repo.create(title: "Hanami in Action", author: "Sean Collins")

      updated = repo.update(book.id, title: "Hanami in Action (2nd ed)")

      expect(updated.title).to eq("Hanami in Action (2nd ed)")
      expect(updated.author).to eq("Sean Collins")
      expect(updated.updated_at).to be >= book.updated_at
    end
  end

  describe "#delete" do
    it "removes the book" do
      book = repo.create(title: "Hanami in Action", author: "Sean Collins")

      repo.delete(book.id)

      expect(repo.all).to be_empty
    end
  end
end
