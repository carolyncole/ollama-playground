# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Show, :db do
  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }
  let(:params) { {"id" => book.id.to_s} }

  it "renders the requested book" do
    response = subject.call(params)

    expect(response).to be_successful
    expect(response.body.join).to include("book 1", "author 1")
  end
end
