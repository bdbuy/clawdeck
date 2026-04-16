class AgentController < ApplicationController
  def chat
    response = case params[:message_type]
    when "focus"
      build_focus_response
    when "weekly_recap"
      build_weekly_recap_response
    when "ask_agent"
      build_ask_response(params[:message].to_s.strip)
    else
      render json: { error: "无效的 message_type" }, status: :unprocessable_entity and return
    end

    render json: { response: response }
  end

  private

  def tasks
    @tasks ||= current_user.tasks.unscoped.where(user_id: current_user.id)
  end

  def build_focus_response
    today = Date.current
    lines = []

    # Overdue tasks are top priority
    overdue = tasks.where("due_date < ? AND status != ?", today, Task.statuses[:done])
                   .order(due_date: :asc).limit(5).pluck(:name, :due_date)
    overdue.each do |name, due|
      lines << "#{name} — 已逾期（截止 #{due.strftime("%-m月%-d日")}）"
    end

    # Tasks due today
    due_today = tasks.where(due_date: today).where.not(status: :done)
                     .order(priority: :desc).pluck(:name)
    due_today.each do |name|
      lines << "#{name} — 今天到期"
    end

    # In-progress tasks (already started, keep momentum)
    in_progress = tasks.where(status: :in_progress).order(priority: :desc).limit(5).pluck(:name)
    in_progress.each do |name|
      lines << "#{name} — 已在进行中" unless lines.length >= 5
    end

    # High priority up_next tasks to fill remaining slots
    if lines.length < 3
      up_next = tasks.where(status: :up_next).order(priority: :desc, position: :asc)
                     .limit(3 - lines.length).pluck(:name, :priority)
      up_next.each do |name, priority|
        label = priority == "high" ? "高优先级" : "接下来"
        lines << "#{name} — #{label}"
      end
    end

    if lines.empty?
      "目前一切清爽：没有逾期任务、今天没有到期任务、也没有进行中的任务。你可以享受空档，或从收件箱/待办里挑一个推进。"
    else
      top = lines.first(3).each_with_index.map { |line, i| "#{i + 1}. #{line}" }
      result = "你需要关注的事项：\n\n#{top.join("\n")}"
      remaining = tasks.where.not(status: :done).count - top.length
      result += "\n\n另外还有 #{remaining} 个未完成任务分布在你的看板中。" if remaining > 0
      result
    end
  end

  def build_weekly_recap_response
    today = Date.current
    week_start = today.beginning_of_week(:monday)

    completed = tasks.where(status: :done).where("completed_at >= ?", week_start)
    completed_names = completed.limit(5).pluck(:name)
    completed_count = completed.count

    in_flight = tasks.where(status: :in_progress).pluck(:name)
    overdue = tasks.where("due_date < ? AND status != ?", today, Task.statuses[:done]).pluck(:name)
    total_open = tasks.where.not(status: :done).count

    # Agent activity this week
    agent_completions = TaskActivity
      .joins(:task)
      .where(tasks: { user_id: current_user.id })
      .where(actor_type: "agent")
      .where("task_activities.created_at >= ?", week_start)
      .count

    lines = []

    # Completed
    if completed_count > 0
      done_text = completed_names.first(3).join(", ")
      done_text += " 等（另有 #{completed_count - 3} 个）" if completed_count > 3
      lines << "本周已完成（#{completed_count}）：#{done_text}。"
    else
      lines << "本周还没有完成任何任务。"
    end

    # In flight
    if in_flight.any?
      suffix = in_flight.length > 3 ? " 等（另有 #{in_flight.length - 3} 个）" : ""
      lines << "进行中（#{in_flight.length}）：#{in_flight.first(3).join(", ")}#{suffix}。"
    end

    # Needs attention
    if overdue.any?
      lines << "需要关注：#{overdue.length} 个逾期 — #{overdue.first(3).join(", ")}。"
    end

    # Agent contribution
    if agent_completions > 0
      lines << "你的 Agent 本周处理了 #{agent_completions} 次动作。"
    end

    lines << "当前仍有 #{total_open} 个未完成任务。" if total_open > 0

    lines.join("\n\n")
  end

  def build_ask_response(message)
    return "可以问我：逾期、进行中、已完成、本周回顾、各看板情况等。" if message.blank?

    q = message.downcase

    if q.match?(/overdue|late|missed|behind|逾期|超期/)
      overdue = tasks.where("due_date < ? AND status != ?", Date.current, Task.statuses[:done])
                     .order(due_date: :asc).pluck(:name, :due_date)
      if overdue.any?
        lines = overdue.first(5).map { |name, due| "#{name} — 截止 #{due.strftime("%-m月%-d日")}" }
        "你有 #{overdue.length} 个逾期任务：\n\n#{lines.join("\n")}"
      else
        "没有逾期任务，进度不错。"
      end

    elsif q.match?(/progress|working|doing|current|进行中|在做|当前/)
      in_progress = tasks.where(status: :in_progress).pluck(:name)
      if in_progress.any?
        "当前进行中（#{in_progress.length}）：\n\n#{in_progress.first(5).join("\n")}"
      else
        "当前没有进行中的任务。"
      end

    elsif q.match?(/done|complete|finish|完成|已完成/)
      week_start = Date.current.beginning_of_week(:monday)
      done = tasks.where(status: :done).where("completed_at >= ?", week_start).pluck(:name)
      if done.any?
        "本周已完成（#{done.length}）：\n\n#{done.first(5).join("\n")}"
      else
        "本周还没有完成任何任务。"
      end

    elsif q.match?(/board|project|看板|项目/)
      boards = current_user.boards.includes(:tasks)
      lines = boards.map do |b|
        open_count = b.tasks.reject(&:completed).length
        "#{b.icon} #{b.name} — #{open_count} 个未完成任务"
      end
      lines.join("\n")

    elsif q.match?(/blocked|stuck|help|阻塞|卡住|需要帮助/)
      blocked = tasks.where(blocked: true).where.not(status: :done).pluck(:name)
      if blocked.any?
        "被阻塞的任务（#{blocked.length}）：\n\n#{blocked.first(5).join("\n")}"
      else
        "当前没有被阻塞的任务。"
      end

    elsif q.match?(/agent|openclaw|智能体|助手/)
      if current_user.agent_last_active_at.present?
        name = current_user.agent_name || "Agent"
        emoji = current_user.agent_emoji || "🦞"
        ago = time_ago_in_words(current_user.agent_last_active_at)
        assigned = tasks.where(assigned_to_agent: true, completed: false).count
        "#{emoji} #{name} 最后活跃于 #{ago} 前。目前有 #{assigned} 个任务分配给你的 Agent。"
      else
        "尚未连接任何 Agent。请到“设置”里完成 OpenClaw 集成。"
      end

    elsif q.match?(/how many|count|total|stat|多少|统计/)
      total = tasks.where.not(status: :done).count
      by_status = tasks.where.not(status: :done).group(:status).count
      lines = by_status.map { |status, count| "#{status.titleize}: #{count}" }
      "未完成任务共 #{total} 个：\n\n#{lines.join("\n")}"

    else
      total_open = tasks.where.not(status: :done).count
      in_progress = tasks.where(status: :in_progress).count
      "你有 #{total_open} 个未完成任务，其中 #{in_progress} 个在进行中。可以问我：逾期、进行中、阻塞、看板概览、本周回顾等。"
    end
  end
end
