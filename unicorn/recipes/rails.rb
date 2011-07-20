include_recipe "deploy::rails"

# setup Nginx virtual host
node[:deploy].each do |application, deploy|
  if deploy[:application_type] != 'rails'
    Chef::Log.debug("Skipping unicorn::rails application #{application} as it is not an Rails app")
    next
  end

  execute "slapadd" do
    command "cd #{deploy[:current_path]} && unicorn_rails &"
    action :run
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
