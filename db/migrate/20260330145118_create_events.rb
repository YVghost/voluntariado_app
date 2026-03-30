class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.datetime :date
      t.integer :status
      t.string :location
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
