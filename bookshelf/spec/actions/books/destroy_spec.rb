# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Destroy, :db do
  subject(:action) { described_class.new }

  let!(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }

  it "deletes the book" do
    expect { action.call(id: book.id.to_s) }.to change { Bookshelf::Repos::BookRepo.new.count }.by(-1)
  end

  it "redirects to the books index with a flash notice" do
    response = action.call(id: book.id.to_s)

    expect(response.status).to eq(302)
    expect(response.headers["Location"]).to eq("/books")
    expect(response.flash.next[:notice]).to eq("Book was successfully destroyed")
  end
end
