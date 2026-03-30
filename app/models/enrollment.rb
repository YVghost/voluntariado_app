class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :event

  enum :status, { inscrito: 0, asistio: 1, cancelado: 2 }
end