class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table   :pictures do |t|
      t.string      :picture
      t.string      :pictureable_type
      t.integer     :pictureable_id
      t.boolean     :main_image
      t.string      :title
      t.string      :alt
      t.string      :caption
      t.integer      :position
      t.timestamps
    end
    add_index :pictures, [:pictureable_type,:pictureable_id]
  end

  def self.down
    drop_table :pictures
  end
end
