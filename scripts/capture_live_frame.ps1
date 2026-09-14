param (
    [string]$Type = "screen",
    [string]$SourceId = "",
    [string]$Title = "",
    [int]$Width = 960,
    [int]$Height = 540,
    [int]$Quality = 65
)

$code = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public class FastLiveFrameCapturer {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr OpenWindowStation(string lpszWinSta, bool fInherit, uint dwDesiredAccess);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetProcessWindowStation(IntPtr hWinSta);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr OpenDesktop(string lpszDesktop, uint dwFlags, bool fInherit, uint dwDesiredAccess);

    [DllImport("user32.dll")]
    public static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumWindowsProc lpfn, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBmp, uint nFlags);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    private static void EnsureDesktopAccess() {
        try {
            IntPtr hwinsta = OpenWindowStation("winsta0", false, 0x00020000 | 0x037F);
            if (hwinsta != IntPtr.Zero) {
                SetProcessWindowStation(hwinsta);
                IntPtr hdesk = OpenDesktop("default", 0, false, 0x01FF);
            }
        } catch {}
    }

    private static ImageCodecInfo GetEncoder(ImageFormat format) {
        ImageCodecInfo[] codecs = ImageCodecInfo.GetImageDecoders();
        foreach (ImageCodecInfo codec in codecs) {
            if (codec.FormatID == format.Guid) return codec;
        }
        return null;
    }

    private static string BitmapToBase64(Bitmap bmp, int targetWidth, int targetHeight, long quality) {
        if (targetWidth <= 0 || targetHeight <= 0) {
            targetWidth = 960;
            targetHeight = 540;
        }
        using (Bitmap resized = new Bitmap(targetWidth, targetHeight)) {
            using (Graphics g = Graphics.FromImage(resized)) {
                g.InterpolationMode = InterpolationMode.Bilinear;
                g.PixelOffsetMode = PixelOffsetMode.HighSpeed;
                g.SmoothingMode = SmoothingMode.HighSpeed;
                g.DrawImage(bmp, 0, 0, targetWidth, targetHeight);
            }
            using (MemoryStream ms = new MemoryStream()) {
                ImageCodecInfo encoder = GetEncoder(ImageFormat.Jpeg);
                if (encoder != null) {
                    EncoderParameters encoderParams = new EncoderParameters(1);
                    encoderParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
                    resized.Save(ms, encoder, encoderParams);
                } else {
                    resized.Save(ms, ImageFormat.Jpeg);
                }
                return Convert.ToBase64String(ms.ToArray());
            }
        }
    }

    public static string CaptureScreen(int screenIndex, int targetWidth, int targetHeight, long quality) {
        EnsureDesktopAccess();
        Screen[] screens = Screen.AllScreens;
        if (screens.Length == 0) return "";
        int idx = (screenIndex >= 0 && screenIndex < screens.Length) ? screenIndex : 0;
        Screen s = screens[idx];
        using (Bitmap bmp = new Bitmap(s.Bounds.Width, s.Bounds.Height)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(s.Bounds.X, s.Bounds.Y, 0, 0, s.Bounds.Size);
            }
            return BitmapToBase64(bmp, targetWidth, targetHeight, quality);
        }
    }

    public static string CaptureWindow(string targetTitle, long targetHandle, int targetWidth, int targetHeight, long quality) {
        EnsureDesktopAccess();
        IntPtr targetHwnd = IntPtr.Zero;
        if (targetHandle > 0) {
            targetHwnd = new IntPtr(targetHandle);
        }

        if (targetHwnd == IntPtr.Zero && !string.IsNullOrEmpty(targetTitle)) {
            string lowerTarget = targetTitle.ToLower().Trim();
            IntPtr hwinsta = OpenWindowStation("winsta0", false, 0x00020000 | 0x037F);
            if (hwinsta != IntPtr.Zero) {
                SetProcessWindowStation(hwinsta);
                IntPtr hdesk = OpenDesktop("default", 0, false, 0x01FF);
                if (hdesk != IntPtr.Zero) {
                    EnumDesktopWindows(hdesk, (hWnd, lParam) => {
                        if (!IsWindowVisible(hWnd)) return true;
                        StringBuilder sb = new StringBuilder(512);
                        if (GetWindowText(hWnd, sb, 512) > 0) {
                            string title = sb.ToString().Trim();
                            string lower = title.ToLower();
                            if (lower == lowerTarget || lower.Contains(lowerTarget) || lowerTarget.Contains(lower)) {
                                targetHwnd = hWnd;
                                return false; // stop enum
                            }
                        }
                        return true;
                    }, IntPtr.Zero);
                }
            }
        }

        if (targetHwnd != IntPtr.Zero) {
            RECT rect;
            GetWindowRect(targetHwnd, out rect);
            int w = rect.Right - rect.Left;
            int h = rect.Bottom - rect.Top;
            if (w > 50 && h > 50) {
                try {
                    using (Bitmap bmp = new Bitmap(w, h)) {
                        using (Graphics g = Graphics.FromImage(bmp)) {
                            IntPtr hdc = g.GetHdc();
                            bool ok = PrintWindow(targetHwnd, hdc, 2); // PW_RENDERFULLCONTENT
                            g.ReleaseHdc(hdc);
                            if (ok) {
                                return BitmapToBase64(bmp, targetWidth, targetHeight, quality);
                            }
                        }
                    }
                } catch {}

                // Fallback to CopyFromScreen for hardware-accelerated / layered windows
                try {
                    using (Bitmap bmp = new Bitmap(w, h)) {
                        using (Graphics g = Graphics.FromImage(bmp)) {
                            g.CopyFromScreen(rect.Left, rect.Top, 0, 0, new Size(w, h));
                        }
                        return BitmapToBase64(bmp, targetWidth, targetHeight, quality);
                    }
                } catch {}
            }
        }

        // Ultimate fallback: Capture primary screen
        return CaptureScreen(0, targetWidth, targetHeight, quality);
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing, System.Windows.Forms

$handle = 0
if ($SourceId -match "^\d+$") {
    $handle = [int64]$SourceId
}

$screenIdx = 0
if ($SourceId -match "screen_(\d+)") {
    $screenIdx = [int]$matches[1] - 1
}

$b64 = ""
try {
    if ($Type -eq "screen") {
        $b64 = [FastLiveFrameCapturer]::CaptureScreen($screenIdx, $Width, $Height, [long]$Quality)
    } else {
        $b64 = [FastLiveFrameCapturer]::CaptureWindow($Title, $handle, $Width, $Height, [long]$Quality)
    }
} catch {
    # Fallback to screen 0
    try {
        $b64 = [FastLiveFrameCapturer]::CaptureScreen(0, $Width, $Height, [long]$Quality)
    } catch {}
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output $b64
