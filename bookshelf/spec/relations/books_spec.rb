# frozen_string_literal: true

RSpec.describe "relations.books", :db do
  subject(:books) { Hanami.app["relations.books"] }

  it "infers the schema from the books table" do
    expect(books.schema.map(&:name)).to contain_exactly(:id, :title, :author, :created_at, :updated_at)
  end

  it "is a plain schema/dataset wrapper with no query or persistence behavior" do
    expect(books).to be_a(Bookshelf::Relations::Books)
    expect(books.to_a).to eq([])
  end
end
