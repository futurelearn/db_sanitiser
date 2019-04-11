require 'spec_helper'

RSpec.describe DbSanitiser::Runner do
  class User < ActiveRecord::Base
  end

  class Hobby < ActiveRecord::Base
  end

  describe 'actually running the sanitiser' do
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

      it 'can drop and recreate an index' do
        user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
        user2 = User.create!(name: 'Wilma Flintstone', email: 'wilma.flintstone@flintstones.com')

        described_class.new(fixture_file('drop_and_create_index.rb')).sanitise
        expect(User.first.email).to eq('barney.rubble@flintstones.com')
        expect(User.last.email).to eq('barney.rubble@flintstones.com')
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

    describe 'truncating tables' do
      it 'removes the contents of the table' do
        user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
        hobby = Hobby.create(user_id: 1, hobby: 'Saying yabba dabba doo')

        described_class.new(fixture_file('truncate.rb')).sanitise

        expect(User.count).to eq(0)
        expect(Hobby.count).to eq(0)
      end
    end

    describe 'allowing every column of a table' do
      it 'can sanitise the same table multiple times' do
        user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')

        described_class.new(fixture_file('allow_entire_table.rb')).sanitise
        expect(User.first.name).to eq('Fred Flintstone')
      end
    end

    describe 'delete_where' do
      it 'partially deletes a table' do
        user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
        user = User.create!(name: 'Barney Rubble', email: 'barney.rubble@flintstones.com')

        described_class.new(fixture_file('partially_delete.rb')).sanitise
        expect(User.count).to eq(1)
        expect(User.first.name).to eq('Fred Flintstone')
      end
    end
  end

  describe 'validating the schema without sanitising' do
    it "doesn't modify any tables" do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      user_id = user.id
      hobby = Hobby.create(user_id: user_id, hobby: 'Saying yabba dabba doo')
      hobby_id = hobby.id
      described_class.new(fixture_file('all_sanitised.rb')).validate
      expect(User.first.attributes).to eq("id" => user_id, "name" => 'Fred Flintstone', "email" => 'fred.flintstone@flintstones.com')
      expect(Hobby.first.attributes).to eq("id" => hobby_id, "user_id" => user_id, "hobby" => 'Saying yabba dabba doo')
    end

    it 'raises an error if there is an unknown column in the table being sanitised' do
      expect {
        described_class.new(fixture_file('missing_column.rb')).validate
      }.to raise_error(RuntimeError, /Please add db_sanitiser config for these columns in 'users': \["name", "email"\]/)
    end

    it "allows columns to be ignored if they shouldn't be sanitised" do
      expect {
        described_class.new(fixture_file('ignored_columns.rb')).validate
      }.to_not raise_error
    end

    it "raises an error if there is an ignored column that doesn't exist" do
      expect {
        described_class.new(fixture_file('unknown_columns.rb')).validate
      }.to raise_error(RuntimeError, /You have db_sanitiser config for these columns in 'users', but they don't exist in the database: \["age"\]/)
    end

    it "raises an error if some tables aren't either sanitised or deleted" do
      expect {
        described_class.new(fixture_file('no_tables.rb')).validate
      }.to raise_error(RuntimeError, /Please add db_sanitiser config for these tables: \["hobbies", "users"\]/)
    end

    it "raises an error if a partially deleted table doesn't allow all columns" do
      expect {
        described_class.new(fixture_file('partially_delete.rb')).validate
      }.to raise_error(RuntimeError, /Please add db_sanitiser config for these columns in 'hobbies': \["id", "user_id", "hobby"\]/)
    end

    it "raises an error if a drop_and_create_index entry doesn't match the schema" do
      expect {
        described_class.new(fixture_file('drop_and_create_wrong_index.rb')).validate
      }.to raise_error RuntimeError, a_string_including("The index `index_users_on_edonkey` was set to be dropped and recreated, but does not match any index in the schema")
    end
  end

  describe 'dry run' do
    it "doesn't modify any tables" do
      user = User.create!(name: 'Fred Flintstone', email: 'fred.flintstone@flintstones.com')
      user_id = user.id
      hobby = Hobby.create(user_id: user_id, hobby: 'Saying yabba dabba doo')
      hobby_id = hobby.id
      described_class.new(fixture_file('all_sanitised.rb')).dry_run(StringIO.new)
      expect(User.first.attributes).to eq("id" => user_id, "name" => 'Fred Flintstone', "email" => 'fred.flintstone@flintstones.com')
      expect(Hobby.first.attributes).to eq("id" => hobby_id, "user_id" => user_id, "hobby" => 'Saying yabba dabba doo')
    end

    it 'prints what columns will be sanitised' do
      io = StringIO.new
      described_class.new(fixture_file('query_sanitised_multiple.rb')).dry_run(io)
      io.rewind
      expect(io.read).to eq(<<~EOF)
        Sanitise rows that match: SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Fred Flintstone': `id` = id, `name` = "Barney Rubble", `email` = "barney.rubble@flintstones.com"
        Sanitise rows that match: SELECT `users`.* FROM `users` WHERE `users`.`name` = 'Wilma Flintstone': `id` = id, `name` = "Betty Rubble", `email` = "betty.rubble@flintstones.com"
        Sanitise rows that match: SELECT `hobbies`.* FROM `hobbies`: `id` = id, `user_id` = user_id, `hobby` = hobby
      EOF
    end

    it 'prints tables that will be deleted' do
      io = StringIO.new
      described_class.new(fixture_file('delete_all.rb')).dry_run(io)
      io.rewind
      expect(io.read).to eq(<<~EOF)
        Delete all rows from "users"
        Delete all rows from "hobbies"
      EOF
    end

    it 'prints tables that will be partially deleted' do
      io = StringIO.new
      described_class.new(fixture_file('partially_delete.rb')).dry_run(io)
      io.rewind
      expect(io.read).to eq(<<~EOF)
        Delete rows from "users" that match: name = "Barney Rubble"
        Delete rows from "hobbies" that match: id > 0
      EOF
    end

    it 'prints indexes that will be dropped and recreated' do
      io = StringIO.new
      described_class.new(fixture_file('drop_and_create_index.rb')).dry_run(io)
      io.rewind
      expect(io.read).to eq(<<~EOF)
        Drop indexes: index_users_on_email
        Sanitise rows that match: SELECT `users`.* FROM `users`: `email` = "barney.rubble@flintstones.com"
        Create indexes: index_users_on_email
        Delete all rows from "hobbies"
      EOF
    end
  end

  context 'when DbSanitiser is disabled' do
    before do
      DbSanitiser.disable!
    end

    it 'should not allow sanitisation' do
      expect {
        described_class.new(fixture_file('all_sanitised.rb')).sanitise
      }.to raise_error(/DbSanitiser is not enabled/)
    end
  end

  def fixture_file(name)
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'support', 'fixtures', name)
  end
end
