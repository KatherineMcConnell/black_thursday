require 'time'

class Merchant
  attr_reader :repo
  attr_accessor :id, :name, :created_at

  def initialize(merchant_hash, repo)
    @id = merchant_hash[:id].to_i
    @name = merchant_hash[:name]
    if merchant_hash[:created_at].to_s == ""
      @created_at = Time.parse((Time.now).to_s)
    else
      @created_at = Time.parse(merchant_hash[:created_at].to_s)
    end
    @repo = repo
  end

  def to_hash
    self_hash = Hash.new
    self_hash[:id] = @id
    self_hash[:name] = @name
    self_hash[:created_at] = @created_at
    self_hash
  end
end
