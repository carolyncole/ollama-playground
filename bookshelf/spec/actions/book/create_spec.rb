# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Create, :db do
  let(:params) { {"book" => {"title" => "awesome book", "author" => "Jane Doe"}} }

  it "creates the book and redirects to its show page" do
    response = subject.call(params)

    book = Bookshelf::Repos::BookRepo.new.all.last
    expect(book.title).to eq("awesome book")
    expect(book.author).to eq("Jane Doe")

    expect(response).to be_redirect
    expect(response.headers["location"]).to eq("/books/#{book.id}")
  end
end
