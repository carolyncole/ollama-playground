# frozen_string_literal: true

require "hanami/db/repo"

module Bookshelf
  module DB
    # App-wide base class for ROM repos (e.g. {Bookshelf::Repos::BookRepo}).
    class Repo < Hanami::DB::Repo
    end
  end
end
