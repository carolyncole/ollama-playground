# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :books do
      primary_key :id
      column :title, String
      column :author, String
      column :created_at, :timestamp, null: false
      column :updated_at, :timestamp, null: false
    end
  end
end
