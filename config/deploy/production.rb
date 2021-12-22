# frozen_string_literal: true

set :stage, :production

role :app, ENV.fetch('DEPLOY_PRODUCTION_ROLES_APP', '').split(',')
role :web, ENV.fetch('DEPLOY_PRODUCTION_ROLES_WEB', '').split(',')
role :db, ENV.fetch('DEPLOY_PRODUCTION_ROLES_DB', '').split(',')

set :sidekiq_processes, ENV.fetch('DEPLOY_PRODUCTION_SIDEKIQ_PROCESSES', 8).to_i
set :sidekiq_concurrency, ENV.fetch('DEPLOY_PRODUCTION_SIDEKIQ_CONCURRENCY', 25).to_i
