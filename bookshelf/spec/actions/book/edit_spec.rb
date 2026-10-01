# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Edit, :db do
  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }
  let(:params) { {"id" => book.id.to_s} }

  it "renders a pre-filled form for the requested book" do
    response = subject.call(params)

    expect(response).to be_successful
    expect(response.body.join).to include(%(action="/books/#{book.id}"), 'value="book 1"')
  end
end
