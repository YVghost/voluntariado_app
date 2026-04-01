class AddOrgFieldsToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :ruc, :string
    add_reference :organizations, :user, null: true, foreign_key: true
  end
end
