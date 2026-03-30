class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_user

  def mark_as_read!
    update!(read: true)
  end

  private

  def broadcast_to_user
    broadcast_prepend_to "notifications_#{user_id}",
      target: "notifications_list",
      partial: "notifications/notification",
      locals: { notification: self }

    broadcast_replace_to "notifications_#{user_id}",
      target: "notifications_badge",
      html: badge_html
  end

  def badge_html
    count = user.notifications.unread.count
    count > 0 ? "<span id='notifications_badge'>(#{count})</span>" : "<span id='notifications_badge'></span>"
  end
end
