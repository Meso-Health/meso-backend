module PaperTrail
  CONTROLLER_INFO_KEYS = %w[release_commit_sha source].map(&:to_sym).freeze

  module_function
  def with_whodunnit(actor, &block)
    raise ArgumentError, "expected to receive a block" unless block_given?

    old_whodunnit = ::PaperTrail.request.whodunnit
    ::PaperTrail.set_whodunnit(actor)
    yield
  ensure
    ::PaperTrail.request.whodunnit = old_whodunnit
  end

  def set_whodunnit(actor)
    ::PaperTrail.request.whodunnit = ::PaperTrail.whodunnit_format(actor)
  end

  def whodunnit_format(actor)
    class_name = actor.class.to_s
    id = actor.to_param
    [class_name, id].join(':')
  end

  def without_versioning
    old_state = ::PaperTrail.enabled?
    ::PaperTrail.enabled = false
    yield
  ensure
    ::PaperTrail.enabled = old_state
  end

  class Version < ActiveRecord::Base
    include PaperTrail::VersionConcern

    def user
      class_name, id = whodunnit.split(':')
      class_name.constantize.find(id)
    end
  end
end
