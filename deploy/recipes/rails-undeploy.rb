#
# Cookbook Name:: deploy
# Recipe:: rails-undeploy
#

include_recipe "deploy"

node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping deploy::rails-undeploy application #{application} as it is not an Rails app")
    next
  end

  case node[:scalarium][:rails_stack][:name]

  when 'apache_passenger'
    include_recipe "#{node[:scalarium][:rails_stack][:service]}::service" if node[:scalarium][:rails_stack][:service]

    link "/etc/apache2/sites-enabled/#{application}.conf" do
      action :delete
      only_if do 
        File.exists?("/etc/apache2/sites-enabled/#{application}.conf")
      end
    
      notifies :restart, resources(:service => node[:scalarium][:rails_stack][:service])
    end

    file "/etc/apache2/sites-available/#{application}.conf" do
      action :delete
      only_if do 
        File.exists?("/etc/apache2/sites-available/#{application}.conf")
      end
    end

    notifies :restart, resources(:service => node[:scalarium][:rails_stack][:service])

  when 'nginx_unicorn'
    link "/etc/nginx/sites-enabled/#{application}" do
      action :delete
      only_if do 
        File.exists?("/etc/nginx/sites-enabled/#{application}")
      end
    
      notifies :restart, resources(:service => node[:scalarium][:rails_stack][:service])
    end

    file "/etc/nginx/sites-available/#{application}" do
      action :delete
      only_if do 
        File.exists?("/etc/nginx/sites-available/#{application}")
      end
    end

    command "sleep #{deploy[:sleep_before_restart]} && ../../shared/scripts/unicorn stop"
    notifies :restart, resources(:service => "nginx")

  else
    raise "Unsupport Rails stack"
  end

  directory "#{deploy[:deploy_to]}" do
    recursive true
    action :delete
  
    only_if do 
      File.exists?("#{deploy[:deploy_to]}")
    end
  end
  
end


