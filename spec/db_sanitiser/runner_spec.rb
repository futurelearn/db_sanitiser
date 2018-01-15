require 'spec_helper'

RSpec.describe DbSanitiser::Runner do
  class User < ActiveRecord::Base
  end

  class Hobby < ActiveRecord::Base
  end

  describe 'sanitising tables' do
    it 'can sanitise multiple tables' do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      user_id = user.id
      hobby = Hobby.create(user_id: user_id, hobby: 'Saying yabba dabba doo')
      hobby_id = hobby.id
      described_class.new(fixture_file('all_sanitised.rb')).sanitise
      expect(User.first.attributes).to eq("id" => user_id + 1000, "name" => 'Barney Rubble', "email" => 'barney.rubble@flintstones.com')
      expect(Hobby.first.attributes).to eq("id" => user_id + 1000, "user_id" => hobby_id + 1000, "hobby" => 'surfing')
    end

    it 'can sanitise a table depending on a query' do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      user2 = User.create!(name: 'Wilma Flintstone', email: 'wilma.flintstone@flintstones.com')

      described_class.new(fixture_file('query_sanitised.rb')).sanitise
      expect(User.first.name).to eq('Barney Rubble')
      expect(User.last.name).to eq('Wilma Flintstone')
    end

    it 'can sanitise the same table multiple times' do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      user2 = User.create!(name: 'Wilma Flintstone', email: 'wilma.flintstone@flintstones.com')

      described_class.new(fixture_file('query_sanitised_multiple.rb')).sanitise
      expect(User.first.name).to eq('Barney Rubble')
      expect(User.last.name).to eq('Betty Rubble')
    end
  end

  describe 'deleting contents of tables' do
    it 'deletes the contents of the table' do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      hobby = Hobby.create(user_id: 1, hobby: 'Saying yabba dabba doo')

      described_class.new(fixture_file('delete_all.rb')).sanitise

      expect(User.count).to eq(0)
      expect(Hobby.count).to eq(0)
    end
  end

  describe 'validating the schema' do
    it 'raises an error if there is an unknown column in the table being sanitised' do
      expect {
        described_class.new(fixture_file('missing_column.rb')).sanitise
      }.to raise_error(RuntimeError, /Missing columns for users: \["name", "email"\]/)
    end

    it "allows columns to be ignored if they shouldn't be sanitised" do
      expect {
        described_class.new(fixture_file('ignored_columns.rb')).sanitise
      }.to_not raise_error
    end
    it "raises an error if there is an ignored column that doesn't exist"
  end

  def fixture_file(name)
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'support', 'fixtures', name)
  end
end
