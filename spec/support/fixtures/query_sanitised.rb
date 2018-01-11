sanitise_table 'users' do
  where name: 'Fred Flintstone'
  sanitise 'id', 'id'
  sanitise 'name', string('Barney Rubble')
  sanitise 'email', string('barney.rubble@flintstones.com')
end

sanitise_table 'hobbies' do
  sanitise 'id', 'id'
  sanitise 'user_id', 'user_id'
  sanitise 'hobby', 'hobby'
end
