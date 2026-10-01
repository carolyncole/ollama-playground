# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Destroy, :db do
  let(:repo) { Bookshelf::Repos::BookRepo.new }
  let(:book) { repo.create(title: "book 1", author: "author 1") }
  let(:params) { {"id" => book.id.to_s} }

  it "deletes the book and redirects to the index" do
    response = subject.call(params)

    expect(repo.all).to be_empty

    expect(response).to be_redirect
    expect(response.headers["location"]).to eq("/books")
  end
end
