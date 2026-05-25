#!/usr/bin/env bash
set -o errexit

bundle binstubs bundler --force
bundle install
bundle exec rails assets:clobber
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate