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
  
  include_recipe "#{node[:scalarium][:rails_stack][:service]}::service" if node[:scalarium][:rails_stack][:service]

  case node[:scalarium][:rails_stack][:service]

  when 'apache_passenger'
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

  else
    raise "Unsupport Rails stack"
  end

  directory "#{deploy[:deploy_to]}" do
    recursive true
    action :delete

    notifies :restart, resources(:service => node[:scalarium][:rails_stack][:service])
  
    only_if do 
      File.exists?("#{deploy[:deploy_to]}")
    end
  end
  
end


