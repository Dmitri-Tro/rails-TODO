class Api::V1::TagsController < Api::V1::BaseController
  before_action :set_tag, only: [ :show, :update, :destroy ]

  # GET /api/v1/tags
  def index
    tags = current_user.tags.includes(:tasks)

    # Фильтрация и поиск
    tags = apply_filters(tags)

    # Сортировка
    tags = apply_sorting(tags)

    # Пагинация
    paginated_tags = paginate_collection(tags)

    render_success({
      tags: paginated_tags.map(&:to_api_json),
      meta: pagination_meta(tags)
    })
  end

  # GET /api/v1/tags/:id
  def show
    render_success(@tag.to_api_json)
  end

  # POST /api/v1/tags
  def create
    tag = current_user.tags.build(tag_params)

    if tag.save
      render_success(tag.to_api_json, :created)
    else
      render_validation_errors(tag)
    end
  end

  # PUT/PATCH /api/v1/tags/:id
  def update
    if @tag.update(tag_params)
      render_success(@tag.to_api_json)
    else
      render_validation_errors(@tag)
    end
  end

  # DELETE /api/v1/tags/:id
  def destroy
    if @tag.delete_safe
      render_success(nil, :no_content)
    else
      render_error(@tag.errors.full_messages.join(", "), :unprocessable_entity)
    end
  end

  private

  def set_tag
    @tag = current_user.tags.find_by(id: params[:id])

    unless @tag
      render_not_found("Тег")
      nil
    end
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end

  def apply_filters(tags)
    # Поиск по названию
    if params[:search].present?
      tags = tags.by_name(params[:search])
    end

    # Фильтр тегов с задачами
    if params[:with_tasks].present? && params[:with_tasks] == "true"
      tags = tags.joins(:tasks).distinct
    end

    # Фильтр неиспользуемых тегов
    if params[:unused].present? && params[:unused] == "true"
      tags = tags.left_joins(:tasks).where(tasks: { id: nil })
    end

    # Фильтр по цвету
    if params[:color].present?
      tags = tags.where(color: params[:color])
    end

    # Фильтр популярных тегов (использование > определенного процента)
    if params[:popular].present? && params[:popular] == "true"
      # Получаем теги с процентом использования > 50%
      # Это требует выполнения в Ruby, так как расчет процентов сложен в SQL
      popular_tag_ids = current_user.tags.includes(:tasks).select { |tag| tag.usage_percentage > 50.0 }.map(&:id)
      tags = tags.where(id: popular_tag_ids)
    end

    tags
  end

  def apply_sorting(tags)
    case params[:sort_by]
    when "name"
      tags.order(name: params[:order] == "desc" ? :desc : :asc)
    when "usage"
      # Сортировка по количеству использований с помощью подзапроса
      order_sql = "(SELECT COUNT(*) FROM task_tags WHERE task_tags.tag_id = tags.id)"
      tags.order("#{order_sql} #{params[:order] == 'asc' ? 'ASC' : 'DESC'}")
    when "created_at"
      params[:order] == "asc" ? tags.order(created_at: :asc) : tags.order(created_at: :desc)
    else
      tags.order(:name) # По умолчанию сортируем по имени
    end
  end
end
