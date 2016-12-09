require 'gibbon'
require 'digest'

class MailchimpWrapper

  EVENT_TO_MAILCHIMP_PREF_MAPPINGS = {
    'users_email_list' => 'Ello News & Features',
    'daily_ello' => 'Best of Ello Daily Updates',
    'weekly_ello' => 'Best of Ello Weekly Updates'
  }

  def remove_from_users_list(email)
    hash = subscriber_hash(email)
    begin
      users_list.members(hash).update(body: { status: 'unsubscribed' })
    rescue Gibbon::MailChimpError => e
      raise e unless e.status_code == 404
    end
  end

  def upsert_to_users_list(email, preferences, categories = [], merge_fields = {})
    return if skip_list.include?(email)
    hash = subscriber_hash(email)
    begin
      users_list.members(hash).upsert(
        body: {
          email_address: email,
          status_if_new: 'subscribed',
          merge_fields: merge_fields,
          interests: interest_groups_from_prefs(preferences).merge(interest_groups_from_categories(categories.map(&:downcase)))
        })
    rescue Gibbon::MailChimpError => e
      # Ideally this would be more specific, but they don't let us just check the e-mail field
      raise e unless e.status_code == 400
    end
  end

  private

  def skip_list
    (ENV['EMAILS_TO_SKIP'] || '').split(',').map(&:strip)
  end

  def users_list
    gibbon.lists(ENV['MAILCHIMP_USERS_LIST_ID'])
  end

  def subscriber_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def interest_groups_from_prefs(prefs)
    prefs.inject({}) do |interest_groups, (key, value)|
      mailchimp_name = EVENT_TO_MAILCHIMP_PREF_MAPPINGS[key]
      if mailchimp_name && mailchimp_group = users_list_newsletters_interest_group_interests.find { |h| h[:name] == mailchimp_name }
        interest_groups[mailchimp_group[:id]] = value
      end
      interest_groups
    end
  end

  def interest_groups_from_categories(categories)
    prefs = assemble_prefs_hash(categories)
    map_category_names_to_ids(prefs)
  end

  def assemble_prefs_hash(categories)
    prefs = users_list_categories_interest_group_interests.keys.each_with_object({}) do |category, interest_groups|
      interest_groups[category] = false
    end
    assign_category_prefs(categories, prefs)
  end

  def users_list_newsletters_interest_group_interests(category_name = 'Ello Newsletters')
    @users_list_newsletters_interest_group_interests ||= begin
      category_id = find_category_id_from_name('Ello Newsletters')
      users_list.interest_categories(category_id).interests.retrieve['interests'].map { |g| { name: g['name'], id: g['id'] } }
    end
  end

  def users_list_categories_interest_group_interests
    @users_list_categories_interest_group_interests ||= begin
      id = find_category_id_from_name('Categories')
      users_list.interest_categories(id).interests.retrieve['interests'].each_with_object({}) do |category, categories|
        categories[category['name'].downcase] = category['id']
      end
    end
  end

  def find_category_id_from_name(category_name)
    users_list.interest_categories.retrieve['categories'].detect { |c| c['title'] == category_name }['id']
  end

  def map_category_names_to_ids(prefs)
    category_map = users_list_categories_interest_group_interests
    prefs.each_with_object({}) do |(category, value), interest_groups|
      category_id = category_map[category]
      interest_groups[category_id] = value
    end
  end

  def assign_category_prefs(categories, prefs)
    categories.each do |category|
      unless prefs.key?(category)
        id = find_category_id_from_name('Categories')
        users_list.interest_categories(id).interests.create(body: { name: category.capitalize })
      end
      prefs[category] = true
    end
    prefs
  end

  def gibbon
    Gibbon::Request.new
  end
end
