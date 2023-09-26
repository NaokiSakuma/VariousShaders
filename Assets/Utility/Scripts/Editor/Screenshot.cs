using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace Utility
{
    public static class Screenshot
    {
        [MenuItem("Tools/Screenshot %F3", false)]
        public static void CaptureScreenshot()
        {
            var homePath = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            var savePath = Path.Combine(homePath, "Downloads", "Blog");
            var fullPath = Path.GetFullPath(savePath);
            var fileName = DateTime.Now.ToString("yyyy-MM-dd HH.mm.ss") + ".png";
            var path = Path.Combine(fullPath, fileName);

            if (!Directory.Exists(fullPath))
            {
                Directory.CreateDirectory(fullPath);
            }

            ScreenCapture.CaptureScreenshot(path);
            Debug.Log($"Screenshot Save : {path}");
        }
    }
}
