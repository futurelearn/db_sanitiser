sanitise_table 'users' do
  allow 'id', 'email', 'name'
end

sanitise_table 'hobbies' do
  allow 'id', 'user_id', 'hobby'
end
