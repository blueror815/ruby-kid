class CategoriesController < ApplicationController

  helper :items

  before_filter :find_current_category, :only => [:show, :edit, :update, :destroy]
  before_filter :set_page_title
  before_filter :verify_admin!, only: [:admin, :new, :edit, :update, :update_all, :create, :destroy]
  skip_before_filter :verify_auth_user, except: [:welcome_kids]

  # GET /categories
  # GET /categories.json
  def index

    if params[:sort] == 'sorted_for_boys'
      @categories = ::Category.where("male_index != 0").order('male_index asc')
    elsif params[:sort] == 'sorted_for_girls'
      @categories = ::Category.where("female_index != 0").order('female_index asc')
    else
      params[:sort] = 'all'
      @categories = ::Category.all
    end

    if auth_user.is_a?(Admin)
      @page_title = 'Categories Admin'
      set_this_as_redirect_back

      respond_to do |format|
        format.html { render(template: 'categories/index', layout:'minimal') }
        format.json { render json: @categories }
      end

    else # regular user
      @page_title = 'Categories'

      respond_to do |format|
        format.html { redirect_to(:user_categories) }
        format.json { render json: @categories }
      end
    end
  end

  def welcome_kids
    result =
      if category_group = ::CategoryGroup.for_user(auth_user)
        logger.info "| #{category_group} w/ #{category_group.curated_categories.count} curated_categories"
        category_group.curated_categories.order('order_index asc').limit(6).compact
      else
        CuratedCategory.get_from_age_group(auth_user.grade, auth_user.gender.upcase)
      end
    message = "You need to post STUFF to trade!"

    respond_to do |format|
      format.json {
        render json: {
          categories: result,
          message: message
        }
      }
      format.text { render text: result.to_json }
    end
  end

  def admin
    @page_title = 'Categories Admin'
    set_this_as_redirect_back

    @categories = ::Category.all
    @category_groups = ::CategoryGroup.includes(:category_group_mappings).all

    respond_to do |format|
      format.js { }
      format.html { render template: 'categories/admin', layout: 'layouts/minimal' }
      format.json { render json: @categories }
    end
  end

  def user_categories
    set_this_as_redirect_back
    @page_title = "User Categories"
    user = auth_user.is_a?(Child) ? auth_user : User.find_by_id(params[:child_id].to_i)
    if user
      @category_group = CategoryGroup.for_user(user)
      logger.info "|----- CategoryGroup #{@category_group}"
      @categories = @category_group.categories.order('order_index asc') if @category_group
    end
    @categories ||= Category.all

    logger.info "|  User Categories: #{@categories.collect(&:name) }"
    respond_to do |format|
      format.html { params[:role] == 'admin' ? render(:index) : render }
      format.json { render json: @categories }
    end
  end

  # GET /categories/1
  # GET /categories/1.json
  def show

    params[:category_id] = params[:id]
    params[:school_id] = auth_user.current_school_id

    @items_search = Item.build_search(params, auth_user)
    @items_search.execute
    @items = @items_search.results

    logger.info "-------------------- #{@items_search.inspect}"
    logger.info "  Page #{params[:page]}: #{@items.size} out of total #{@items_search.total}"

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: {items: @items_search.results, page: (params[:page] || 1), per_page: Item.per_page, total_count: @items_search.total} }
    end
  end

  # GET /categories/new
  # GET /categories/new.json
  def new
    @category = Category.new
    @category_group = CategoryGroup.find_by_id(params[:category_group_id]) if params[:category_group_id]
    respond_to do |format|
      format.html { render template:'categories/new', layout:'minimal' }
      format.json { render json: @category }
    end
  end

  # GET /categories/1/edit
  def edit
    set_referer_as_redirect_back

    @category_group = CategoryGroup.find_by_id(params[:category_group_id]) if params[:category_group_id]

    respond_to do|format|
      format.html { render template:'categories/edit', layout:'minimal' }
      format.js
    end
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = Category.new(params[:category])
    @category.category_group_id ||= params[:category_group_id]

    respond_to do |format|
      if @category.save
        save_curated_items(@category)
        format.html { redirect_to(categories_path, notice: 'Category was successfully created.') }
        format.json { render json: @category, status: :created, location: @category }
      else
        set_flash_messages_from_errors(@category)
        format.html { render action: "new" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.json
  def update
    respond_to do |format|
      category_params = params[:category]
      if category_params
        category_params[:male_index] = 0 if category_params[:male_index].nil?
        category_params[:female_index] = 0 if category_params[:female_index].nil?
      end
      if category_params.nil? || @category.update_attributes(category_params)
        save_curated_items(@category)
        format.js
        format.html { redirect_back(categories_path, notice: category_params ? 'Category was successfully updated.' : '') }
        format.json { head :no_content }
      else
        set_flash_messages_from_errors(@category)
        format.js
        format.html { render action: "edit" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_all
    params.each_pair do|k, v|
      if k.to_s =~ /^category_(\d+)$/
        cat_id = $1.to_i
        cat = Category.find cat_id
        logger.info "| Category #{cat_id} #{cat.name}: #{v.inspect}"
        ::Category.update(cat_id, v)
      end
    end
    respond_to do|format|
      format.js { render text:'' }
      format.html { redirect_to(categories_path(t: Time.now.to_i) ) }
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    @category.destroy

    respond_to do |format|
      format.js
      format.html { redirect_to(admin_categories_path) }
      format.json { head :no_content }
    end
  end

  private

  def find_current_category
    @category = Category.find_by_id(params[:id])
    unless @category
      flash[:error] = "The requested category cannot be found."
      redirect_back(categories_path) && return
    else
      @category.category_group_id = params[:category_group_id]
    end
  end

  def save_curated_items(category)
    uploaded_images = params[:curated_item_image] || []
    curated_item_ids = params[:curated_item_id] || []
    if uploaded_images.present? || curated_item_ids.present?
      @category.category_curated_items.delete_all
      new_curated_items = []
      0.upto(3).each do|idx|
        if ( uploaded_image = uploaded_images[idx] ) && uploaded_image.is_a?(ActionDispatch::Http::UploadedFile)
          citem = ::Items::CategoryCuratedItem.create_sample_item(nil, category.id,
            item_photos:[uploaded_image] )
          new_curated_items << citem
          logger.info ">> Created sample curated item: #{citem}"
        elsif (item_id = curated_item_ids[idx].to_i ) > 0
          if (item = Item.find_by_id(item_id))
            citem = ::Items::CategoryCuratedItem.new(item_id: item.id, category_id: category.id )
            new_curated_items << citem
            logger.info ">> Connecting item #{item_id} to category #{category.id}"
          end
        end
      end
      @category.category_curated_items = new_curated_items
      @category.save
    end
  end

  def set_page_title
    @page_title = @category.name if @category
  end
end
