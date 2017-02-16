require_relative './interest_group.rb'

class UserInterestGroups

  EVENT_TO_MAILCHIMP_PREF_MAPPINGS = {
    'users_email_list' => 'Ello News & Features',
    'daily_ello' => 'Best of Ello Daily Updates',
    'weekly_ello' => 'Best of Ello Weekly Updates',
    'onboarding_drip' => 'Tips for Getting Started',
  }

  def initialize(preferences:)
    @preferences = preferences
  end

  def as_json
    preference_interest_groups
  end

  def preference_interest_groups
    @preferences.each_with_object({}) do |(name, subscribe), memo|
      mc_pref = EVENT_TO_MAILCHIMP_PREF_MAPPINGS[name]
      next unless mc_pref
      id = InterestGroup.find_interest_group_id('Ello Newsletters', mc_pref)
      memo[id] = subscribe if id
    end
  end
end
