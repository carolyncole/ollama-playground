# frozen_string_literal: true

# Ported near-verbatim from the Rails app's spec/system/book_index_spec.rb
# (type: :system -> type: :feature, ActiveRecord -> BookRepo).
RSpec.describe "books/", type: :feature do
  it "visits the home page and shows a welcome message" do
    visit "/books"

    expect(page).to have_content "Welcome to the Bookshelf"
  end

  it "shows books on the index" do
    repo = Bookshelf::Repos::BookRepo.new
    repo.create(title: "book 1", author: "author 1")
    repo.create(title: "book 2", author: "author 2")
    visit "/books"

    expect(page).to have_content "Title: book 1"
    expect(page).to have_content "Title: book 2"
    expect(page).to have_content "Author: author 1"
    expect(page).to have_content "Author: author 2"
  end
end
