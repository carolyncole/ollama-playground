# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Book::Index, :db do
  let(:repo) { Bookshelf::Repos::BookRepo.new }
  let(:params) { {} }

  it "renders every book" do
    repo.create(title: "book 1", author: "author 1")
    repo.create(title: "book 2", author: "author 2")

    response = subject.call(params)

    expect(response).to be_successful
    expect(response.body.join).to include("book 1", "author 1", "book 2", "author 2")
  end

  it "renders the welcome message when there are no books" do
    response = subject.call(params)

    expect(response).to be_successful
    expect(response.body.join).to include("Welcome to the Bookshelf")
  end
end
