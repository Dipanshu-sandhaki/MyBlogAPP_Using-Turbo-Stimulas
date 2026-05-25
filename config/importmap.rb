pin "application"

pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.23
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"

pin "chart.js" # @4.5.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.4.0
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.1.300
