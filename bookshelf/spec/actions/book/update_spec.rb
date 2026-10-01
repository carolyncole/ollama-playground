# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Update, :db do
  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }
  let(:params) { {"id" => book.id.to_s, "book" => {"title" => "book 1 update"}} }

  it "updates the book and redirects to its show page" do
    response = subject.call(params)

    expect(Bookshelf::Repos::BookRepo.new.get(book.id).title).to eq("book 1 update")

    expect(response).to be_redirect
    expect(response.headers["location"]).to eq("/books/#{book.id}")
  end
end
