class MergeableMember
  attr_reader :primary_member
  attr_reader :duplicate_members

  def initialize(primary_member, duplicate_members)
    raise ArgumentError 'Must provide a primary member' unless primary_member.present?

    @primary_member = primary_member
    @duplicate_members = duplicate_members
  end

  def merge_and_archive_duplicates!
    return if @duplicate_members.blank?

    ActiveRecord::Base.transaction do
      @duplicate_members.each do |member|
        member.archive_as_duplicate_of!(primary_member)
      end
    end
  end
end
