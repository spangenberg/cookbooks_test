define :unicorn_web_app do
  deploy = params[:deploy]
  application = params[:application]

  ruby_block 'Determine Unicorn application type' do
    inner_deploy = deploy
    inner_application = application
    block do
      inner_deploy[:unicorn_handler] = if File.exists?("#{inner_deploy[:deploy_to]}/current/config.ru")
        Chef::Log.info("Looks like #{inner_application} is a Rack application")
        "Rack"
      else
        Chef::Log.info("No config.ru found, assuming #{inner_application} is a Rails application")
        "Rails"
      end
    end
  end

  nginx_web_app deploy[:application] do
    docroot deploy[:absolute_document_root]
    server_name deploy[:domains].first
    server_aliases deploy[:domains][1, deploy[:domains].size] unless deploy[:domains][1, deploy[:domains].size].empty?
    rails_env deploy[:rails_env]
    mounted_at deploy[:mounted_at]
    ssl_certificate_ca deploy[:ssl_certificate_ca]
    cookbook "unicorn"
    deploy deploy
    template "nginx_unicorn_web_app.erb"
    application deploy
  end
end
