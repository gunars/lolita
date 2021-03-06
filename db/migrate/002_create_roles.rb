class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false, :force => true  do |t|
      t.integer :user_id
      t.integer :role_id
      t.datetime :created_at
      t.datetime :updated_at
    end
    create_table :admin_roles, :force => true do |t|
      t.string :name,               :limit => 40
      t.boolean :built_in
      t.string :authorizable_type,  :limit => 30
      t.integer :authorizable_id
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    insert("INSERT INTO admin_roles (name,built_in) VALUES('administrators',1)")
    insert("INSERT INTO roles_users (user_id,role_id) VALUES(1,1)")
  end

  def self.down
    drop_table :admin_roles
    drop_table :roles_users
  end
end
