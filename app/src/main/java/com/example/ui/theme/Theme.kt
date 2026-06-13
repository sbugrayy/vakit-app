package com.example.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme = darkColorScheme(
    primary = GreenPrimaryDark,
    secondary = GreenSecondaryDark,
    tertiary = GreenTertiaryDark,
    background = GreenBackgroundDark,
    surface = GreenSurfaceDark,
    onPrimary = GreenOnPrimaryDark,
    onBackground = GreenOnBackgroundDark,
    onSurface = GreenOnBackgroundDark,
    primaryContainer = GreenContainerDark,
    onPrimaryContainer = GreenOnContainerDark,
    outline = GreenBorderDark
)

private val LightColorScheme = lightColorScheme(
    primary = GreenPrimaryLight,
    secondary = GreenSecondaryLight,
    tertiary = GreenTertiaryLight,
    background = GreenBackgroundLight,
    surface = GreenSurfaceLight,
    onPrimary = GreenOnPrimaryLight,
    onBackground = GreenOnBackgroundLight,
    onSurface = GreenOnBackgroundLight,
    primaryContainer = GreenContainerLight,
    onPrimaryContainer = GreenPrimaryLight,
    outline = Color(0xFFC4C8C3)
)

@Composable
fun MyApplicationTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
