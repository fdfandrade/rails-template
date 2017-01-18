RAILS_REQUIREMENT = '~> 5.0.1'

def apply_template!
  start_message
  assert_minimum_rails_version
  #assert_git
  #assert_heroku
  #assert_valid_options
  #assert_postgresql
  add_template_repository_to_source_path

  template 'Gemfile.tt',   :force => true
  template 'README.md.tt', :force => true

  rails_command 'db:setup'

  rails_command 'g devise:install'
  rails_command 'g devise user -e'

  rails_command 'db:migrate'

  rails_command 'g devise:views user -e'
  rails_command 'g controller home index -e'

  # add first language, remember to copy helper and application controller
  rails_command 'gettext:add_language LANGUAGE=en'

  # configure puma
  copy_file 'Procfile', 'Procfile', :force => true

  directory 'config', 'config', :force => true

  directory 'app/assets/javascripts', 'app/assets/javascripts', :force => true
  directory 'app/assets/stylesheets', 'app/assets/stylesheets', :force => true
  
  directory 'app/controllers', 'app/controllers', :force => true
  
  directory 'app/helpers', 'app/helpers', :force => true
  
  directory 'app/views', 'app/views', :force => true

  inject_into_file 'config/environments/development.rb', after: "config.action_mailer.perform_caching = false\n" do <<-'RUBY'
  config.action_mailer.default_url_options = {:host => "localhost:3000"}
    RUBY
  end

  inject_into_file 'config/environments/production.rb', after: "config.action_mailer.perform_caching = false\n" do <<-'RUBY'
  config.action_mailer.default_url_options = { host: 'https://your-app-name.herokuapp.com/' }
    RUBY
  end
  
  # create the git repo and the first commit
  git :init

  # create heroku app
  run 'heroku create'

  git add: '.'
  run 'git commit -m "Initialize repository!"'

  # we need to do a first successfull installation
  run 'git push heroku master'

  # run db:setup
  run 'heroku run rails db:migrate'

  # run db:migrate
  run 'heroku ps:scale web=1'

  # configure sendgrid
  run 'heroku addons:create sendgrid:starter'

end

def start_message
  puts '================================================================'
  puts '=  Start configuring your application -> ' + app_name
  puts '================================================================'
end

#
# copied from https://github.com/mattbrictson
#
def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = 'This template requires Rails #{RAILS_REQUIREMENT}. '\
           'You are using #{rails_version}. Continue anyway?'
  exit 1 if no?(prompt)
end

#
# copied from https://github.com/mattbrictson
#
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git :clone => [
      '--quiet',
      'https://github.com/mattbrictson/rails-template.git',
      tempdir
    ].map(&:shellescape).join(' ')
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

# apply the template
apply_template!