# frozen_string_literal: true

RSpec.describe "Root", type: :request do
  it "renders the books index" do
    get "/"

    expect(last_response.status).to be(200)
    expect(last_response.body).to include("Welcome to the Bookshelf")
  end
end
