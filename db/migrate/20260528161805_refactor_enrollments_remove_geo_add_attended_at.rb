class RefactorEnrollmentsRemoveGeoAddAttendedAt < ActiveRecord::Migration[8.1]
  def up
    # Datos primero (antes de cambiar el enum en el modelo)
    execute "UPDATE enrollments SET status = 3 WHERE status = 2"  # cancelado: 2→3
    execute "UPDATE enrollments SET status = 2 WHERE status = 1"  # asistio:   1→2
    execute "UPDATE enrollments SET status = 1 WHERE status = 0"  # inscrito→confirmado: 0→1

    remove_column :enrollments, :latitude
    remove_column :enrollments, :longitude
    add_column    :enrollments, :attended_at, :datetime
  end

  def down
    add_column :enrollments, :latitude,  :float
    add_column :enrollments, :longitude, :float
    remove_column :enrollments, :attended_at
    execute "UPDATE enrollments SET status = 0 WHERE status = 1"
    execute "UPDATE enrollments SET status = 1 WHERE status = 2"
    execute "UPDATE enrollments SET status = 2 WHERE status = 3"
  end
end
