#
# Cookbook Name:: deploy
# Recipe:: rails-restart
#

include_recipe "deploy"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping deploy::rails-restart application #{application} as it is not a Rails app")
    next
  end
  
  execute "restart Server" do
    cwd deploy[:current_path]
    command "sleep #{deploy[:sleep_before_restart]} && /srv/www/#{application}/shared/scripts/unicorn stop"
    action :run
    
    only_if do 
      File.exists?(deploy[:current_path])
    end
  end
    
end


