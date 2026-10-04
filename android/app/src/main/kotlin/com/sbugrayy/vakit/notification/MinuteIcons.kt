package com.sbugrayy.vakit.notification

import com.sbugrayy.vakit.R

// Kaynaklar tool/gen_status_icons.py ile üretiliyor.
// getIdentifier yerine doğrudan derleme zamanı R referansları kullanılır:
// R8 kaynak küçültmesi (resource shrinking) adı dinamik çözülen kaynakları
// kullanılmıyor sanıp silebilir; açık başvuru kaynakların korunmasını sağlar.
object MinuteIcons {
    const val MAX_MINUTES = 60

    private val RES = intArrayOf(
        R.drawable.ic_stat_minute_00, R.drawable.ic_stat_minute_01,
        R.drawable.ic_stat_minute_02, R.drawable.ic_stat_minute_03,
        R.drawable.ic_stat_minute_04, R.drawable.ic_stat_minute_05,
        R.drawable.ic_stat_minute_06, R.drawable.ic_stat_minute_07,
        R.drawable.ic_stat_minute_08, R.drawable.ic_stat_minute_09,
        R.drawable.ic_stat_minute_10, R.drawable.ic_stat_minute_11,
        R.drawable.ic_stat_minute_12, R.drawable.ic_stat_minute_13,
        R.drawable.ic_stat_minute_14, R.drawable.ic_stat_minute_15,
        R.drawable.ic_stat_minute_16, R.drawable.ic_stat_minute_17,
        R.drawable.ic_stat_minute_18, R.drawable.ic_stat_minute_19,
        R.drawable.ic_stat_minute_20, R.drawable.ic_stat_minute_21,
        R.drawable.ic_stat_minute_22, R.drawable.ic_stat_minute_23,
        R.drawable.ic_stat_minute_24, R.drawable.ic_stat_minute_25,
        R.drawable.ic_stat_minute_26, R.drawable.ic_stat_minute_27,
        R.drawable.ic_stat_minute_28, R.drawable.ic_stat_minute_29,
        R.drawable.ic_stat_minute_30, R.drawable.ic_stat_minute_31,
        R.drawable.ic_stat_minute_32, R.drawable.ic_stat_minute_33,
        R.drawable.ic_stat_minute_34, R.drawable.ic_stat_minute_35,
        R.drawable.ic_stat_minute_36, R.drawable.ic_stat_minute_37,
        R.drawable.ic_stat_minute_38, R.drawable.ic_stat_minute_39,
        R.drawable.ic_stat_minute_40, R.drawable.ic_stat_minute_41,
        R.drawable.ic_stat_minute_42, R.drawable.ic_stat_minute_43,
        R.drawable.ic_stat_minute_44, R.drawable.ic_stat_minute_45,
        R.drawable.ic_stat_minute_46, R.drawable.ic_stat_minute_47,
        R.drawable.ic_stat_minute_48, R.drawable.ic_stat_minute_49,
        R.drawable.ic_stat_minute_50, R.drawable.ic_stat_minute_51,
        R.drawable.ic_stat_minute_52, R.drawable.ic_stat_minute_53,
        R.drawable.ic_stat_minute_54, R.drawable.ic_stat_minute_55,
        R.drawable.ic_stat_minute_56, R.drawable.ic_stat_minute_57,
        R.drawable.ic_stat_minute_58, R.drawable.ic_stat_minute_59,
        R.drawable.ic_stat_minute_60,
    )

    fun resFor(minutes: Int): Int = RES[minutes.coerceIn(0, MAX_MINUTES)]
}
