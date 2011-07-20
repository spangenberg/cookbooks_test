include_recipe "deploy::rails"

# setup Nginx virtual host
node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping unicorn::rails application #{application} as it is not an Rails app")
    next
  end
  
  template "#{deploy[:deploy_to]}/shared/scripts/unicorn" do
    mode '0755'
    owner deploy[:user]
    group deploy[:group]
    source "unicorn.service.erb"
    variables(:deploy => deploy, :application => application)
  end
  
  service "unicorn_#{application}" do
    start_command "#{deploy[:deploy_to]}/shared/scripts/unicorn start"
    stop_command "#{deploy[:deploy_to]}/shared/scripts/unicorn stop"
    restart_command "#{deploy[:deploy_to]}/shared/scripts/unicorn restart"
    status_command "ps aux | grep unicorn_rails | grep #{deploy[:deploy_to]}"
    action :nothing
  end
  
  template "#{deploy[:deploy_to]}/shared/config/unicorn.conf" do
    mode '0644'
    owner deploy[:user]
    group deploy[:group]
    source "unicorn.conf.erb"
    variables(:deploy => deploy, :application => application)
    #notifies :restart, resources(:service => "unicorn_#{application}")
  end

# TODO: SSL Krams
=begin  
  template "/etc/apache2/ssl/#{deploy[:domains].first}.crt" do
    mode '0600'
    source "ssl.key.erb"
    variables :key => deploy[:ssl_certificate]
    only_if do
      deploy[:ssl_support]
    end
  end
  
  template "/etc/apache2/ssl/#{deploy[:domains].first}.key" do
    mode '0600'
    source "ssl.key.erb"
    variables :key => deploy[:ssl_certificate_key]
    only_if do
      deploy[:ssl_support]
    end
  end
  
  template "/etc/apache2/ssl/#{deploy[:domains].first}.ca" do
    mode '0600'
    source "ssl.key.erb"
    variables :key => deploy[:ssl_certificate_ca]
    only_if do
      deploy[:ssl_support] && deploy[:ssl_certificate_ca]
    end
  end
=end
end
