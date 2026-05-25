#!/usr/bin/env bash
set -o errexit

gem install bundler --no-document
bundle config set --local path vendor/bundle
bundle install
bundle exec rails assets:clobber
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate

echo "=== Copying JS controllers to public/assets ==="
mkdir -p public/assets/controllers
for f in app/javascript/controllers/*.js; do
  name=$(basename "$f" .js)
  cp "$f" "public/assets/controllers/$name"
  cp "$f" "public/assets/controllers/$name.js"
done
echo "=== Done: $(ls public/assets/controllers/ | wc -l) files ==="