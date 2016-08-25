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

  def upsert_to_users_list(email, preferences)
    return if skip_list.include?(email)
    hash = subscriber_hash(email)
    begin
      users_list.members(hash).upsert(
        body: {
          email_address: email,
          status_if_new: 'subscribed',
          interests: prefs_to_interest_groups(preferences)
        })
    rescue Gibbon::MailChimpError => e
      # Ideally this would be more specific, but they don't let us just check the e-mail field
      raise e unless e.status_code == 400
    end
  end

  def upsert_to_categories_list(email, preferences)
    hash = subscriber_hash(email)
    begin
      categories_list.members(hash).upsert(
        body: {
          email_address: email,
          status_if_new: 'subscribed',
          interests: prefs_to_interest_groups_for_categories(preferences)
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

  def categories_list
    gibbon.lists(ENV['MAILCHIMP_CATEGORIES_LIST_ID'])
  end

  def subscriber_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def prefs_to_interest_groups(prefs)
    prefs.inject({}) do |interest_groups, (key, value)|
      mailchimp_name = EVENT_TO_MAILCHIMP_PREF_MAPPINGS[key]
      if mailchimp_name
        if mailchimp_group = users_list_interest_groups.find { |h| h[:name] == mailchimp_name }
          interest_groups[mailchimp_group[:id]] = value
        end
      end
      interest_groups
    end
  end

  def prefs_to_interest_groups_for_categories(categories)
    prefs = assemble_prefs_hash(categories)
    map_category_names_to_ids(prefs)
  end

  def assemble_prefs_hash(categories)
    prefs = categories_list_interest_groups.keys.each_with_object({}) do |category, interest_groups|
      interest_groups[category] = false
    end
    assign_category_prefs(categories, prefs)
  end

  def users_list_interest_groups(category_name = 'Ello Newsletters')
    @interest_groups ||= begin
                      category_id = users_list.interest_categories.retrieve['categories'].find { |c| c['title'] == category_name }['id']
                      users_list.interest_categories(category_id).interests.retrieve['interests'].map { |g| { name: g['name'], id: g['id'] } }
                    end
  end

  def categories_list_interest_groups
    id = interest_categories_id_for_categories
    categories_list.interest_categories(id).interests.retrieve['interests'].each_with_object({}) do |category, categories|
      categories[category['name'].downcase] = category['id']
    end
  end

  def interest_categories_id_for_categories
    @id ||= categories_list.interest_categories.retrieve['categories'].first['id']
  end

  def map_category_names_to_ids(prefs)
    category_map = categories_list_interest_groups
    prefs.each_with_object({}) do |(category, value), interest_groups|
      category_id = category_map[category]
      interest_groups[category_id] = value
    end
  end

  def assign_category_prefs(categories, prefs)
    categories.each do |category|
      if prefs.has_key?(category)
        prefs[category] = true
      else
        id = interest_categories_id_for_categories
        categories_list.interest_categories(id).interests.create(body: { name: category.capitalize })
        prefs[category] = true
      end
    end
    prefs
  end

  def gibbon
    Gibbon::Request.new
  end
end
