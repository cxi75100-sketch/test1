package cn.edu.ncpu.timetable.ncpu_timetable.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import cn.edu.ncpu.timetable.ncpu_timetable.MainActivity
import cn.edu.ncpu.timetable.ncpu_timetable.R

/** 把 [WidgetDayState] 渲染成 RemoteViews。 */
internal object WidgetRenderer {
    /** 小组件尺寸再大也最多显示的行数。 */
    const val MAX_ROWS = 6

    fun render(context: Context, state: WidgetDayState, maxRows: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_timetable)
        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.removeAllViews(R.id.widget_rows)

        when (state) {
            WidgetDayState.Empty -> {
                setHeader(views, context.getString(R.string.widget_app_name))
                showMessage(context, views, R.string.widget_open_app_hint)
            }

            WidgetDayState.NotStarted -> {
                setHeader(views, context.getString(R.string.widget_app_name))
                showMessage(context, views, R.string.widget_not_started)
            }

            WidgetDayState.Finished -> {
                setHeader(views, context.getString(R.string.widget_app_name))
                showMessage(context, views, R.string.widget_finished)
            }

            is WidgetDayState.InTerm -> {
                setHeader(
                    views,
                    context.getString(
                        R.string.widget_header,
                        state.week,
                        weekdayLabel(context, state.weekday),
                    ),
                )
                if (state.items.isEmpty()) {
                    showMessage(context, views, R.string.widget_no_class)
                } else {
                    showRows(context, views, state.items, maxRows)
                }
            }
        }
        return views
    }

    private fun setHeader(views: RemoteViews, text: String) =
        views.setTextViewText(R.id.widget_header, text)

    private fun showMessage(context: Context, views: RemoteViews, messageRes: Int) {
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        views.setViewVisibility(R.id.widget_rows, View.GONE)
        views.setTextViewText(R.id.widget_empty, context.getString(messageRes))
    }

    private fun showRows(
        context: Context,
        views: RemoteViews,
        items: List<WidgetItem>,
        maxRows: Int,
    ) {
        views.setViewVisibility(R.id.widget_empty, View.GONE)
        views.setViewVisibility(R.id.widget_rows, View.VISIBLE)

        val limit = maxRows.coerceIn(1, MAX_ROWS)
        // 课程多于可见行时，最后一行留给「还有 N 门课」提示。
        val slots = if (items.size > limit) limit - 1 else limit
        val visible = items.take(slots.coerceAtLeast(0))
        val overflow = items.size - visible.size

        visible.forEach { views.addView(R.id.widget_rows, rowViews(context, it)) }
        if (overflow > 0) {
            views.addView(R.id.widget_rows, overflowViews(context, overflow))
        }
    }

    private fun rowViews(context: Context, item: WidgetItem): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_row).apply {
            setTextViewText(R.id.widget_row_time, item.timeRange)
            setTextViewText(R.id.widget_row_name, item.name)
            setTextViewText(R.id.widget_row_classroom, item.classroom)
            setInt(R.id.widget_row_color, "setBackgroundColor", parseColor(item.colorHex))
        }

    private fun overflowViews(context: Context, count: Int): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_row).apply {
            setViewVisibility(R.id.widget_row_color, View.INVISIBLE)
            setTextViewText(R.id.widget_row_time, "")
            setTextViewText(R.id.widget_row_name, context.getString(R.string.widget_overflow, count))
            setTextViewText(R.id.widget_row_classroom, "")
        }

    private fun weekdayLabel(context: Context, weekday: Int): String =
        context.resources.getStringArray(R.array.widget_weekdays)
            .getOrElse(weekday - 1) { "" }

    private fun parseColor(hex: String): Int =
        try {
            Color.parseColor(hex)
        } catch (_: IllegalArgumentException) {
            Color.GRAY
        }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
