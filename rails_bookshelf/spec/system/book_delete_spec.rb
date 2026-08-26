require "rails_helper"

RSpec.describe "books/new", type: :system do

    it "visits the book show page and destroys the book" do
      book = Book.create(title: "book 1", author: "author 1")
      visit "/books/#{book.id}"

      expect(page).to have_content "Title: book 1"
      expect(page).to have_content "Author: author 1"

      expect { click_on "Destroy this book" }.to change(Book, :count).by(-1)
      expect(page).to have_content("Book was successfully destroyed")
      expect(page).to have_content "Welcome to the Bookshelf"
    end
  end
