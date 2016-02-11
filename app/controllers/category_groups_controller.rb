class CategoryGroupsController < ApplicationController

  helper :items

  before_filter :verify_admin!
  before_filter :find_current_category_group, :except => [:create, :update_all]


  def create
    @category_group = CategoryGroup.new(params[:category_group])
    if @category_group.save
      redirect_to(admin_categories_path(last_id: @category_group.id) )
    else
      set_flash_messages_from_errors(@category_group)
      redirect_back(admin_categories_path)
    end
  end

  ##
  # Single category group update: PUT /category_groups/10

  def update
    set_referer_as_redirect_back
    @category_group.attributes = params[:category_group]
    if @category_group.save
      respond_to do|format|
        format.js
        format.html { redirect_back(admin_categories_path(updated_id: @category_group.id)) }
      end
    else
      set_flash_messages_from_errors(@category_group)
      respond_with_error(session[:original_uri] || admin_categories_path)
    end
  end

  ##
  # Multiple categories with attributes for CategoryGroup 10 w/ params[:category_group_10][:name],
  # params[:category_group_10][:lowest_age], etc.
  def update_all
    set_referer_as_redirect_back

    params.each_pair do|k, v|
      if k.to_s =~ /^category_group_(\d+)$/
        cat_group_id = $1.to_i
        logger.info "| CategoryGroup #{cat_group_id}: #{v.inspect}"
        ::CategoryGroup.update(cat_group_id, v)

      elsif k.to_s =~ /^mapping_(\d+)$/
        cc_id = $1.to_i
        logger.info "| Mapping #{cc_id}: #{v.inspect}"
        ::CategoryGroupMapping.update(cc_id, v)

      elsif k.to_s =~ /^curated_category_(\d+)$/
        cc_id = $1.to_i
        logger.info "| Mapping #{cc_id}: #{v.inspect}"
        ::CuratedCategory.update(cc_id, v)
      end
    end

    respond_to do|format|
      format.js { render text:'' }
      format.html { redirect_to(admin_categories_path(t: Time.now.to_i) ) }
    end
  end

  ##
  # PUT|POST /category_groups/:id/add_mapping?category_group_mapping[:category_id] and add more to attributes to category_group_mapping hash
  def add_mapping
    set_referer_as_redirect_back

    if (mapping_param = params[:mapping] ) && (@category = ::Category.find_by_id(mapping_param[:category_id]) )
      @category_group_mapping = @category.assign_to_category_group!(@category_group, mapping_param)
    end
    respond_to do|format|
      format.js
      format.html { redirect_back(admin_categories_path(t: Time.now.to_i) ) }
    end
  end

  # DELETE /category_groups/:id/remove_mapping?category_id=:category_id
  def remove_mapping
    if params[:category_id]
      ::CategoryGroupMapping.delete(category_group_id: @category_group.id, category_id: params[:category_id])
    end
    respond_to do|format|
      format.js
      format.html { redirect_back(admin_categories_path(t: Time.now.to_i) ) }
    end
  end

  ##
  # PUT|POST /category_groups/:id/add_curated_category?curated_category[:category_id] and add more to attributes to curated_category hash
  def add_curated_category
    set_referer_as_redirect_back

    if (mapping_param = params[:curated_category] ) && (@category = ::Category.find_by_id(mapping_param[:category_id]) )
      attr_h = { category_group_id: @category_group.id, category_id: @category.id }
      @curated_category = ::CuratedCategory.where(attr_h).first || ::CuratedCategory.new(attr_h)
      @curated_category.attributes = mapping_param
      @curated_category.save

      if @category_group.for_female?
        @category.female_index
      end
    end
    respond_to do|format|
      format.js
      format.html { redirect_back(admin_categories_path(t: Time.now.to_i) ) }
    end
  end

  private

  def find_current_category_group
    @category_group = CategoryGroup.find_by_id(params[:id])
    unless @category_group
      flash[:error] = "The requested category group cannot be found."
      redirect_back(admin_categories_path) && return
    end
  end

end