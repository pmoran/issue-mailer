class Issues

  GIT_USERNAME = ENV['GIT_USERNAME']
  GIT_PASSWORD = ENV['GIT_PASSWORD']
  GIT_REPO_OWNER = ENV['GIT_REPO_OWNER']
  GIT_REPO = ENV['GIT_REPO']
  MAILBOX_USERNAME = ENV['MAILBOX_USERNAME']
  MAILBOX_PASSWORD = ENV['MAILBOX_PASSWORD']
  EMAIL = ENV['EMAIL']

  def initialize(options = {})
    Mail.defaults do
      retriever_method :pop3,
        :address    => options[:address]    || "mail.gandi.net",
        :port       => options[:port]       || 110,
        :enable_ssl => options[:enable_ssl] || false,
        :user_name  => options[:mailbox_username] || MAILBOX_USERNAME,
        :password   => options[:mailbox_password] || MAILBOX_PASSWORD
    end
    @repo = Git.repo(:username => GIT_USERNAME, :password => GIT_PASSWORD, :owner => GIT_REPO_OWNER, :repo => GIT_REPO)
  end

  def self.update(options = {})
    issues = Issues.new(options)
    count = 0
    Mail.find_and_delete do |mail|
      if mail.to.include?(EMAIL) and mail.from.all? {|m| m =~ /jetstar\.com/ }
        issues.post(Issues.from(mail)) ? count += 1 : mail.skip_deletion
      else
        mail.skip_deletion
      end
    end
    count
  end

  def self.from(mail)
    body = mail.multipart? ? mail.parts.first.body.to_s : mail.body.to_s
    body.gsub!(/\#end.*/m, '')
    {
      title: mail.subject,
      body: "[Submitted by: #{mail.from.first}]\n\n#{body}",
      labels: ["emailed"]
    }
  end

  def post(issue)
    result = @repo.issue(issue)
    return true if result.code.to_s =~ /^2/
    p "Couldn't post issue: #{result}" unless result.code.to_s =~ /^2/
    false
  end

end
