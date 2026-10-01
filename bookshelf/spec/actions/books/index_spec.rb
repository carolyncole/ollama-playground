# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Index, :db do
  subject(:action) { described_class.new }

  it "renders every book" do
    Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1")
    Bookshelf::Repos::BookRepo.new.create(title: "book 2", author: "author 2")

    response = action.call({})

    expect(response.status).to eq(200)
    expect(response.body.join).to include("book 1").and include("book 2")
  end

  it "renders the welcome message when there are no books" do
    response = action.call({})

    expect(response.body.join).to include("Welcome to the Bookshelf")
  end
end
