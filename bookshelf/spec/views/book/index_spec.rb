# frozen_string_literal: true

RSpec.describe Bookshelf::Views::Book::Index, :db do
  subject(:rendered) { described_class.new.call(books: repo.all, notice: notice).to_s }

  let(:repo) { Bookshelf::Repos::BookRepo.new }
  let(:notice) { nil }

  it "shows the welcome message" do
    expect(rendered).to include("Welcome to the Bookshelf")
  end

  it "lists every book's title and author, linked to its show page" do
    book_one = repo.create(title: "book 1", author: "author 1")
    book_two = repo.create(title: "book 2", author: "author 2")

    expect(rendered).to include("book 1", "author 1", "book 2", "author 2")
    expect(rendered).to include(%(href="/books/#{book_one.id}"))
    expect(rendered).to include(%(href="/books/#{book_two.id}"))
  end

  context "with a notice" do
    let(:notice) { "Book was successfully created." }

    it "shows the notice" do
      expect(rendered).to include("Book was successfully created.")
    end
  end
end
