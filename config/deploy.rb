# config valid only for current version of Capistrano
lock '3.7.1'

set :application, 'loomio'
set :repo_url, 'git@github.com:panter/loomio.git'
set :branch, 'panter'

set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push(*%w[
  plugins
  public/system
  public/client
  public/uploads
  public/img/emojis
])

namespace :deploy do
  before :updating, :build_angular do
    run_locally do
      rake 'deploy:build'
    end
  end

  after :updated, :restart_delayed_job do
    on roles(:app) do
      within release_path do
        execute :curl, '--silent -d "action=restart" http://localhost:2812/delayed_job > /dev/null'
      end
    end
  end

  after :updated, :sync_assets do
    require_relative '../lib/version'

    paths = {
      'client/development' => "client/#{Loomio::Version.current}",
      'client/fonts'       => 'client/fonts',
      'img/emojis'         => 'img/emojis',
    }

    roles(:app).each do |role|
      paths.each do |source, target|
        system "rsync -az --del public/#{source}/ #{fetch :user}@#{role.hostname}:#{release_path}/public/#{target}/"
      end
    end

    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          rake 'plugins:fetch[panter]'
          rake 'plugins:install[fetched]'
        end
      end
    end
  end

  after :published, :update_clients do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          rake 'loomio:notify_clients_of_update'
        end
      end
    end
  end
end
