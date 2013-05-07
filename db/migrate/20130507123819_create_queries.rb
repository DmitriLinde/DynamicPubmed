class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :value

      t.timestamps
    end
  end
end
