define :nginx_web_app, :template => "nginx_web_app.conf.erb" do
  
  application_name = params[:name]

  template "/etc/nginx/sites-available/#{application_name}.conf" do
    Chef::Log.debug("Generating Nginx site template for #{application_name.inspect}")
    source params[:template]
    owner "root"
    group "root"
    mode 0644
    if params[:cookbook]
      cookbook params[:cookbook]
    end
    variables(
      :application_name => application_name,
      :params => params
    )
    if File.exists?("/etc/nginx/sites-enabled/#{application_name}.conf")
      notifies :reload, resources(:service => "nginx"), :delayed
    end
  end
  
  nginx_site "#{params[:name]}.conf" do
    enable enable_setting
  end
end
