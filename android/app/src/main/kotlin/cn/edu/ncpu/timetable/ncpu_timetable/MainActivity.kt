package cn.edu.ncpu.timetable.ncpu_timetable

import cn.edu.ncpu.timetable.ncpu_timetable.widget.TimetableWidgetProvider
import cn.edu.ncpu.timetable.ncpu_timetable.widget.WidgetChannel
import cn.edu.ncpu.timetable.ncpu_timetable.widget.WidgetPreferences
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WidgetChannel.NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                WidgetChannel.METHOD_UPDATE_PAYLOAD -> handleUpdatePayload(call.arguments, result)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 保存最新课表快照并立即刷新桌面小组件。
     *
     * 载荷只包含课表数据，不含账号、Cookie、Session 或 Token。
     */
    private fun handleUpdatePayload(arguments: Any?, result: MethodChannel.Result) {
        val payload = arguments as? String
        if (payload == null) {
            result.error("invalid_argument", "payload must be a JSON string", null)
            return
        }
        WidgetPreferences.save(applicationContext, payload)
        TimetableWidgetProvider.refreshAll(applicationContext)
        result.success(true)
    }
}
