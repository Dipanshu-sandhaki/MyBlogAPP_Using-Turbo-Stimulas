cat > bin/render-build.sh << 'EOF'
#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails assets:clobber
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
EOF