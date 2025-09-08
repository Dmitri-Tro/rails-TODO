class Api::V1::CategoriesController < Api::V1::BaseController
  before_action :set_category, only: [ :show, :update, :destroy ]

  # GET /api/v1/categories
  def index
    categories = current_user.categories.includes(:tasks)

    # Фильтрация и поиск
    categories = apply_filters(categories)

    # Сортировка
    categories = apply_sorting(categories)

    # Пагинация
    paginated_categories = paginate_collection(categories)

    render_success({
      categories: paginated_categories.map(&:to_api_json),
      meta: pagination_meta(categories)
    })
  end

  # GET /api/v1/categories/:id
  def show
    render_success(@category.to_api_json)
  end

  # POST /api/v1/categories
  def create
    category = current_user.categories.build(category_params)

    if category.save
      render_success(category.to_api_json, :created)
    else
      render_validation_errors(category)
    end
  end

  # PUT/PATCH /api/v1/categories/:id
  def update
    if @category.update(category_params)
      render_success(@category.to_api_json)
    else
      render_validation_errors(@category)
    end
  end

  # DELETE /api/v1/categories/:id
  def destroy
    if @category.delete_safe
      render_success(nil, :no_content)
    else
      render_error(@category.errors.full_messages.join(", "), :unprocessable_entity)
    end
  end

  private

  def set_category
    @category = current_user.categories.find_by(id: params[:id])

    unless @category
      render_not_found("Категория")
      nil
    end
  end

  def category_params
    params.require(:category).permit(:name, :description, :color)
  end

  def apply_filters(categories)
    # Поиск по названию
    if params[:search].present?
      categories = categories.by_name(params[:search])
    end

    # Фильтр категорий с задачами
    if params[:with_tasks].present? && params[:with_tasks] == "true"
      categories = categories.joins(:tasks).distinct
    end

    # Фильтр пустых категорий
    if params[:empty].present? && params[:empty] == "true"
      categories = categories.left_joins(:tasks).where(tasks: { id: nil })
    end

    categories
  end

  def apply_sorting(categories)
    case params[:sort_by]
    when "name"
      categories.order(name: params[:order] == "desc" ? :desc : :asc)
    when "tasks_count"
      # Sort by tasks count using a subquery to avoid GROUP BY conflicts with pagination
      order_sql = "(SELECT COUNT(*) FROM tasks WHERE tasks.category_id = categories.id)"
      categories.order("#{order_sql} #{params[:order] == 'asc' ? 'ASC' : 'DESC'}")
    when "created_at"
      params[:order] == "asc" ? categories.order(created_at: :asc) : categories.order(created_at: :desc)
    else
      categories.order(:name) # По умолчанию сортируем по имени
    end
  end
end
