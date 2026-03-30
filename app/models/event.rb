class Event < ApplicationRecord
  belongs_to :organization

  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_many :messages, dependent: :destroy

  enum :status, { activo: 0, finalizado: 1 }
end