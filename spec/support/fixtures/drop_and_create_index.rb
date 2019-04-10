sanitise_table 'users' do
  drop_and_create_index 'index_users_on_email', 'email'

  sanitise 'email', string('barney.rubble@flintstones.com')

  allow 'id', 'name'
end

delete_all 'hobbies'
