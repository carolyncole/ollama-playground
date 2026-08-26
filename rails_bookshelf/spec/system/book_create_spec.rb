require "rails_helper"

RSpec.describe "books/new", type: :system do

    it "visits new book page and creates a book" do
      visit "/books/new"

      fill_in "Title", with: "awesome book"
      fill_in "Author", with: "Jane Doe"

      click_on "Create Book"
      expect(page).to have_content("Book was successfully created")
      book = Book.last
      expect(book.title).to eq("awesome book")
      expect(book.author).to eq("Jane Doe")
    end
  end
