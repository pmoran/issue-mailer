namespace :issues do

  desc "Check for new issues mails and post to git issues"
  task :update => :environment do
    count = Issues.update
    puts "Updated #{count} issues"
  end

end
