package cn.edu.ncpu.timetable.ncpu_timetable.widget

/** Flutter 与原生小组件之间的通道约定，需与 Dart 侧 `WidgetBridge` 保持一致。 */
object WidgetChannel {
    const val NAME = "cn.edu.ncpu.timetable/widget"
    const val METHOD_UPDATE_PAYLOAD = "updatePayload"
}
