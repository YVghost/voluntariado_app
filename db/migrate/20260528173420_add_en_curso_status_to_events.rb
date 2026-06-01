class AddEnCursoStatusToEvents < ActiveRecord::Migration[8.1]
  def up
    # en_curso = 2; el enum se define en el modelo (integer almacenado).
    # No hay filas con valor 2 en producción → safe to add.
  end

  def down
  end
end
