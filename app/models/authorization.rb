class Authorization < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    provider :string, :null => false, :index => true
    uid      :string, :null => false, :index => true
    email_address :string, :index => true
    name     :string
    nickname :string
    location :string
    image    :string
    description :text
    phone    :string
    urls     :serialized
    timestamps
  end
  attr_accessible :uid, :provider, :user, :user_id, :email_address, :name, :nickname, :location, :image, :description, :phone, :urls, :user, :user_id
  validates_uniqueness_of :uid, :scope => :provider

  mattr_accessor :user_class
  def self.user_class
    @@user_class.constantize
  end
  @@user_class ||= "User"

  belongs_to :user, :class_name => Authorization.user_class

  validates_presence_of :user_id, :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.id == user_id || acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.id == user_id || acting_user.administrator?
  end

  def view_permitted?(field)
    acting_user.id == user_id || acting_user.administrator?
  end

end
