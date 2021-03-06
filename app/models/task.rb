class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  field :description, type: String
  field :finished_at, type: Time
  belongs_to :user
  has_and_belongs_to_many :targets

  validates_presence_of :description
  validates_presence_of :finished_at

  scope :recent, -> {order("id desc")}

  def to_s
    description
  end

  after_create :refresh_targets_tasks_count
  after_update :refresh_targets_tasks_count
  def refresh_targets_tasks_count
    if self.changes['target_ids']
      new_ids = self.changes['target_ids'].first.nil? ? self.changes['target_ids'].last : (self.changes['target_ids'].last - self.changes['target_ids'].first)
      Target.find(new_ids).each{|target| target.inc(tasks_count: 1)} unless new_ids.blank?
      unless self.changes['target_ids'].first.blank?
        old_ids = self.changes['target_ids'].first - self.changes['target_ids'].last
        Target.find(old_ids).each{|target| target.inc(tasks_count: -1)} unless old_ids.blank?
      end
    end
  end

  after_destroy :dec_targets_tasks_count
  def dec_targets_tasks_count
    self.targets.each do |target|
      target.inc tasks_count: -1
    end
  end
end
