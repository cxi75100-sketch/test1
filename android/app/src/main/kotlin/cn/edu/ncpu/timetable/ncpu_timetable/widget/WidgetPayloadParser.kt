package cn.edu.ncpu.timetable.ncpu_timetable.widget

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * 解析 Flutter 侧 `buildWidgetPayload`（lib/features/widget/services/widget_payload_builder.dart）
 * 产出的 JSON。
 *
 * 版本不匹配、字段缺失或 JSON 损坏时返回 null，由调用方降级为「打开 App 完成设置」，
 * 不抛异常、不猜测数据。
 */
internal object WidgetPayloadParser {
    /** 与 Dart 侧 `widgetPayloadSchemaVersion` 必须一致。 */
    private const val SCHEMA_VERSION = 1

    fun parse(json: String?): WidgetPayload? {
        if (json.isNullOrBlank()) return null
        return try {
            val root = JSONObject(json)
            if (root.optInt("schemaVersion", -1) != SCHEMA_VERSION) return null
            val semester = root.optJSONObject("semester") ?: return null
            val firstWeekMonday = parseDate(semester.optString("firstWeekMonday")) ?: return null
            WidgetPayload(
                firstWeekMonday = firstWeekMonday,
                totalWeeks = semester.optInt("totalWeeks", 0),
                courses = root.optJSONArray("courses").toCourses(),
                sectionTimes = root.optJSONArray("sectionTimes").toSectionTimes(),
            )
        } catch (_: JSONException) {
            null
        }
    }

    private fun parseDate(value: String): CivilDate? {
        val parts = value.split("-")
        if (parts.size != 3) return null
        val year = parts[0].toIntOrNull() ?: return null
        val month = parts[1].toIntOrNull() ?: return null
        val day = parts[2].toIntOrNull() ?: return null
        return CivilDate(year = year, month = month, day = day)
    }

    private fun JSONArray?.toCourses(): List<WidgetCourse> {
        if (this == null) return emptyList()
        return (0 until length()).mapNotNull { index ->
            val item = optJSONObject(index) ?: return@mapNotNull null
            WidgetCourse(
                name = item.optString("name"),
                classroom = item.optString("classroom"),
                weekday = item.optInt("weekday", 0),
                startSection = item.optInt("startSection", 0),
                endSection = item.optInt("endSection", 0),
                startTime = item.optStringOrNull("startTime"),
                endTime = item.optStringOrNull("endTime"),
                weeks = item.optJSONArray("weeks").toIntSet(),
                colorHex = item.optString("colorHex"),
            )
        }
    }

    private fun JSONArray?.toSectionTimes(): Map<Int, SectionTimeRange> {
        if (this == null) return emptyMap()
        return (0 until length()).mapNotNull { index ->
            val item = optJSONObject(index) ?: return@mapNotNull null
            val section = item.optInt("section", 0)
            if (section <= 0) return@mapNotNull null
            section to SectionTimeRange(
                startTime = item.optString("startTime"),
                endTime = item.optString("endTime"),
            )
        }.toMap()
    }

    private fun JSONArray?.toIntSet(): Set<Int> {
        if (this == null) return emptySet()
        return (0 until length()).mapNotNull { optInt(it, 0).takeIf { value -> value > 0 } }.toSet()
    }

    private fun JSONObject.optStringOrNull(key: String): String? =
        if (isNull(key)) null else optString(key).ifEmpty { null }
}
