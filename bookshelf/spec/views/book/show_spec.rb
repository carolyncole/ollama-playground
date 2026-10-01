# frozen_string_literal: true

RSpec.describe Bookshelf::Views::Book::Show, :db do
  subject(:rendered) { described_class.new.call(book: book, notice: notice).to_s }

  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }
  let(:notice) { nil }

  it "shows the book's title and author" do
    expect(rendered).to include("Title:", "book 1", "Author:", "author 1")
  end

  it "links to edit and back-to-index, and includes a destroy form" do
    expect(rendered).to include(%(href="/books/#{book.id}/edit"))
    expect(rendered).to include('href="/books"')
    expect(rendered).to include(%(action="/books/#{book.id}"))
    expect(rendered).to include('name="_method" value="delete"')
  end

  context "with a notice" do
    let(:notice) { "Book was successfully updated." }

    it "shows the notice" do
      expect(rendered).to include("Book was successfully updated.")
    end
  end
end
