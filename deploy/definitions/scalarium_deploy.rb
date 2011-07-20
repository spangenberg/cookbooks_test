define :scalarium_deploy do
  application = params[:app]
  deploy = params[:deploy_data]

  directory "#{deploy[:deploy_to]}" do
    group deploy[:group]
    owner deploy[:user]
    mode "0775"
    action :create
    recursive true
  end

  if deploy[:scm]
    ensure_scm_package_installed(deploy[:scm][:scm_type])

    prepare_git_checkouts(:user => deploy[:user],
                          :group => deploy[:group],
                          :home => deploy[:home],
                          :ssh_key => deploy[:scm][:ssh_key]) if deploy[:scm][:scm_type].to_s == 'git'

    prepare_svn_checkouts(:user => deploy[:user],
                          :group => deploy[:group],
                          :home => deploy[:home],
                          :deploy => deploy,
                          :application => application) if deploy[:scm][:scm_type].to_s == 'svn'

    if deploy[:scm][:scm_type].to_s == 'archive'
      repository = prepare_archive_checkouts(deploy[:scm])
      deploy[:scm] = {
        :scm_type => 'git',
        :repository => repository
      }
    end
  end

  Chef::Log.debug("Checking out source code of application #{application} with type #{deploy[:application_type]}")
  
  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
  end

  ruby_block "change HOME to #{deploy[:home]} for source checkout" do
    block do
      ENV['HOME'] = "#{deploy[:home]}"
    end
  end

  # setup deployment & checkout
  if deploy[:scm]
    deploy deploy[:deploy_to] do
      repository deploy[:scm][:repository]
      user deploy[:user]
      revision deploy[:scm][:revision]
      migrate deploy[:migrate]
      migration_command deploy[:migrate_command]
      environment deploy[:environment]
      symlink_before_migrate deploy[:symlink_before_migrate]
      action deploy[:action]
      restart_command "sleep #{deploy[:sleep_before_restart]} && #{node[:scalarium][:rails_stack][:restart_command]}"
      case deploy[:scm][:scm_type].to_s
      when 'git'
        scm_provider :git
        enable_submodules deploy[:enable_submodules]
        shallow_clone deploy[:shallow_clone]
      when 'svn'
        scm_provider :subversion
        svn_username deploy[:scm][:user]
        svn_password deploy[:scm][:password]
        svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
        svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
      else
        raise "unsupported SCM type #{deploy[:scm][:scm_type].inspect}"
      end

      before_migrate do
        run_symlinks_before_migrate
        if deploy[:application_type] == 'rails'
          if deploy[:auto_bundle_on_deploy]
            Scalarium::RailsConfiguration.bundle(application, node[:deploy][application], release_path)
          end

          node[:deploy][application][:database][:adapter] = Scalarium::RailsConfiguration.determine_database_adapter(application, node[:deploy][application], release_path, :force => node[:force_database_adapter_detection], :consult_gemfile => node[:deploy][application][:auto_bundle_on_deploy])
          template "#{node[:deploy][application][:deploy_to]}/shared/config/database.yml" do
            cookbook "rails"
            source "database.yml.erb"
            mode "0660"
            owner node[:deploy][application][:user]
            group node[:deploy][application][:group]
            variables(:database => node[:deploy][application][:database], :environment => node[:deploy][application][:rails_env])
          end.run_action(:create)
        elsif deploy[:application_type] == 'nodejs'
          if deploy[:auto_npm_install_on_deploy]
            Scalarium::NodejsConfiguration.npm_install(application, node[:deploy][application], release_path)
          end
        end

        # run user provided callback file
        run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
      end
    end
  end

  ruby_block "change HOME back to /root after source checkout" do
    block do
      ENV['HOME'] = "/root"
    end
  end

  # Need to be uncommented in production
  # XXX
  if deploy[:application_type] == 'rails'# && node[:scalarium][:instance][:roles].include?('rails-app')
    case node[:scalarium][:rails_stack][:name]

    when 'apache_passenger'
      passenger_web_app do
        application application
        deploy deploy
      end

    when 'nginx_unicorn'
      unicorn_web_app do
        application application
        deploy deploy
      end
      
    else
      raise "Unsupport Rails stack"
    end
  end

  template "/etc/logrotate.d/scalarium_app_#{application}" do
    backup false
    source "logrotate.erb"
    cookbook 'deploy'
    owner "root"
    group "root"
    mode 0644
    variables( :log_dirs => ["#{deploy[:deploy_to]}/shared/log" ] )
  end
end
