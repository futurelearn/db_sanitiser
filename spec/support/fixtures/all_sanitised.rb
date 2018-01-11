sanitise_table 'users' do
  sanitise 'id', 'id + 1000'
  sanitise 'name', string('Barney Rubble')
  sanitise 'email', string('barney.rubble@flintstones.com')
end

sanitise_table 'hobbies' do
  sanitise 'id', 'id + 1000'
  sanitise 'user_id', 'user_id + 1000'
  sanitise 'hobby', string('surfing')
end
