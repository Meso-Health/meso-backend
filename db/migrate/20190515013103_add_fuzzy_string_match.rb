class AddFuzzyStringMatch < ActiveRecord::Migration[5.0]
  def change
    enable_extension "fuzzystrmatch"
  end
end
