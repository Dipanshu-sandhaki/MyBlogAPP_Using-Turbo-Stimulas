cat > bin/render-build.sh << 'EOF'
#!/usr/bin/env bash
set -o errexit

gem install bundler --no-document
bundle install
bundle exec rails assets:clobber
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate

echo "=== COMPILED CONTROLLERS ==="
ls public/assets/controllers/ 2>/dev/null || echo "NO CONTROLLERS DIRECTORY FOUND"
echo "==========================="
EOF