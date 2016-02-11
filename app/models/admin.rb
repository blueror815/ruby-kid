class Admin < User

  DEFAULT_PROFILE_IMAGE_NAME = 'cubbyshop-yellow-regular@2x.png'

  def self.cubbyshop_admin
    cubbyshop_admin = find_by_user_name('KidsTrade')
    if cubbyshop_admin.nil?
      cubbyshop_admin = new(user_name:'KidsTrade', email:'admin@KidsTrade.com', first_name:'KidsTrade')

      cubbyshop_admin.type = 'Admin'
      cubbyshop_admin.password = 'p16mo$4KidsBH@p'
      cubbyshop_admin.parent_id = 0
      cubbyshop_admin.profile_image_name = DEFAULT_PROFILE_IMAGE_NAME
      cubbyshop_admin.save
    end
    cubbyshop_admin
  end
end
