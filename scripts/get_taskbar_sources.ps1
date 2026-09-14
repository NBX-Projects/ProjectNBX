$code = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Diagnostics;
using System.Windows.Forms;

public class NativeSourceDetector {
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
    public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);

    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hwnd, IntPtr hdcBmp, uint nFlags);

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out int pvAttribute, int cbAttribute);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TOOLWINDOW = 0x00000080;
    private const int WS_EX_APPWINDOW = 0x00040000;
    private const uint GW_OWNER = 4;
    private const int DWMWA_CLOAKED = 14;

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public class WindowDto {
        public long handle { get; set; }
        public string title { get; set; }
        public string app { get; set; }
        public uint pid { get; set; }
        public bool isMinimized { get; set; }
        public string thumbnail { get; set; }
    }

    public class ScreenDto {
        public string id { get; set; }
        public string title { get; set; }
        public string resolution { get; set; }
        public bool isPrimary { get; set; }
        public string thumbnail { get; set; }
    }

    public class ResultDto {
        public List<ScreenDto> screens { get; set; }
        public List<WindowDto> windows { get; set; }
    }

    public static ResultDto GetAllSources() {
        var res = new ResultDto();
        res.screens = new List<ScreenDto>();
        res.windows = new List<WindowDto>();

        // 1. Screens
        int sIdx = 1;
        foreach (Screen s in Screen.AllScreens) {
            string thumbB64 = "";
            try {
                using (Bitmap bmp = new Bitmap(s.Bounds.Width, s.Bounds.Height)) {
                    using (Graphics g = Graphics.FromImage(bmp)) {
                        g.CopyFromScreen(s.Bounds.X, s.Bounds.Y, 0, 0, s.Bounds.Size);
                    }
                    using (Bitmap thumb = new Bitmap(320, 180)) {
                        using (Graphics gThumb = Graphics.FromImage(thumb)) {
                            gThumb.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                            gThumb.DrawImage(bmp, 0, 0, 320, 180);
                            using (MemoryStream ms = new MemoryStream()) {
                                thumb.Save(ms, ImageFormat.Jpeg);
                                thumbB64 = Convert.ToBase64String(ms.ToArray());
                            }
                        }
                    }
                }
            } catch {}

            res.screens.Add(new ScreenDto {
                id = "screen_" + sIdx,
                title = s.Primary ? "Tela " + sIdx + " (Principal)" : "Tela " + sIdx,
                resolution = s.Bounds.Width + " × " + s.Bounds.Height,
                isPrimary = s.Primary,
                thumbnail = thumbB64
            });
            sIdx++;
        }

        // 2. Windows on winsta0/default
        IntPtr hwinsta = OpenWindowStation("winsta0", false, 0x00020000 | 0x037F);
        if (hwinsta != IntPtr.Zero) {
            SetProcessWindowStation(hwinsta);
            IntPtr hdesk = OpenDesktop("default", 0, false, 0x01FF);
            if (hdesk != IntPtr.Zero) {
                EnumDesktopWindows(hdesk, (hWnd, lParam) => {
                    bool visible = IsWindowVisible(hWnd);
                    bool iconic = IsIconic(hWnd);
                    if (!visible && !iconic) return true;

                    // Filter out cloaked windows (suspended UWP apps like SystemSettings, hidden background windows)
                    int isCloaked = 0;
                    if (DwmGetWindowAttribute(hWnd, DWMWA_CLOAKED, out isCloaked, sizeof(int)) == 0) {
                        if (isCloaked != 0) return true;
                    }

                    IntPtr owner = GetWindow(hWnd, GW_OWNER);
                    int exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
                    if ((exStyle & WS_EX_TOOLWINDOW) != 0 && (exStyle & WS_EX_APPWINDOW) == 0) return true;
                    if (owner != IntPtr.Zero && (exStyle & WS_EX_APPWINDOW) == 0) return true;

                    StringBuilder sb = new StringBuilder(512);
                    if (GetWindowText(hWnd, sb, 512) > 0) {
                        string title = sb.ToString().Trim();
                        if (string.IsNullOrEmpty(title)) return true;

                        string lower = title.ToLower();
                        if (lower == "program manager" || lower == "default ime" || lower == "msctfime ui" ||
                            lower.Contains("desktopwindowxaml") || lower.Contains("overlay input trap") ||
                            lower == "settings" || lower.Contains("configura") ||
                            lower.Contains("janela de estouro") || lower.Contains("experi") ||
                            lower.Contains("input experience") || lower == "dwm notification window" ||
                            lower.Contains("powertoys") || lower.Contains("spotifylauncher") ||
                            lower.Contains("quick access")) return true;

                        uint pid;
                        GetWindowThreadProcessId(hWnd, out pid);
                        string app = "";
                        try {
                            app = Process.GetProcessById((int)pid).ProcessName + ".exe";
                        } catch {}

                        string appLower = app.ToLower();
                        // Filter out ProjectNBX itself (only the exact projectnbx.exe process, preserving IDEs/terminals/editors working on projectNBX)
                        if (appLower == "projectnbx.exe") return true;

                        // Filter out Windows internal background/system hosts
                        if (appLower.Contains("textinputhost") ||
                            appLower.Contains("systemsettings") ||
                            appLower.Contains("shellexperiencehost") ||
                            appLower.Contains("startmenuexperiencehost") ||
                            appLower.Contains("searchhost") ||
                            appLower.Contains("searchapp") ||
                            appLower.Contains("searchui") ||
                            appLower.Contains("lockapp") ||
                            appLower.Contains("screenclippinghost") ||
                            appLower.Contains("securityhealth") ||
                            appLower.Contains("applicationframehost") ||
                            appLower.Contains("powertoys") ||
                            appLower.Contains("spotifylauncher")) return true;

                        string thumbB64 = "";
                        RECT rect;
                        GetWindowRect(hWnd, out rect);
                        int w = rect.Right - rect.Left;
                        int h = rect.Bottom - rect.Top;

                        if (w > 100 && h > 100 && !iconic) {
                            try {
                                using (Bitmap bmp = new Bitmap(w, h)) {
                                    using (Graphics g = Graphics.FromImage(bmp)) {
                                        IntPtr hdc = g.GetHdc();
                                        bool ok = PrintWindow(hWnd, hdc, 2); // PW_RENDERFULLCONTENT
                                        g.ReleaseHdc(hdc);
                                        if (ok) {
                                            using (Bitmap thumb = new Bitmap(320, 180)) {
                                                using (Graphics gThumb = Graphics.FromImage(thumb)) {
                                                    gThumb.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                                                    gThumb.DrawImage(bmp, 0, 0, 320, 180);
                                                    using (MemoryStream ms = new MemoryStream()) {
                                                        thumb.Save(ms, ImageFormat.Jpeg);
                                                        thumbB64 = Convert.ToBase64String(ms.ToArray());
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {}
                        }

                        res.windows.Add(new WindowDto {
                            handle = hWnd.ToInt64(),
                            title = title,
                            app = app,
                            pid = pid,
                            isMinimized = iconic,
                            thumbnail = thumbB64
                        });
                    }
                    return true;
                }, IntPtr.Zero);
            }
        }

        return res;
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing, System.Windows.Forms
$res = [NativeSourceDetector]::GetAllSources()
$json = $res | ConvertTo-Json -Depth 4 -Compress
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Output $json
