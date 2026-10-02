# app/relations/book.rb
#
# Rails:
#   class Book < ApplicationRecord; end
#
# Hanami: schema + keys only. Associations (if any) declared as OneToMany /
# OneToOne here or in an associations map.

class Book < Relations::Base
  model do
    columns(
      :id         do { Integer; primary_key }.end,
      :title      do { String }.end,
      :author     do { String }.end,
      :created_at do { Time }.end,
      :updated_at do { Time }.end,
    )
  end
end

# For orcid User (with associations):
#
# class User < Relations::Base
#   model do
#     columns(
#       :id do { Integer; primary_key }.end,
#       :orcid do { String }.end,
#       :token do { String }.end,
#       ...
#     )
#   end
#   associations do
#     has_many :tokens, via: :token_id
#   end
# end
