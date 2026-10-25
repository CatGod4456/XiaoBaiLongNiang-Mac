using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Media.Imaging;
using Forms = System.Windows.Forms;

public sealed class GptWidgetTray : IDisposable {
    [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr value);
    readonly Forms.NotifyIcon tray = new Forms.NotifyIcon();
    readonly Forms.ToolStripMenuItem quota = new Forms.ToolStripMenuItem("正在读取额度…");
    readonly Forms.ToolStripMenuItem onlyTray = new Forms.ToolStripMenuItem("仅显示托盘");
    Icon icon;
    Bitmap portrait;
    string badge = "?";
    public event Action<string> Requested;
    void Raise(string action) { var handler=Requested;if(handler!=null)handler(action); }
    public GptWidgetTray() {
        var menu=new Forms.ContextMenuStrip();quota.Enabled=false;menu.Items.Add(quota);
        Add(menu,"查看额度","quota");Add(menu,"刷新额度","refresh");
        onlyTray.CheckOnClick=false;onlyTray.Click+=(s,e)=>Raise("toggle");menu.Items.Add(onlyTray);
        Add(menu,"挂件设置","settings");menu.Items.Add(new Forms.ToolStripSeparator());Add(menu,"退出 小白龙娘","exit");
        tray.ContextMenuStrip=menu;tray.DoubleClick+=(s,e)=>Raise("quota");tray.Text="小白龙娘 · Codex 额度";
        Redraw();tray.Visible=true;
    }
    void Add(Forms.ContextMenuStrip menu,string title,string action) { var item=new Forms.ToolStripMenuItem(title);item.Click+=(s,e)=>Raise(action);menu.Items.Add(item); }
    public void SetPortrait(BitmapSource image) {
        var encoder=new PngBitmapEncoder();encoder.Frames.Add(BitmapFrame.Create(image));
        using(var stream=new MemoryStream()) {
            encoder.Save(stream);stream.Position=0;
            using(var decoded=new Bitmap(stream)) { if(portrait!=null)portrait.Dispose();portrait=new Bitmap(decoded); }
        }
        Redraw();
    }
    public void Update(string value,string tooltip,bool hidden) {
        onlyTray.Checked=hidden;quota.Text=tooltip;
        string text="小白龙娘 · "+tooltip;tray.Text=text.Length>63?text.Substring(0,63):text;
        if(value!=badge){badge=value;Redraw();}
    }
    void Redraw() {
        using(var bitmap=new Bitmap(64,64)) {
            using(var g=Graphics.FromImage(bitmap)) {
                g.Clear(Color.Transparent);g.SmoothingMode=SmoothingMode.AntiAlias;g.InterpolationMode=InterpolationMode.HighQualityBicubic;
                if(portrait!=null)g.DrawImage(portrait,new Rectangle(6,0,52,48));
                using(var brush=new SolidBrush(Color.FromArgb(240,91,65,130)))g.FillRectangle(brush,2,39,60,25);
                using(var font=new Font("Segoe UI",18,FontStyle.Bold,GraphicsUnit.Pixel))
                using(var text=new SolidBrush(Color.White))
                using(var format=new StringFormat{Alignment=StringAlignment.Center,LineAlignment=StringAlignment.Center})g.DrawString(badge,font,text,new RectangleF(1,38,62,26),format);
            }
            IntPtr handle=bitmap.GetHicon();Icon next;
            try{using(var borrowed=Icon.FromHandle(handle)){next=(Icon)borrowed.Clone();}}finally{DestroyIcon(handle);}
            var previous=icon;icon=next;tray.Icon=next;if(previous!=null)previous.Dispose();
        }
    }
    public void Dispose() { tray.Visible=false;var menu=tray.ContextMenuStrip;tray.Dispose();if(menu!=null)menu.Dispose();if(icon!=null)icon.Dispose();if(portrait!=null)portrait.Dispose(); }
}
