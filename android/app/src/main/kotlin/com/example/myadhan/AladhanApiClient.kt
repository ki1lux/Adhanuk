package com.example.myadhan

import android.util.Log
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

/**
 * Lightweight HTTP client for the Aladhan prayer-times API.
 * Uses java.net.HttpURLConnection — no external dependencies.
 *
 * API docs: https://aladhan.com/prayer-times-api
 */
object AladhanApiClient {

    private const val TAG = "AladhanApiClient"
    private const val BASE_URL = "https://api.aladhan.com/v1/timings"
    private const val TIMEOUT_MS = 15_000

    /**
     * Fetches today's prayer times for the given coordinates.
     *
     * @param latitude  User latitude
     * @param longitude User longitude
     * @param method    Calculation method (19 = Algeria)
     * @param school    Juristic school (0 = Shafi)
     * @return [PrayerTimesResponse] on success, null on failure
     */
    fun fetchPrayerTimes(
        latitude: Double,
        longitude: Double,
        method: Int = 19,
        school: Int = 0,
        date: java.util.Date? = null
    ): PrayerTimesResponse? {
        val dateFormat = java.text.SimpleDateFormat("dd-MM-yyyy", java.util.Locale.US)
        val dateString = dateFormat.format(date ?: java.util.Date())
        val urlStr = "$BASE_URL/$dateString?latitude=$latitude&longitude=$longitude&method=$method&school=$school"

        Log.d(TAG, "Fetching: $urlStr")

        var connection: HttpURLConnection? = null
        try {
            connection = (URL(urlStr).openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = TIMEOUT_MS
                readTimeout = TIMEOUT_MS
            }

            if (connection.responseCode != 200) {
                Log.e(TAG, "HTTP ${connection.responseCode}")
                return null
            }

            val body = BufferedReader(InputStreamReader(connection.inputStream)).use { it.readText() }
            val json = JSONObject(body)

            if (json.getInt("code") != 200) {
                Log.e(TAG, "API error: ${json.optString("status")}")
                return null
            }

            val data = json.getJSONObject("data")
            val timings = data.getJSONObject("timings")
            val hijriObj = data.getJSONObject("date").getJSONObject("hijri")

            val hijriStr = "${hijriObj.getString("day")} " +
                    "${hijriObj.getJSONObject("month").getString("ar")} " +
                    hijriObj.getString("year")

            return PrayerTimesResponse(
                fajr    = cleanTime(timings.getString("Fajr")),
                dhuhr   = cleanTime(timings.getString("Dhuhr")),
                asr     = cleanTime(timings.getString("Asr")),
                maghrib = cleanTime(timings.getString("Maghrib")),
                isha    = cleanTime(timings.getString("Isha")),
                hijriDate = hijriStr
            )
        } catch (e: Exception) {
            Log.e(TAG, "Fetch failed: ${e.message}")
            return null
        } finally {
            connection?.disconnect()
        }
    }

    /** Strip any timezone suffix like " (CEST)" → keep only "HH:mm" */
    private fun cleanTime(raw: String): String = raw.split(" ").first()

    data class PrayerTimesResponse(
        val fajr: String,
        val dhuhr: String,
        val asr: String,
        val maghrib: String,
        val isha: String,
        val hijriDate: String
    )
}
