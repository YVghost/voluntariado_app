class AddPersonalFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :cedula, :string
    add_column :users, :nombres, :string
    add_column :users, :apellidos, :string
  end
end
