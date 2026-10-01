# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Edit, :db do
  subject(:action) { described_class.new }

  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }

  it "renders the book pre-filled into the edit form" do
    response = action.call(id: book.id.to_s)

    expect(response.status).to eq(200)
    expect(response.body.join).to include("Editing book").and include("Update Book")
  end
end
