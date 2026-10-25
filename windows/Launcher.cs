using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Reflection;
[assembly: AssemblyTitle("Xiao Bai Long Niang")]
[assembly: AssemblyDescription("Community Codex quota widget for Windows")]
[assembly: AssemblyVersion("APP_VERSION")]
[assembly: AssemblyFileVersion("APP_VERSION")]
internal static class Launcher {
    [STAThread] static int Main(string[] args) {
        string app = Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"gpt-niang-usage");
        try {
            if (!File.Exists(Path.Combine(app,"installation.json"))) {
                string script=Path.Combine(app,"Install.ps1");
                var registration=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),@"System32\WindowsPowerShell\v1.0\powershell.exe"),"-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \""+script+"\"");
                registration.UseShellExecute=false;registration.CreateNoWindow=true;registration.WorkingDirectory=app;
                using(var process=Process.Start(registration)) { process.WaitForExit();if(process.ExitCode!=0)throw new InvalidOperationException("Please install and sign in to the Codex desktop app, then run Setup again."); }
            }
            var start=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),@"System32\wscript.exe"),"\""+Path.Combine(app,"launch.vbs")+"\"");
            start.UseShellExecute=false;start.CreateNoWindow=true;start.WorkingDirectory=app;Process.Start(start);
            return 0;
        } catch { MessageBox.Show("The widget could not start. Please install and sign in to Codex, then run the installer again. Your saved preferences are kept.","Xiao Bai Long Niang",MessageBoxButtons.OK,MessageBoxIcon.Information);return 1; }
    }
}
