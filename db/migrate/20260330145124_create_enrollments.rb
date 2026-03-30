class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :status
      t.datetime :check_in_time
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
