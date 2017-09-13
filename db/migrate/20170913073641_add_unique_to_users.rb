class AddUniqueToUsers < ActiveRecord::Migration
  def change
    add_index :users, [:twi_id, :twi_screen_name], :unique => true
  end
end
