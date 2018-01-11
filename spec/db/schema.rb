ActiveRecord::Schema.define(version: 1) do
  create_table :users do |t|
    t.string :name
    t.string :email
  end

  create_table :hobbies do |t|
    t.integer :user_id
    t.string :hobby
  end
end
