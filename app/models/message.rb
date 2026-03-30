class Message < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :content, presence: true

  after_create_commit do
    broadcast_append_to [event, :chat],
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
  end
end