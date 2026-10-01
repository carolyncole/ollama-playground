# frozen_string_literal: true

RSpec.describe Bookshelf::Actions::Books::New, :db do
  subject(:action) { described_class.new }

  it "renders the new book form" do
    response = action.call({})

    expect(response.status).to eq(200)
    expect(response.body.join).to include("New book").and include("Create Book")
  end
end
