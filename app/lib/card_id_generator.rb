module CardIdGenerator
  extend self

  PREFIX_REGEX = /[A-Z]{3}/
  FORMAT_REGEX = /\A#{PREFIX_REGEX}[0-9]{6}\z/
  PERMITTED_LETTERS = ('A'..'Z').to_a

  def random(prefix = nil)
    prefix ||= random_prefix
    raise ArgumentError, "Provided prefix '#{prefix}' does not match UHP Card ID format" unless prefix =~ PREFIX_REGEX

    [prefix, "%06d" % Random.rand(1_000_000)].join
  end

  def random_prefix
    Array.new(3) { PERMITTED_LETTERS.sample }.join
  end

  def unique(prefix = nil)
    loop do
      id = CardIdGenerator.random(prefix)
      return id unless Card.where(id: id).exists?
    end
  end
end
