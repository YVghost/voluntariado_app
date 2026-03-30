json.extract! enrollment, :id, :user_id, :event_id, :status, :check_in_time, :latitude, :longitude, :created_at, :updated_at
json.url enrollment_url(enrollment, format: :json)
