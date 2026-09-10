package cn.edu.ncpu.timetable.ncpu_timetable.widget

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * 小组件的日期与周次计算测试。
 *
 * 这些用例是与 Dart 侧 `SemesterService.currentWeek` 保持一致的契约：
 * 2026-09-07 是周一，因此该日即第 1 周周一。
 */
class WidgetScheduleCalculatorTest {
    private val calculator = WidgetScheduleCalculator()

    private val defaultSectionTimes = mapOf(
        1 to SectionTimeRange("08:00", "08:45"),
        2 to SectionTimeRange("08:55", "09:40"),
        3 to SectionTimeRange("10:00", "10:45"),
        4 to SectionTimeRange("10:55", "11:40"),
    )

    private fun payload(
        totalWeeks: Int = 20,
        courses: List<WidgetCourse> = emptyList(),
        sectionTimes: Map<Int, SectionTimeRange> = defaultSectionTimes,
    ) = WidgetPayload(
        firstWeekMonday = CivilDate(2026, 9, 7),
        totalWeeks = totalWeeks,
        courses = courses,
        sectionTimes = sectionTimes,
    )

    private fun course(
        name: String = "课程",
        weekday: Int = 1,
        startSection: Int = 1,
        endSection: Int = 2,
        weeks: Set<Int> = setOf(1),
        startTime: String? = null,
        endTime: String? = null,
    ) = WidgetCourse(
        name = name,
        classroom = "A101",
        weekday = weekday,
        startSection = startSection,
        endSection = endSection,
        startTime = startTime,
        endTime = endTime,
        weeks = weeks,
        colorHex = "#5B8FF9",
    )

    private fun stateOn(
        year: Int,
        month: Int,
        day: Int,
        data: WidgetPayload? = payload(),
    ) = calculator.evaluate(data, CivilDate(year, month, day))

    @Test
    fun epochDayAndIsoWeekdayMatchKnownDates() {
        assertEquals(0L, CivilDate(1970, 1, 1).toEpochDay())
        assertEquals(4, CivilDate(1970, 1, 1).isoWeekday())
        assertEquals(1, CivilDate(2026, 9, 7).isoWeekday())
        assertEquals(7, CivilDate(2026, 9, 13).isoWeekday())
    }

    @Test
    fun emptyWhenPayloadMissing() {
        assertEquals(WidgetDayState.Empty, stateOn(2026, 9, 7, data = null))
    }

    @Test
    fun notStartedBeforeFirstWeekMonday() {
        assertEquals(WidgetDayState.NotStarted, stateOn(2026, 9, 6))
    }

    @Test
    fun firstWeekStartsOnFirstMonday() {
        val state = stateOn(2026, 9, 7) as WidgetDayState.InTerm
        assertEquals(1, state.week)
        assertEquals(1, state.weekday)
    }

    @Test
    fun secondWeekWednesday() {
        val state = stateOn(2026, 9, 16) as WidgetDayState.InTerm
        assertEquals(2, state.week)
        assertEquals(3, state.weekday)
    }

    @Test
    fun lastSundayIsStillInTerm() {
        val state = stateOn(2027, 1, 24) as WidgetDayState.InTerm
        assertEquals(20, state.week)
        assertEquals(7, state.weekday)
    }

    @Test
    fun finishedAfterLastWeek() {
        assertEquals(WidgetDayState.Finished, stateOn(2027, 1, 25))
    }

    @Test
    fun finishedWhenTotalWeeksInvalid() {
        assertEquals(WidgetDayState.Finished, stateOn(2026, 9, 7, payload(totalWeeks = 0)))
    }

    @Test
    fun emptyItemsWhenNoCourseMatchesToday() {
        val state = stateOn(2026, 9, 8, payload(courses = listOf(course(weekday = 1)))) as WidgetDayState.InTerm
        assertEquals(emptyList<WidgetItem>(), state.items)
    }

    @Test
    fun filtersByWeekdayAndTeachingWeekThenSortsBySection() {
        val courses = listOf(
            course(name = "第五节", startSection = 5, weeks = setOf(1)),
            course(name = "第一节", startSection = 1, weeks = setOf(1)),
            course(name = "别的星期", weekday = 2, startSection = 1, weeks = setOf(1)),
            course(name = "别的周次", startSection = 1, weeks = setOf(3)),
        )
        val state = stateOn(2026, 9, 7, payload(courses = courses)) as WidgetDayState.InTerm
        assertEquals(listOf("第一节", "第五节"), state.items.map { it.name })
    }

    @Test
    fun timeRangeComesFromSectionTimes() {
        val state = stateOn(2026, 9, 7, payload(courses = listOf(course()))) as WidgetDayState.InTerm
        assertEquals("08:00-09:40", state.items.single().timeRange)
    }

    @Test
    fun courseOwnTimeWinsOverSectionTimes() {
        val state = stateOn(
            2026,
            9,
            7,
            payload(courses = listOf(course(startTime = "07:30", endTime = "09:00"))),
        ) as WidgetDayState.InTerm
        assertEquals("07:30-09:00", state.items.single().timeRange)
    }

    @Test
    fun fallsBackToSectionLabelWhenSectionTimesMissing() {
        val state = stateOn(
            2026,
            9,
            7,
            payload(
                courses = listOf(course(startSection = 3, endSection = 4)),
                sectionTimes = emptyMap(),
            ),
        ) as WidgetDayState.InTerm
        assertEquals("第3-4节", state.items.single().timeRange)
    }
}
