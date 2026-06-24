class AddCanceladoStatusToEvents < ActiveRecord::Migration[8.1]
  def change
    # El enum usa integers. activo=0, finalizado=1, en_curso=2.
    # cancelado=3 es un valor nuevo que no colisiona con ninguno existente.
    # No requiere ALTER TABLE porque Rails almacena el integer directamente.
    # Solo actualizamos el comentario para documentación.
    execute "COMMENT ON COLUMN events.status IS '0=activo 1=finalizado 2=en_curso 3=cancelado'"
  end
end
