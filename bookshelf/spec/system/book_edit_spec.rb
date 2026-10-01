require "spec_helper"

RSpec.describe "book/", type: :system do

    it "visits the book show page and edits the book" do
      book = Bookshelf::Repos::BookRepo.new.create(title: "book 1", author: "author 1")
      Bookshelf::Repos::BookRepo.new.create(title: "book 2", author: "author 2")
      visit "/books/#{book.id}"
  
      expect(page).to have_content "Title: book 1"
      expect(page).not_to have_content "Title: book 2"
      expect(page).to have_content "Author: author 1"
      expect(page).not_to have_content "Author: author 2"
      click_on "Edit this book"
      expect(find('#book-title').value).to eq("book 1")
      expect(find('#book-author').value).to eq("author 1")
      fill_in "book-title", with: "book 1 update"
      click_on "Update Book"
      book = Bookshelf::Repos::BookRepo.new.get(book.id)
      expect(book.title).to eq("book 1 update")
    end
  end
