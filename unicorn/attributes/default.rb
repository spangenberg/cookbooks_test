default[:unicorn][:worker_processes] = node[:rails][:max_pool_size] ? node[:rails][:max_pool_size] : 4
default[:unicorn][:worker_processes] = 60
default[:unicorn][:backlog] = 64
default[:unicorn][:preload_app] = false