class AddColumnToAssignmentReviewWeight < ActiveRecord::Migration
  def self.up
    add_column :assignment_review_weights, :min_num_of_reviews, :integer
    add_column :assignment_review_weights, :min_num_of_metareviews, :integer
  end

  def self.down
  end
end
