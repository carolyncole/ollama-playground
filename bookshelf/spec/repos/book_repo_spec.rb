# frozen_string_literal: true

RSpec.describe Bookshelf::Repos::BookRepo, :db do
  subject(:repo) { described_class.new }

  let!(:book) { repo.create(title: "Practical Object-Oriented Design", author: "Sandi Metz") }

  describe "#all" do
    it "returns every book" do
      expect(repo.all).to contain_exactly(book)
    end
  end

  describe "#count" do
    it "returns the number of books" do
      expect(repo.count).to eq(1)
    end
  end

  describe "#get" do
    it "returns the book with the given id" do
      expect(repo.get(book.id)).to eq(book)
    end

    it "raises when no book matches the id" do
      expect { repo.get(-1) }.to raise_error(ROM::TupleCountMismatchError)
    end
  end

  describe "#last" do
    it "returns the most recently inserted book" do
      newer = repo.create(title: "Design Patterns", author: "Gang of Four")

      expect(repo.last).to eq(newer)
    end
  end

  describe "#create" do
    it "persists a new book with timestamps" do
      created = repo.create(title: "99 Bottles of OOP", author: "Sandi Metz")

      expect(created.title).to eq("99 Bottles of OOP")
      expect(created.author).to eq("Sandi Metz")
      expect(created.created_at).not_to be_nil
      expect(created.updated_at).not_to be_nil
    end
  end

  describe "#update" do
    it "updates the given attributes and refreshes updated_at" do
      updated = repo.update(book.id, title: "Updated Title")

      expect(updated.title).to eq("Updated Title")
      expect(updated.updated_at).to be >= book.updated_at
    end
  end

  describe "#delete" do
    it "removes the book" do
      repo.delete(book.id)

      expect(repo.all).to be_empty
    end
  end
end
