# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Update, :db do
  subject(:action) { described_class.new }

  let(:book) { Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1") }

  context "with valid params" do
    let(:params) { {id: book.id.to_s, book: {title: "book 1 update", author: "author 1"}} }

    it "updates the book" do
      action.call(params)

      updated = Bookshelf::Repos::BookRepo.new.get(book.id)
      expect(updated.title).to eq("book 1 update")
    end

    it "redirects to the book's show page with a flash notice" do
      response = action.call(params)

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/#{book.id}")
      expect(response.flash.next[:notice]).to eq("Book was successfully updated")
    end
  end

  context "with invalid params" do
    let(:params) { {id: book.id.to_s, book: {title: "", author: ""}} }

    it "does not update the book" do
      action.call(params)

      unchanged = Bookshelf::Repos::BookRepo.new.get(book.id)
      expect(unchanged.title).to eq("book 1")
    end

    it "re-renders the form with a flash alert" do
      response = action.call(params)

      expect(response.status).to eq(200)
      expect(response.flash[:alert]).to eq("Could not update book")
    end
  end
end
