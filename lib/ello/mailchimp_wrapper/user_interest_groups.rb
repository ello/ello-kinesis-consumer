require_relative './interest_group.rb'

class UserInterestGroups

  EVENT_TO_MAILCHIMP_PREF_MAPPINGS = {
    'users_email_list' => 'Ello News & Features',
    'daily_ello' => 'Best of Ello Daily Updates',
    'weekly_ello' => 'Best of Ello Weekly Updates'
  }

  def initialize(preferences:, categories:, featured_categories:)
    @preferences = preferences
    @categories = categories
    @featured_categories = featured_categories
  end

  def as_json
    followed_category_interest_groups.
      merge(preference_interest_groups).
      merge(featured_category_interest_groups)
  end

  def followed_category_interest_groups
    @categories.each_with_object({}) do |category, memo|
      id = InterestGroup.find_or_create_interest_group_id('Categories', category)
      memo[id] = true if id
    end
  end

  def featured_category_interest_groups
    @featured_categories.each_with_object({}) do |category, memo|
      id = InterestGroup.find_or_create_interest_group_id('Featured Categories', category)
      memo[id] = true if id
    end
  end

  def preference_interest_groups
    @preferences.each_with_object({}) do |(name, subscribe), memo|
      mc_pref = EVENT_TO_MAILCHIMP_PREF_MAPPINGS[name]
      next unless mc_pref
      id = InterestGroup.find_or_create_interest_group_id('Ello Newsletters', mc_pref)
      memo[id] = subscribe if id
    end
  end
end
