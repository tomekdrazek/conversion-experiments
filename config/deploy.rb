# lock '3.4.0'

set :application, 'conversion-experiments'
set :repo_url, 'git@git.newshubmedia.com:SPV/conversion-experiments.git'

set :deploy_to, '/home/spv/conversion-experiments'

set :log_level, :debug

set :linked_files,  [ "config/init.rb" ]
set :linked_dirs,   [ "config/apps", "public", "log", "tmp" ]
