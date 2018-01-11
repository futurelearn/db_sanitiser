RSpec.describe DbSanitiser do
  it "has a version number" do
    expect(DbSanitiser::VERSION).not_to be nil
  end

  it 'loads the database tables' do
    users = Class.new(ActiveRecord::Base) { self.table_name = 'users' }
    expect(users.count).to eq(0)
    hobbies = Class.new(ActiveRecord::Base) { self.table_name = 'hobbies' }
    expect(hobbies.count).to eq(0)
  end
end
