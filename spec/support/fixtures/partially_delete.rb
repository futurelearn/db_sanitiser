partially_delete 'users' do
  where 'name = "Barney Rubble"'
  allow 'id', 'email', 'name'
end

partially_delete 'hobbies' do
  where 'id > 0'
end
