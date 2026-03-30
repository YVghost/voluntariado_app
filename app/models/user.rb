class User < ApplicationRecord
  # Devise
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Roles
  enum :role, { admin: 0, organizador: 1, voluntario: 2 }

  # Relaciones
  has_many :enrollments, dependent: :destroy
  has_many :events, through: :enrollments
  has_many :messages, dependent: :destroy
end