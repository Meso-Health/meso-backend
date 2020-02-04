# All the tree structure logic is copied from https://hashrocket.com/blog/posts/recursive-sql-in-activerecord

class AdministrativeDivision < ApplicationRecord
  belongs_to :parent, class_name: 'AdministrativeDivision', optional: true
  validates :name, presence: true
  validates :level, presence: true
  has_many :users
  has_many :providers
  has_many :households
  has_many :household_enrollment_records

  def self_and_descendants
    self.class.descendant_tree_for(self)
  end

  def self.self_and_descendants_ids(administrative_division)
    if administrative_division.nil?
      AdministrativeDivision.pluck(:id)
    else
      administrative_division.self_and_descendants.pluck(:id)
    end
  end

  def self.descendant_tree_for(instance)
    where("#{table_name}.id IN (#{descendant_tree_sql_for(instance)})").order("#{table_name}.id")
  end

  def self.descendant_tree_sql_for(instance)
    tree_sql =  <<-SQL
      WITH RECURSIVE search_tree(id, path) AS (
          SELECT id, ARRAY[id]
          FROM #{table_name}
          WHERE id = #{instance.id}
        UNION ALL
          SELECT #{table_name}.id, path || #{table_name}.id
          FROM search_tree
          JOIN #{table_name} ON #{table_name}.parent_id = search_tree.id
          WHERE NOT #{table_name}.id = ANY(path)
      )
      SELECT id FROM search_tree ORDER BY path
    SQL
  end

  def self_and_ancestors
    [self] + self.class.ancestor_tree_for(self)
  end

  def self.self_and_ancestors_ids(administrative_division)
    if administrative_division.nil?
      AdministrativeDivision.pluck(:id)
    else
      administrative_division.self_and_ancestors.pluck(:id)
    end
  end

  def self.ancestor_tree_for(instance)
    where("#{table_name}.id IN (#{ancestor_tree_sql_for(instance)})").order("#{table_name}.parent_id")
  end

  def self.ancestor_tree_sql_for(instance)
    tree_sql = <<-SQL
      WITH RECURSIVE search_tree(parent_id, path) AS (
          SELECT parent_id, array[parent_id]
          FROM #{table_name}
          WHERE id = #{instance.id}
        UNION ALL
          SELECT #{table_name}.parent_id, path || #{table_name}.parent_id
          FROM #{table_name}
          INNER JOIN search_tree ON #{table_name}.id = search_tree.parent_id
          WHERE NOT #{table_name}.parent_id = ANY(path)
      )
      SELECT parent_id from search_tree ORDER BY path
    SQL
  end
end
