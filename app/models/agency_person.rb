class AgencyPerson < ActiveRecord::Base
  acts_as :user
  
  belongs_to :agency
  belongs_to :branch
  has_and_belongs_to_many :agency_roles
  has_and_belongs_to_many :job_categories, join_table: 'job_specialities'
  has_and_belongs_to_many :job_seekers, join_table: 'seekers_agency_people'

  validates_presence_of :agency_id
  
  STATUS = { IVT: 'Invited',
             ACT: 'Active' }
          
  validates :status, inclusion: STATUS.values
  
  validate :not_removing_sole_agency_admin, on: :update
  
  def not_removing_sole_agency_admin
    # This validation is to prevent the removal of a sole agency admin - which
    # would result in no AgencyPerson able to perform the admin role.
    
    # If the AA role is set for this person we are OK
    agency_roles.each { |role| return if role.role == AgencyRole::ROLE[:AA] }
    
    errors[:agency_admin] << 'cannot be unset for sole agency admin.' unless
                      other_agency_admin?
  end
  
  def other_agency_admin?
    admins = Agency.agency_admins(agency)

    (admins.count == 1 && !admins.include?(self)) || admins.count > 1
  end
  
  def sole_agency_admin?
    # Is this person even an admin?
    return false unless agency_roles.pluck(:role).include? AgencyRole::ROLE[:AA]
    
    not other_agency_admin?
  end
  
  def agency_role_ids
    agency_roles.pluck(:id)
  end
  
  def job_category_ids
    job_categories.pluck(:id)
  end
  
  def job_seeker_ids
    job_seekers.pluck(:id)
  end
  
end
