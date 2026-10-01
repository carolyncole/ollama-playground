# frozen_string_literal: true

RSpec.describe Bookshelf::Views::Book::Edit, :db do
  subject(:rendered) { described_class.new.call(book: book).to_s }

  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }

  it "shows a pre-filled form that patches to the book's own path" do
    expect(rendered).to include(%(action="/books/#{book.id}"))
    expect(rendered).to include('name="_method" value="patch"')
    expect(rendered).to include('id="book_title" value="book 1"')
    expect(rendered).to include('id="book_author" value="author 1"')
    expect(rendered).to include('value="Update Book"')
  end
end
