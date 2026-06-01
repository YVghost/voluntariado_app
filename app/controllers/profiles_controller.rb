class ProfilesController < ApplicationController
  def show
    @user    = current_user
    @profile = @user.volunteer_profile

    @participaciones = @user.enrollments
                            .includes(:event, review: :reviewer)
                            .where.not(status: :cancelado)
                            .joins(:event)
                            .order("events.date DESC")

    # Promedio de scores recibidos por skill
    if @profile
      reviews = EnrollmentReview.joins(:enrollment)
                                .where(enrollments: { user: @user })
      @avg_scores = {}
      EnrollmentReview::SKILL_ATTRS.each do |attr|
        vals = reviews.pluck(attr).compact.reject { |v| v == 0 }
        @avg_scores[attr] = vals.any? ? (vals.sum.to_f / vals.size).round(1) : nil
      end
      @total_reviews = reviews.count
    end
  end
end
