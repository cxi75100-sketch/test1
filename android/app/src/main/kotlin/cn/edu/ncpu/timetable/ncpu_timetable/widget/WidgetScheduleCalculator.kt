package cn.edu.ncpu.timetable.ncpu_timetable.widget

/** 小组件在指定日期应当显示的内容。 */
sealed interface WidgetDayState {
    /** 从未打开过 App，或本地载荷已损坏。 */
    data object Empty : WidgetDayState

    /** 学期尚未开始。 */
    data object NotStarted : WidgetDayState

    /** 学期已结束（含假期）。 */
    data object Finished : WidgetDayState

    /** 学期进行中。 */
    data class InTerm(
        val week: Int,
        val weekday: Int,
        val items: List<WidgetItem>,
    ) : WidgetDayState
}

/** 小组件中的一行课程。 */
data class WidgetItem(
    val name: String,
    val classroom: String,
    val timeRange: String,
    val colorHex: String,
)

/**
 * 按设备日期计算小组件内容。
 *
 * 周次规则必须与 Dart 侧 `SemesterService.currentWeek`
 * （lib/services/semester_service.dart）保持一致：以开学周一为起点每 7 天记一周。
 * 区别仅在边界展示：App 内把开学前显示为第 1 周、学期结束后封顶在总周数，
 * 而小组件直接展示「学期还没开始」/「学期已结束」，避免假期里继续显示旧课表。
 */
class WidgetScheduleCalculator {
    fun evaluate(payload: WidgetPayload?, today: CivilDate): WidgetDayState {
        if (payload == null) return WidgetDayState.Empty
        val offsetDays = today.toEpochDay() - payload.firstWeekMonday.toEpochDay()
        if (offsetDays < 0) return WidgetDayState.NotStarted
        val week = (offsetDays / 7).toInt() + 1
        if (payload.totalWeeks <= 0 || week > payload.totalWeeks) return WidgetDayState.Finished
        val weekday = today.isoWeekday()
        val items = payload.courses
            .filter { it.weekday == weekday && week in it.weeks }
            .sortedBy { it.startSection }
            .map { it.toItem(payload.sectionTimes) }
        return WidgetDayState.InTerm(week = week, weekday = weekday, items = items)
    }

    private fun WidgetCourse.toItem(sectionTimes: Map<Int, SectionTimeRange>): WidgetItem {
        val start = startTime ?: sectionTimes[startSection]?.startTime
        val end = endTime ?: sectionTimes[endSection]?.endTime
        val timeRange =
            if (start != null && end != null) "$start-$end" else "第${startSection}-${endSection}节"
        return WidgetItem(
            name = name,
            classroom = classroom,
            timeRange = timeRange,
            colorHex = colorHex,
        )
    }
}
