package com.onetoolkit.one_toolkit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FavoritesWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.favorites_widget).apply {
            val openApp =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_root, openApp)

            setTextViewText(
                R.id.widget_title,
                widgetData.getString("title", null) ?: "OneToolkit",
            )
            setTextViewText(
                R.id.widget_subtitle,
                widgetData.getString("subtitle", null) ?: "Favorites",
            )

            val toolViews =
                listOf(
                    R.id.tool_0,
                    R.id.tool_1,
                    R.id.tool_2,
                    R.id.tool_3,
                )
            for (i in toolViews.indices) {
              val name = widgetData.getString("tool_$i", null).orEmpty()
              val toolId = widgetData.getString("tool_id_$i", null).orEmpty()
              if (name.isEmpty()) {
                setViewVisibility(toolViews[i], View.GONE)
              } else {
                setViewVisibility(toolViews[i], View.VISIBLE)
                setTextViewText(toolViews[i], name)
                val uri =
                    if (toolId.isNotEmpty()) {
                      Uri.parse("onetoolkit://tool/$toolId")
                    } else {
                      null
                    }
                val pending =
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        uri,
                    )
                setOnClickPendingIntent(toolViews[i], pending)
              }
            }

            val count = widgetData.getInt("tool_count", 0)
            if (count == 0) {
              setViewVisibility(R.id.widget_empty, View.VISIBLE)
              setTextViewText(R.id.widget_empty, "Star tools in the app to pin them here")
            } else {
              setViewVisibility(R.id.widget_empty, View.GONE)
            }
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
