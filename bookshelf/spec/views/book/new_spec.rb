# frozen_string_literal: true

RSpec.describe Bookshelf::Views::Book::New do
  subject(:rendered) { described_class.new.call.to_s }

  it "shows a blank form that posts to /books" do
    expect(rendered).to include('action="/books"')
    expect(rendered).not_to include('name="_method" value="patch"')
    expect(rendered).to include('id="book_title" value=""')
    expect(rendered).to include('id="book_author" value=""')
    expect(rendered).to include('value="Create Book"')
  end
end
