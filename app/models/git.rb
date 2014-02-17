class Git

  include HTTParty

  base_uri 'https://api.github.com/repos'
  headers 'Content-Type' => 'application/json'

  def self.repo(options = {})
    Git.basic_auth(options[:username], options[:password])
    Repo.new(options[:owner], options[:repo])
  end

end

class Repo

  attr_reader :name, :user

  def initialize(user, name)
    @user = user
    @name = name
  end

  def issues
    JSON.parse(get("issues").body)
  end

  def issue(issue)
    post("issues", :body => issue.to_json)
  end

  private

  def get(action, options = {})
    Git.get repo_url_for(action), options
  end

  def post(action, options = {})
    Git.post repo_url_for(action), options
  end

  def repo_url_for(action)
    "/#{user}/#{name}/#{action}"
  end
end
