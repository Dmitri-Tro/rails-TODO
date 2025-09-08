class Api::V1::StatsController < Api::V1::BaseController
  def index
    stats = {
      users: {
        total: User.count,
        admins: User.admins.count,
        regular: User.regular_users.count
      },
      tasks: {
        total: Task.count,
        by_status: {
          pending: Task.pending.count,
          in_progress: Task.in_progress.count,
          completed: Task.completed.count,
          cancelled: Task.cancelled.count
        },
        by_priority: {
          high: Task.high_priority.count,
          medium: Task.where(priority: 3).count,
          low: Task.where(priority: [ 0, 1, 2 ]).count
        },
        overdue: Task.overdue.count,
        due_soon: Task.due_soon.count
      },
      categories: {
        total: Category.count,
        with_tasks: Category.joins(:tasks).distinct.count
      },
      tags: {
        total: Tag.count,
        used: Tag.joins(:tasks).distinct.count
      }
    }

    render_success(stats)
  end
end
