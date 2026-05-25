#!/usr/bin/env bash
set -o errexit

gem install bundler --no-document

bundle config set --local path vendor/bundle
bundle install

bundle exec rails assets:clobber
bundle exec rails assets:precompile
bundle exec rails assets:clean

bundle exec rails db:migrate