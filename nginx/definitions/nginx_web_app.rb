define :nginx_web_app, :template => "site.erb", :enable => true do
  include_recipe "nginx::service"
  
  application = params[:application]
  application_name = params[:name]

  template "/etc/nginx/sites-available/#{application_name}" do
    Chef::Log.debug("Generating Nginx site template for #{application_name.inspect}")
    source params[:template]
    owner "root"
    group "root"
    mode 0644
    if params[:cookbook]
      cookbook params[:cookbook]
    end
    variables(
      :application => application,
      :application_name => application_name,
      :params => params
    )
    if File.exists?("/etc/nginx/sites-enabled/#{application_name}")
      notifies :reload, resources(:service => "nginx"), :delayed
    end
  end
  
  include_recipe "nginx::service"

  if params[:enable]
    execute "nxensite #{application_name}" do
      command "/usr/sbin/nxensite #{application_name}"
      notifies :reload, resources(:service => "nginx")
      not_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{application_name}") end
    end
  else
    execute "nxdissite #{application_name}" do
      command "/usr/sbin/nxdissite #{application_name}"
      notifies :reload, resources(:service => "nginx")
      only_if do File.symlink?("#{node[:nginx][:dir]}/sites-enabled/#{application_name}") end
    end
  end
end
