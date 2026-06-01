class CreateEnrollmentReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollment_reviews do |t|
      t.references :enrollment, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.integer :primeros_auxilios_score
      t.integer :busqueda_rescate_score
      t.integer :apoyo_psicosocial_score
      t.integer :logistica_abastecimiento_score
      t.integer :maquinaria_construccion_score
      t.text :comment
      t.timestamps
    end
    add_index :enrollment_reviews, [:enrollment_id, :reviewer_id], unique: true
  end
end
