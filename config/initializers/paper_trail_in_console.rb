Rails.application.console do
  old_logger = ActiveRecord::Base.logger
  ActiveRecord::Base.logger = nil

  user = nil
  until user.present? do
    puts
    puts 'Please enter your username to continue:'
    print '> '
    username = gets.strip

    user = User.where(role: ['admin', 'system_admin']).find_by(username: username)

    unless user.present?
      puts "Could not find user."
    end
  end

  puts
  puts "Welcome to the UHP Backend, #{user.name}."

  PaperTrail.set_whodunnit(user)
  PaperTrail.request.controller_info = {
    release_commit_sha: UhpBackend.release.git_sha,
    source: 'Rails::Console'
  }
  puts 'Changes made in this console will be attributed to your user record.'
  puts

  ActiveRecord::Base.logger = old_logger
end
