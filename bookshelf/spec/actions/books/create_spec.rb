# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::Create, :db do
  subject(:action) { described_class.new }

  context "with valid params" do
    let(:params) { {book: {title: "awesome book", author: "Jane Doe"}} }

    it "creates the book" do
      expect { action.call(params) }.to change { Bookshelf::Repos::BookRepo.new.count }.by(1)

      book = Bookshelf::Repos::BookRepo.new.last
      expect(book.title).to eq("awesome book")
      expect(book.author).to eq("Jane Doe")
    end

    it "redirects to the book's show page with a flash notice" do
      response = action.call(params)
      book = Bookshelf::Repos::BookRepo.new.last

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("/books/#{book.id}")
      expect(response.flash.next[:notice]).to eq("Book was successfully created")
    end
  end

  context "with invalid params" do
    let(:params) { {book: {title: "", author: ""}} }

    it "does not create a book" do
      expect { action.call(params) }.not_to change { Bookshelf::Repos::BookRepo.new.count }
    end

    it "re-renders the form with a flash alert" do
      response = action.call(params)

      expect(response.status).to eq(200)
      expect(response.flash[:alert]).to eq("Could not create book")
    end
  end
end
