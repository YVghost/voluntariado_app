class AddDefaultRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: nil, to: 2
    # Asignar voluntario a usuarios existentes sin rol
    User.where(role: nil).update_all(role: 2)
  end
end
