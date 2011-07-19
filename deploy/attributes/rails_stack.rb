default[:scalarium][:rails_stack][:name] = "apache_passenger"
case default[:scalarium][:rails_stack][:name]
when "apache_passenger"
  Chef::Log.error("Setting to passenger")
  default[:scalarium][:rails_stack][:recipe] = "passenger_apache2::rails"
  default[:scalarium][:rails_stack][:needs_reload] = true
  default[:scalarium][:rails_stack][:service] = 'apache2'
when "nginx_unicorn"
  Chef::Log.error("Setting to unicorn")
  default[:scalarium][:rails_stack][:recipe] = "unicorn::rails"
  default[:scalarium][:rails_stack][:needs_reload] = true
  default[:scalarium][:rails_stack][:service] = 'unicorn'
else
  raise "Unknown stack: #{default[:scalarium][:rails_stack][:name].inspect}"
end

Chef::Log.error("Set to: #{default[:scalarium][:rails_stack][:recipe].inspect}")