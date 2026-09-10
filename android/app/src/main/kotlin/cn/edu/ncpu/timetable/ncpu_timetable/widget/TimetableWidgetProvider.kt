package cn.edu.ncpu.timetable.ncpu_timetable.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.os.Bundle
import java.util.Calendar

/**
 * 桌面小组件入口。
 *
 * 只读取本地载荷并按设备日期重绘，不做任何网络或数据库访问：
 * - 系统每 30 分钟（`updatePeriodMillis`）触发一次，覆盖凌晨跨天；
 * - App 推送新载荷时由 [refreshAll] 立即触发；
 * - 用户调整尺寸时由 [onAppWidgetOptionsChanged] 触发。
 */
class TimetableWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { updateWidget(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    companion object {
        /** 表头、分隔线与内边距占用的高度，用于估算可见行数。 */
        private const val FIXED_HEIGHT_DP = 48
        private const val ROW_HEIGHT_DP = 24
        private const val DEFAULT_MAX_ROWS = 4

        /** 课表数据变化后刷新桌面上所有小组件实例。 */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TimetableWidgetProvider::class.java),
            )
            ids.forEach { updateWidget(context, manager, it) }
        }

        private fun updateWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val state = WidgetScheduleCalculator().evaluate(
                WidgetPayloadParser.parse(WidgetPreferences.load(context)),
                today(),
            )
            val views = WidgetRenderer.render(context, state, maxRows(manager, widgetId))
            manager.updateAppWidget(widgetId, views)
        }

        /** 设备本地日期，与 Dart 侧 `DateTime.now()` 同为本地时区。 */
        private fun today(): CivilDate {
            val calendar = Calendar.getInstance()
            return CivilDate(
                year = calendar.get(Calendar.YEAR),
                month = calendar.get(Calendar.MONTH) + 1,
                day = calendar.get(Calendar.DAY_OF_MONTH),
            )
        }

        private fun maxRows(manager: AppWidgetManager, widgetId: Int): Int {
            val heightDp = manager.getAppWidgetOptions(widgetId)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            if (heightDp <= 0) return DEFAULT_MAX_ROWS
            return ((heightDp - FIXED_HEIGHT_DP) / ROW_HEIGHT_DP)
                .coerceIn(1, WidgetRenderer.MAX_ROWS)
        }
    }
}
