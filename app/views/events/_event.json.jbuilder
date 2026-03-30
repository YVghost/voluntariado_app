json.extract! event, :id, :title, :description, :date, :status, :location, :organization_id, :created_at, :updated_at
json.url event_url(event, format: :json)
