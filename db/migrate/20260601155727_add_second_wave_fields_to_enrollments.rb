class AddSecondWaveFieldsToEnrollments < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :second_wave, :boolean, default: false, null: false
    add_column :enrollments, :expected_arrival, :datetime
  end
end
