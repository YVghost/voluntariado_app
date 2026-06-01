class AddSkillScoresToVolunteerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :volunteer_profiles, :skill_scores, :jsonb, default: {}
  end
end
