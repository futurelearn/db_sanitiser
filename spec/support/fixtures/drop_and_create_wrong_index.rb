sanitise_table 'users' do
  drop_and_create_index 'index_users_on_email', 'email', unique: true

  sanitise 'email', "CONCAT('user-', id, '@example.com')"

  allow 'id', 'name'
end

delete_all 'hobbies'
