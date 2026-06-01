class CreateVolunteerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :volunteer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.decimal    :score, precision: 4, scale: 2, default: 0.0
      t.text       :skills, array: true, default: []
      t.jsonb      :certifications, default: {}
      t.jsonb      :quiz_answers, default: {}
      t.datetime   :quiz_completed_at
      t.string     :country
      t.string     :city
      t.string     :sector
      t.boolean    :available, default: true
      t.timestamps
    end
  end
end
