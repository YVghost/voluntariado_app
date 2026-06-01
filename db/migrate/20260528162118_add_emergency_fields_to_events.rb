class AddEmergencyFieldsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :emergency_level, :integer
    add_column :events, :emergency_type,  :string
    add_column :events, :required_skills, :text, array: true, default: []
    add_column :events, :min_score,       :integer, default: 3
  end
end
