package cn.edu.ncpu.timetable.ncpu_timetable.widget

import android.content.Context

/**
 * 小组件载荷的本地存储。
 *
 * 仅保存课表快照（学期起止、课程、节次时间），不含账号、Cookie、Session 或 Token。
 */
internal object WidgetPreferences {
    private const val PREFERENCES_NAME = "ncpu_timetable_widget"
    private const val KEY_PAYLOAD = "payload"

    fun save(context: Context, payload: String) {
        preferences(context).edit().putString(KEY_PAYLOAD, payload).apply()
    }

    fun load(context: Context): String? = preferences(context).getString(KEY_PAYLOAD, null)

    private fun preferences(context: Context) =
        context.applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
}
