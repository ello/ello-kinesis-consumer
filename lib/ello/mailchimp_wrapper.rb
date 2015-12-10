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
    hash = subscriber_hash(email)
    users_list.members(hash).upsert(
      body: {
        email_address: email,
        status: 'subscribed',
        interests: prefs_to_interest_groups(preferences)
      })
  end

  def remove_from_experimental_list(email)
    hash = subscriber_hash(email)
    begin
      experimental_list.members(hash).update(body: { status: 'unsubscribed' })
    rescue Gibbon::MailChimpError => e
      raise e unless e.status_code == 404
    end
  end

  def upsert_to_experimental_list(email)
    hash = subscriber_hash(email)
    experimental_list.members(hash).upsert(
      body: {
        email_address: email,
        status: 'subscribed'
      })
  end

  private

  def users_list
    gibbon.lists(ENV['MAILCHIMP_USERS_LIST_ID'])
  end

  def experimental_list
    gibbon.lists(ENV['MAILCHIMP_EXPERIMENTAL_LIST_ID'])
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

  def users_list_interest_groups(category_name = 'Ello Newsletters')
    @interest_groups ||= begin
                      category_id = users_list.interest_categories.retrieve['categories'].find { |c| c['title'] == category_name }['id']
                      users_list.interest_categories(category_id).interests.retrieve['interests'].map { |g| { name: g['name'], id: g['id'] } }
                    end
  end

  def gibbon
    Gibbon::Request.new
  end
end
