package cn.edu.ncpu.timetable.ncpu_timetable.widget

/**
 * 与 Dart 侧 `DateTime(year, month, day)` 对应的纯日期值。
 *
 * 刻意不使用 java.time：minSdk 24 上 java.time 需要 API 26 或额外的 desugaring 依赖。
 */
data class CivilDate(val year: Int, val month: Int, val day: Int) {
    /**
     * 自 1970-01-01 起的天数（Howard Hinnant 的 days_from_civil 算法）。
     *
     * 两端都以「纯日期」比较，避免时区与夏令时带来的偏差。
     */
    fun toEpochDay(): Long {
        val adjustedYear = if (month <= 2) year - 1 else year
        val era = (if (adjustedYear >= 0) adjustedYear else adjustedYear - 399) / 400
        val yearOfEra = adjustedYear - era * 400
        val dayOfYear =
            (153 * (if (month > 2) month - 3 else month + 9) + 2) / 5 + day - 1
        val dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097L + dayOfEra - 719468L
    }

    /** ISO 星期：1 = 周一 … 7 = 周日，与 Dart 的 `DateTime.weekday` 一致。 */
    fun isoWeekday(): Int = ((toEpochDay() + 3).mod(7L) + 1).toInt()
}

/** 由 Flutter 侧推送的整周课表快照。 */
data class WidgetPayload(
    val firstWeekMonday: CivilDate,
    val totalWeeks: Int,
    val courses: List<WidgetCourse>,
    val sectionTimes: Map<Int, SectionTimeRange>,
)

/** 课程条目；只保留小组件渲染需要的字段。 */
data class WidgetCourse(
    val name: String,
    val classroom: String,
    val weekday: Int,
    val startSection: Int,
    val endSection: Int,
    val startTime: String?,
    val endTime: String?,
    val weeks: Set<Int>,
    val colorHex: String,
)

/** 某个节次的上下课时间。 */
data class SectionTimeRange(val startTime: String, val endTime: String)
