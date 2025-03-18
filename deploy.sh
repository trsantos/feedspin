#!/bin/bash -i

set -e
git pull
bundle install
bundle exec bootsnap precompile --gemfile
bundle exec bootsnap precompile app/ lib/
bin/rails assets:precompile
bin/rails db:prepare
sudo systemctl restart puma sidekiq
