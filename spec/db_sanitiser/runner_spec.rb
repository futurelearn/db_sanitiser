require 'spec_helper'

RSpec.describe DbSanitiser::Runner do
  class User < ActiveRecord::Base
  end

  class Hobby < ActiveRecord::Base
  end

  describe 'sanitising tables' do
    it 'can sanitise multiple tables'
    it 'can sanitise a table depending on a query'
    it 'can sanitise the same table multiple times'
  end

  describe 'deleting contents of tables' do
    it 'deletes the contents of the table'
  end

  describe 'validating the schema' do
    it 'raises an error if there is an unknown column in the table'
    it "allows columns to be ignore if they shouldn't be sanitised"
    it "raises an error if there is an ignored column that doesn't exist"
  end

  def fixture_file(name)
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'support', 'fixtures', name)
  end
end
