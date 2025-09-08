class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [ :show, :update, :destroy, :complete, :uncomplete ]

  # GET /api/v1/tasks
  def index
    tasks = current_user.tasks.includes(:category, :tags)

    # Фильтрация по параметрам
    tasks = apply_filters(tasks)

    # Сортировка
    tasks = apply_sorting(tasks)

    # Пагинация
    paginated_tasks = paginate_collection(tasks)

    render_success({
      tasks: paginated_tasks.map(&:to_api_json),
      meta: pagination_meta(tasks)
    })
  end

  # GET /api/v1/tasks/completed
  def completed
    render_filtered_tasks(current_user.tasks.completed)
  end

  # GET /api/v1/tasks/pending
  def pending
    render_filtered_tasks(current_user.tasks.pending)
  end

  # GET /api/v1/tasks/in_progress
  def in_progress
    render_filtered_tasks(current_user.tasks.in_progress)
  end

  # GET /api/v1/tasks/cancelled
  def cancelled
    render_filtered_tasks(current_user.tasks.cancelled)
  end

  # GET /api/v1/tasks/:id
  def show
    render_success(@task.to_api_json)
  end

  # POST /api/v1/tasks
  def create
    task = current_user.tasks.build(task_params)

    if task.save
      # Добавляем теги если они указаны
      if params[:task][:tag_ids].present?
        tag_ids = params[:task][:tag_ids].select { |id| current_user.tags.exists?(id) }
        task.tags = current_user.tags.where(id: tag_ids)
      end

      render_success(task.reload.to_api_json, :created)
    else
      render_validation_errors(task)
    end
  end

  # PUT/PATCH /api/v1/tasks/:id
  def update
    if @task.update(task_params)
      # Обновляем теги если они указаны
      if params[:task].key?(:tag_ids)
        tag_ids = params[:task][:tag_ids].select { |id| current_user.tags.exists?(id) }
        @task.tags = current_user.tags.where(id: tag_ids)
      end

      render_success(@task.reload.to_api_json)
    else
      render_validation_errors(@task)
    end
  end

  # DELETE /api/v1/tasks/:id
  def destroy
    @task.destroy
    render_success(nil, :no_content)
  end

  # PATCH /api/v1/tasks/:id/complete
  def complete
    if @task.complete!
      render_success(@task.to_api_json)
    else
      render_validation_errors(@task)
    end
  end

  # PATCH /api/v1/tasks/:id/uncomplete
  def uncomplete
    case @task.status
    when "completed"
      @task.update!(status: "pending")
    when "cancelled"
      @task.update!(status: "pending")
    else
      render_error("Задача уже не завершена", :unprocessable_entity)
      return
    end

    render_success(@task.to_api_json)
  end

  private

  def set_task
    @task = current_user.tasks.find_by(id: params[:id])

    unless @task
      render_not_found("Задача")
      nil
    end
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :priority, :due_date, :category_id)
  end

  def apply_filters(tasks)
    # Фильтр по статусу
    if params[:status].present?
      tasks = tasks.where(status: params[:status])
    end

    # Фильтр по приоритету
    if params[:priority].present?
      tasks = tasks.where(priority: params[:priority])
    end

    # Фильтр по категории
    if params[:category_id].present?
      tasks = tasks.where(category_id: params[:category_id])
    end

    # Фильтр по тегу
    if params[:tag_id].present?
      tasks = tasks.joins(:tags).where(tags: { id: params[:tag_id] })
    end

    # Фильтр просроченных задач
    if params[:overdue].present? && params[:overdue] == "true"
      tasks = tasks.overdue
    end

    # Фильтр задач с приближающимся дедлайном
    if params[:due_soon].present? && params[:due_soon] == "true"
      tasks = tasks.due_soon
    end

    # Поиск по названию или описанию
    if params[:search].present?
      tasks = tasks.by_name(params[:search])
    end

    tasks
  end

  def apply_sorting(tasks)
    case params[:sort_by]
    when "created_at"
      params[:order] == "asc" ? tasks.order(created_at: :asc) : tasks.recent
    when "due_date"
      tasks.by_due_date
    when "priority"
      tasks.by_priority
    when "title"
      tasks.order(title: params[:order] == "desc" ? :desc : :asc)
    else
      tasks.recent # По умолчанию сортируем по дате создания
    end
  end

  def render_filtered_tasks(tasks)
    tasks = tasks.includes(:category, :tags)
    tasks = apply_filters(tasks)
    tasks = apply_sorting(tasks)

    paginated_tasks = paginate_collection(tasks)

    render_success({
      tasks: paginated_tasks.map(&:to_api_json),
      meta: pagination_meta(tasks)
    })
  end
end
